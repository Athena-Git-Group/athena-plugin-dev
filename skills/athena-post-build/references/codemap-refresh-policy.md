# Codemap Auto-Refresh Policy

`athena-post-build` 在每次成功 commit 之後，會 best-effort 執行一次
`graphify <repo-root> --update`，讓下一輪 `/athena-point` 評分時拿到的
`graphify-out/` 永遠新鮮。本文件規範這個 refresh 的觸發、跳過、失敗、與雙路徑一致性。

> 對應 read-side（point 階段如何「消費」codemap、白名單 / 黑名單子指令）
> 請見 `../../athena-point/references/codemap-guidelines.md`。
> 這份文件只談 **write-side**：`--update` 在哪裡跑、在什麼條件下跑、跑壞了怎麼辦。

## 何時刷新（三道 guard 全成立才執行）

1. **`graphify-out/graph.json` 存在於 repo root**
   - 表示使用者曾經跑過 `/codemap`，已經 opt-in。
   - 若不存在 → 完全不刷新（也不自動初始化），保持與 `/athena-point` 一致的「沒裝就跳過」哲學。

2. **`command -v graphify` 成功**
   - 表示 graphify CLI 還在 PATH。
   - 使用者可能裝過後再移除，但 `graphify-out/` 還留著（被 git track 或單純沒刪）。
     此時 read-side 會優雅降級成「把 `GRAPH_REPORT.md` 當純文字讀」，
     write-side 則直接跳過（沒 CLI 就沒法 update）。

3. **`git check-ignore graphify-out/` 退出 0**
   - 表示 `graphify-out/` 已在 `.gitignore` 內。`--update` 會寫盤到該目錄，
     若沒被 ignore，post-build 之後 `git status` 會出現 untracked / modified 變更，
     干擾 verify / ship 階段的乾淨 working tree 假設。
   - 未被 ignore → silent skip + 在 flow context 留下
     `codemap_refresh: skipped (graphify-out tracked)`，由 plugin maintainer 或
     consumer repo 自行決定要不要把 `graphify-out/` 加入 `.gitignore`。

額外實作守門：

4. **`command -v timeout` 成功**
   - 沒有 `timeout`（部分 macOS 未裝 GNU coreutils）就跳過，
     避免 `graphify --update` hang 把 flow 卡死。
   - 記錄 `codemap_refresh: skipped (no timeout binary)`。

## 何時跳過（明確記錄原因，不靜默吞掉）

| Guard 失敗 | flow context 記錄 | log 訊息（stderr） |
| --- | --- | --- |
| `graphify-out/graph.json` 不存在 | `codemap_refresh: skipped (no graphify-out)` | `codemap_refresh: skipped (no graphify-out)` |
| `command -v graphify` 失敗 | `codemap_refresh: skipped (cli missing)` | `codemap_refresh: skipped (cli missing)` |
| `graphify-out/` 未被 .gitignore | `codemap_refresh: skipped (graphify-out tracked)` | `codemap_refresh: skipped (graphify-out tracked)` |
| `timeout` 不可用 | `codemap_refresh: skipped (no timeout binary)` | `codemap_refresh: skipped (no timeout binary)` |

> 所有 skip 都是 silent skip——只寫 flow context 與 stderr log，
> **不**提示使用者、**不**詢問、**不**自動補裝。
> `/codemap` 是使用者一次性 opt-in；post-build 只在 opt-in 還有效時順手刷新。

## 失敗處理（best-effort，永不阻斷）

`timeout 90 graphify "<repo-root>" --update` 的所有失敗模式都一律當成「跳過」處理：

| Exit code 範圍 | 視為 | flow context 記錄 |
| --- | --- | --- |
| 0 | 成功 | `codemap_refresh: done` |
| 1-123, 125-255 | 一般失敗（CLI bug、IO error、LLM backend 不可達） | `codemap_refresh: failed (exit=<code>)` |
| 124 | timeout kill（GNU `timeout` 約定退出碼） | `codemap_refresh: failed (exit=124)` |
| 137 | SIGKILL（OOM kill 或外部 9 號訊號） | `codemap_refresh: failed (exit=137)` |

非 0 結果**絕對不**:

- 不 raise / propagate exit code 給呼叫端
- 不轉成 flow 階段失敗
- 不寫死在 handoff 的 Gate Verdict
- 不發 Notification、不開 issue、不要求使用者修

唯一動作就是：寫 flow context（或在 hook 模式下寫 stderr log）、繼續流程。

## 為何刷新放在 post-build 而非 point 階段

