#!/usr/bin/env python3
"""validate_plan.py — mechanical validator for a specformula plan directory.

Usage:
    python3 validate_plan.py [--require-touches] plans/<slug>/

Validates:
  1. plan.md exists and its YAML frontmatter parses (the frontmatter is the
     single mechanical source of truth for the Dependency Graph).
  2. Every phase id is a unique two-digit string ("01".."99").
  3. Every depends_on entry references an existing phase id.
  4. The dependency graph is acyclic (topological sort).
  5. Each phase has exactly one NN-*.md card across todo/ | doing/ | done/
     (status_source: folders — folder location is the status truth).
  6. The markdown Dependency Graph table (human view) agrees with the
     frontmatter on the phase id set and the dependency edges.
  7. independence-overlap: for every pair of phases that are mutually
     unreachable on the DAG (no ancestor relation, i.e. parallel-eligible),
     their optional `touches` ownership declarations must not intersect
     (files by conservative glob-prefix heuristic, resources by exact
     string match). A non-empty intersection is an error.

`touches` is optional per phase (missing → warning, for backward
compatibility); pass --require-touches to turn missing touches into errors.

No hard third-party dependency: tries `import yaml`, falls back to a
mini-parser targeted at the fixed frontmatter schema.

Exit code: 0 = valid, 1 = at least one error (all errors listed on stderr).
"""

import argparse
import re
import sys
from pathlib import Path

ID_RE = re.compile(r"^\d{2}$")


# ---------------------------------------------------------------------------
# Frontmatter extraction + parsing
# ---------------------------------------------------------------------------

def extract_frontmatter(text: str):
    """Return the raw frontmatter block (without --- fences), or None."""
    m = re.match(r"^---\n(.*?)\n---\s*(\n|$)", text, re.DOTALL)
    return m.group(1) if m else None


def _strip_quotes(s: str) -> str:
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in "\"'":
        return s[1:-1]
    return s


def _parse_inline_list(s: str):
    """Parse an inline YAML list like [] or ["05", "07"]."""
    s = s.strip()
    if not (s.startswith("[") and s.endswith("]")):
        raise ValueError(f"expected inline list, got: {s!r}")
    inner = s[1:-1].strip()
    if not inner:
        return []
    return [_strip_quotes(item) for item in inner.split(",")]


def parse_frontmatter_fallback(fm_text: str) -> dict:
    """Mini-parser for the fixed plan frontmatter schema (no pyyaml needed).

    Handles exactly:
        plan: <slug>
        phases:
          - id: "01"
            name: <name>
            depends_on: ["..."]
            touches:            # optional, one nesting level
              files: ["..."]
              resources: ["..."]
        status_source: folders
    """
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
            elif in_touches and stripped.startswith("files:"):
                current["touches"]["files"] = _parse_inline_list(stripped.split(":", 1)[1])
            elif in_touches and stripped.startswith("resources:"):
                current["touches"]["resources"] = _parse_inline_list(stripped.split(":", 1)[1])
            else:
                raise ValueError(f"frontmatter line {lineno}: unexpected line: {stripped!r}")
    return data


def parse_frontmatter(fm_text: str) -> dict:
    try:
        import yaml  # type: ignore
    except ImportError:
        return parse_frontmatter_fallback(fm_text)
    data = yaml.safe_load(fm_text)
    if not isinstance(data, dict):
        raise ValueError("frontmatter did not parse to a mapping")
    return data


# ---------------------------------------------------------------------------
# Markdown table (human view) parsing
# ---------------------------------------------------------------------------

def parse_table_deps(cell: str):
    cell = cell.strip()
    if cell in ("", "—", "-", "–", "無"):
        return []
    parts = re.split(r"[,、]", cell)
    return [p.strip() for p in parts if p.strip()]


def parse_markdown_table(body: str) -> dict:
    """Extract {id: [deps]} from Dependency Graph table rows.

    Rows are recognised as pipe-table rows whose first cell is exactly a
    two-digit id: | 01 | Name | deps | status |
    """
    table = {}
    for line in body.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 3 or not ID_RE.match(cells[0]):
            continue
        table[cells[0]] = parse_table_deps(cells[2])
    return table


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

