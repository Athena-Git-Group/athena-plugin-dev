#!/usr/bin/env bash
# lint-plugin.sh — static checks for the athena-dev-plugin repository.
#
# This is a cheap, API-free lint suitable for CI. It does NOT run
# athena-skill-eval (which would need spawn-agent capability and an
# Anthropic API key) — semantic / behavioural checks are left to a
# manual or nightly workflow.
#
# Exit code: 0 = all checks pass; 1 = at least one check failed.
#
# Checks performed:
#   1. plugin.json, marketplace.json, hooks.json, .claude/settings.json
#      are valid JSON.
#   2. Every plugin manifest path (skills/commands/agents/hooks) resolves
#      to an existing directory or file.
#   3. Every SKILL.md / commands/*.md / agents/*.md has a valid
#      frontmatter block with required fields.
#   4. SKILL.md name field matches its containing directory.
#   5. Skills declaring a `stage` use a permitted value.
#   6. Shell scripts under hooks/ and scripts/ pass `bash -n` syntax
#      check and have the executable bit set.

set -uo pipefail

cd "$(dirname "$0")/.."
PLUGIN_ROOT="$PWD"

FAIL=0
fail() { echo "  ❌ $*"; FAIL=1; }
ok()   { echo "  ✅ $*"; }
step() { echo ""; echo "▶ $*"; }

# ---------- 1. JSON validity ----------
step "JSON manifests"
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json .claude/settings.json; do
  if [ ! -f "$f" ]; then
    fail "$f missing"; continue
  fi
  if python3 -c "import json,sys; json.load(open('$f'))" 2>/dev/null; then
    ok "$f valid"
  else
    fail "$f invalid JSON"
  fi
done

# ---------- 2. plugin.json paths resolve ----------
step "plugin.json paths"
SKILLS_DIR="$(python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json')).get('skills',''))")"
COMMANDS_DIR="$(python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json')).get('commands',''))")"
AGENTS_DIR="$(python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json')).get('agents',''))")"
HOOKS_FILE="$(python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json')).get('hooks',''))")"

for p in "$SKILLS_DIR" "$COMMANDS_DIR" "$AGENTS_DIR"; do
  [ -z "$p" ] && continue
  if [ -d "$p" ]; then ok "$p is a directory"; else fail "$p declared but missing"; fi
done
if [ -n "$HOOKS_FILE" ]; then
  if [ -f "$HOOKS_FILE" ]; then ok "$HOOKS_FILE present"; else fail "$HOOKS_FILE declared but missing"; fi
fi

# ---------- 3. Frontmatter on SKILL.md / commands/*.md / agents/*.md ----------
check_frontmatter() {
  local f="$1"; shift
  local required=("$@")
  python3 - <<PY
import re, sys
content = open("$f").read()
m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
if not m:
    print("missing frontmatter")
    sys.exit(1)
fm = m.group(1)
required = ${required[@]@Q}
missing = [r for r in [${"\"$(printf "%s\",\""  "${required[@]}")\""}] if (r+":") not in fm]
if missing:
    print("missing fields: " + ",".join(missing))
    sys.exit(1)
PY
}

step "SKILL.md frontmatter"
shopt -s nullglob
for d in skills/*/; do
  name="${d%/}"; name="${name##*/}"
  f="$d/SKILL.md"
  [ -f "$f" ] || { fail "$d missing SKILL.md"; continue; }
  fm="$(awk '/^---$/{c++; if(c==2)exit} c==1' "$f")"
  if ! grep -q '^name:' <<<"$fm"; then fail "$f: missing name"; continue; fi
  if ! grep -q '^description:' <<<"$fm"; then fail "$f: missing description"; continue; fi
  declared_name="$(grep -E '^name:' <<<"$fm" | head -1 | sed 's/^name:[[:space:]]*//')"
  if [ "$declared_name" != "$name" ]; then
    fail "$f: name='$declared_name' does not match dir '$name'"
    continue
  fi
  # If stage is declared, check value
  if grep -q '^stage:' <<<"$fm"; then
    stage="$(grep -E '^stage:' <<<"$fm" | head -1 | sed 's/^stage:[[:space:]]*//')"
    case "$stage" in
      pre-build|spec|plan|build|post-build|verify|review|ship)
        ok "$f stage=$stage" ;;
      *)
        fail "$f: invalid stage '$stage'" ;;
    esac
  else
    ok "$f"
  fi
done

step "commands/*.md frontmatter"
for f in commands/*.md; do
  fm="$(awk '/^---$/{c++; if(c==2)exit} c==1' "$f")"
  if ! grep -q '^description:' <<<"$fm"; then
    fail "$f: missing description"
  else
    ok "$f"
  fi
done

step "agents/*.md frontmatter"
for f in agents/*.md; do
  fm="$(awk '/^---$/{c++; if(c==2)exit} c==1' "$f")"
  for field in name description tools; do
    if ! grep -q "^${field}:" <<<"$fm"; then
      fail "$f: missing $field"
      continue 2
    fi
  done
  ok "$f"
done
shopt -u nullglob

# ---------- 4. Shell scripts ----------
step "Shell scripts syntax + executable bit"
for f in hooks/*.sh scripts/*.sh; do
  [ -e "$f" ] || continue
  if bash -n "$f" 2>/dev/null; then ok "$f bash -n"; else fail "$f bash -n failed"; fi
  if [ -x "$f" ]; then ok "$f executable"; else fail "$f not executable"; fi
done

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "🎉 All lint checks passed."
  exit 0
else
  echo "💥 Lint failed — see ❌ entries above."
  exit 1
fi
