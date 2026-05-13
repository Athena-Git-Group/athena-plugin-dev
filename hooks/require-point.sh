#!/usr/bin/env bash
# require-point.sh — Athena PreToolUse hook.
#
# Blocks Edit / Write / MultiEdit / NotebookEdit when the current Athena
# project has no point-report under points/*.md, enforcing the
# "always run /athena-point first" rule defined in the plugin CLAUDE.md.
#
# Scope:
#   - Only fires when CWD looks like an Athena project (has .athena/ or points/).
#     Any other project is unaffected — installing this plugin will not
#     interfere with unrelated repos.
#
# Escape hatches (in order of evaluation):
#   1. Env var:     ATHENA_SKIP_POINT_GATE=1
#   2. Marker file: <cwd>/.athena/skip-point-gate
#   3. Self-protection paths (always allowed, so the gate can be edited
#      or disabled without locking the user out):
#        - hooks/**          (the gate machinery itself)
#        - .claude-plugin/** (plugin manifest)
#        - commands/**       (slash command entry points)
#        - .claude/**        (harness settings)
#        - .athena/**        (team config, knowledge base, escape marker dir)
#        - points/**         (point reports themselves)
#        - handoffs/**       (stage handoff artifacts written by flow)
#
# Behaviour:
#   - exit 0 → allow the tool call
#   - exit 2 → block the tool call; stderr is shown to Claude

set -euo pipefail

INPUT="$(cat)"

# jq is part of the Claude Code default environment; degrade safely if absent.
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty')"
case "$TOOL_NAME" in
  Edit|Write|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

TARGET_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')"
CWD="$(echo "$INPUT" | jq -r '.cwd // empty')"
[ -z "$CWD" ] && CWD="$PWD"

# 1. Env var escape hatch
if [ "${ATHENA_SKIP_POINT_GATE:-}" = "1" ]; then
  exit 0
fi

# 2. Marker file escape hatch
if [ -f "$CWD/.athena/skip-point-gate" ]; then
  exit 0
fi

# Only enforce inside Athena-enabled projects.
if [ ! -d "$CWD/.athena" ] && [ ! -d "$CWD/points" ]; then
  exit 0
fi

# 3. Self-protection — never block these paths.
case "$TARGET_PATH" in
  "$CWD"/hooks/*|\
  "$CWD"/.claude-plugin/*|\
  "$CWD"/commands/*|\
  "$CWD"/.claude/*|\
  "$CWD"/.athena/*|\
  "$CWD"/points/*|\
  "$CWD"/handoffs/*)
    exit 0
    ;;
esac

# Allow if at least one point report exists.
shopt -s nullglob
reports=("$CWD"/points/*.md)
shopt -u nullglob
if [ "${#reports[@]}" -gt 0 ]; then
  exit 0
fi

cat >&2 <<EOF
⛔ Athena point gate: no points/*.md found in this project.

Run /athena-point (or /athena-flow) first to score the request before
editing code.

Bypass options (use only when intentional):
  export ATHENA_SKIP_POINT_GATE=1
  # or
  mkdir -p "$CWD/.athena" && touch "$CWD/.athena/skip-point-gate"
EOF
exit 2
