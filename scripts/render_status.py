#!/usr/bin/env python3
"""render_status.py — project Athena flow state into a static HTML dashboard.

The dashboard is a MECHANICAL PROJECTION of on-disk state. It is generated
by this script (normally via the SubagentStop hook `hooks/render-status.sh`)
and must never be hand-edited: every render fully overwrites the output.
The HTML is a pure function of the inputs below — if the page looks wrong,
fix the state or this script, not the page.

Inputs (all read-only):
  - plans/<slug>/plan.md          YAML frontmatter = DAG topology
                                  (mini-parser vendored from
                                  skills/athena-specformula/scripts/validate_plan.py)
  - plans/<slug>/todo|doing|done/ phase cards — folder location is the
                                  single source of truth for phase status
  - handoffs/<slug>-*.md          Gate Verdict per stage (loose parse;
                                  unparseable -> "unknown")
  - .athena/.flow-context.json    current stage / parallel_phases (optional)
  - .athena/traces/runs.jsonl     historical run summaries (last 10)

Output:
  - .athena/status.html (default) — fully self-contained: no external
    resources (works over file://), auto-reloads via inline JS
    (~5 s, paused while the detail drawer is open), light/dark via
    prefers-color-scheme. DAG nodes and kanban cards are clickable and
    open a detail drawer; all detail data is embedded at render time in
    a <script type="application/json"> blob (mechanical projection —
    the page never fetches anything).

Zero third-party dependencies (Python stdlib only).

Usage:
    python3 scripts/render_status.py [project_root] [--output PATH]
"""

import argparse
import html
import json
import re
import sys
from datetime import datetime
from pathlib import Path

ID_RE = re.compile(r"^\d{2}$")
STATUS_FOLDERS = ("todo", "doing", "done")

# ---------------------------------------------------------------------------
# Frontmatter mini-parser
# Vendored from skills/athena-specformula/scripts/validate_plan.py (the
# canonical mechanical parser for plan.md frontmatter). Keep in sync with it;
# validate_plan.py stays the source of truth for validation semantics.
# ---------------------------------------------------------------------------

def extract_frontmatter(text):
    """Return the raw frontmatter block (without --- fences), or None."""
    m = re.match(r"^---\n(.*?)\n---\s*(\n|$)", text, re.DOTALL)
    return m.group(1) if m else None


def _strip_quotes(s):
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in "\"'":
        return s[1:-1]
    return s


def _parse_inline_list(s):
    """Parse an inline YAML list like [] or ["05", "07"]."""
    s = s.strip()
    if not (s.startswith("[") and s.endswith("]")):
        raise ValueError(f"expected inline list, got: {s!r}")
    inner = s[1:-1].strip()
    if not inner:
        return []
    return [_strip_quotes(item) for item in inner.split(",")]


def parse_frontmatter(fm_text):
    """Mini-parser for the fixed plan frontmatter schema (no pyyaml needed).

    Tolerant by design: unknown nested (indented) structure is skipped, not
    raised on — the schema may grow new per-phase fields (e.g. `touches`)
    without breaking the status board. `touches` itself is parsed so the
    drawer can show ownership."""
    data = {"plan": None, "phases": [], "status_source": None}
    current = None
    in_touches = False
    for lineno, raw in enumerate(fm_text.splitlines(), start=1):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indented = raw.startswith((" ", "\t"))
        if not indented:
            current = None
            in_touches = False
            if stripped.startswith("plan:"):
                data["plan"] = _strip_quotes(stripped.split(":", 1)[1])
            elif stripped == "phases:" or stripped.startswith("phases:"):
                continue
            elif stripped.startswith("status_source:"):
                data["status_source"] = _strip_quotes(stripped.split(":", 1)[1])
            else:
                raise ValueError(f"frontmatter line {lineno}: unknown top-level key: {stripped!r}")
        else:
            if stripped.startswith("- id:"):
                in_touches = False
                current = {
                    "id": _strip_quotes(stripped.split(":", 1)[1]),
                    "name": None,
                    "depends_on": [],
                    "touches": None,
                }
                data["phases"].append(current)
            elif current is not None and stripped.startswith("name:"):
                in_touches = False
                current["name"] = _strip_quotes(stripped.split(":", 1)[1])
            elif current is not None and stripped.startswith("depends_on:"):
                in_touches = False
                current["depends_on"] = _parse_inline_list(stripped.split(":", 1)[1])
            elif current is not None and stripped.startswith("touches:"):
                in_touches = True
                current["touches"] = {}
            elif in_touches and stripped.startswith(("files:", "resources:")):
                key, _, rest = stripped.partition(":")
                try:
                    current["touches"][key] = _parse_inline_list(rest)
                except ValueError:
                    pass  # non-inline list form: ignore, board stays up
            else:
                continue  # unknown nested structure: tolerate (future schema fields)
    return data


# ---------------------------------------------------------------------------
# State collection (all read-only)
# ---------------------------------------------------------------------------

CARD_META_RE = re.compile(
    r"^\s*[-*]?\s*\**(owner|claimed_by|claimed by|started_at|started at)\**\s*[:：]\s*(\S.*)$",
    re.IGNORECASE,
)


def read_card_meta(card_path):
    """Loosely pull owner / started_at lines out of a phase card, if present."""
    meta = {}
    try:
        lines = card_path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return meta
    for line in lines[:40]:
        m = CARD_META_RE.match(line)
        if not m:
            continue
        key = m.group(1).lower().replace(" ", "_")
        if key == "claimed_by":
            key = "owner"
        meta.setdefault(key, m.group(2).strip())
    return meta


def collect_cards(plan_dir):
    """Map phase id -> {folder, name(file), path, meta} from todo/doing/done."""
    cards = {}
    for folder in STATUS_FOLDERS:
        fdir = plan_dir / folder
        if not fdir.is_dir():
            continue
        for card in sorted(fdir.glob("[0-9][0-9]-*.md")):
            pid = card.name[:2]
            cards.setdefault(pid, {
                "folder": folder,
                "file": card.name,
                "meta": read_card_meta(card),
                "path": card,
            })
    return cards


