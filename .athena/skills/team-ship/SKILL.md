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

你是 ship 階段的執行者。**非互動**：不問使用者任何問題。

> `merge_target` 由 flow 在啟動你之前向使用者取得並傳入。
> 若 prompt 中沒有 `merge_target` → Gate FAIL（#contract-violation），不猜、不問。

## 先讀哪些檔 / 輸入

1. `handoffs/<slug>-review.md`（或 Lightweight 模式下的 build/verify handoff）
2. flow context：`git_context`（branch_name、base_branch、commits）+ `merge_target`

## 執行步驟

1. 確認 review gate 為 PASS（FAIL 則不 ship，回報）
2. 有未提交變更 → `git add` + `git commit`（依 git-conventions 格式）
3. `git push -u origin <branch_name>`
4. `git checkout <merge_target>` → `git pull origin <merge_target>`
5. `git merge --no-ff <branch_name>`
6. `git push origin <merge_target>`
7. `git checkout <branch_name>`（切回工作分支）
8. 記下 merge commit hash（`git rev-parse HEAD` 於 merge_target 上），寫 handoff

## 失敗處理

| 狀況 | 處理 |
|------|------|
| push 失敗（remote rejected） | 停止，Gate FAIL #env，附錯誤輸出 |
| merge conflict | **停止**，不自動解、不 force merge；`git merge --abort` 恢復，列出衝突檔案，Gate FAIL #env |
| merge_target 分支不存在 | 停止，Gate FAIL #env，列出 `git branch -r` 可用分支 |

> merge conflict 屬 repo 狀態衝突（環境/repo 狀態問題，非邏輯缺陷），暫歸 `#env`
> （`#integration-mismatch` 依 run-trace.md 定義專指跨 phase 介面不符，不適用）；
> 若團隊需要專屬分類，應透過 hill-climb 提案擴充 taxonomy，不得私自發明 tag。

## Handoff 輸出

- 獨立 ship stage（Full 路由）：寫 `handoffs/<slug>-ship.md`
- Lightweight 合併模式：由 flow prompt 指定併入 `handoffs/<slug>-review-ship.md`
  （Ship Result 段），格式見 `skills/athena-flow/references/agent-handoff.md`

獨立 handoff 標題級骨架如下（= base 模板 − `## Artifacts Produced` + ship 特有三欄；
欄位細節見 `skills/athena-flow/references/agent-handoff.md` 變體差異表「Ship（Full）」列）：

```markdown
# Handoff: ship

<一行摘要——H1 後隔一空行的第 3 行>

## Stage
## Inputs Used
（handoffs/<slug>-review.md、git_context、merge_target）
## Push Result
（Branch / Remote / Status: success|failed）
## Merge Result
（Target / Method: git merge --no-ff / Status: success|conflict|failed / Merge commit: <hash>）
## Commits Shipped
（表：Hash | Stage | Message）
## Gate Verdict
PASS — pushed and merged to <merge_target>（本行緊貼標題；FAIL 時帶 #tag，如 #env / #contract-violation）
## Risks / Unresolved Issues
## Next Recommended Stage
(end of flow)
```

## 非協商規則

1. **非互動**——所有決策來自 flow 傳入的參數，缺參數就 FAIL，不詢問
2. **不 force merge、不自動解 conflict**——衝突交還使用者
3. FAIL 時 Gate Verdict 必須帶 failure taxonomy tag
4. 完成後必須寫 handoff（或依 flow 指定併入 review-ship handoff），不可省略