# --- independence-overlap heuristic --------------------------------------
# CONSERVATIVE HEURISTIC (over-approximates overlap; documented in --help):
#   * each file glob is truncated at its first wildcard char (* ? [) to a
#     literal prefix, then trimmed back to whole path segments (a partial
#     trailing segment like "src/back" from "src/back*" falls back to "src");
#   * two globs are considered overlapping when one prefix is a path-prefix
#     of the other (segment-wise); an empty prefix (e.g. "**") overlaps all;
#   * brace expansion / extglob syntax is NOT understood — patterns like
#     "src/{a,b}/**" are compared by literal prefix "src" only;
#   * resources overlap only on exact string equality.
# Consequence: disjoint globs sharing a directory (src/a*.py vs src/b*.py)
# are flagged as overlapping — re-slice ownership by directory to satisfy it.

_WILDCARD_RE = re.compile(r"[*?\[]")


def glob_literal_prefix(pattern: str) -> str:
    """Literal prefix of a glob, truncated at the first wildcard and
    trimmed back to whole path segments."""
    m = _WILDCARD_RE.search(pattern)
    if m is None:
        return pattern.strip("/")
    literal = pattern[: m.start()]
    # drop the partial trailing segment so only complete segments remain
    cut = literal.rfind("/")
    literal = literal[: cut + 1] if cut >= 0 else ""
    return literal.strip("/")


def _segments(prefix: str):
    return [s for s in prefix.split("/") if s]


def prefixes_overlap(a: str, b: str) -> bool:
    """True when one literal prefix is a path-prefix of the other."""
    sa, sb = _segments(a), _segments(b)
    n = min(len(sa), len(sb))
    return sa[:n] == sb[:n]


def compute_ancestors(ids, deps_map):
    """Transitive dependencies per phase id. Call only on an acyclic graph."""
    memo = {}

    def anc(pid):
        if pid in memo:
            return memo[pid]
        memo[pid] = set()  # placeholder (graph verified acyclic beforehand)
        result = set()
        for dep in deps_map.get(pid, []):
            if dep in deps_map:
                result.add(dep)
                result |= anc(dep)
        memo[pid] = result
        return result

    for pid in ids:
        anc(pid)
    return memo


def check_independence_overlap(plan_md, ids, deps_map, touches_map):
    """Error for each mutually-unreachable phase pair whose touches intersect."""
    errors = []
    ancestors = compute_ancestors(ids, deps_map)
    for i, p in enumerate(ids):
        for q in ids[i + 1:]:
            if p in ancestors[q] or q in ancestors[p]:
                continue  # ordered by the DAG — overlap is fine
            tp, tq = touches_map.get(p), touches_map.get(q)
            if tp is None or tq is None:
                continue  # missing touches handled separately (warning/error)
            file_hits = []
            for ga in tp.get("files") or []:
                for gb in tq.get("files") or []:
                    pa, pb = glob_literal_prefix(ga), glob_literal_prefix(gb)
                    if prefixes_overlap(pa, pb):
                        file_hits.append(
                            f'"{ga}" vs "{gb}" (literal prefixes '
                            f'"{pa or "<repo root>"}" / "{pb or "<repo root>"}")')
            res_hits = sorted(set(tp.get("resources") or []) & set(tq.get("resources") or []))
            if file_hits or res_hits:
                detail = []
                if file_hits:
                    detail.append("file globs: " + "; ".join(file_hits))
                if res_hits:
                    detail.append("resources: " + ", ".join(f'"{r}"' for r in res_hits))
                errors.append(
                    f'{plan_md}: independence-overlap — phases "{p}" and "{q}" are '
                    f'parallel-eligible (no ancestor relation on the DAG) but their '
                    f'touches intersect ({"; ".join(detail)}). '
                    f'Fix: add a depends_on edge between them (if there is a real '
                    f'ordering) or re-slice ownership so their touches are disjoint. '
                    f'Note: file matching is a conservative glob-prefix heuristic '
                    f'(truncate at first wildcard, whole path segments).')
    return errors


