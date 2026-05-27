#!/usr/bin/env bash
# auto-commit.sh — Athena SubagentStop hook for post-build auto-commit.
#
# Fires when a flow-spawned subagent completes. Reads the flow context
# marker file written by athena-flow before the subagent was launched,
# determines triggering_stage, and runs the same commit logic as the
# athena-post-build skill — but driven by a hook rather than by flow
# inlining the skill.
#
# Activation contract (opt-in):
#   1. flow agent writes <cwd>/.athena/.flow-context.json before
#      invoking the Agent tool:
#         {
#           "mode": "hook",                       # 必須是 "hook"，否則此 hook no-op
#           "triggering_stage": "build-phase-05",
#           "slug": "harness-p3-improvements",
#           "branch_name": "feature/main_...",
#           "ticket": "",
#           "phase_number": "05",                 # only when build-phase-NN
#           "expires_at": "2026-05-13T15:00:00Z"  # monotonic guard
#         }
#   2. After Agent completes, harness fires SubagentStop, which calls
#      this hook. Hook reads context, validates expiry, reads the
#      handoff Gate Verdict, stages & commits if PASS.
#   3. Hook deletes the marker file on success so the same stop event
#      cannot trigger a duplicate commit.
#
# If the marker file is missing, malformed, expired, or has
# mode != "hook", the hook exits 0 silently and lets the inline
# post-build skill (if flow chose inline mode) do its job instead.
#
# Self-protection: this hook never executes git push, never amends,
# never rebases. Push remains the ship stage's job.

set -euo pipefail

# Best-effort codemap refresh after a successful commit.
#
# Mirrors the inline path documented in
#   skills/athena-post-build/SKILL.md (step 8 "Refresh codemap")
#   skills/athena-post-build/references/codemap-refresh-policy.md
#
# Contract (dual-path symmetry — verify checks this):
#   - Three guards must all be true to actually run:
#       1. <repo-root>/graphify-out/graph.json exists
#       2. graphify CLI on PATH
#       3. graphify-out/ is gitignored (so --update won't dirty working tree)
#     Plus implementation guard:
#       4. timeout binary on PATH (don't risk hanging the hook)
#   - Skip / failure / timeout: log a single line to stderr, return 0.
#     This function MUST NOT propagate any non-zero exit up to the hook —
#     SubagentStop hook is on the critical path and must not be blocked
#     by a best-effort codemap refresh.
#
# Args:
#   $1  repo root (absolute path; usually $CWD from the hook)
refresh_codemap() {
  local repo_root="$1"

  if [ ! -f "$repo_root/graphify-out/graph.json" ]; then
    echo "codemap_refresh: skipped (no graphify-out)" >&2
    return 0
  fi
  if ! command -v graphify >/dev/null 2>&1; then
    echo "codemap_refresh: skipped (cli missing)" >&2
    return 0
  fi
  if ! git -C "$repo_root" check-ignore -q graphify-out/ 2>/dev/null; then
    echo "codemap_refresh: skipped (graphify-out tracked)" >&2
    return 0
  fi
  if ! command -v timeout >/dev/null 2>&1; then
    echo "codemap_refresh: skipped (no timeout binary)" >&2
    return 0
  fi

  local rc=0
  timeout 90 graphify "$repo_root" --update >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "codemap_refresh: done" >&2
  else
    echo "codemap_refresh: failed (exit=$rc)" >&2
  fi
  return 0
}

INPUT="$(cat 2>/dev/null || true)"

# Degrade to no-op if jq is unavailable.
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

CWD="$(echo "$INPUT" | jq -r '.cwd // empty')"
[ -z "$CWD" ] && CWD="$PWD"

CONTEXT_FILE="$CWD/.athena/.flow-context.json"
[ -f "$CONTEXT_FILE" ] || exit 0

MODE="$(jq -r '.mode // "inline"' "$CONTEXT_FILE" 2>/dev/null || echo "")"
[ "$MODE" = "hook" ] || exit 0

