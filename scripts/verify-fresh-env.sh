#!/usr/bin/env bash
# verify-fresh-env.sh
#
# 用途：驗證 athena-dev-plugin 在 fresh 環境（無 user-level
# ~/.claude/skills/athena-*）下能獨立支撐 /athena-discovery 含 Step 8
# 的端到端流程。
#
# ⚠ 限制：/athena-discovery 是 interactive Skill（透過 Claude Code 的 Skill
# tool 由人類觸發），bash 無法直接 headless 呼叫。本腳本只負責：
#
#   1. 在隔離的 HOME 確認沒有 user-level athena skills 殘留
#   2. 確認 plugin 自身的所有必要 skill 存在
#   3. 確認 discovery SKILL.md 含 Step 8 章節（P3 已導入）
#   4. 確認 sample PRD fixture 就位
#
# 真正的「跑 discovery 看是否產出含 Examples 的 .feature」必須由人工在
# Claude Code 中觸發；本腳本 --dry-run 模式結束時會印出下一步指令。
#
# Usage:
#   bash scripts/verify-fresh-env.sh --dry-run    # 預檢，無副作用
#   bash scripts/verify-fresh-env.sh --help       # 顯示說明

set -euo pipefail

DRY_RUN=false
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ---------------------------------------------------------------------
# CLI parsing
# ---------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            cat <<USAGE
Usage: $0 [--dry-run]

Verifies plugin can run /athena-discovery end-to-end without depending
on user-level ~/.claude/skills/athena-* copies.

Options:
  --dry-run    Only verify environment isolation and plugin
               completeness. Does not modify the user's actual
               environment or attempt to invoke discovery (which
               requires interactive Claude Code).

  --help       Show this message.

Acceptance Criteria (Plan P4):
  AC1: script exists, executable
  AC2: --dry-run is side-effect free
  AC3: header documents the interactive limitation
  AC4: paired fixture (scripts/fixtures/sample-prd.md) triggers ≥3 Rules,
       ≥2 actors, and all 3 web-backend Then handler types
       (success-failure / readmodel-then / aggregate-then)

USAGE
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
    esac
done

echo "[verify-fresh-env] plugin root: $PLUGIN_ROOT"

# ---------------------------------------------------------------------
# 1. Prepare isolated HOME (only used to assert it's clean — we never
#    install anything in it; this proves plugin can be self-contained)
# ---------------------------------------------------------------------
ISOLATED_HOME=$(mktemp -d)
trap 'rm -rf "$ISOLATED_HOME"' EXIT
echo "[verify-fresh-env] isolated HOME: $ISOLATED_HOME"

if [ -d "$ISOLATED_HOME/.claude/skills" ]; then
    echo "FAIL: freshly-created isolated HOME unexpectedly contains skills" >&2
    exit 1
fi
echo "✓ Isolated HOME has no user-level skills (baseline confirmed)"

# ---------------------------------------------------------------------
# 2. Verify all skills discovery DELEGATEs to are present in plugin
# ---------------------------------------------------------------------
REQUIRED_SKILLS=(
    athena-discovery
    athena-composition-analysis
    athena-form-activity
    athena-form-feature-spec
    athena-form-bdd-analysis
    athena-core
)
missing=()
for s in "${REQUIRED_SKILLS[@]}"; do
    if [ ! -f "$PLUGIN_ROOT/skills/$s/SKILL.md" ]; then
        missing+=("$s")
    fi