def detect_cycle(ids, deps_map):
    """Kahn's algorithm; return list of node ids stuck in a cycle ([] if acyclic)."""
    indegree = {i: 0 for i in ids}
    dependents = {i: [] for i in ids}
    for node in ids:
        for dep in deps_map[node]:
            if dep in indegree:
                indegree[node] += 1
                dependents[dep].append(node)
    queue = [i for i in ids if indegree[i] == 0]
    visited = 0
    while queue:
        n = queue.pop()
        visited += 1
        for m in dependents[n]:
            indegree[m] -= 1
            if indegree[m] == 0:
                queue.append(m)
    if visited == len(ids):
        return []
    return sorted(i for i in ids if indegree[i] > 0)


def validate(plan_dir: Path, require_touches: bool = False):
    """Return (errors, warnings)."""
    errors = []
    warnings = []
    plan_md = plan_dir / "plan.md"
    if not plan_dir.is_dir():
        return [f"{plan_dir}: not a directory"], warnings
    if not plan_md.is_file():
        return [f"{plan_md}: plan.md not found"], warnings

    text = plan_md.read_text(encoding="utf-8")
    fm_text = extract_frontmatter(text)
    if fm_text is None:
        return [f"{plan_md}: no YAML frontmatter block found (--- ... --- at top of file)"], warnings

    try:
        data = parse_frontmatter(fm_text)
    except Exception as e:
        return [f"{plan_md}: frontmatter failed to parse: {e}"], warnings

    phases = data.get("phases")
    if not isinstance(phases, list) or not phases:
        return [f"{plan_md}: frontmatter has no 'phases' list"], warnings
    if data.get("status_source") != "folders":
        errors.append(f"{plan_md}: frontmatter status_source must be 'folders' "
                      f"(got {data.get('status_source')!r})")

    # --- ids: format + uniqueness ---
    ids = []
    deps_map = {}
    touches_map = {}
    for idx, ph in enumerate(phases):
        if not isinstance(ph, dict):
            errors.append(f"{plan_md}: phases[{idx}] is not a mapping")
            continue
        pid = ph.get("id")
        if not isinstance(pid, str) or not ID_RE.match(pid):
            errors.append(f"{plan_md}: phases[{idx}] id must be a two-digit string, got {pid!r}")
            continue
        if pid in deps_map:
            errors.append(f"{plan_md}: duplicate phase id \"{pid}\"")
            continue
        deps = ph.get("depends_on", [])
        if not isinstance(deps, list) or not all(isinstance(d, str) for d in deps):
            errors.append(f"{plan_md}: phase \"{pid}\" depends_on must be a list of strings, got {deps!r}")
            deps = []
        ids.append(pid)
        deps_map[pid] = deps

        # --- optional touches (ownership declaration) ---
        touches = ph.get("touches")
        if touches is None:
            touches_map[pid] = None
            msg = (f"{plan_md}: phase \"{pid}\" has no 'touches' ownership declaration "
                   f"(independence-overlap check cannot cover this phase)")
            if require_touches:
                errors.append(msg + " [--require-touches]")
            else:
                warnings.append(msg)
        elif not isinstance(touches, dict):
            errors.append(f"{plan_md}: phase \"{pid}\" touches must be a mapping "
                          f"with 'files' / 'resources' lists, got {touches!r}")
            touches_map[pid] = None
        else:
            bad = False
            for key in touches:
                if key not in ("files", "resources"):
                    errors.append(f"{plan_md}: phase \"{pid}\" touches has unknown key "
                                  f"{key!r} (allowed: files, resources)")
                    bad = True
            for key in ("files", "resources"):
                val = touches.get(key, [])
                if not isinstance(val, list) or not all(isinstance(v, str) for v in val):
                    errors.append(f"{plan_md}: phase \"{pid}\" touches.{key} must be "
                                  f"a list of strings, got {val!r}")
                    bad = True
            touches_map[pid] = None if bad else touches

    id_set = set(ids)

    # --- depends_on references exist ---
    for pid in ids:
        for dep in deps_map[pid]:
            if dep not in id_set:
                errors.append(f"{plan_md}: phase \"{pid}\" depends_on \"{dep}\" "
                              f"which is not a declared phase id (dangling reference)")

    # --- acyclicity ---
    cyclic = detect_cycle(ids, deps_map)
    if cyclic:
        errors.append(f"{plan_md}: dependency cycle detected involving phases: "
                      + ", ".join(f'"{i}"' for i in cyclic))

    # --- independence-overlap (touches of parallel-eligible phase pairs) ---
    if not cyclic:  # ancestor computation requires an acyclic graph
        errors.extend(check_independence_overlap(plan_md, ids, deps_map, touches_map))

    # --- exactly one card per phase across todo/doing/done ---
    folders = ["todo", "doing", "done"]
    card_locations = {pid: [] for pid in ids}
    for folder in folders:
        fdir = plan_dir / folder
        if not fdir.is_dir():
            continue  # missing folder == empty
        for card in sorted(fdir.glob("[0-9][0-9]-*.md")):
            prefix = card.name[:2]
            if prefix in card_locations:
                card_locations[prefix].append(f"{folder}/{card.name}")
            else:
                errors.append(f"{plan_dir}: card {folder}/{card.name} has phase id "
                              f"\"{prefix}\" not declared in frontmatter")
    for pid in ids:
        locs = card_locations[pid]
        if len(locs) == 0:
            errors.append(f"{plan_dir}: phase \"{pid}\" has no card in todo/, doing/ or done/")
        elif len(locs) > 1:
            errors.append(f"{plan_dir}: phase \"{pid}\" has {len(locs)} cards "
                          f"(must be exactly 1): " + ", ".join(locs))

    # --- markdown table (human view) consistency ---
    body = text[text.index(fm_text) + len(fm_text):]
    table = parse_markdown_table(body)
    if not table:
        errors.append(f"{plan_md}: no Dependency Graph markdown table rows found "
                      f"(human view missing; cannot verify consistency)")
    else:
        table_ids = set(table)
        if table_ids != id_set:
            missing = sorted(id_set - table_ids)
            extra = sorted(table_ids - id_set)
            if missing:
                errors.append(f"{plan_md}: table is missing phases declared in frontmatter: "
                              + ", ".join(f'"{i}"' for i in missing))
            if extra:
                errors.append(f"{plan_md}: table has phases not declared in frontmatter: "
                              + ", ".join(f'"{i}"' for i in extra))
        for pid in sorted(id_set & table_ids):
            if sorted(table[pid]) != sorted(deps_map[pid]):
                errors.append(f"{plan_md}: phase \"{pid}\" dependency mismatch — "
                              f"frontmatter says {sorted(deps_map[pid])}, "
                              f"table says {sorted(table[pid])}")

    return errors, warnings


