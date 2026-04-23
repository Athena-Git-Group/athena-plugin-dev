# Verify Retry

## 適用條件

本文件**僅適用於 Full Weight 流程**（`PASS-SPEC-FIRST`）。

Lightweight 路由（`PASS-BUILD-WITH-VERIFY`）的 verify 失敗處理方式不同：
- 沒有 phase loop，無法做 targeted re-build
- Verify fail → flow 開一個 fresh build agent（repair mode），載入 build skill + verify handoff 中的 issues
- Agent 修復所有 issues → 重跑 smoke test → 更新 build handoff
- Flow 觸發 post-build commit（`triggering_stage: verify-fix-lightweight`，commit type = `fix`）
- Re-verify（完整重跑），最多 2 輪，超過交給使用者
- 見 `stage-contracts.md`「build（Lightweight）」段落

---

## 概述

Verify stage 失敗時的回退與修復流程（Full Weight）。
目標：精確定位問題 phase → targeted re-build → re-verify。

## 前提

- Build 已採用 phase loop，每個 phase 都有 mini-handoff（`handoffs/<slug>-build-phase-<NN>.md`）
- Verify agent 必須在 issue list 中標記 `affected_phase`
- Phase-level smoke test 已通過（verify 抓到的是跨 phase 整合問題或 smoke test 未覆蓋的問題）

## Verify Handoff 格式（擴充）

Verify fail 時，handoff 的 issue list 必須標記每個 issue 屬於哪個 phase：

```markdown
# Handoff: verify

## Stage
verify

## Gate Verdict
FAIL — 2 issues found

## Issues Found

1. **[Phase 05]** approval_test.rs line 42: assertion uses wrong field name `approve_status` should be `approval_status`
2. **[Phase 06]** frontend calls `/api/approval` instead of `/api/approvals` (plural), mismatch with Phase 05 actual endpoint

## Affected Phases
- Phase 05: 1 issue
- Phase 06: 1 issue

## Inputs Used
- handoffs/<slug>-build.md
- handoffs/<slug>-build-phase-05.md
- handoffs/<slug>-build-phase-06.md
- handoffs/<slug>-build-phase-07.md

## Next Recommended Stage
re-build (targeted)
```

### 必要欄位

| 欄位 | 說明 |
|------|------|
| Issues Found | 每個 issue 必須以 `[Phase NN]` 開頭標記 affected phase |
| Affected Phases | 彙整受影響的 phase 及 issue 數量 |

## Retry 流程

```
Verify FAIL
    │
    ▼
Flow 讀 verify handoff
    │
    ├── 解析 Issues Found → 按 affected_phase 分組
    │
    ▼
對每個 affected phase（按依賴順序）：
    │
    ├── 1. 開 fresh agent（repair mode）
    │      載入：
    │      - build skill
    │      - 該 phase 的 phase card
    │      - 該 phase 的 mini-handoff（上一次的）
    │      - verify handoff 中屬於此 phase 的 issues
    │
    ├── 2. Agent 修復 issues
    │      - 讀取 issues 描述
    │      - 修復程式碼
    │      - 重跑 smoke test
    │      - 更新 mini-handoff
    │
    ├── 3. Flow 檢查更新後的 mini-handoff Gate Verdict
    │      - PASS → post-build commit（fix type）→ 繼續修下一個 phase
    │      - FAIL → 再 retry（見下方上限規則）
    │
    ▼
所有 affected phases 修復完成
    │
    ▼
Flow 重新合成 handoffs/<slug>-build.md
    │
    ▼
Re-Verify：開 fresh verify agent → 完整重跑
    │
    ├── PASS → 繼續 review
    └── FAIL → 再次循環（見下方上限規則）
```

## Repair Mode Agent Prompt

```
你正在修復 Phase <NN>: <Phase Name> 的問題。

讀取以下資料：
1. .athena/skills/<build-skill>/SKILL.md
2. plans/<slug>/phase-cards/<NN>-<name>.md
3. handoffs/<slug>-build-phase-<NN>.md（你上次的 mini-handoff）
4. 以下是 Verify 發現的問題：

   - <issue 1 description>
   - <issue 2 description>

修復步驟：
1. 逐一修復上述 issues
2. 重跑 smoke test：<phase card 中的 smoke_test 指令>
3. 更新 mini-handoff（handoffs/<slug>-build-phase-<NN>.md）
```

## Retry 上限

| 層級 | 上限 | 超過時 |
|------|------|--------|
| Phase smoke test retry | 2 輪 | 停止該 phase，交給使用者 |
| Verify → re-build → re-verify 循環 | 2 輪 | 停止流程，交給使用者 |

### 計數方式

```
第 1 輪：Build phases → Verify FAIL → Targeted re-build → Re-Verify
第 2 輪：Re-Verify FAIL → 再次 Targeted re-build → Re-Verify
第 3 輪：不執行，停止流程
```

## Re-Verify 的範圍

Re-Verify **完整重跑**，不只驗修復的項目。原因：
- 修復 Phase 05 可能影響 Phase 07 的整合結果
- Smoke test 只驗單一 phase，verify 驗跨 phase 整合
- 局部 re-verify 可能遺漏連鎖影響

## Fix Commit 格式

修復產生的 commit 使用 `fix` type，標明修復的 phase：

```
[HAP-3621] fix(approval): fix plural endpoint path (verify-fix-phase-06)
```

## 非協商規則

1. **Verify issue 必須標記 affected_phase** — 未標記的 issue 視為 verify skill 的 bug，停止流程
2. **Targeted re-build，不整個 Build 重來** — 只修 affected phases
3. **修完後完整 re-verify** — 不做局部 re-verify
4. **最多 2 輪** — 超過交給使用者，不無限循環
5. **修復 commit 獨立** — 不 amend 原 phase commit，新開 fix commit