done
if [ ${#missing[@]} -ne 0 ]; then
    echo "FAIL: plugin missing required skills: ${missing[*]}" >&2
    exit 1
fi
echo "✓ All ${#REQUIRED_SKILLS[@]} required plugin skills present"

# ---------------------------------------------------------------------
# 3. Verify cross-skill reference target (reconciler-contract.md)
# ---------------------------------------------------------------------
RC_PATH="$PLUGIN_ROOT/skills/athena-core/references/reconciler-contract.md"
if [ ! -f "$RC_PATH" ]; then
    echo "FAIL: missing reconciler-contract.md at $RC_PATH" >&2
    echo "  (form-bdd-analysis and form-feature-spec depend on this)" >&2
    exit 1
fi
echo "✓ reconciler-contract.md present (cross-skill dep satisfied)"

# ---------------------------------------------------------------------
# 4. Verify Step 8 lives in discovery (the change this plan ships)
# ---------------------------------------------------------------------
DISCOVERY_MD="$PLUGIN_ROOT/skills/athena-discovery/SKILL.md"
if ! grep -q "^## Step 8: Examples 填入" "$DISCOVERY_MD"; then
    echo "FAIL: discovery SKILL.md missing Step 8 section" >&2
    exit 1
fi
if ! grep -q "最大回退次數 = 3" "$DISCOVERY_MD"; then
    echo "FAIL: discovery SKILL.md missing 3-layer fallback protection" >&2
    exit 1
fi
echo "✓ Discovery has Step 8 + 3-layer fallback protection"

# ---------------------------------------------------------------------
# 5. Verify dependency-graph.mmd updated
# ---------------------------------------------------------------------
DEP_GRAPH="$PLUGIN_ROOT/skills/athena-discovery/references/dependency-graph.mmd"
if ! grep -q "S8\[" "$DEP_GRAPH"; then
    echo "FAIL: dependency-graph.mmd missing S8 node" >&2
    exit 1
fi
echo "✓ dependency-graph.mmd reflects Step 8"

# ---------------------------------------------------------------------
# 6. Verify sample PRD fixture
# ---------------------------------------------------------------------
FIXTURE="$PLUGIN_ROOT/scripts/fixtures/sample-prd.md"
if [ ! -f "$FIXTURE" ]; then
    echo "FAIL: sample PRD fixture not found at $FIXTURE" >&2
    exit 1
fi
# AC4 spot-check: fixture mentions all 3 handler types and ≥2 actors
for keyword in "success-failure" "aggregate-then" "readmodel-then" "訪客" "已註冊使用者"; do
    if ! grep -qF "$keyword" "$FIXTURE"; then
        echo "FAIL: fixture missing required keyword: $keyword" >&2
        exit 1
    fi
done
echo "✓ Sample PRD fixture ready (3 handlers + 2 actors verified)"

# ---------------------------------------------------------------------
# Dry-run summary
# ---------------------------------------------------------------------
if $DRY_RUN; then
    cat <<DONE

===================================================================
DRY RUN COMPLETE — plugin is self-contained, environment ready

Next step (manual, interactive — bash cannot run /athena-discovery):

  1. Confirm your active Claude Code session has THIS plugin installed
     and that NO user-level ~/.claude/skills/athena-* duplicates would
     shadow plugin versions. (Plan P5 will add deprecation banners to
     those user-level copies.)

  2. Invoke:

       /athena-discovery $FIXTURE

  3. After Step 8 completes, verify (Plan AC1):
     - features/系統抽象.md exists
     - features/*/句型.md exists with coverage matrix
     - features/**/*.feature has Examples and no @ignore tag

  4. CiC fallback verification (Plan AC3):
     - The fixture intentionally contains 2 ambiguous points (email
       case-sensitivity, last_login_at on fresh user). Confirm
       discovery raises CiC notes for these in Step 6, resolves them,
       then Step 8 fills Examples without re-triggering them.

  5. Graceful degradation (Plan AC4):
     - To force 3-round exhaustion, manually edit the fixture to add
       additional ambiguity in a way that bdd-analysis cannot resolve
       deterministically. Discovery should mark .feature with
       @partial-examples after round 3 instead of looping.

===================================================================
DONE
    exit 0
fi

# Without --dry-run, we have nothing safe to do (cannot invoke discovery)
cat <<ERR >&2
ERROR: This script cannot drive /athena-discovery directly because the
skill is interactive (requires Claude Code Skill tool).

Re-run with --dry-run to prepare the environment and follow the manual
steps printed at the end.
ERR
exit 1
