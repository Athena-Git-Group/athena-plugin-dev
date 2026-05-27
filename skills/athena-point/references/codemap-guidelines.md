# Codemap-Assisted Scoring Guidelines

當專案根目錄存在 `graphify-out/`（由 `/codemap` 透過 [graphify](https://github.com/safishamsi/graphify)
產生），point subagent 可以透過唯讀的 `graphify` 子指令查詢 codebase 結構，
用以輔助 Impact Radius / Contract-Schema / Regression Risk 的評分，
**取代**對 `src/` 做大範圍 Read / Grep 掃描以節省 token。

> 本文件規範 **read-side**（point 階段如何「消費」codemap）。
> 對應的 **write-side**（post-build commit 後如何自動執行 `--update`，
> 在什麼 guard 下會跳過 / 失敗 / 不阻斷 flow）請見
> `../../athena-post-build/references/codemap-refresh-policy.md`。

## 什麼是 `graphify-out/`

`graphify-out/` 是 `/codemap`（或 `/graphify`）產生的輸出資料夾，固定位於專案根目錄。
其中至少會包含：

- `graphify-out/graph.json`：完整的 codebase 知識圖譜（節點 = 模組/類別/函式/概念；邊 = 呼叫、引用、概念相關）
- `graphify-out/GRAPH_REPORT.md`：human-readable 摘要報告（god nodes、surprising connections、社群結構）
- 其他可能輸出：`graph.html`、`graph.svg`、`obsidian/` 等視覺化或匯出產物

`graphify-out/graph.json` 存在 ＝ codemap 可用。

## 允許的 graphify 子指令（白名單）

只有以下三個唯讀子指令被允許在 point 階段執行：

```bash
graphify query "<question>"      # BFS 廣度查詢，回傳廣域 context
graphify query "<question>" --dfs --budget 1500   # DFS 走特定路徑
graphify path "ModuleA" "ModuleB"                 # 兩節點間最短路徑
graphify explain "EntityName"                     # 單一節點的鄰居與摘要
```

範例呼叫：

- 評估 Impact Radius：`graphify query "modules that import auth/session"`
- 評估 Contract/Schema：`graphify path "UserController" "UserSchema"`
- 評估 Regression Risk：`graphify explain "PaymentGateway"`（看 fan-in / fan-out）

## 禁止的 graphify 子指令（黑名單）

**絕對不得**執行以下任何一個——它們會寫入磁碟、修改使用者環境或重建圖譜：

- `graphify install`、`graphify install --platform <os>`
- `graphify clone <url>`
- `graphify add <url>`、`graphify add <url> --author/--contributor`
- `graphify <path>`（不帶子指令的呼叫 = 重新建圖）
- `graphify <path> --update` / `--cluster-only` / `--mode deep` / `--directed` / `--watch`
- `graphify extract <path>`
- `graphify merge-graphs ...`
- `graphify export <format>`、`graphify benchmark`
- `graphify hook install/uninstall`、`graphify claude install/uninstall`
- `graphify save-result ...`（會把 Q&A 寫回圖譜）
- 任何帶 `--neo4j-push`、`--obsidian-dir <path>`、`--wiki`、`--svg`、`--graphml` 旗標的呼叫

判斷原則：**只讀不寫**。若指令名稱不在白名單，預設禁止。

## 何時使用 codemap，何時跳過

| 狀態 | 行動 |
| --- | --- |
| `graphify-out/graph.json` 存在 + `command -v graphify` 成功 | 使用 graphify query/path/explain 蒐證 |
| `graphify-out/graph.json` 存在但 `command -v graphify` 失敗 | 優雅降級：Read `graphify-out/GRAPH_REPORT.md` 與 `graph.json` 當純文字 |
| `graphify-out/` 不存在 | 跳過此步驟，**不要**自動執行 `/codemap` 或建議使用者跑 |
| codemap 過期（stale，見下方） | 仍可使用，但 **必須**在 report 中標註過期 |

## 偵測 codemap 是否過期（stale）

比對 `graphify-out/graph.json` 的修改時間 vs. 最後一次 git commit 時間：

```bash
GRAPH_MTIME=$(stat -f %m graphify-out/graph.json 2>/dev/null || stat -c %Y graphify-out/graph.json)
LAST_COMMIT_TS=$(git log -1 --format=%ct)
if [ "$GRAPH_MTIME" -lt "$LAST_COMMIT_TS" ]; then
  echo "codemap is stale"
fi
```

若 graph.json 比最後一次 commit 還舊 → 視為 stale。
仍然可以使用，但在 `Codemap consulted` 欄位標記：
`yes (stale, generated <相對時間，例如 3 commits ago>)`。
評分仍須謹慎——stale codemap 可能漏掉新增的 cross-module fan-out。

## 評分使用上的硬性限制

1. **codemap 只能微調 ±1**：對 Impact Radius / Contract-Schema / Regression Risk 任一維度，
   依 codemap 線索最多上調 1 分或下調 1 分。
2. **codemap 不得單獨翻轉 route**：rubric 閾值表（0-4 Trivial、5-7 Direct、8-14 Verify、15+ Spec）
   與 override rules 仍是唯一的 route 判定依據。若 codemap 把分數從 7 推到 8，
   route 升為 Build With Verify 是因為**閾值**而非 codemap；
   但若 codemap 想把分數從 4 一路推到 8（跨閾值多階），則禁止——
   單一 codemap 觀察的影響面 cap 在 ±1，要跨閾值必須其他維度也獨立 cross。
3. **codemap 線索必須在 `Why` 欄位記錄**：例如
   「Impact +1：graphify query 顯示 AuthSession 被 12 個模組引用」，
   讓人類審查者能溯源。
4. **codemap 不能替代知識庫**：業務規則、權限、計費等 Domain Rule Complexity 與
   Knowledge Dependency 維度，仍以 `.athena/knowledge/` 為主，codemap 只反映程式碼結構。

## 為什麼這些限制存在

- **Scoring stability**：同一份需求在 codemap 缺/有 兩種狀態下不應被打到不同 route，
  否則使用者跑 `/codemap` 與否會影響流程走向，造成評分不可預期。
- **Tool boundary**：point 階段原則上是「讀 + 評」，不允許實際改動使用者環境。
  白名單機制把 Bash 開放範圍鎖在 graphify 唯讀子指令。
- **Codemap 過期風險**：graphify 不會自動知道 codebase 有變動。
  若 graph.json 是兩個月前產的，盲目相信會誤導評分；必須明確標註。
- **graceful degrade**：使用者可能只裝過一次、後來移除 graphify CLI 但 `graphify-out/` 還在；
  此時改成「被動 Read」是最安全的 fallback。