VERDICT_HEADING_RE = re.compile(r"^#{1,6}\s*.*gate\s+verdict", re.IGNORECASE)
VERDICT_INLINE_RE = re.compile(r"^\s*(?:gate\s+)?verdict\s*[:：]\s*(\S.*)$", re.IGNORECASE)


def parse_verdict(handoff_path):
    """Loose Gate Verdict extraction: (normalized, raw_line). Unknown if absent."""
    try:
        lines = handoff_path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return "unknown", ""
    raw = None
    for i, line in enumerate(lines):
        if VERDICT_HEADING_RE.match(line):
            for follow in lines[i + 1:]:
                if follow.strip():
                    raw = follow.strip()
                    break
            break
        m = VERDICT_INLINE_RE.match(line)
        if m:
            raw = m.group(1).strip()
            break
    if raw is None:
        return "unknown", ""
    token = raw.upper()
    if token.startswith("PASS"):
        return "PASS", raw
    if token.startswith("FAIL"):
        return "FAIL", raw
    return "unknown", raw


def collect_handoffs(root, slug):
    """List of {stage, file, verdict, raw} for handoffs/<slug>-*.md."""
    hdir = root / "handoffs"
    if not hdir.is_dir():
        return []
    out = []
    for f in sorted(hdir.glob(slug + "-*.md")):
        stage = f.name[len(slug) + 1:-3]
        verdict, raw = parse_verdict(f)
        out.append({"stage": stage, "file": f.name, "verdict": verdict, "raw": raw})
    return out


