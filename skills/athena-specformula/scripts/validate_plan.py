#!/usr/bin/env python3
"""validate_plan.py — mechanical validator for a specformula plan directory.

Usage:
    python3 validate_plan.py plans/<slug>/

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

No hard third-party dependency: tries `import yaml`, falls back to a
mini-parser targeted at the fixed frontmatter schema.

Exit code: 0 = valid, 1 = at least one error (all errors listed on stderr).
"""

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
        status_source: folders
    """
    data = {"plan": None, "phases": [], "status_source": None}
    current = None
    for lineno, raw in enumerate(fm_text.splitlines(), start=1):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indented = raw.startswith((" ", "\t"))
        if not indented:
            current = None
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
                current = {
                    "id": _strip_quotes(stripped.split(":", 1)[1]),
                    "name": None,
                    "depends_on": [],
                }
                data["phases"].append(current)
            elif current is not None and stripped.startswith("name:"):
                current["name"] = _strip_quotes(stripped.split(":", 1)[1])
            elif current is not None and stripped.startswith("depends_on:"):
                current["depends_on"] = _parse_inline_list(stripped.split(":", 1)[1])
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


def validate(plan_dir: Path):
    errors = []
    plan_md = plan_dir / "plan.md"
    if not plan_dir.is_dir():
        return [f"{plan_dir}: not a directory"]
    if not plan_md.is_file():
        return [f"{plan_md}: plan.md not found"]

    text = plan_md.read_text(encoding="utf-8")
    fm_text = extract_frontmatter(text)
    if fm_text is None:
        return [f"{plan_md}: no YAML frontmatter block found (--- ... --- at top of file)"]

    try:
        data = parse_frontmatter(fm_text)
    except Exception as e:
        return [f"{plan_md}: frontmatter failed to parse: {e}"]

    phases = data.get("phases")
    if not isinstance(phases, list) or not phases:
        return [f"{plan_md}: frontmatter has no 'phases' list"]
    if data.get("status_source") != "folders":
        errors.append(f"{plan_md}: frontmatter status_source must be 'folders' "
                      f"(got {data.get('status_source')!r})")

    # --- ids: format + uniqueness ---
    ids = []
    deps_map = {}
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

    return errors


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <plans/<slug>/ directory>", file=sys.stderr)
        sys.exit(1)
    plan_dir = Path(sys.argv[1])
    errors = validate(plan_dir)
    if errors:
        print(f"validate_plan: {plan_dir} INVALID — {len(errors)} error(s):", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        sys.exit(1)
    print(f"validate_plan: {plan_dir} OK")
    sys.exit(0)


if __name__ == "__main__":
    main()