| 替代位置 | 為何不選 |
| --- | --- |
| `/athena-point` 階段 | point 應該是**唯讀** + **冪等**：同一份輸入，跑幾次都得一樣的 verdict。`--update` 會寫盤，破壞冪等性。也違反 `codemap-guidelines.md` 的「白名單只允許 query/path/explain」。 |
| `pre-build` 階段 | pre-build 在分支建立之前跑；codebase 還沒改動，refresh 也只會看到舊狀態，意義小。 |
| `verify` 階段 | verify 是另開 fresh subagent，加入 graphify 呼叫會把 verify skill 的工具邊界擴大；而且 verify 還沒進到 commit，刷新後若 verify 本身又改了檔，graph 又過期。 |
| `ship` 階段 | 太晚——下次 `/athena-point` 在新的 flow 開始就會跑，需要刷新的時間點是 commit 落地的那一刻。 |
| **post-build（採用）** | 與 commit 同層語意：commit 改變了 codebase 的「穩態快照」，這是 graph 該更新的時機點。amortize 成本到 commit 自然節點，使用者感受不到額外延遲。 |

## 雙路徑一致性（SKILL.md vs `hooks/auto-commit.sh`）

athena-post-build 有兩條等價執行路徑：

- **Inline mode**（marker 為 `mode: inline` 或無 marker）：flow agent 內聯執行
  `skills/athena-post-build/SKILL.md` 的 step 1-9。
- **Hook mode**（marker 為 `mode: hook`）：harness SubagentStop event 觸發
  `hooks/auto-commit.sh`，由該 hook 完成 commit。

兩條路徑必須對 codemap refresh 行為**完全對稱**：相同 guards、相同 timeout、
相同 skip 訊息、相同 best-effort 語意。差別只在「結果寫到哪」：

| 路徑 | refresh 結果寫到 |
| --- | --- |
| Inline mode | flow context（`git_context.commits[].codemap_refresh`） |
| Hook mode | stderr log（flow agent 看不到 hook 內部狀態，只能靠 log；marker 已被 hook `rm` 消費） |

> 兩條路徑互斥（marker 在 spawn subagent 前就決定走哪條），所以不會雙重 refresh。

若未來 marker schema 擴充成支援「hook 寫回結果欄位」，hook 也可以把
`codemap_refresh` 寫回去；但目前 v1 marker 只支援 read-only 消費後 `rm`，
所以 hook mode 的 refresh 結果僅存在於 stderr。

## Debounce note

Full Weight 路線下，一輪 flow 可能觸發 N 個 phase commit + verify commit +
verify-fix commit，每個都會跑一次 `--update`。當前**不做** debounce：

- graphify `--update` 是 incremental（只重新分析變動檔），單次成本通常數秒。
- N 次 incremental 仍遠低於一次 full rebuild，且能讓中途的 phase-NN 評分用到
  該 phase 的最新 graph。
- 90s timeout 是個別保險，不會把 N 個 phase 串成 N × 90s 的 worst case 累積。

若未來實測發現累積成本顯著，可考慮在 flow context 加 `codemap_refresh_last_ts`，
同一輪 flow 內距離上次 refresh < 30s 就跳過。此優化目前 **不**實作，
留給後續觀察 telemetry 後再決定。

## 不該做的事（負向 spec）

無論在 SKILL.md 還是 `auto-commit.sh`，以下行為都被禁止：

1. **不得自動安裝 graphify**：CLI 缺席就跳過，**不**跑 `uv tool install graphifyy`
   或任何套件安裝。系統層級變更需走 `/codemap` Phase A 取得使用者同意。
2. **不得自動跑 `/codemap` 初始化**：`graphify-out/` 缺席表示使用者沒 opt-in，
   不要替使用者決定要不要建 graph（建一次很貴、會佔磁碟、可能呼叫付費 LLM）。
3. **不得跑 force update**：禁止「不帶 `--update`」的 `graphify <path>`——那是重建模式，
   會把現有 graph.json 整個覆寫。本 policy 只允許 incremental `--update`。
4. **不得跑任何其他寫盤 flag 組合**：禁用 `--cluster-only`、`--watch`、`--neo4j-push`、
   `--obsidian-dir`、`--wiki`、`--svg`、`--graphml`、`--mode deep`、`--directed`、
   `save-result`、`extract`、`merge-graphs`、`hook install` 等。
   白名單只有：`timeout 90 graphify "<repo-root>" --update`。
5. **不得讓 refresh 失敗影響 commit**：commit 永遠先於 refresh；refresh 是事後動作。
   commit 失敗就走 commit 的失敗處理，與 refresh 無關。
6. **不得阻塞 flow**：90s timeout 是硬上限。timeout 觸發即視為失敗、繼續流程，
   不得 retry、不得加長 timeout、不得提示使用者「要不要等更久」。