def load_flow_context(root):
    ctx_path = root / ".athena" / ".flow-context.json"
    if not ctx_path.is_file():
        return None
    try:
        data = json.loads(ctx_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    return data if isinstance(data, dict) else None


def load_runs(root, limit=10):
    runs_path = root / ".athena" / "traces" / "runs.jsonl"
    if not runs_path.is_file():
        return []
    runs = []
    try:
        for line in runs_path.read_text(encoding="utf-8", errors="replace").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if isinstance(d, dict):
                runs.append(d)
    except OSError:
        return []
    return runs[-limit:][::-1]  # newest first


def load_plan(plan_dir):
    """Read one plans/<slug>/ directory into a render model."""
    plan = {
        "slug": plan_dir.name,
        "phases": [],
        "parse_error": None,
        "cards": collect_cards(plan_dir),
    }
    plan_md = plan_dir / "plan.md"
    if not plan_md.is_file():
        plan["parse_error"] = "plan.md not found"
        return plan
    try:
        text = plan_md.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        plan["parse_error"] = f"plan.md unreadable: {e}"
        return plan
    fm_text = extract_frontmatter(text)
    if fm_text is None:
        plan["parse_error"] = "plan.md has no YAML frontmatter (DAG not machine-parseable)"
        return plan
    try:
        data = parse_frontmatter(fm_text)
    except Exception as e:
        plan["parse_error"] = f"frontmatter failed to parse: {e}"
        return plan
    phases = data.get("phases") or []
    plan["phases"] = [
        {
            "id": p.get("id"),
            "name": p.get("name") or "(unnamed)",
            "depends_on": [d for d in (p.get("depends_on") or [])],
            "touches": p.get("touches") or None,
        }
        for p in phases
        if isinstance(p, dict) and isinstance(p.get("id"), str) and ID_RE.match(p.get("id"))
    ]
    if not plan["phases"]:
        plan["parse_error"] = "frontmatter has no valid phases list"
    return plan


def phase_state(pid, plan, handoffs):
    """Folder status is truth; a FAIL gate on this phase paints it red
    unless the card already sits in done/ (folder wins)."""
    card = plan["cards"].get(pid)
    state = card["folder"] if card else "none"
    if state != "done":
        for h in handoffs:
            if h["verdict"] == "FAIL" and f"phase-{pid}" in h["stage"]:
                return "fail"
    return state


# ---------------------------------------------------------------------------
# Detail-drawer data (embedded JSON, rendered at projection time)
# ---------------------------------------------------------------------------

_MD_HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
_MD_LIST_RE = re.compile(r"^(?:[-*+]|\d+[.)])\s+(.*)$")
_MD_INLINE_CODE_RE = re.compile(r"`([^`]+)`")
_MD_BOLD_RE = re.compile(r"\*\*([^*]+)\*\*")


def _md_inline(escaped):
    """Inline markdown on already-HTML-escaped text (code spans, bold)."""
    escaped = _MD_INLINE_CODE_RE.sub(r"<code>\1</code>", escaped)
    escaped = _MD_BOLD_RE.sub(r"<strong>\1</strong>", escaped)
    return escaped


def md_lite(text):
    """Minimal, safe markdown -> HTML: everything is HTML-escaped first;
    headings / lists / code fences / inline code / bold get light styling.
    Deliberately NOT a full markdown parser — readable is enough."""
    out, in_list, in_code, code_buf = [], False, False, []

    def close_list():
        nonlocal in_list
        if in_list:
            out.append("</ul>")
            in_list = False

    for raw in text.splitlines():
        stripped = raw.strip()
        if stripped.startswith("```"):
            if in_code:
                out.append("<pre>" + esc("\n".join(code_buf)) + "</pre>")
                code_buf, in_code = [], False
            else:
                close_list()
                in_code = True
            continue
        if in_code:
            code_buf.append(raw)
            continue
        hm = _MD_HEADING_RE.match(stripped)
        lm = _MD_LIST_RE.match(stripped)
        if hm:
            close_list()
            lvl = min(len(hm.group(1)), 4)
            out.append(f'<div class="md-h md-h{lvl}">{_md_inline(esc(hm.group(2)))}</div>')
        elif lm:
            if not in_list:
                out.append("<ul>")
                in_list = True
            out.append("<li>" + _md_inline(esc(lm.group(1))) + "</li>")
        elif not stripped:
            close_list()
        else:
            close_list()
            out.append("<p>" + _md_inline(esc(stripped)) + "</p>")
    if in_code:
        out.append("<pre>" + esc("\n".join(code_buf)) + "</pre>")
    close_list()
    return "".join(out)


_FILES_CHANGED_RE = re.compile(r"files\s+changed", re.IGNORECASE)
_RISKS_RE = re.compile(r"\brisks?\b", re.IGNORECASE)


def extract_md_section(text, title_re):
    """Return the body of the first heading whose title matches title_re,
    up to the next heading of the same or higher level. None if absent."""
    out, level = None, 0
    for line in text.splitlines():
        m = _MD_HEADING_RE.match(line.strip())
        if m and out is None:
            if title_re.search(m.group(2)):
                out, level = [], len(m.group(1))
            continue
        if m and out is not None and len(m.group(1)) <= level:
            break
        if out is not None:
            out.append(line)
    if out is None:
        return None
    return "\n".join(out).strip() or None


def phase_gate(pid, handoffs):
    """Last handoff whose stage mentions this phase, or None."""
    hit = None
    for h in handoffs:
        if f"phase-{pid}" in h["stage"]:
            hit = h
    return hit


def build_phase_details(plan, handoffs, root):
    """Per-phase detail model for the drawer, keyed by phase id.
    Pure read-time projection: card markdown and mini-handoff excerpts are
    pre-rendered (escaped) HTML strings embedded into the JSON blob."""
    dependents = {}
    for p in plan["phases"]:
        for d in p["depends_on"]:
            dependents.setdefault(d, []).append(p["id"])
    touches_by_id = {p["id"]: p.get("touches") for p in plan["phases"]}
    details = {}

    def base_detail(pid, name, state, depends_on):
        card = plan["cards"].get(pid)
        meta = card["meta"] if card else {}
        d = {
            "id": pid,
            "name": name,
            "state": state,
            "state_label": STATE_LABEL[state],
            "depends_on": depends_on,
            "dependents": sorted(dependents.get(pid, [])),
            "touches": touches_by_id.get(pid),
            "folder": card["folder"] if card else None,
            "card_file": card["file"] if card else None,
            "owner": meta.get("owner"),
            "started_at": meta.get("started_at"),
            "gate": None,
            "card_html": None,
            "handoff": None,
        }
        g = phase_gate(pid, handoffs)
        if g:
            d["gate"] = {"verdict": g["verdict"], "raw": g["raw"], "file": g["file"]}
        if card:
            try:
                d["card_html"] = md_lite(
                    card["path"].read_text(encoding="utf-8", errors="replace")
                )
            except OSError:
                pass
        hpath = root / "handoffs" / f"{plan['slug']}-build-phase-{pid}.md"
        if hpath.is_file():
            try:
                htext = hpath.read_text(encoding="utf-8", errors="replace")
            except OSError:
                htext = None
            if htext is not None:
                fc = extract_md_section(htext, _FILES_CHANGED_RE)
                rk = extract_md_section(htext, _RISKS_RE)
                d["handoff"] = {
                    "file": hpath.name,
                    "files_changed_html": md_lite(fc) if fc else None,
                    "risks_html": md_lite(rk) if rk else None,
                }
        return d

    for p in plan["phases"]:
        pid = p["id"]
        details[pid] = base_detail(
            pid, p["name"], phase_state(pid, plan, handoffs), p["depends_on"]
        )
    # Orphan cards (present in todo|doing|done but absent from the DAG)
    for pid, card in plan["cards"].items():
        if pid not in details:
            details[pid] = base_detail(pid, card["file"], card["folder"], [])
    return details


# ---------------------------------------------------------------------------
# SVG DAG (pure-python, Kahn layering, left-to-right)
# ---------------------------------------------------------------------------

NODE_W, NODE_H = 172, 48
H_GAP, V_GAP, MARGIN = 52, 16, 14

STATE_LABEL = {
    "todo": "todo", "doing": "doing", "done": "done",
    "fail": "gate FAIL", "none": "no card",
}


def layer_phases(phases):
    """Longest-path layering via Kahn topological order. Cyclic leftovers
    are dumped into one extra trailing layer (and reported)."""
    ids = [p["id"] for p in phases]
    idset = set(ids)
    deps = {p["id"]: [d for d in p["depends_on"] if d in idset] for p in phases}
    dependents = {i: [] for i in ids}
    indeg = {i: len(deps[i]) for i in ids}
    for n in ids:
        for d in deps[n]:
            dependents[d].append(n)
    queue = [i for i in ids if indeg[i] == 0]
    layer = {}
    while queue:
        queue.sort()
        n = queue.pop(0)
        layer[n] = max((layer[d] + 1 for d in deps[n]), default=0)
        for m in dependents[n]:
            indeg[m] -= 1
            if indeg[m] == 0:
                queue.append(m)
    cyclic = sorted(i for i in ids if i not in layer)
    if cyclic:
        nxt = max(layer.values(), default=-1) + 1
        for i in cyclic:
            layer[i] = nxt
    return layer, deps, cyclic


def esc(s):
    return html.escape(str(s), quote=True)


def truncate(s, n):
    return s if len(s) <= n else s[: n - 1] + "…"


def render_dag_svg(plan, handoffs, uid):
    phases = plan["phases"]
    if not phases:
        return ""
    layer, deps, cyclic = layer_phases(phases)
    columns = {}
    for p in phases:
        columns.setdefault(layer[p["id"]], []).append(p["id"])
    for col in columns.values():
        col.sort()
    ncols = max(columns) + 1
    nrows = max(len(v) for v in columns.values())
    width = 2 * MARGIN + ncols * NODE_W + (ncols - 1) * H_GAP
    height = 2 * MARGIN + nrows * NODE_H + (nrows - 1) * V_GAP
    pos = {}
    for c, col in sorted(columns.items()):
        for r, pid in enumerate(col):
            pos[pid] = (MARGIN + c * (NODE_W + H_GAP), MARGIN + r * (NODE_H + V_GAP))

    parts = []
    parts.append(
        f'<svg class="dag" id="dag-{uid}" role="img" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" '
        f'aria-label="Dependency graph for {esc(plan["slug"])}">'
    )
    parts.append(
        f'<defs><marker id="arrow-{uid}" viewBox="0 0 10 10" refX="9" refY="5" '
        f'markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
        f'<path class="dag-arrowhead" d="M0,0 L10,5 L0,10 z"/></marker>'
        f'<marker id="arrow-hl-{uid}" viewBox="0 0 10 10" refX="9" refY="5" '
        f'markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
        f'<path class="dag-arrowhead-hl" d="M0,0 L10,5 L0,10 z"/></marker></defs>'
    )
    # edges first (under nodes); data-from/data-to drive JS highlight
    for pid in sorted(deps):
        x2, y2 = pos[pid]
        for d in deps[pid]:
            x1, y1 = pos[d]
            sx, sy = x1 + NODE_W, y1 + NODE_H / 2
            ex, ey = x2, y2 + NODE_H / 2
            mx = (sx + ex) / 2
            parts.append(
                f'<path class="dag-edge" data-from="{esc(d)}" data-to="{esc(pid)}" '
                f'marker-end="url(#arrow-{uid})" '
                f'd="M{sx:.1f},{sy:.1f} C{mx:.1f},{sy:.1f} {mx:.1f},{ey:.1f} {ex - 2:.1f},{ey:.1f}"/>'
            )
    # nodes
    name_by_id = {p["id"]: p["name"] for p in phases}
    for pid, (x, y) in sorted(pos.items()):
        state = phase_state(pid, plan, handoffs)
        label = STATE_LABEL[state]
        name = name_by_id.get(pid, "")
        parts.append(
            f'<g class="dag-node st-{state}" data-phase="{esc(pid)}" data-uid="{uid}" '
            f'role="button" tabindex="0" '
            f'aria-label="{esc(pid)} {esc(name)}，狀態 {esc(label)}，按 Enter 看詳情">'
        )
        parts.append(f'<title>{esc(pid)} {esc(name)} — {esc(label)}</title>')
        parts.append(
            f'<rect class="card" x="{x}" y="{y}" width="{NODE_W}" height="{NODE_H}" rx="7"/>'
        )
        parts.append(
            f'<text class="node-title" x="{x + 12}" y="{y + 20}">'
            f'{esc(pid)} · {esc(truncate(name, 18))}</text>'
        )
        parts.append(f'<circle class="node-dot" cx="{x + 16}" cy="{y + 34}" r="4"/>')
        parts.append(
            f'<text class="node-status" x="{x + 25}" y="{y + 38}">{esc(label)}</text>'
        )
        parts.append("</g>")
    parts.append("</svg>")
    if cyclic:
        parts.append(
            '<p class="warn">依賴圖含循環，以下 phase 無法分層：'
            + esc(", ".join(cyclic)) + "</p>"
        )
    return "".join(parts)


# ---------------------------------------------------------------------------
# HTML sections
# ---------------------------------------------------------------------------

def render_kanban(plan, uid):
    name_by_id = {p["id"]: p["name"] for p in plan["phases"]}
    cols = []
    for folder in STATUS_FOLDERS:
        items = sorted(
            (pid, c) for pid, c in plan["cards"].items() if c["folder"] == folder
        )
        cards_html = []
        for pid, c in items:
            meta = c["meta"]
            extra = ""
            if meta.get("owner"):
                extra += f'<div class="card-meta">owner: {esc(meta["owner"])}</div>'
            if meta.get("started_at"):
                extra += f'<div class="card-meta">started: {esc(meta["started_at"])}</div>'
            title = name_by_id.get(pid) or c["file"]
            cards_html.append(
                f'<li class="kcard" data-phase="{esc(pid)}" data-uid="{uid}" '
                f'role="button" tabindex="0">'
                f'<span class="kcard-id">{esc(pid)}</span> {esc(title)}{extra}</li>'
            )
        body = "".join(cards_html) or '<li class="kempty">—</li>'
        cols.append(
            f'<div class="kcol kcol-{folder}"><h4>{folder} '
            f'<span class="count">{len(items)}</span></h4><ul>{body}</ul></div>'
        )
    return '<div class="kanban">' + "".join(cols) + "</div>"


def render_gate_table(handoffs):
    if not handoffs:
        return '<p class="muted">尚無 handoff。</p>'
    rows = []
    for h in handoffs:
        cls = {"PASS": "v-pass", "FAIL": "v-fail"}.get(h["verdict"], "v-unknown")
        rows.append(
            "<tr>"
            f"<td><code>{esc(h['file'])}</code></td>"
            f"<td>{esc(h['stage'])}</td>"
            f'<td><span class="badge {cls}"><span class="dot"></span>{esc(h["verdict"])}</span></td>'
            f'<td class="raw">{esc(truncate(h["raw"], 90))}</td>'
            "</tr>"
        )
    return (
        '<div class="tblwrap"><table><thead><tr>'
        "<th>Handoff</th><th>Stage</th><th>Verdict</th><th>摘要</th>"
        "</tr></thead><tbody>" + "".join(rows) + "</tbody></table></div>"
    )


def render_runs_table(runs):
    if not runs:
        return '<p class="muted">尚無 run 紀錄（<code>.athena/traces/runs.jsonl</code> 不存在或為空）。</p>'
    rows = []
    for r in runs:
        point = r.get("point") or {}
        verdict = point.get("verdict", "—") if isinstance(point, dict) else "—"
        rows.append(
            "<tr>"
            f"<td><code>{esc(r.get('run_id', '—'))}</code></td>"
            f"<td>{esc(r.get('ts', '—'))}</td>"
            f"<td>{esc(r.get('slug', '—'))}</td>"
            f"<td>{esc(r.get('trigger', '—'))}</td>"
            f"<td>{esc(verdict)}</td>"
            f"<td>{esc(r.get('weight', '—'))}</td>"
            f"<td>{esc(r.get('outcome', '—'))}</td>"
            "</tr>"
        )
    return (
        '<div class="tblwrap"><table><thead><tr>'
        "<th>Run</th><th>時間</th><th>Slug</th><th>Trigger</th>"
        "<th>Point</th><th>Weight</th><th>Outcome</th>"
        "</tr></thead><tbody>" + "".join(rows) + "</tbody></table></div>"
    )


def render_plan_section(plan, handoffs, active, ctx, uid):
    parts = [f'<section class="plan" id="plan-{esc(plan["slug"])}">']
    badge = '<span class="active-badge">active</span>' if active else ""
    parts.append(f'<h2>{esc(plan["slug"])} {badge}</h2>')
    if active and ctx:
        stage = ctx.get("triggering_stage") or "—"
        par = ctx.get("parallel_phases")
        par_txt = f"、parallel_phases: {esc(par)}" if par else ""
        parts.append(
            f'<p class="ctx">當前 stage: <strong>{esc(stage)}</strong>{par_txt}</p>'
        )
    if plan["parse_error"]:
        parts.append(f'<p class="warn">{esc(plan["parse_error"])}</p>')
    if plan["phases"]:
        parts.append('<div class="dag-wrap">' + render_dag_svg(plan, handoffs, uid) + "</div>")
    parts.append(render_kanban(plan, uid))
    parts.append("<h3>Gate Verdicts</h3>")
    parts.append(render_gate_table(handoffs))
    parts.append("</section>")
    return "".join(parts)


CSS = """
:root {
  color-scheme: light dark;
  --page: #f9f9f7; --surface: #fcfcfb;
  --ink: #0b0b0b; --ink2: #52514e; --muted: #898781;
  --grid: #e1e0d9; --border: rgba(11,11,11,.10); --edge: #91907f;
  --st-todo: #898781; --st-doing: #2a78d6; --st-done: #0ca30c;
  --st-fail: #d03b3b; --st-none: #898781;
}
@media (prefers-color-scheme: dark) {
  :root {
    --page: #0d0d0d; --surface: #1a1a19;
    --ink: #ffffff; --ink2: #c3c2b7; --muted: #898781;
    --grid: #2c2c2a; --border: rgba(255,255,255,.10); --edge: #7d7c72;
    --st-doing: #3987e5;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0; padding: 24px; background: var(--page); color: var(--ink);
  font: 14px/1.5 system-ui, -apple-system, "Segoe UI", sans-serif;
}
main { max-width: 1100px; margin: 0 auto; }
h1 { font-size: 20px; margin: 0 0 4px; }
h2 { font-size: 17px; margin: 0 0 10px; }
h3 { font-size: 14px; margin: 18px 0 8px; color: var(--ink2); }
h4 { font-size: 13px; margin: 0 0 8px; color: var(--ink2); }
code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 12px; }
.gen-meta { color: var(--muted); font-size: 12px; margin: 0 0 6px; }
.principle { color: var(--muted); font-size: 12px; margin: 0 0 20px; }
.muted { color: var(--muted); }
.warn { color: var(--st-fail); font-size: 13px; }
section.plan, section.runs {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 10px; padding: 18px 20px; margin: 0 0 18px;
}
.active-badge {
  display: inline-block; font-size: 11px; font-weight: 600;
  color: var(--st-doing); border: 1px solid var(--st-doing);
  border-radius: 999px; padding: 1px 9px; vertical-align: 2px;
}
.ctx { color: var(--ink2); font-size: 13px; margin: 0 0 10px; }
.dag-wrap { overflow-x: auto; padding: 4px 0 10px; }
.dag-edge { stroke: var(--edge); stroke-width: 1.5; fill: none; }
.dag-arrowhead { fill: var(--edge); }
.dag-node rect.card { fill: var(--surface); stroke-width: 1.5; }
.dag-node.st-todo rect.card, .dag-node.st-none rect.card
  { stroke: var(--st-todo); fill: var(--st-todo); fill-opacity: .08; }
.dag-node.st-none rect.card { stroke-dasharray: 4 3; }
.dag-node.st-doing rect.card { stroke: var(--st-doing); fill: var(--st-doing); fill-opacity: .12; }
.dag-node.st-done rect.card { stroke: var(--st-done); fill: var(--st-done); fill-opacity: .10; }
.dag-node.st-fail rect.card { stroke: var(--st-fail); fill: var(--st-fail); fill-opacity: .12; }
.node-title { fill: var(--ink); font-size: 12.5px; font-weight: 600; }
.node-status { fill: var(--ink2); font-size: 11px; }
.dag-node .node-dot { fill: var(--st-todo); }
.dag-node.st-doing .node-dot { fill: var(--st-doing); }
.dag-node.st-done .node-dot { fill: var(--st-done); }
.dag-node.st-fail .node-dot { fill: var(--st-fail); }
.kanban { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin-top: 6px; }
@media (max-width: 720px) { .kanban { grid-template-columns: 1fr; } }
.kcol { border: 1px solid var(--border); border-radius: 8px; padding: 10px 12px; min-width: 0; }
.kcol .count { color: var(--muted); font-weight: 400; }
.kcol ul { list-style: none; margin: 0; padding: 0; }
.kcard {
  border: 1px solid var(--grid); border-left: 3px solid var(--st-todo);
  border-radius: 6px; padding: 6px 9px; margin: 0 0 6px; font-size: 13px;
  overflow-wrap: anywhere;
}
.kcol-doing .kcard { border-left-color: var(--st-doing); }
.kcol-done .kcard { border-left-color: var(--st-done); }
.kcard-id { font-weight: 600; color: var(--ink2); }
.card-meta { color: var(--muted); font-size: 11.5px; }
.kempty { color: var(--muted); }
.tblwrap { overflow-x: auto; }
table { border-collapse: collapse; width: 100%; font-size: 13px; }
th, td { text-align: left; padding: 5px 10px 5px 0; border-bottom: 1px solid var(--grid); }
th { color: var(--ink2); font-weight: 600; }
td.raw { color: var(--ink2); }
.badge { display: inline-flex; align-items: center; gap: 6px; white-space: nowrap; }
.badge .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--muted); }
.badge.v-pass .dot { background: var(--st-done); }
.badge.v-fail .dot { background: var(--st-fail); }
footer { color: var(--muted); font-size: 12px; margin: 8px 0 0; }
.skip-note { color: var(--muted); font-size: 12px; margin: 8px 0 0; }

/* ---- interactivity: clickable nodes / cards ---- */
.dag-node, .kcard[role="button"] { cursor: pointer; }
.dag-node:focus { outline: none; }
.dag-node:focus rect.card, .dag-node:hover rect.card { stroke-width: 2.5; }
.kcard[role="button"]:hover { border-color: var(--st-doing); }
.kcard[role="button"]:focus-visible, .chip:focus-visible, .drawer-close:focus-visible
  { outline: 2px solid var(--st-doing); outline-offset: 2px; }

/* ---- selection highlight: upstream/downstream edges pop, rest dim ---- */
svg.dag.has-selection .dag-node { opacity: .35; }
svg.dag.has-selection .dag-node.selected,
svg.dag.has-selection .dag-node.adjacent { opacity: 1; }
svg.dag.has-selection .dag-edge { opacity: .18; }
svg.dag.has-selection .dag-edge.hl {
  opacity: 1; stroke: var(--st-doing); stroke-width: 2.4;
}
.dag-arrowhead-hl { fill: var(--st-doing); }
svg.dag .dag-node.selected rect.card { stroke-width: 3; }

/* ---- detail drawer ---- */
.overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,.38); z-index: 40;
}
.drawer {
  position: fixed; top: 0; right: 0; bottom: 0; width: min(460px, 92vw);
  background: var(--surface); border-left: 1px solid var(--border);
  box-shadow: -8px 0 28px rgba(0,0,0,.18); z-index: 50;
  overflow-y: auto; padding: 16px 20px 24px;
}
.drawer-head {
  display: flex; align-items: center; justify-content: space-between;
  gap: 12px; margin: 0 0 6px;
}
.drawer-head h3 { margin: 0; font-size: 15px; color: var(--ink); }
.drawer-close {
  border: 1px solid var(--border); background: none; color: var(--ink2);
  border-radius: 6px; font-size: 16px; line-height: 1; padding: 4px 9px;
  cursor: pointer;
}
.drawer-close:hover { color: var(--ink); border-color: var(--ink2); }
.dsec { margin: 14px 0 0; }
.dsec-title {
  font-size: 11px; font-weight: 600; letter-spacing: .04em;
  text-transform: uppercase; color: var(--muted); margin: 0 0 5px;
}
.dsub { font-size: 12px; font-weight: 600; color: var(--ink2); margin: 8px 0 3px; }
.drow { font-size: 13px; color: var(--ink2); margin: 2px 0; overflow-wrap: anywhere; }
.drow.mono { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 12px; }
.st-badge {
  display: inline-block; font-size: 11px; font-weight: 600;
  border: 1px solid; border-radius: 999px; padding: 1px 9px; margin: 0 0 4px;
}
.st-badge.st-todo, .st-badge.st-none { color: var(--st-todo); }
.st-badge.st-doing { color: var(--st-doing); }
.st-badge.st-done { color: var(--st-done); }
.st-badge.st-fail { color: var(--st-fail); }
.chips { display: flex; flex-wrap: wrap; gap: 6px; }
.chip {
  border: 1px solid var(--grid); background: none; color: var(--ink);
  border-radius: 999px; font-size: 12px; padding: 2px 10px; cursor: pointer;
}
.chip:hover { border-color: var(--st-doing); color: var(--st-doing); }
.md {
  border: 1px solid var(--grid); border-radius: 8px; padding: 8px 12px;
  font-size: 12.5px; color: var(--ink2); overflow-wrap: anywhere;
}
.md p { margin: 4px 0; }
.md ul { margin: 4px 0; padding-left: 18px; }
.md li { margin: 2px 0; }
.md pre {
  background: var(--page); border: 1px solid var(--grid); border-radius: 6px;
  padding: 6px 9px; overflow-x: auto; font-size: 11.5px;
}
.md .md-h { font-weight: 600; color: var(--ink); margin: 8px 0 3px; }
.md .md-h1 { font-size: 14px; } .md .md-h2 { font-size: 13.5px; }
.md .md-h3, .md .md-h4 { font-size: 12.5px; }

/* ---- auto-refresh pause pill ---- */
.pause-pill {
  position: fixed; left: 14px; bottom: 14px; z-index: 60;
  background: var(--surface); border: 1px solid var(--border);
  color: var(--ink2); font-size: 12px; border-radius: 999px;
  padding: 4px 12px; box-shadow: 0 2px 10px rgba(0,0,0,.15);
}
[hidden] { display: none !important; }
"""

# Inline behaviour script. Zero external requests: detail data comes from the
# embedded JSON blob, auto-refresh is a plain location.reload() so the page
# works over file:// exactly like over http.
JS = r"""
(function () {
  "use strict";
  var RELOAD_MS = 5000;
  var dataEl = document.getElementById("athena-status-data");
  var DATA = {};
  try { DATA = dataEl ? JSON.parse(dataEl.textContent) : {}; } catch (e) { DATA = {}; }

  var drawer = document.getElementById("phase-drawer");
  var overlay = document.getElementById("drawer-overlay");
  var body = document.getElementById("drawer-body");
  var title = document.getElementById("drawer-title");
  var closeBtn = document.getElementById("drawer-close");
  var pill = document.getElementById("pause-pill");

  var reloadTimer = null;
  function scheduleReload() {
    if (reloadTimer) clearTimeout(reloadTimer);
    reloadTimer = setTimeout(function () { location.reload(); }, RELOAD_MS);
  }
  function cancelReload() {
    if (reloadTimer) { clearTimeout(reloadTimer); reloadTimer = null; }
  }

  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }

  function clearHighlight() {
    Array.prototype.forEach.call(
      document.querySelectorAll("svg.dag.has-selection"),
      function (svg) {
        svg.classList.remove("has-selection");
        Array.prototype.forEach.call(svg.querySelectorAll(".dag-edge.hl"), function (e) {
          e.classList.remove("hl");
          if (e.dataset.marker) e.setAttribute("marker-end", e.dataset.marker);
        });
        Array.prototype.forEach.call(
          svg.querySelectorAll(".dag-node.selected, .dag-node.adjacent"),
          function (n) { n.classList.remove("selected"); n.classList.remove("adjacent"); }
        );
      }
    );
  }

  function highlight(uid, pid) {
    clearHighlight();
    var svg = document.getElementById("dag-" + uid);
    if (!svg) return;
    var adjacent = {};
    Array.prototype.forEach.call(svg.querySelectorAll(".dag-edge"), function (e) {
      if (e.dataset.from === pid || e.dataset.to === pid) {
        e.classList.add("hl");
        if (!e.dataset.marker) e.dataset.marker = e.getAttribute("marker-end") || "";
        e.setAttribute("marker-end", "url(#arrow-hl-" + uid + ")");
        adjacent[e.dataset.from] = true;
        adjacent[e.dataset.to] = true;
      }
    });
    svg.classList.add("has-selection");
    Array.prototype.forEach.call(svg.querySelectorAll(".dag-node"), function (n) {
      var p = n.dataset.phase;
      if (p === pid) n.classList.add("selected");
      else if (adjacent[p]) n.classList.add("adjacent");
    });
  }

  function section(name) {
    var s = el("div", "dsec");
    s.appendChild(el("div", "dsec-title", name));
    return s;
  }

  function depChips(uid, ids, plan) {
    var wrap = el("div", "chips");
    if (!ids || !ids.length) {
      wrap.appendChild(el("span", "muted", "—"));
      return wrap;
    }
    ids.forEach(function (id) {
      var d = plan && plan.phases ? plan.phases[id] : null;
      var b = el("button", "chip", d && d.name ? id + " · " + d.name : id);
      b.type = "button";
      b.addEventListener("click", function () { openPhase(uid, id); });
      wrap.appendChild(b);
    });
    return wrap;
  }

  function mdBlock(htmlStr) {
    var n = el("div", "md");
    n.innerHTML = htmlStr; // pre-rendered + escaped at projection time
    return n;
  }

  function openPhase(uid, pid) {
    var plan = DATA[uid];
    var d = (plan && plan.phases && plan.phases[pid]) || {
      id: pid, name: "", state: "none", state_label: "no card",
      depends_on: [], dependents: []
    };
    title.textContent = d.name ? pid + " · " + d.name : pid;
    body.innerHTML = "";

    var meta = section("狀態");
    meta.appendChild(el("span", "st-badge st-" + d.state, d.state_label));
    if (d.owner) meta.appendChild(el("div", "drow", "owner: " + d.owner));
    if (d.started_at) meta.appendChild(el("div", "drow", "started: " + d.started_at));
    if (d.card_file) {
      meta.appendChild(el("div", "drow mono", (d.folder || "?") + "/" + d.card_file));
    }
    body.appendChild(meta);

    var dep = section("依賴 depends_on");
    dep.appendChild(depChips(uid, d.depends_on, plan));
    body.appendChild(dep);
    var rdep = section("被依賴 dependents");
    rdep.appendChild(depChips(uid, d.dependents, plan));
    body.appendChild(rdep);

    var tch = d.touches;
    if (tch && ((tch.files && tch.files.length) || (tch.resources && tch.resources.length))) {
      var town = section("Touches 所有權");
      if (tch.files && tch.files.length)
        town.appendChild(el("div", "drow mono", "files: " + tch.files.join(", ")));
      if (tch.resources && tch.resources.length)
        town.appendChild(el("div", "drow mono", "resources: " + tch.resources.join(", ")));
      body.appendChild(town);
    }

    var gate = section("Gate Verdict");
    if (d.gate) {
      var gtxt = d.gate.raw || d.gate.verdict;
      if (d.gate.raw &&
          d.gate.raw.toUpperCase().indexOf(d.gate.verdict.toUpperCase()) !== 0) {
        gtxt = d.gate.verdict + " — " + d.gate.raw;
      }
      gate.appendChild(el("div", "drow", gtxt));
      gate.appendChild(el("div", "drow mono", "handoffs/" + d.gate.file));
    } else {
      gate.appendChild(el("div", "drow muted", "尚無 gate 紀錄"));
    }
    body.appendChild(gate);

    if (d.card_html) {
      var card = section("Phase 卡");
      card.appendChild(mdBlock(d.card_html));
      body.appendChild(card);
    }
    if (d.handoff) {
      var h = section("Mini-handoff · " + d.handoff.file);
      if (d.handoff.files_changed_html) {
        h.appendChild(el("div", "dsub", "Files Changed"));
        h.appendChild(mdBlock(d.handoff.files_changed_html));
      }
      if (d.handoff.risks_html) {
        h.appendChild(el("div", "dsub", "Risks"));
        h.appendChild(mdBlock(d.handoff.risks_html));
      }
      if (!d.handoff.files_changed_html && !d.handoff.risks_html) {
        h.appendChild(el("div", "drow muted", "（無 Files Changed / Risks 段）"));
      }
      body.appendChild(h);
    }

    drawer.hidden = false;
    overlay.hidden = false;
    pill.hidden = false;
    cancelReload();
    highlight(uid, pid);
    drawer.scrollTop = 0;
    closeBtn.focus();
  }

  function closeDrawer() {
    if (drawer.hidden) return;
    drawer.hidden = true;
    overlay.hidden = true;
    pill.hidden = true;
    clearHighlight();
    scheduleReload();
  }

  Array.prototype.forEach.call(
    document.querySelectorAll("[data-phase][data-uid]"),
    function (n) {
      n.addEventListener("click", function () {
        openPhase(n.dataset.uid, n.dataset.phase);
      });
      n.addEventListener("keydown", function (ev) {
        if (ev.key === "Enter" || ev.key === " ") {
          ev.preventDefault();
          openPhase(n.dataset.uid, n.dataset.phase);
        }
      });
    }
  );
  overlay.addEventListener("click", closeDrawer);
  closeBtn.addEventListener("click", closeDrawer);
  document.addEventListener("keydown", function (ev) {
    if (ev.key === "Escape") closeDrawer();
  });

  scheduleReload();
})();
"""


def render_page(root):
    plans_dir = root / "plans"
    plan_dirs = sorted(
        d for d in plans_dir.iterdir() if d.is_dir() and (d / "plan.md").is_file()
    ) if plans_dir.is_dir() else []

    ctx = load_flow_context(root)
    active_slug = (ctx or {}).get("slug")
    plan_dirs.sort(key=lambda d: (0 if d.name == active_slug else 1, d.name))

    runs = load_runs(root)
    now = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M:%S %z")
    detail_data = {}

    body = []
    body.append("<h1>Athena Flow 狀態看板</h1>")
    body.append(
        f'<p class="gen-meta">產生時間 {esc(now)} · 每 5 秒自動重新載入'
        "（開啟詳情面板時暫停）</p>"
    )
    body.append(
        '<p class="principle">此頁為機械投影（由 <code>scripts/render_status.py</code> '
        "從 plans/ · handoffs/ · .athena/ 唯讀產生），請勿手動編輯——任何手改都會在下次渲染被覆蓋。</p>"
    )

    # Only plans whose plan.md carries machine-parseable frontmatter (a
    # drawable DAG) get a full section. Legacy-format plans are skipped but
    # never silently: they are listed in a one-line note near the footer.
    skipped = []
    uid = 0
    for d in plan_dirs:
        plan = load_plan(d)
        if plan["parse_error"]:
            skipped.append(plan["slug"])
            continue
        handoffs = collect_handoffs(root, plan["slug"])
        body.append(
            render_plan_section(plan, handoffs, plan["slug"] == active_slug, ctx, uid)
        )
        detail_data[str(uid)] = {
            "slug": plan["slug"],
            "phases": build_phase_details(plan, handoffs, root),
        }
        uid += 1

    if uid == 0:
        body.append(
            '<section class="plan"><h2>目前沒有進行中的計畫</h2>'
            '<p class="muted">看板會在 <code>plans/&lt;slug&gt;/plan.md</code> 出現後自動顯示。'
            "資料來源：<code>plans/*/plan.md</code>（DAG frontmatter）、"
            "<code>plans/*/todo|doing|done/</code>（phase 狀態）、"
            "<code>handoffs/</code>（gate verdict）、"
            "<code>.athena/.flow-context.json</code>（當前 stage）、"
            "<code>.athena/traces/runs.jsonl</code>（歷史 run）。</p></section>"
        )

    body.append('<section class="runs"><h2>歷史 Run（最近 10 筆）</h2>')
    body.append(render_runs_table(runs))
    body.append("</section>")
    if skipped:
        body.append(
            f'<p class="skip-note">{len(skipped)} 個舊格式 plan 未顯示'
            "（plan.md 缺機械 frontmatter）："
            + esc("、".join(skipped)) + "</p>"
        )
    body.append("<footer>athena-dev-plugin status dashboard — mechanical projection, do not hand-edit.</footer>")

    # Detail data for the drawer, embedded at projection time (no fetch).
    # "</" is escaped so markdown content can never terminate the script tag.
    blob = json.dumps(detail_data, ensure_ascii=False).replace("</", "<\\/")

    drawer_html = (
        '<div class="overlay" id="drawer-overlay" hidden></div>\n'
        '<aside class="drawer" id="phase-drawer" hidden role="dialog" '
        'aria-modal="true" aria-labelledby="drawer-title">\n'
        '<div class="drawer-head"><h3 id="drawer-title"></h3>'
        '<button type="button" class="drawer-close" id="drawer-close" '
        'aria-label="關閉詳情面板">×</button></div>\n'
        '<div class="drawer-body" id="drawer-body"></div>\n'
        "</aside>\n"
        '<div class="pause-pill" id="pause-pill" hidden>auto-refresh paused</div>'
    )

    return (
        "<!DOCTYPE html>\n"
        '<html lang="zh-Hant">\n<head>\n'
        '<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        "<title>Athena Flow 狀態看板</title>\n"
        f"<style>{CSS}</style>\n"
        "</head>\n<body>\n<main>\n" + "\n".join(body) + "\n</main>\n"
        + drawer_html + "\n"
        f'<script type="application/json" id="athena-status-data">{blob}</script>\n'
        f"<script>{JS}</script>\n"
        "</body>\n</html>\n"
    )


def main():
    ap = argparse.ArgumentParser(description="Render Athena flow status dashboard.")
    ap.add_argument("project_root", nargs="?", default=".",
                    help="project root containing plans/ (default: cwd)")
    ap.add_argument("--output", "-o", default=None,
                    help="output HTML path (default: <root>/.athena/status.html)")
    args = ap.parse_args()

    root = Path(args.project_root).resolve()
    if not root.is_dir():
        print(f"render_status: {root} is not a directory", file=sys.stderr)
        sys.exit(1)

    out = Path(args.output) if args.output else root / ".athena" / "status.html"
    page = render_page(root)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(page, encoding="utf-8")
    print(f"render_status: wrote {out}")


if __name__ == "__main__":
    main()
