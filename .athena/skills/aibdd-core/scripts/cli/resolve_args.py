#!/usr/bin/env python3
"""
resolve_args.py

Shared placeholder resolver for every aibdd-xxx skill.

Reads arbitrary text from stdin, substitutes every `${dotted.key}` placeholder
with the corresponding value from `.aibdd/arguments.yml` (path is hard-coded
relative to CWD), and writes the resolved text to stdout.

Behavior:
  - Substitution is recursive: if a resolved value itself contains `${...}`,
    those nested placeholders are expanded too, up to MAX_DEPTH passes.
  - Missing `.aibdd/arguments.yml` -> exit 1, message on stderr.
  - Any `${key}` that remains unresolvable after convergence -> exit 2, list
    of missing keys on stderr; stdout stays empty so callers cannot silently
    consume a partially-resolved blob.
  - Cyclic references (e.g. `a: ${b}` and `b: ${a}`) trip the depth cap and
    fail with exit 3.

Usage:
  echo 'IMPACT_MATRIX_YML=${IMPACT_MATRIX_YML}' \\
    | python3 ${CLAUDE_PLUGIN_ROOT}/.athena/skills/aibdd-core/scripts/cli/resolve_args.py
"""

from __future__ import annotations

import sys
from pathlib import Path

_SCRIPTS_DIR = Path(__file__).resolve().parents[1]
if str(_SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS_DIR))

from aibdd_core.project_args import resolve_text  # noqa: E402


def main() -> int:
    result = resolve_text(sys.stdin.read(), cwd=Path.cwd())
    if result.stderr:
        sys.stderr.write(result.stderr)
    if not result.ok:
        return result.exit_code
    sys.stdout.write(result.text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
