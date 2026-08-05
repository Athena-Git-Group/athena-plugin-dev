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

# ---------- 5. Plan validator self-test ----------
step "validate_plan.py fixture self-test"
VALIDATOR="skills/athena-specformula/scripts/validate_plan.py"
FIXTURE="tests/fixtures/plan-valid"
if [ ! -f "$VALIDATOR" ]; then
  fail "$VALIDATOR missing"
elif [ ! -d "$FIXTURE" ]; then
  fail "$FIXTURE missing"
else
  out="$(python3 "$VALIDATOR" "$FIXTURE" 2>&1)"
  if [ $? -eq 0 ]; then
    ok "$VALIDATOR passes on $FIXTURE"
  else
    fail "$VALIDATOR failed on $FIXTURE:"
    echo "$out" | sed 's/^/     /'
  fi
fi

# ---------- 5b. Plan validator touches self-test ----------
step "validate_plan.py touches / independence-overlap self-test"
if [ ! -f "$VALIDATOR" ] || [ ! -d "$FIXTURE" ]; then
  fail "touches self-test skipped: $VALIDATOR or $FIXTURE missing"
else
  # (a) positive: fixture declares touches on every phase → --require-touches passes
  out="$(python3 "$VALIDATOR" --require-touches "$FIXTURE" 2>&1)"
  if [ $? -eq 0 ]; then
    ok "$VALIDATOR --require-touches passes on $FIXTURE"
  else
    fail "$VALIDATOR --require-touches failed on $FIXTURE:"
    echo "$out" | sed 's/^/     /'
  fi
  # (b) negative: make phases 05 and 06 (parallel-eligible) touch the same glob
  #     → validator must exit 1 and mention the overlap
  tmpneg="$(mktemp -d)"
  cp -R "$FIXTURE" "$tmpneg/plan-overlap"
  python3 - "$tmpneg/plan-overlap/plan.md" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
new = text.replace('files: ["src/frontend/**"]', 'files: ["src/backend/**"]', 1)
assert new != text, "fixture no longer declares phase 06 glob src/frontend/**"
open(path, "w", encoding="utf-8").write(new)
PY
  if [ $? -ne 0 ]; then
    fail "could not prepare overlap fixture copy in $tmpneg"
  else
    out="$(python3 "$VALIDATOR" "$tmpneg/plan-overlap" 2>&1)"
    rc=$?
    if [ "$rc" -eq 1 ] && grep -qi "overlap" <<<"$out"; then
      ok "$VALIDATOR rejects overlapping touches on parallel phases (exit 1, mentions overlap)"
    else
      fail "$VALIDATOR negative test: expected exit 1 mentioning 'overlap', got exit $rc:"
      echo "$out" | sed 's/^/     /'
    fi
  fi
  rm -rf "$tmpneg"
fi

# ---------- 6. Status renderer self-test ----------
step "render_status.py fixture self-test"
RENDERER="scripts/render_status.py"
if [ ! -f "$RENDERER" ]; then
  fail "$RENDERER missing"
elif [ ! -d "$FIXTURE" ]; then
  fail "$FIXTURE missing"
else
  tmproot="$(mktemp -d)"
  mkdir -p "$tmproot/plans"
  cp -R "$FIXTURE" "$tmproot/plans/plan-valid"
  out_html="$tmproot/status.html"
  if python3 "$RENDERER" "$tmproot" --output "$out_html" >/dev/null 2>&1 && [ -f "$out_html" ]; then
    missing_phases=""
    for pid in 01 02 03 04 05 06 07 08; do
      grep -q "data-phase=\"$pid\"" "$out_html" || missing_phases="$missing_phases $pid"
    done
    if [ -z "$missing_phases" ]; then
      ok "$RENDERER renders fixture with all 8 phase ids"
    else
      fail "$RENDERER output missing phase id(s):$missing_phases"
    fi
    # Interactive dashboard invariants:
    #   - embedded JSON detail blob (drawer data, no fetch at runtime)
    #   - dependency edges drawn (fixture DAG has 8 edges; require >= 7)
    #   - no external resource references (self-contained, file:// safe)
    if grep -q 'type="application/json" id="athena-status-data"' "$out_html"; then
      ok "$RENDERER embeds phase-detail JSON blob"
    else
      fail "$RENDERER output missing embedded JSON blob (athena-status-data)"
    fi
    edge_count="$(grep -oE '<(line|path)[^>]*class="dag-edge"' "$out_html" | wc -l | tr -d ' ')"
    if [ "$edge_count" -ge 7 ]; then
      ok "$RENDERER draws $edge_count dependency edges (>= 7)"
    else
      fail "$RENDERER output has only $edge_count dependency edges (expected >= 7)"
    fi
    if grep -qE '(src|href)="https?://' "$out_html"; then
      fail "$RENDERER output references external resources (must be self-contained)"
    else
      ok "$RENDERER output is self-contained (no external src/href)"
    fi
  else
    fail "$RENDERER failed on $tmproot (fixture copy of $FIXTURE)"
  fi
  rm -rf "$tmproot"
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "🎉 All lint checks passed."
  exit 0
else
  echo "💥 Lint failed — see ❌ entries above."
  exit 1
fi