# Expiry check — refuse to act on stale markers.
EXPIRES_AT="$(jq -r '.expires_at // empty' "$CONTEXT_FILE" 2>/dev/null || echo "")"
if [ -n "$EXPIRES_AT" ]; then
  NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  # String comparison is fine for ISO-8601 in UTC.
  if [ "$NOW" \> "$EXPIRES_AT" ]; then
    rm -f "$CONTEXT_FILE"
    exit 0
  fi
fi

TRIGGERING_STAGE="$(jq -r '.triggering_stage // empty' "$CONTEXT_FILE")"
SLUG="$(jq -r '.slug // empty' "$CONTEXT_FILE")"
BRANCH_NAME="$(jq -r '.branch_name // empty' "$CONTEXT_FILE")"
TICKET="$(jq -r '.ticket // empty' "$CONTEXT_FILE")"
PHASE_NUMBER="$(jq -r '.phase_number // empty' "$CONTEXT_FILE")"

# Locate the relevant handoff artifact.
case "$TRIGGERING_STAGE" in
  build-lightweight|build-minimal|verify-fix-lightweight)
    HANDOFF="$CWD/handoffs/${SLUG}-build.md"
    ;;
  build-phase-*|verify-fix-phase-*)
    HANDOFF="$CWD/handoffs/${SLUG}-build-phase-${PHASE_NUMBER}.md"
    ;;
  verify)
    HANDOFF="$CWD/handoffs/${SLUG}-verify.md"
    ;;
  *)
    # Unknown stage — leave marker for human inspection, do not commit.
    exit 0
    ;;
esac

[ -f "$HANDOFF" ] || exit 0

# Refuse to commit if the handoff Gate Verdict is not PASS.
if ! grep -qE '^## Gate Verdict' "$HANDOFF"; then
  exit 0
fi
VERDICT_LINE="$(awk '/^## Gate Verdict/{getline; print; exit}' "$HANDOFF" | tr -d ' \t')"
case "$VERDICT_LINE" in
  PASS*) ;;
  *) exit 0 ;;
esac

# Refuse to commit if working tree has no staged-able changes.
if [ -z "$(git -C "$CWD" status --porcelain)" ]; then
  rm -f "$CONTEXT_FILE"
  exit 0
fi

# Compose commit type / phase-tag identically to athena-post-build skill.
case "$TRIGGERING_STAGE" in
  verify) TYPE="test"; PHASE_TAG="(verify)" ;;
  verify-fix-*) TYPE="fix"; PHASE_TAG="(${TRIGGERING_STAGE})" ;;
  build-phase-*) TYPE="feat"; PHASE_TAG="(phase-${PHASE_NUMBER})" ;;
  build-lightweight) TYPE="feat"; PHASE_TAG="" ;;
  build-minimal) TYPE="feat"; PHASE_TAG="" ;;
  *) TYPE="chore"; PHASE_TAG="(${TRIGGERING_STAGE})" ;;
esac

# Short description pulled from the handoff's first line summary if present.
DESC="$(awk '/^# Handoff/{getline; getline; print; exit}' "$HANDOFF" | head -c 60)"
[ -z "$DESC" ] && DESC="${TRIGGERING_STAGE} changes"

PREFIX=""
[ -n "$TICKET" ] && PREFIX="[HAP-${TICKET}] "

MSG_HEAD="${PREFIX}${TYPE}: ${DESC}"
[ -n "$PHASE_TAG" ] && MSG_HEAD="${MSG_HEAD} ${PHASE_TAG}"

# Stage everything currently modified — flow guarantees that the
# subagent's edits are the only diff at this point.
git -C "$CWD" add -A
COMMIT_RC=0
git -C "$CWD" commit -m "$MSG_HEAD" -m "auto-commit via athena post-build hook (${TRIGGERING_STAGE})" >/dev/null 2>&1 || COMMIT_RC=$?

# Best-effort codemap refresh — only after commit succeeded.
# refresh_codemap always returns 0; it MUST NOT block hook exit.
if [ "$COMMIT_RC" -eq 0 ]; then
  refresh_codemap "$CWD"
fi

# Consume the marker so a re-fire on the same stop event cannot
# produce a duplicate commit.
rm -f "$CONTEXT_FILE"

exit 0
