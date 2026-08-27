# Agent 干預協議（Intervention Protocol）

## 讀取時機

**想中止一個進行中的 agent、判定某 agent 失效、或重新 spawn 同一 stage / phase 之前必讀。**
本協議規範的是 orchestrator **主動介入另一個 agent**——不是 agent 自己的收尾。

**與 gate FAIL retry 是兩條路徑，不可混用**：agent 自己收尾、寫了 mini-handoff、gate 判
FAIL → 那是正常結束，走 `phase-orchestration.md`「Phase Retry」（最多 2 輪），本檔不適用。

一句動機：orchestrator 對其他 agent 的狀態結構上只有二手資訊——**二手回報只是線索，
artifact 與 git 才是唯一權威**。

## 觸發條件（做這些動作之前必須先查證）

以下**任一**動作被本協議擋住：

1. 中止一個進行中的 agent
2. 判定某 agent 已失敗 / 已卡死 / 已放棄
3. 重新 spawn 同一個 stage 或 phase（等同宣告前一個無效）
4. 把某個 phase 從平行集移除、或改變既定路由
5. 依「某 agent 的狀態」向使用者做出結論性回報

觸發來源是任何**非該 agent 自己產出的 artifact** 的資訊：使用者轉述、其他 agent
的回報、orchestrator 自己的推測、逾時感覺。

## 查證階梯（依序執行，任一層取得確定結論即停止）

| 層 | 手段 | 判定 |
|----|------|------|
| 1 | **artifact 存在性**：Read / Glob 主樹 `handoffs/<slug>-<stage>.md` 或 `handoffs/<slug>-build-phase-<NN>.md` | 存在且有 `## Gate Verdict` → 該 agent **已收尾**，狀態以此為準（不必再往下查） |
| 2 | **git 事實**：`git branch --list`、`git log --oneline <branch>`。**分支名要先確定再查**：手動協議下是 flow 自己命名的 `athena/phase/<slug>-<NN>`；原生 `isolation: "worktree"` 模式下**分支名由 harness 決定、flow 並不知道**，只掃 `'athena/phase/<slug>-*'` 是**保證掃不到**的假否定（`worktree-isolation.md`「Pre-Flight 健檢」同一理由），須改以該 phase mini-handoff 回報的 `Worktree Branch:`、或 `git worktree list` 的輸出交叉比對 | 分支存在且有 commit → 產出已落地（分支永遠承載最新狀態）。**分支名確定不了**時這一層記「取不到 + 原因：原生模式分支名未知」並往下一層，**不得**把假否定當成「沒有產出」 |
| 3 | **harness 的 task 查詢工具**（若當前 session 可用，例如 `TaskList` / `TaskOutput` 一類） | 回報 running / done / failed → 以此為準。**可用即用，不是硬依賴**——不可用就當這一層不存在，不得因此停擺 |

**查證是一次性的 point-in-time 查詢**（Read / Glob / 唯讀 git / 單次 task 查詢）。
**不得**輪詢、不得寫等待迴圈、不得「重複查到有結果為止」、不得設時間門檻——
查不到就走下面的出口（與非協商規則「flow agent 不輪詢」同向）。

## 查不到時的出口（非協商）

「查不到確定結論」= 第 3 層工具在本 session 不可用；各層結論互相矛盾（例：無 handoff
但分支有 commit）；只能取得「不確定」（例：分支存在但無 commit）。

→ **不得**中止、**不得**判定失效、**不得**重新 spawn。改為**問使用者**——回報
「我無法查證 `<具體對象>` 的狀態；我查了 `<已執行的層>`，結果 `<實際輸出>`；
請確認要不要中止／重啟」，然後**停在該分支動作上**（其餘不受影響的 phase 照常繼續）。

## C-1 orchestrator 不得自行中止（無條件）

主動中止一律需要使用者拍板——保全狀況只決定「交給使用者什麼證據」，**不決定「誰有權決定」**。
適用於任何主動終結動作：中止、放棄、以「重新來一次」取代它、把它排除在平行集之外。
不適用：agent **自己**收尾（正常結束或 gate FAIL）不是中止，走既有 retry 路徑。

## C-2 中止前必須嘗試保全，並記錄「實際取到什麼」

向使用者提出中止請求**之前**，依序嘗試並記錄**實際結果**（不是「我以為應該有」）：

