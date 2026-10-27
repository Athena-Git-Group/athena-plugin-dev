# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Deterministic smoke-test runner for athena team skills.

Single responsibility: given a set of changed files, match each file against
a glob->check table (built-in defaults mirroring
.athena/skills/team-common/rules/smoke-test.md Rule 3, optionally overridden
by .athena/smoke-checks.json), run every matched check, and report
PASS/FAIL/SKIP with a deterministic exit code.

Interface:
  input : --base <git ref> | --files f1 f2 ... | (default: git diff HEAD + untracked)
  config: --config <path>  (default: .athena/smoke-checks.json if present)
  output: markdown report on stdout (or JSON with --json)
  exit  : 0 = all executed checks passed (SKIP is not failure)
          1 = at least one check failed
          2 = runner error (bad args, git failure, bad config)
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import re
import subprocess
import sys
from pathlib import Path

TAIL_LINES = 20
TAIL_CHARS = 2000

# Built-in check table. The *content* of these rows is owned by
# .athena/skills/team-common/rules/smoke-test.md (Rule 3) — that file is the
# single source of truth; when its table changes, this dict must change in
# the same commit. Language knowledge stays here (overridable), never in the
# matching/execution logic below, because the skills run against target
# projects with different tech stacks.
BUILTIN_CHECKS: dict[str, list[dict]] = {
    "*.sh": [{"cmd": "bash -n {file}", "label": "bash syntax (bash -n)"}],
    "*.py": [{"cmd": "python3 -m py_compile {file}", "label": "python compile"}],
    "*.md": [{"internal": "markdown", "label": "frontmatter + relative links"}],
    "*.feature": [{"internal": "gherkin", "label": "gherkin keyword structure"}],
}


def run_git(args: list[str], repo_root: Path) -> list[str]:
    # core.quotepath=false: without it, git quotes non-ASCII paths as
    # "\350..." octal escapes (this repo has many Chinese-named rules files),
    # and those quoted strings never match a file on disk — the file would
    # silently fall into SKIP/missing instead of being checked.
    proc = subprocess.run(
        ["git", "-c", "core.quotepath=false", *args],
        cwd=repo_root, capture_output=True, text=True,
    )
    if proc.returncode != 0:
        print(f"git {' '.join(args)} failed: {proc.stderr.strip()}", file=sys.stderr)
        sys.exit(2)
    return [line for line in proc.stdout.splitlines() if line.strip()]


def collect_files(args: argparse.Namespace, repo_root: Path) -> list[str]:
    if args.files:
        return args.files
    if args.base:
        return run_git(["diff", "--name-only", f"{args.base}...HEAD"], repo_root)
    # No base given: a build agent usually works on uncommitted changes, so
    # untracked files must count too or brand-new files would never be smoked.
    changed = run_git(["diff", "--name-only", "HEAD"], repo_root)
    untracked = run_git(["ls-files", "--others", "--exclude-standard"], repo_root)
    seen: dict[str, None] = {}
    for f in changed + untracked:
        seen.setdefault(f, None)
    return list(seen)


FRONTMATTER_KEY_RE = re.compile(r"^[A-Za-z0-9_-]+\s*:")
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")


