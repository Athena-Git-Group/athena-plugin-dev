# Handoff: verify

逐條驗收 approval-workflow 的 6 個 phase 產出，發現 1 個跨 phase 介面不符

## Stage
verify

## Inputs Used
- points/approval-workflow.md
- handoffs/approval-workflow-build.md（flow 合成的最終 build handoff）
- handoffs/approval-workflow-build-phase-01.md
- handoffs/approval-workflow-build-phase-02.md
- handoffs/approval-workflow-build-phase-03.md
- git diff main...HEAD

## Artifacts Produced
- handoffs/approval-workflow-verify.md（本檔；verify 只回報，不產出程式碼）

## Gate Verdict
FAIL — frontend 呼叫 /api/approval 但後端是 /api/approvals #integration-mismatch

## Checks Performed
- 驗收條目「API 端點依 spec Section 3 命名」: FAIL
- bash -n hooks/require-point.sh: exit 0（自跑）
- python3 -m py_compile scripts/emit_trace.py: exit 0（自跑）
- grep -rn 'api/approval[^s]' src/: 2 筆殘留（風險查證）

## Issues Found
1. **[Phase 03]** src/frontend/api.ts:41 — 呼叫 `/api/approval`，後端路由為 `/api/approvals` #integration-mismatch

## Affected Phases
- Phase 03: 1

## Risks / Unresolved Issues
None

## Next Recommended Stage
build（FAIL，flow 按 affected_phase 做 per-phase targeted fix）

## Timing
- Started At: 2026-08-05T14:02:11Z
- Ended At: 2026-08-05T14:18:47Z
