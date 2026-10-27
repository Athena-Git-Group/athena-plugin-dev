# Rule 1 - Gate Verdict 為 FAIL 時必帶 taxonomy tag

- Level: `MUST`
- taxonomy tag 是 FAIL 原因的分類標籤（例如 `#spec-gap`、`#env`、`#contract-violation`），合法清單（enum）見 `skills/hxde-flow/references/run-trace.md` 的 Failure Taxonomy 段。
- FAIL 的固定格式：`FAIL — <一句話原因> #<tag>`，且本行緊貼 `## Gate Verdict` 標題，不可先空行。
- 一個 handoff 裡有多個獨立問題時，各帶各的 tag，不共用一個籠統的 tag。
- 回報的 issue 應具體到 `檔案:行號`，附一句話說明與判定依據（指令輸出或 diff 行）。

## Good Example

- 這個例子是好的，因為 FAIL 原因一句話講清楚、帶 tag、緊貼標題。

```md
## Gate Verdict
FAIL — contract-surface.md 缺 grep 實據 #spec-gap
```

## Bad Example

- 這個例子是壞的，因為沒有 tag、原因模糊，且先空了一行。

```md
## Gate Verdict

FAIL — 有些問題
```

# Rule 2 - 不使用 taxonomy enum 裡不存在的 tag

- Level: `MUST`
- 只能使用 `skills/hxde-flow/references/run-trace.md` Failure Taxonomy 段列出的 tag。
- 覺得現有分類不夠用時，不得私自發明新 tag——應透過 hill-climb 提案擴充 taxonomy。
- 已有的歸類結論：merge conflict 屬 repo 狀態衝突，用 `#env`（`#integration-mismatch` 依 run-trace.md 定義專指跨 phase 介面不符，不適用於 merge conflict）。

## Good Example

- 這個例子是好的，因為 merge conflict 套用既定結論的 `#env`。

```md
## Gate Verdict
FAIL — merge conflict，衝突檔案見下 #env
```

## Bad Example

- 這個例子是壞的，因為它發明了 enum 裡不存在的 tag。

```md
## Gate Verdict
FAIL — merge conflict #merge-conflict
```

# Rule 3 - FAIL 不免除 handoff——停止前仍須寫出 handoff

- Level: `MUST`
- 不論 PASS 或 FAIL，完成（或中止）本 stage 時都必須寫 handoff，不可省略。
- FAIL 時，原因與 tag 寫在 Gate Verdict，佐證（錯誤輸出、衝突檔案清單、問題清單路徑）寫在 handoff 對應段落，然後才停止。
- 「停止」的意思是不再往下做本 stage 之後的事，由 flow 依 FAIL 決定下一步，不是默默結束。

## Good Example

- 這個例子是好的，因為 FAIL 後仍產出完整 handoff 再停止。

```md
push 被 remote 拒絕。寫 handoffs/add-tag-ship.md：
Gate Verdict 填 FAIL — push 失敗 #env，Push Result 段附上完整錯誤輸出。
寫完停止，不嘗試 merge。
```

## Bad Example

- 這個例子是壞的，因為遇到失敗就直接結束，沒留下任何 handoff。

```md
push 失敗了，看起來是權限問題，先結束這次執行。
```

# Rule 4 - Ship 階段 git 失敗依處理表停止回報，不自行補救

- Level: `MUST`
- ship 階段遇到下列 git 失敗，一律**停止並回報**，不自動解、不 force merge、不重試繞過：

| 狀況 | 處理 |
|------|------|
| push 失敗（remote rejected） | 停止，Gate FAIL `#env`，附錯誤輸出 |
| merge conflict | 停止，不自動解、不 force merge；`git merge --abort` 恢復，列出衝突檔案，Gate FAIL `#env` |
| merge_target 分支不存在 | 停止，Gate FAIL `#env`，列出 `git branch -r` 可用分支 |

- 衝突交還使用者處理，ship agent 的職責到「把現場恢復乾淨並講清楚」為止。

## Good Example

- 這個例子是好的，因為 conflict 時先恢復現場、列出衝突、照格式 FAIL。

```md
git merge --no-ff feature/add-tag 發生 conflict。
執行 git merge --abort 恢復，handoff 列出衝突檔案：
- skills/hxde-flow/references/run-trace.md
Gate Verdict：FAIL — merge conflict，衝突檔案如上 #env
```

## Bad Example

- 這個例子是壞的，因為它自己動手解 conflict 還強行 merge。

```md
有兩個檔案衝突，我看起來 ours 版本比較新，
直接 git checkout --ours 解掉後 git merge --continue 完成 merge。
```