HELP_EPILOG = """\
touches / independence-overlap:
  Each phase may declare an ownership block:
      touches:
        files: ["src/backend/**", "tests/backend/**"]
        resources: ["db-migration-sequence"]
  For every pair of phases with no ancestor relation on the DAG
  (i.e. parallel-eligible), a non-empty touches intersection is an ERROR.

  Heuristic limits (conservative, over-approximates overlap):
    - each file glob is truncated at its first wildcard (* ? [) to a literal
      prefix, then trimmed back to whole path segments
      ("src/backend/**" -> "src/backend"; "src/back*" -> "src");
    - two globs overlap when one prefix is a path-prefix of the other;
      an empty prefix (e.g. "**") overlaps everything;
    - brace expansion / extglob are not understood (compared by prefix only);
    - disjoint globs sharing a directory (src/a*.py vs src/b*.py) are still
      flagged — slice ownership by directory instead;
    - resources overlap only on exact string equality.

  Phases without touches are skipped by the check and produce a warning
  (backward compatible); --require-touches turns those into errors.
"""


def main():
    parser = argparse.ArgumentParser(
        description="Mechanical validator for a specformula plan directory.",
        epilog=HELP_EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("plan_dir", metavar="plans/<slug>/",
                        help="plan directory containing plan.md (+ todo/doing/done)")
    parser.add_argument("--require-touches", action="store_true",
                        help="error (instead of warn) when any phase lacks a "
                             "'touches' ownership declaration")
    args = parser.parse_args()
    plan_dir = Path(args.plan_dir)
    errors, warnings = validate(plan_dir, require_touches=args.require_touches)
    for w in warnings:
        print(f"validate_plan: WARNING — {w}", file=sys.stderr)
    if errors:
        print(f"validate_plan: {plan_dir} INVALID — {len(errors)} error(s):", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        sys.exit(1)
    print(f"validate_plan: {plan_dir} OK")
    sys.exit(0)


if __name__ == "__main__":
    main()