def check_markdown(path: Path) -> tuple[int, str]:
    """Frontmatter block (if any) is well-formed; SKILL.md requires
    name/description; relative markdown-link targets must exist.

    Zero-dependency constraint: no PyYAML, so frontmatter is validated
    structurally (block closes, top-level lines look like 'key:') rather
    than fully parsed — enough to catch the truncated/garbled cases the
    checklist targets.
    """
    problems: list[str] = []
    notes: list[str] = []
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        return 1, f"cannot read file: {exc}"
    lines = text.splitlines()

    fm_keys: set[str] = set()
    if lines and lines[0].strip() == "---":
        end = None
        for i, line in enumerate(lines[1:], start=1):
            if line.strip() == "---":
                end = i
                break
        if end is None:
            problems.append("frontmatter opened with '---' but never closed")
        else:
            for raw in lines[1:end]:
                if not raw.strip() or raw.lstrip().startswith("#"):
                    continue
                if raw[0] in " \t":  # continuation of a multi-line value
                    continue
                if not FRONTMATTER_KEY_RE.match(raw):
                    problems.append(f"frontmatter line not 'key: value': {raw!r}")
                else:
                    fm_keys.add(raw.split(":", 1)[0].strip())
            notes.append(f"frontmatter OK ({len(fm_keys)} top-level keys)")
    else:
        notes.append("no frontmatter block (allowed for plain markdown)")

    if path.name == "SKILL.md":
        for required in ("name", "description"):
            if required not in fm_keys:
                problems.append(f"SKILL.md frontmatter missing required key: {required}")

    checked = 0
    for target in LINK_RE.findall(text):
        if target.startswith(("http://", "https://", "#", "mailto:", "/")):
            continue
        # Placeholder/glob-looking targets (<slug>, *.md, {file}) are docs
        # notation, not literal paths — checking them would be pure noise.
        if any(ch in target for ch in "<>*{"):
            continue
        ref = (path.parent / target.split("#", 1)[0]).resolve()
        checked += 1
        if not ref.exists():
            problems.append(f"relative link target missing: {target}")
    notes.append(f"relative link targets checked: {checked}")

    if problems:
        return 1, "\n".join(problems + notes)
    return 0, "\n".join(notes)


def check_gherkin(path: Path) -> tuple[int, str]:
    """Keyword structure check — the checklist's fallback when no gherkin
    parser is available, which is the only case this zero-dependency script
    can guarantee."""
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        return 1, f"cannot read file: {exc}"
    problems = []
    if not re.search(r"^\s*Feature:", text, re.MULTILINE):
        problems.append("missing 'Feature:' keyword")
    if not re.search(r"^\s*(Scenario:|Scenario Outline:|Rule:)", text, re.MULTILINE):
        problems.append("missing 'Scenario:' / 'Scenario Outline:' / 'Rule:'")
    if not re.search(r"^\s*(Given|When|Then)\b", text, re.MULTILINE):
        problems.append("no Given/When/Then step found")
    if problems:
        return 1, "\n".join(problems)
    return 0, "Feature/Scenario/step keywords present"


INTERNAL_CHECKS = {"markdown": check_markdown, "gherkin": check_gherkin}


def load_config(config_path: Path | None, repo_root: Path) -> dict[str, list[dict]]:
    """Merge the project override table over the built-in table.

    Override file format (JSON): {"<glob>": "<cmd template>" | ["<cmd>", ...] | null}
    `{file}` in a template is replaced by the file path. Same glob replaces
    the built-in entry entirely (so a target project can swap python3 for its
    own toolchain); null disables a built-in entry outright.
    """
    table = {pat: list(checks) for pat, checks in BUILTIN_CHECKS.items()}
    if config_path is None:
        default = repo_root / ".athena" / "smoke-checks.json"
        if not default.exists():
            return table
        config_path = default
    elif not config_path.exists():
        print(f"config not found: {config_path}", file=sys.stderr)
        sys.exit(2)
    try:
        raw = json.loads(config_path.read_text(encoding="utf-8"))
        if not isinstance(raw, dict):
            raise ValueError("top level must be an object of glob -> command(s)")
    except (ValueError, OSError) as exc:
        print(f"bad config {config_path}: {exc}", file=sys.stderr)
        sys.exit(2)
    for pat, spec in raw.items():
        if spec is None:
            table.pop(pat, None)
            continue
        cmds = spec if isinstance(spec, list) else [spec]
        entries = []
        for cmd in cmds:
            if not isinstance(cmd, str) or not cmd.strip():
                print(f"bad config {config_path}: value for {pat!r} must be "
                      "a command string, list of strings, or null", file=sys.stderr)
                sys.exit(2)
            entries.append({"cmd": cmd, "label": f"project override: {cmd}"})
        table[pat] = entries
    return table


def matches(path_str: str, pattern: str) -> bool:
    # Match basename too, so the common "*.sh" style hits nested files
    # without forcing every table row to be written as "**/*.sh".
    return fnmatch.fnmatch(path_str, pattern) or fnmatch.fnmatch(
        Path(path_str).name, pattern
    )


