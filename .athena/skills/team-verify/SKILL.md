---
name: team-verify
description: >
  本 repo（athena-dev-plugin）的 verify stage skill。獨立驗證 build 宣稱的完成項：
  逐條對 point-report 驗收、重跑 smoke 檢查、針對 Risks 段做機械查證。
  只回報不修（無 Edit 權限），issue 具體到檔案:行號。Handoff 依路由分兩種模式：
  走過 spec/plan 完整路（PASS-SPEC-FIRST）用 Full 模式——讀所有 mini-handoff、
  每個 issue 標 affected phase；跳過 spec 的驗證路（PASS-BUILD-WITH-VERIFY）
  用 Lightweight 模式——不讀 mini-handoff、issue 不標 phase。
stage: verify
---

# Team Verify（athena-dev-plugin）

你是 verify 階段的執行者。**你沒有 Edit 權限——只回報，不修**（規範見
`rules/issue-reporting.md`）。

# SOP

## Phase 1 -- 讀取輸入並選定模式

1. READ 讀取 `.athena/skills/team-common/rules/agent-isolation.md`，確認 fresh agent 的
   輸入來源與「不採信 handoff 宣稱」要求。
2. WRITE （選填）取 `Started At:`（`date -u +%Y-%m-%dT%H:%M:%SZ`），供 handoff Timing 段。
3. READ 讀取 `handoffs/<slug>-build.md`（build 宣稱的完成項與 smoke 結果）與
   `points/<slug>.md`（任務描述、驗收條件與 **Risks 段**）。
4. READ 讀取實際 diff：`git diff <base>...HEAD` 或 `git show`（以 git 為準，
   不以 handoff 敘述為準）。
5. THINK 判定本次模式：路由 verdict 為 PASS-SPEC-FIRST（走過 spec/plan 的完整路）
   → **Full 模式**；PASS-BUILD-WITH-VERIFY（跳過 spec、直接 build 但需獨立驗證）
   → **Lightweight 模式**。
6. READ 僅 Full 模式：讀取所有 mini-handoff `handoffs/<slug>-build-phase-*.md`，
   用來把 issue 對回 affected phase。

## Phase 2 -- 逐項查證

1. THINK 把 point-report 的任務描述與驗收條件拆成清單，逐條對 diff 查證有做且做對。
2. READ 讀取 `.athena/skills/team-common/rules/smoke-test.md` 的 Rule 4（verify 時重跑規則）。
3. DELEGATE 依改動類型自己重跑 smoke 指令，記錄每條指令與實際輸出。
4. THINK 對 point-report Risks 段的每一條風險，設計一個可機械判定的檢查
   （例如「可能漏改其他引用處」→ `grep -rn` 全 repo 查舊字串殘留）。
5. DELEGATE 執行上述風險檢查指令，記錄輸出。
6. THINK 範圍檢查：diff 中是否有 point-report 範圍外的改動。

## Phase 3 -- 回報與 handoff

1. READ 讀取 `rules/issue-reporting.md`，確認 issue 的記載格式與 phase 標記要求。
2. READ 任一查證為 FAIL 時，讀取 `.athena/skills/team-common/rules/fail-reporting.md`，
   確認 Gate Verdict 的 FAIL 格式與 taxonomy tag 要求。
3. WRITE 依模式複製對應骨架填寫 `handoffs/<slug>-verify.md`：
   Full 模式用 `templates/verify-handoff-full.md`（成品樣貌見
   `templates/verify-handoff-full.example.md`）；Lightweight 模式用
   `templates/verify-handoff-lightweight.md`（成品樣貌見
   `templates/verify-handoff-lightweight.example.md`）。
   Next Recommended Stage：Full 模式 PASS → review、FAIL → build（flow 按
   affected_phase 做 per-phase targeted fix）；Lightweight 模式 PASS → review-ship、
   FAIL → build（targeted re-build）。
4. READ 回頭檢查 handoff 是否符合本次已載入規則與所選骨架；若不符合，立即修正。
