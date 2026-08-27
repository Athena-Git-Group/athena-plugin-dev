#!/usr/bin/env bash
# sync-spec-pack.sh — one-way sync of the vendored PM→Eng spec pack.
#
# Direction of truth: upstream athena-skills → plugin pack → dogfood install.
#
#   Always performed:
#     skills/athena-core/assets/spec-pack-pm-to-eng/phases/   (source of truth)
#       → .athena/skills/pm-to-eng-spec/phases/               (dogfood install)
#
#   Optional first argument: path to the upstream athena-skills directory.
#     When given, first re-vendors upstream → plugin pack phases/ using the
#     transformation rules documented in the pack's VENDORED.md
#     (rsync the 9 phase dirs + pm-to-eng-flow/references, then
#     eng-output/ → specs/ on vendored files only).
#
# The two phases/ trees must be byte-identical after a sync; the root-level
# SKILL.md is the only legitimate divergence between the two pack copies
# (plugin side declares `stage: spec`, dogfood side does not) and is never
# touched here. Drift is gated in CI by scripts/lint-plugin.sh
# ("spec-pack drift check" step).
#
# Exit code: 0 = sync complete and both phases/ trees identical;
#            non-zero = a step failed (trees left as-is for inspection).

set -euo pipefail

cd "$(dirname "$0")/.."

PACK="skills/athena-core/assets/spec-pack-pm-to-eng"
DOGFOOD=".athena/skills/pm-to-eng-spec"
PHASE_DIRS=(score clarify data_model class_diagram db_table api screens ui_contract gherkin)

ok()   { echo "  ✅ $*"; }
die()  { echo "  ❌ $*" >&2; exit 1; }
step() { echo ""; echo "▶ $*"; }

[ -d "$PACK/phases" ] || die "$PACK/phases missing — run from plugin root"
[ -d "$DOGFOOD" ]     || die "$DOGFOOD missing — dogfood install not present"

# ---------- 0. Optional: upstream athena-skills → plugin pack ----------
if [ $# -ge 1 ]; then
  SRC="$1"
  step "Re-vendor upstream: $SRC → $PACK/phases/"
  [ -d "$SRC" ] || die "upstream path '$SRC' is not a directory"
  for d in "${PHASE_DIRS[@]}"; do
    [ -d "$SRC/$d" ] || die "upstream missing phase dir '$d'"
    rsync -a --delete --exclude='.DS_Store' --exclude='__pycache__' \
      "$SRC/$d/" "$PACK/phases/$d/"
  done
  [ -d "$SRC/pm-to-eng-flow/references" ] || die "upstream missing pm-to-eng-flow/references"
  rsync -a --delete --exclude='.DS_Store' --exclude='__pycache__' \
    "$SRC/pm-to-eng-flow/references/" "$PACK/phases/pm-to-eng-flow/references/"
  # Transform vendored files only ($PACK/phases/) — the pack root SKILL.md /
  # README.md / VENDORED.md are repo-original and mention "eng-output" as meta
  # text, so they must never be sed'd.
  to_fix="$(grep -rl 'eng-output/' "$PACK/phases" || true)"
  if [ -n "$to_fix" ]; then
    while IFS= read -r f; do
      sed -i '' 's|eng-output/|specs/|g' "$f"
    done <<<"$to_fix"
  fi
  ok "upstream vendored, eng-output/ → specs/ applied"
fi

# ---------- 1. Guard: source tree must already be transformed ----------
step "Guard: no eng-output/ left in $PACK/phases/"
if grep -rn 'eng-output/' "$PACK/phases" >/dev/null 2>&1; then
  grep -rn 'eng-output/' "$PACK/phases" | sed 's/^/     /'
  die "source tree still contains 'eng-output/' — upstream transform incomplete"
fi
ok "source tree clean"

# ---------- 2. Plugin pack → dogfood install ----------
step "Sync $PACK/phases/ → $DOGFOOD/phases/"
rsync -a --delete --exclude='.DS_Store' --exclude='__pycache__' \
  "$PACK/phases/" "$DOGFOOD/phases/"
ok "rsync complete"

# ---------- 3. Integrity check ----------
step "Integrity: diff -rq of both phases/ trees"
if drift="$(diff -rq -x .DS_Store -x __pycache__ "$PACK/phases" "$DOGFOOD/phases" 2>&1)"; then
  ok "phases/ trees identical"
else
  echo "$drift" | sed 's/^/     /'
  die "phases/ trees still differ after sync"
fi

echo ""
echo "🎉 spec-pack sync complete."
