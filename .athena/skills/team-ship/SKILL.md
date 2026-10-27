---
name: team-ship
description: >
  本 repo（athena-dev-plugin）的 ship stage skill。非互動執行：
  依 flow 傳入的 merge_target 與 git_context，push 工作分支、
  --no-ff merge 到 merge_target、回報 commit hash。merge conflict
  時停止並回報，不自動解、不 force merge。
stage: ship
---

# Team Ship（athena-dev-plugin）

你是 ship 階段的執行者。**非互動**：不問使用者任何問題，所有決策來自
flow 傳入的參數。

# SOP

## Phase 1 -- 讀取輸入與前置檢查

1. READ 讀取 `.athena/skills/team-common/rules/agent-isolation.md`，確認 fresh agent 的
   輸入來源要求。
2. READ 讀取 `handoffs/<slug>-review.md`（Lightweight 合併模式改讀 build/verify
   handoff）與 flow context：`git_context`（branch_name、base_branch、commits）
   + `merge_target`（flow 在啟動你之前向使用者取得並傳入）。
3. THINK 若 prompt 中沒有 `merge_target` → Gate FAIL（#contract-violation），
   不猜、不問，直接跳到 Phase 3 寫 handoff。
4. THINK 確認 review gate 為 PASS；FAIL 則不 ship，直接跳到 Phase 3 回報。

## Phase 2 -- push 與 merge

1. WRITE 有未提交變更 → `git add` + `git commit`（commit message 依
   git-conventions skill 的格式）。
2. WRITE `git push -u origin <branch_name>`。
3. WRITE `git checkout <merge_target>` → `git pull origin <merge_target>`。
4. WRITE `git merge --no-ff <branch_name>`。
5. WRITE `git push origin <merge_target>`。
6. WRITE `git checkout <branch_name>`（切回工作分支）。
7. READ 記下 merge commit hash（於 merge_target 上 `git rev-parse HEAD`）。
8. READ 上述任一 git 步驟失敗（push 被拒、merge conflict、merge_target 不存在）
   時，讀取 `.athena/skills/team-common/rules/fail-reporting.md` 的 Rule 4 失敗處理表，
   依表停止、恢復現場並記錄，然後進 Phase 3。

## Phase 3 -- handoff

1. READ Gate Verdict 為 FAIL 且尚未讀取 `.athena/skills/team-common/rules/fail-reporting.md`
   時，先讀取之（FAIL 格式與 taxonomy tag 要求）。
2. READ 讀取 `skills/athena-flow/references/agent-handoff.md` 的變體差異表
   「Ship（Full）」列（Lightweight 合併模式改讀「Review-ship」列）。
3. WRITE 依該變體格式寫 handoff：獨立 ship stage（Full 路由）寫
   `handoffs/<slug>-ship.md`；Lightweight 合併模式依 flow prompt 指定併入
   `handoffs/<slug>-review-ship.md` 的 Ship Result 段。
   Next Recommended Stage = (end of flow)。
4. READ 回頭檢查 handoff 是否符合本次已載入規則；若不符合，立即修正。
