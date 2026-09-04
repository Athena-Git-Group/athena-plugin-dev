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
#     transformation rules documented in the pack's VENDORED.md (rsync every
#     dir listed in UPSTREAM_PHASE_DIRS + pm-to-eng-flow/references, then
#     eng-output/ → specs/ on vendored files only).
#
# phases/ holds two kinds of dirs, tracked by the two lists below:
# UPSTREAM_PHASE_DIRS (vendored from athena-skills, re-vendored by step 0) and
# PLUGIN_OWN_PHASE_DIRS (originate in this repo, never re-vendored). Read the
# comment above those lists before adding a new phase dir.
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

# ---- phases/ dir ownership — read this before adding a new phase dir --------
#   UPSTREAM_PHASE_DIRS    phase dirs vendored from upstream athena-skills.
#                          Step 0 re-vendors each of them with rsync --delete,
#                          so upstream wins and local edits are overwritten.
#   PLUGIN_OWN_PHASE_DIRS  phase dirs that originate in THIS repo. They have no
#                          upstream counterpart and are never re-vendored;
#                          step 0 only checks that they came out intact.
#
# A NEW phase dir belongs in PLUGIN_OWN_PHASE_DIRS unless it really exists in
# upstream athena-skills. Listing a plugin-original dir under
# UPSTREAM_PHASE_DIRS aborts the next `sync-spec-pack.sh <upstream>` run at the
# ownership guard below, before any rsync runs — such a dir does not come from
# upstream（該目錄不來自上游）, which is not the same as upstream missing a dir.
# Neither list is needed for the dogfood install: step 2 rsyncs the whole
# phases/ tree, so a new dir propagates to .athena/ on its own. A name may be
# registered here before the dir exists — step 0 warns instead of failing.
UPSTREAM_PHASE_DIRS=(score clarify data_model class_diagram db_table api screens ui_contract gherkin)
PLUGIN_OWN_PHASE_DIRS=(specify ui_prototype)

ok()   { echo "  ✅ $*"; }
warn() { echo "  ⚠️  $*"; }
die()  { echo "  ❌ $*" >&2; exit 1; }
step() { echo ""; echo "▶ $*"; }

[ -d "$PACK/phases" ] || die "$PACK/phases missing — run from plugin root"
[ -d "$DOGFOOD" ]     || die "$DOGFOOD missing — dogfood install not present"

# ---------- Guard: phase dir ownership ----------
# Runs unconditionally and before any rsync: a dir claimed by both lists has no
# safe interpretation, and hitting that mid-loop would leave phases/ half
# re-vendored.
step "Guard: phase dir ownership (upstream list vs plugin-own list)"
for u in "${UPSTREAM_PHASE_DIRS[@]}"; do
  for p in "${PLUGIN_OWN_PHASE_DIRS[@]}"; do
    [ "$u" != "$p" ] || die "phase dir '$u' is listed in BOTH UPSTREAM_PHASE_DIRS and PLUGIN_OWN_PHASE_DIRS — it is plugin-original, 該目錄不來自上游: keep it only in PLUGIN_OWN_PHASE_DIRS"
  done
done
ok "lists disjoint (upstream: ${#UPSTREAM_PHASE_DIRS[@]}, plugin-own: ${#PLUGIN_OWN_PHASE_DIRS[@]})"

# ---------- 0. Optional: upstream athena-skills → plugin pack ----------
if [ $# -ge 1 ]; then
  SRC="$1"
  step "Re-vendor upstream: $SRC → $PACK/phases/"
  [ -d "$SRC" ] || die "upstream path '$SRC' is not a directory"
  for d in "${UPSTREAM_PHASE_DIRS[@]}"; do
    if [ ! -d "$SRC/$d" ]; then
      # Two different mistakes land here and this loop cannot tell them apart:
      # a plugin-original dir filed under the wrong list, or a genuine upstream
      # removal (a vendored dir has a local copy too, so its presence proves
      # nothing either way). Naming only the upstream hypothesis sends the
      # maintainer hunting through athena-skills for a dir that may only ever
      # have existed in this repo, so both are named — plugin-original first,
      # since that is what a freshly added phase dir looks like. With no local
      # copy at all only the upstream hypothesis is left standing.
      [ ! -d "$PACK/phases/$d" ] || die "phase dir '$d' is listed in UPSTREAM_PHASE_DIRS but is absent from '$SRC' while present in $PACK/phases/ — either 該目錄不來自上游 (plugin-original, misfiled: move it to PLUGIN_OWN_PHASE_DIRS) or upstream really dropped it (re-vendor from a matching upstream revision, or drop it from the list)"
      die "upstream missing phase dir '$d' — expected '$SRC/$d' (upstream layout changed?)"
    fi
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

  # Nothing above should have touched these dirs, so this is a cheap assertion
  # that the ownership split actually held. A registered name whose dir does
  # not exist yet is legitimate (names get reserved before the dir lands), but
  # an existing dir that came out empty means repo-original content is gone,
  # and step 2 would propagate that loss into the dogfood install.
  step "Verify plugin-own phase dirs survived the re-vendor"
  for d in "${PLUGIN_OWN_PHASE_DIRS[@]}"; do
    if [ ! -d "$PACK/phases/$d" ]; then
      warn "plugin-own phase dir '$d' is registered but does not exist yet — skipped"
      continue
    fi
    [ -n "$(ls -A "$PACK/phases/$d")" ] || die "plugin-own phase dir '$d' is empty after re-vendor — repo-original content lost, restore it before syncing"
    ok "'$d' intact"
  done
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
