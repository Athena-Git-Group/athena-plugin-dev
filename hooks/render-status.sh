#!/usr/bin/env bash
# render-status.sh — Athena SubagentStop hook: re-project the status dashboard.
#
# Thin shell around scripts/render_status.py. The dashboard
# (.athena/status.html) is a mechanical projection of plans/ + handoffs/ +
# .athena/ state — this hook only re-runs the projection after a subagent
# stops; it never mutates flow state.
#
# Contract:
#   - Fast, silent no-op when the cwd is not an Athena project
#     (no .athena/ -> exit 0, print nothing). plans/ is NOT required:
#     minimal flows have no plan stage, and the renderer already shows an
#     empty-state section plus the runs-history table without plans/.
#   - NEVER exits non-zero: a rendering failure must not break the hook
#     chain. On failure it writes a single line to stderr and still exits 0.

set -u

INPUT="$(cat 2>/dev/null || true)"

CWD=""
if command -v jq >/dev/null 2>&1; then
  CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)"
fi
[ -z "$CWD" ] && CWD="$PWD"

# Fast silent no-op outside Athena projects.
[ -d "$CWD/.athena" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
RENDERER="$SCRIPT_DIR/../scripts/render_status.py"
[ -f "$RENDERER" ] || exit 0

if ! python3 "$RENDERER" "$CWD" >/dev/null 2>&1; then
  echo "athena render-status: dashboard render failed (non-fatal)" >&2
fi

exit 0