| # | 手段 | 指令 / 動作 | 可用性 |
|---|------|-------------|--------|
| 1 | 主樹 artifact | Read / Glob `handoffs/<slug>-build-phase-<NN>.md` | 一律可用（artifact 走主樹絕對路徑） |
| 2 | 分支 commit | `git branch --list`、`git log --oneline <branch>`——分支名的取得同查證階梯第 2 層（手動協議用 `athena/phase/<slug>-<NN>`；原生模式分支名由 harness 決定，**不得只掃 `'athena/phase/<slug>-*'`**，改用 mini-handoff 的 `Worktree Branch:` 或 `git worktree list`） | 一律可用（分支主樹可見）；分支名取不到時記「取不到 + 原因：原生模式分支名未知」 |
| 3 | **worktree 路徑發現** | `git worktree list` | 一律可**嘗試**。手動協議下路徑本來就已知；原生 `isolation: "worktree"` 模式下**若** harness 的 worktree 註冊在本 repo 的 git dir，此指令就會列出它 |
| 4 | worktree 工作區快照 | 對手段 3 取得的路徑執行 `git -C <path> status --porcelain` 與 `git -C <path> diff` | 僅在手段 3 取得路徑時可用；`git -C …` 的前綴可能不在預先核准清單內而觸發權限詢問——被擋就記「取不到 + 原因：工具邊界」 |

**保全是「讀取並記錄」，不是 commit**——四項手段全部唯讀（責任歸屬見 C-6）。
記錄內容必須是實際值，三種之一：**取到了什麼**（handoff 路徑 / commit hash 與 message /
status 與 diff 摘要）；**「取不到」＋原因**（**不得留空、不得寫「不確定」**）；
**部分取到**（逐手段標明哪一項成功、哪一項失敗）。

## C-3 產出可保全時的時序

```
依查證階梯確認實際狀態
  → 依 C-2 保全並記錄取到的內容
  → 帶保全結果請使用者確認是否中止
  → 使用者同意 → 中止
  → 掛回既有分支續作（不重做，見 C-7）
```

## C-4 取不到產出時：**無法保全 ≠ 禁止中止**

取不到任何產出（零 commit、`git worktree list` 沒列出、工具邊界被擋）時，**不得**因此
禁止中止，也**不得**因此自行中止。必須把**完整狀態**交給使用者，至少三項：

| # | 必須交出 | 內容要求 |
|---|---------|---------|
| 1 | **已知產出** | 有什麼、在哪（路徑 / 分支 / commit）；或明確寫「取不到，原因是 `<X>`」——不得留空、不得寫「不確定」 |
| 2 | **該 agent 的實際狀態** | **必須是依上述查證階梯查證過的結果，並註明是哪一層取得的（artifact / git / harness 工具）。不得二手轉述。** 寫不出「這個結論是從哪一層查到的」就等於沒查證 → 走上面的出口，回報「我無法查證」，**不得**猜一個狀態填進中止請求裡 |
| 3 | **為什麼想中止它** | 具體理由（例：「它宣告要改的檔案與 phase 07 重疊」／「已無新 commit 且無 handoff，我判斷它卡住了」），不得只寫「卡住了」 |

使用者拍板後 orchestrator 才動作：**說停就停，說留就留**。

## C-5 保全紀錄的去處

**不寫成 handoff、不新增檔案**——它是交給使用者那則回報的一段內容，順序固定為
**白話摘要 → 保全紀錄 → 機械欄位**（見 flow `SKILL.md`「必要輸出」）。
每次觸發計一次 `human_interventions`（`run-trace.md` run 層**既有**欄位，照既有語意
計數）；**不改** run-trace 的 schema、不新增欄位。

## C-6 責任歸屬：orchestrator 永不對 agent 的分支 commit

| 情境 | 誰 commit |
|------|-----------|
| agent 自己收尾（gate PASS 或 FAIL） | **phase agent**（PASS 正常格式 / FAIL `wip:` 前綴），見 `worktree-isolation.md`「收尾義務」——**不變** |
| orchestrator 保全（C-2） | **沒有人 commit** — 四項手段皆唯讀查詢，產物是「紀錄」 |
| 使用者同意中止之後 | **沒有人代為 commit** |

**本協議不新增任何「orchestrator 代替 agent commit」的路徑**——不存在第二套與收尾義務
競爭同一分支 commit 語意的機制。

## C-7 中止之後一律接續，不重做

- 掛回**既有分支**：`git worktree add .athena/worktrees/<slug>-<NN>-retry <既有分支>`
  ——分支已存在，**不帶 `-b`**（沿用 `phase-orchestration.md`「Phase Retry」的續作協議，不新增機制）
- 接續 agent 的 prompt **必須**指明：「分支上已有的 commit 代表**已完成**的工作，
  從該狀態往下做，**不重做**」
- **分支保留**：中止不觸發任何分支刪除（與「絕不自動刪未 merge 的分支」同向）

## C-8 沒有使用者可問時（`ci` / `cron` / `inbox`）

human gate 不得因此退化成「那就自己決定」，也不得死鎖：

- **不中止**該 agent（保持現狀，不銷毀任何東西）
- **停止**該 run，並把 C-4 的三項完整狀態寫進最終回報
- run 的 `outcome` 用**既有值** `handed-to-human`，handoff 依既有 Retention Policy
  **保留**（未解 → 保留，供 resume 與 Loop 3）；使用者稍後可據此 resume 並拍板

全部沿用既有機制：**不新增** outcome 值、trigger 值、欄位或檔案。
