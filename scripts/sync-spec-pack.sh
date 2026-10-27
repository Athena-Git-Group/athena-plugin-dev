#!/usr/bin/env bash
# sync-spec-pack.sh — one-way sync of the PM→Eng spec pack: plugin source of
# truth → dogfood install.
#
# The pack was originally vendored from an internal athena-skills repo. As of
# 2026-10-27 it is a fork: athena-skills is no longer the source of truth and
# this script no longer re-vendors anything from it. There is now exactly one
# sync direction, both copies living in this repo:
#
#   skills/athena-core/assets/spec-pack-pm-to-eng/   (source of truth)
#     → .athena/skills/pm-to-eng-spec/               (dogfood install)
#
# Scope: the ENTIRE pack directory is mirrored — root rules/, templates/,
# phases/ (each phase's own rules/ templates/ scripts/), all of it — with one
# exception: the root-level SKILL.md is never touched. It is the only
# legitimate divergence between the two pack copies (plugin side declares
# `stage: spec` in frontmatter, dogfood side does not), so both the rsync and
# the integrity check below exclude it by path.
#
# Drift between the two copies (outside that one file) is gated in CI by
# scripts/lint-plugin.sh ("spec-pack drift check" step).
#
# Exit code: 0 = sync complete and both copies identical (root SKILL.md
#            aside); non-zero = a step failed (trees left as-is for
#            inspection).

set -euo pipefail

cd "$(dirname "$0")/.."

PACK="skills/athena-core/assets/spec-pack-pm-to-eng"
DOGFOOD=".athena/skills/pm-to-eng-spec"

ok()   { echo "  ✅ $*"; }
die()  { echo "  ❌ $*" >&2; exit 1; }
step() { echo ""; echo "▶ $*"; }

[ -d "$PACK" ]     || die "$PACK missing — run from plugin root"
[ -d "$DOGFOOD" ]  || die "$DOGFOOD missing — dogfood install not present"

step "Sync $PACK/ → $DOGFOOD/ (root SKILL.md excluded)"
rsync -a --delete \
  --exclude='.DS_Store' --exclude='__pycache__' \
  --exclude='/SKILL.md' \
  "$PACK/" "$DOGFOOD/"
ok "rsync complete"

step "Integrity: diff of both pack trees (root SKILL.md excluded)"
# diff -rq's -x excludes by filename only, and phases/*/SKILL.md files share
# that name with the root one and must still be compared — so -x SKILL.md
# would blind the check to real phase-level drift. Instead, set each side's
# root SKILL.md aside into a scratch dir for the duration of the diff, then
# put it straight back regardless of how the diff turns out.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/pack" "$tmp/dogfood"
mv "$PACK/SKILL.md" "$tmp/pack/SKILL.md"
mv "$DOGFOOD/SKILL.md" "$tmp/dogfood/SKILL.md"
drift="$(diff -rq -x .DS_Store -x __pycache__ "$PACK" "$DOGFOOD" 2>&1)" || true
mv "$tmp/pack/SKILL.md" "$PACK/SKILL.md"
mv "$tmp/dogfood/SKILL.md" "$DOGFOOD/SKILL.md"

if [ -z "$drift" ]; then
  ok "pack trees identical (root SKILL.md aside)"
else
  echo "$drift" | sed 's/^/     /'
  die "pack trees still differ after sync"
fi

echo ""
echo "🎉 spec-pack sync complete."