def tail(text: str) -> str:
    lines = text.splitlines()[-TAIL_LINES:]
    out = "\n".join(lines)
    if len(out) > TAIL_CHARS:
        out = out[-TAIL_CHARS:]
    return out.strip()


def run_check(entry: dict, file_path: Path, repo_root: Path) -> dict:
    rel = str(file_path)
    if "internal" in entry:
        code, output = INTERNAL_CHECKS[entry["internal"]](file_path)
        cmd_desc = f"builtin:{entry['internal']} {rel}"
    else:
        cmd = entry["cmd"].replace("{file}", str(file_path))
        cmd_desc = cmd
        proc = subprocess.run(
            cmd, shell=True, cwd=repo_root, capture_output=True, text=True
        )
        code = proc.returncode
        output = (proc.stdout + ("\n" + proc.stderr if proc.stderr else "")).strip()
    return {
        "file": rel,
        "check": entry.get("label", cmd_desc),
        "command": cmd_desc,
        "exit_code": code,
        "status": "PASS" if code == 0 else "FAIL",
        "output_tail": tail(output),
    }


def render_markdown(summary: dict) -> str:
    lines = [
        "## Smoke Test Result",
        "",
        f"- Changed files: {summary['files_total']}",
        f"- Checks run: {summary['checks_run']}",
        f"- PASS: {summary['pass']} / FAIL: {summary['fail']} / "
        f"SKIP (unmatched files): {summary['skip']}",
        "",
    ]
    for r in summary["results"]:
        lines.append(f"### {r['status']} — {r['file']} — {r['check']}")
        lines.append(f"- command: `{r['command']}`")
        lines.append(f"- exit code: {r['exit_code']}")
        if r["output_tail"]:
            lines.append("```")
            lines.append(r["output_tail"])
            lines.append("```")
        lines.append("")
    if summary["skipped_files"]:
        # Explicit SKIP list: an unmatched file must be visible to the agent
        # reading the report, never a silent pass.
        lines.append("### SKIP — files with no matching check (not silently passed)")
        for f in summary["skipped_files"]:
            lines.append(f"- {f}")
        lines.append("")
    if summary["missing_files"]:
        lines.append("### NOTE — listed but not on disk (deleted/renamed), not checked")
        for f in summary["missing_files"]:
            lines.append(f"- {f}")
        lines.append("")
    lines.append(f"Overall: {'FAIL' if summary['fail'] else 'PASS'}")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Deterministic smoke-test runner (glob -> check table)."
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--base", help="git ref: check files in <base>...HEAD")
    group.add_argument("--files", nargs="+", help="explicit file list")
    parser.add_argument("--config", type=Path,
                        help="override table (default: .athena/smoke-checks.json)")
    parser.add_argument("--json", action="store_true",
                        help="emit machine-readable JSON instead of markdown")
    args = parser.parse_args()

    repo_root = Path.cwd()
    table = load_config(args.config, repo_root)
    files = collect_files(args, repo_root)

    results: list[dict] = []
    skipped: list[str] = []
    missing: list[str] = []
    for f in files:
        fp = (repo_root / f) if not Path(f).is_absolute() else Path(f)
        if not fp.exists():
            missing.append(f)
            continue
        entries = [e for pat, es in table.items() if matches(f, pat) for e in es]
        if not entries:
            skipped.append(f)
            continue
        for entry in entries:
            results.append(run_check(entry, fp, repo_root))

    summary = {
        "files_total": len(files),
        "checks_run": len(results),
        "pass": sum(1 for r in results if r["status"] == "PASS"),
        "fail": sum(1 for r in results if r["status"] == "FAIL"),
        "skip": len(skipped),
        "results": results,
        "skipped_files": skipped,
        "missing_files": missing,
        "overall": "FAIL" if any(r["status"] == "FAIL" for r in results) else "PASS",
    }

    if args.json:
        print(json.dumps(summary, ensure_ascii=False, indent=2))
    else:
        print(render_markdown(summary))
    return 1 if summary["fail"] else 0


if __name__ == "__main__":
    sys.exit(main())
