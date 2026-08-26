# Phase Orchestration

## 適用條件

Phase loop **僅在 Full Weight 流程中執行**（`PASS-SPEC-FIRST`）。

若路由為 `PASS-DIRECT-BUILD` 或 `PASS-BUILD-WITH-VERIFY`：
- **不進入 phase loop** — 沒有 `plan.md`，沒有 Dependency Graph
- Build 以 Lightweight 模式執行（見 `stage-contracts.md`「build（Lightweight）」段落）
- 本文件的所有規則不適用於 Lightweight 模式

---

## 概述

Build stage 不再是單一 agent 執行的 opaque stage。
Flow 讀取 `plans/<slug>/plan.md` 的 Dependency Graph，將 **implementation phases**（通常 Phase 05-07）拆解為獨立的 sub-stage，逐一（或平行）調度。

每個 phase 獲得與 standard stage 相同等級的：
- **Agent 隔離** — fresh agent
- **Handoff** — mini-handoff artifact
- **Gate** — smoke test 驗證
- **Commit** — per-phase git commit

## Phase 與 Stage 的關係

```
Standard Stage（spec, plan, build, verify, review, ship）
    └── Build Stage
         └── Phase Loop（由 flow 驅動）
              ├── Phase 05: Backend TDD
              ├── Phase 06: Frontend Build
              └── Phase 07: Integration
```

- **Stage** = flow 的一級調度單位（fresh agent + handoff artifact）
- **Phase** = Build 內的二級調度單位（fresh agent + mini-handoff）
- Phase 的定義來自 `plan.md` 的 YAML frontmatter，不是 flow 硬編碼
- Flow 只認 phase 卡位於 `plans/<slug>/todo/` 的 implementation phase（位置即狀態）

## 解析 Dependency Graph

Flow 讀取 `plans/<slug>/plan.md` 的 **YAML frontmatter** 作為 Dependency Graph 的**唯一機械真相**。Schema 固定如下：

```yaml
---
plan: <slug>
phases:
  - id: "01"
    name: Strategic
    depends_on: []
  - id: "06"
    name: Frontend Build
    depends_on: ["04"]
  - id: "08"
    name: Integration
    depends_on: ["05", "07"]
status_source: folders
---
```

- `id` 為兩位數字字串；`depends_on` 只准引用存在的 `id`
- `status_source: folders` 表示 **`todo/` / `doing/` / `done/` 資料夾位置是 phase 狀態的唯一真相**——plan.md 內的任何狀態欄位只是人類視圖
- plan.md 正文中的 markdown 表格（若有）**僅為人類視圖**；與 frontmatter 衝突時，**以 frontmatter 為準**

**識別規則：**
1. 卡片在 `done/` 的 phase 跳過（已完成，含 spec/plan 階段完成的外部品質 phase）
2. 卡片在 `doing/` 的 phase 視為被占用，不重複調度
3. 卡片在 `todo/` 的 phase 進入 phase loop
4. 依照 frontmatter 的 `depends_on` 建立執行順序

## Phase Loop 執行流程

```
Flow 讀 plan.md frontmatter → 掃描 todo/doing/done/ → 建立依賴圖
    │
    ├── 順序執行（預設）
    │   for each phase in dependency order:
    │     1. mv plans/<slug>/todo/<NN>-<name>.md → plans/<slug>/doing/（即鎖，spawn 前執行）
    │     2. 開 fresh agent
    │     3. 載入 build skill + phase card（doing/ 中的卡）
    │     4. Agent 讀取前一個 phase 的 mini-handoff（若有）
    │     5. Agent 讀取指定的 spec sections（由 phase card 標明）
    │     6. Agent 執行實作
    │     7. Agent 執行 smoke test（phase card 中定義的指令）
    │     8. Agent 寫 mini-handoff（含 smoke test 結果）
    │     9. Flow 讀 mini-handoff → 檢查 Gate Verdict
    │     10. PASS → post-build commit（per-phase）→ mv doing/<NN>-<name>.md → done/ → 繼續
    │     11. FAIL → 停止 phase loop → 進入 phase retry（卡片留在 doing/）
    │
    └── 平行執行（當依賴允許時）
        見「平行 Phase 執行」段落
```

**Phase 卡狀態語意（位置即狀態、mv 即鎖）：**
- spawn phase agent **前**，flow 先 `mv todo/<NN>-*.md → doing/`
- gate PASS 後，flow `mv doing/<NN>-*.md → done/`
- 平行 spawn 前，先把該平行集合的**所有**卡片 mv 到 `doing/`（即鎖），再送出 agents

## Phase Agent 的載入內容

每個 phase agent 被啟動時，flow 指示它讀取以下資料：

| 資料 | 路徑 | 說明 |
|------|------|------|
| Build skill | `.athena/skills/<build-skill>/SKILL.md` | 團隊的 build skill（同一份，每個 phase 都讀） |
| Phase card | `plans/<slug>/doing/<NN>-<name>.md` | 該 phase 的具體任務卡片（flow 已在 spawn 前從 `todo/` mv 過來） |
| 前一個 phase 的 mini-handoff | `handoffs/<slug>-build-phase-<prev-NN>.md` | 知道上一個 phase 做了什麼（首個 phase 無此項） |
| Spec（指定 section） | 由 phase card 的 `spec_sections` 欄位指定 | 只讀需要的 section，不全讀 |
| Plan handoff | `handoffs/<slug>-plan.md` | 整體計畫的概覽（只讀一次，不用每個 phase 都讀） |

### Agent Prompt 模板

```
你正在執行 Phase <NN>: <Phase Name>。

開工第一步：執行 `date -u +%Y-%m-%dT%H:%M:%SZ`，記下作為 Started At。

讀取以下資料：
1. .athena/skills/<build-skill>/SKILL.md（你的 build skill）
2. plans/<slug>/doing/<NN>-<name>.md（你的任務卡片）
3. handoffs/<slug>-build-phase-<prev-NN>.md（上一個 phase 的交接）
4. spec 的 Section <X>, <Y>（phase card 中 spec_sections 指定的）

你的 touches 邊界（來自 plan.md frontmatter 此 phase 的 touches 宣告）：
- files: <該 phase 的 touches.files glob 清單>
- resources: <該 phase 的 touches.resources 清單>

只准改宣告範圍內的檔案；若實作中發現必須碰宣告外的檔案，
停下來在 mini-handoff 記 gate FAIL + 原因 `#plan-gap`，不得逕自修改。

完成實作後：
1. 執行 smoke test：<phase card 中的 smoke_test 指令>
2. 再執行一次 `date -u +%Y-%m-%dT%H:%M:%SZ` 取得 Ended At
3. 寫 mini-handoff 到 handoffs/<slug>-build-phase-<NN>.md，
   含選填的 `## Timing` 區塊（Started At / Ended At，格式見 agent-handoff.md）

（worktree 隔離模式時，flow 額外注入以下段落）

主樹絕對路徑：<main-repo-root>
Main Tree Branch: <flow 自己的 branch_name>
Expected Branch: <僅手動 worktree 協議時注入——flow 用 -b 建的分支名>

開工第二步（Pre-Flight 三項健檢，在 Edit 任何程式碼之前先做完並自報實測值）：
1. 跑 `git branch --show-current`：輸出必須**非空**，且 ≠ 上面的 Main Tree Branch；
   上面有 Expected Branch 時，必須**等於**它。空輸出（detached HEAD）算不通過
2. 跑 `pwd`：輸出必須 ≠ 上面的主樹絕對路徑（確認你不在主樹）
3. Read 兩類路徑各一項：(a) 主樹 artifact——`<main-repo-root>/plans/<slug>/doing/<NN>-<name>.md`
   （上列任務卡片，加主樹絕對路徑前綴，見下方雙路徑規則）可讀；(b) worktree code——
   上列 touches.files 中已存在於基線的任一檔案（你 cwd 的相對路徑）可讀。
   本 phase 全為新建檔案時，此項記 `n/a (all-new)` 即算通過

三項都通過 → 在 mini-handoff 加一行（選填自報，不列入 gate 判定），然後照上面開工：
Pre-Flight: OK (branch=<實測>, cwd=<實測>, targets=<ok|n/a (all-new)>)

任一項不通過 → **立即停止**：不 Edit、不 Write、不 commit、**不寫 mini-handoff**，
以 final response 回下列固定格式（多項不符每項一行）後結束：
PRE-FLIGHT MISMATCH — <branch|cwd|target-file>: expected <X>, actual <Y>
不要自己修復（不要 `git checkout`、不要換目錄）——修復是 flow 的決策，你只回報。

你在獨立的 git worktree 中工作，雙路徑規則：
- code 讀寫 → 用你 cwd（worktree）的相對路徑
- artifact 讀寫 → 上列任務卡片、handoff、spec、mini-handoff 一律改用
  <main-repo-root>/ 前綴的主樹絕對路徑
收尾時無論 gate 結果都 commit 到你的 worktree 分支
（PASS 用 git-conventions 正常格式；FAIL 用 `wip:` 前綴），
並在 mini-handoff（寫到 <main-repo-root>/handoffs/…）回報
`Worktree Branch:`（值 = `git branch --show-current` 實測）。
```

> Timing 是**選填**欄位——agent 漏記不算 gate 失敗，emit-trace 缺就略。

## Smoke Test Gate

Phase agent 在實作完成後、寫 mini-handoff 之前，執行 phase card 中定義的 `smoke_test` 指令。

- Smoke test 由 **phase agent 自己執行**，不另開 agent
- 結果寫入 mini-handoff 的 `Smoke Test Result` 欄位
- Flow 讀取 mini-handoff 的 `Gate Verdict` 欄位決定是否繼續

### Phase Card 格式（擴充）

```markdown
## Phase 05: Backend TDD Track

- **Depends On:** 04
- **Spec Sections:** 1, 3, 4
- **Smoke Test:** `cargo test && cargo clippy`
- **Skill:** my-team-build-backend（可選，若省略則使用 stage-level build skill）
```

### Gate 判定

| Smoke Test 結果 | Gate Verdict | Flow 動作 |
|-----------------|-------------|-----------|
| 全部通過 | PASS | post-build commit → 繼續下一個 phase |
| 有失敗 | FAIL | 停止 phase loop → 進入 phase retry |
| 無 smoke test 定義 | PASS（預設） | 繼續（信任 agent 的自我判斷） |

## Phase Retry（單一 Phase 失敗時）

Phase loop 中某個 phase gate FAIL 時：

```
Phase <NN> gate FAIL
    ↓
Flow 讀取該 phase 的 mini-handoff → 取得失敗原因
    ↓
開 fresh agent（repair mode）：
  - 載入 build skill + phase card + 失敗的 mini-handoff
  - Agent 讀取失敗原因並修復
  - Agent 重跑 smoke test
  - Agent 更新 mini-handoff
    ↓
Flow 再次檢查 Gate Verdict
  - PASS → post-build commit → 繼續下一個 phase
  - FAIL → 再 retry 一次（最多 2 輪）
  - 超過 2 輪 → 停止流程，交給使用者
```

**Worktree 模式的 retry**：repair agent 用手動 worktree 協議掛回**既有分支**續作——
`git worktree add .athena/worktrees/<slug>-<NN>-retry <Worktree Branch>`（分支已存在，
**不帶 `-b`**）。prompt 同樣注入主樹絕對路徑（雙路徑規則不變），repair agent 修復、
commit（PASS 正常格式 / 仍 FAIL 用 `wip:` 前綴）、重跑 gate、更新主樹的 mini-handoff；
flow 收尾 `git worktree remove` + `git worktree prune`。輪數上限沿用 2 輪；
**latest gate = FAIL 的分支絕不 merge**。

> **續作 spawn 的開工義務（與下文「Worktree 隔離」段扣合）**：repair agent 也在 worktree
> 內，所以 prompt 除主樹絕對路徑外**必須**一併注入 `Main Tree Branch:`（flow 自己的分支）
> 與 `Expected Branch:`（= 上面掛回的那個既有分支——flow 自己指定的，必然已知）。
> pre-flight 三項健檢、以及不符時「不得更新既有 mini-handoff、只回 `PRE-FLIGHT MISMATCH`」
> 的處置，見下文「Worktree 隔離」段的開工義務（其適用範圍已明文涵蓋續作 spawn）。
> 這條同樣適用於 verify-fix 的 per-phase 修復 agent。

## Agent 干預協議

**Agent 干預協議**規範的是 **orchestrator 主動介入另一個 agent**（中止、判定失效、
重新 spawn）——不是 agent 自己的收尾。

> **與 gate FAIL retry 是兩條不同路徑，不可混用。** 上一節的 Phase Retry 處理的是
> 「agent 自己收尾、寫了 mini-handoff、gate 判 FAIL」——那是 agent 的正常結束，
> 走 retry（最多 2 輪），本小節完全不適用。本小節處理的是「orchestrator 想從外部
> 終結或重來一個還在跑的 agent」。

### 為什麼需要這一節

orchestrator 對其他 agent 的狀態，結構上**只能拿到二手資訊**：使用者的轉述、
另一個 agent 的回報、或自己從時間推測。這些都可能是錯的——回報者看到的是自己
那一格的視野。**二手回報只是線索，artifact 與 git 才是唯一權威。**

### 觸發條件（做這些動作之前必須先查證）

以下**任一**動作被本協議擋住：

1. 中止一個進行中的 agent
2. 判定某 agent 已失敗 / 已卡死 / 已放棄
3. 重新 spawn 同一個 stage 或 phase（等同宣告前一個無效）
4. 把某個 phase 從平行集移除、或改變既定路由
5. 依「某 agent 的狀態」向使用者做出結論性回報

觸發來源是任何**非該 agent 自己產出的 artifact** 的資訊：使用者轉述、其他 agent
的回報、orchestrator 自己的推測、逾時感覺。

### 查證階梯（依序執行，任一層取得確定結論即停止）

| 層 | 手段 | 判定 |
|----|------|------|
| 1 | **artifact 存在性**：Read / Glob 主樹 `handoffs/<slug>-<stage>.md` 或 `handoffs/<slug>-build-phase-<NN>.md` | 存在且有 `## Gate Verdict` → 該 agent **已收尾**，狀態以此為準（不必再往下查） |
| 2 | **git 事實**：`git branch --list 'athena/phase/<slug>-*'`、`git log --oneline <branch>` | 分支存在且有 commit → 產出已落地（分支永遠承載最新狀態） |
| 3 | **harness 的 task 查詢工具**（若當前 session 可用，例如 `TaskList` / `TaskOutput` 一類） | 回報 running / done / failed → 以此為準。**可用即用，不是硬依賴**——不可用就當這一層不存在，不得因此停擺 |

**查證是一次性的 point-in-time 查詢**（Read / Glob / 唯讀 git / 單次 task 查詢）。
**不得**輪詢、不得寫等待迴圈、不得「重複查到有結果為止」、不得設時間門檻——
查不到就走下面的出口，而不是再查一次（與非協商規則「flow agent 不輪詢」同向）。

### 查不到時的出口（非協商）

以下任一情形都算「查不到確定結論」：第 3 層工具在本 session 不可用；各層結論
互相矛盾（例：無 handoff 但分支有 commit）；只能取得「不確定」（例：分支存在但
無 commit，無法區分「還在做」與「什麼都沒做」）。

→ **不得**中止、**不得**判定失效、**不得**重新 spawn。改為**問使用者**——回報
「我無法查證 `<具體對象>` 的狀態；我查了 `<已執行的層>`，結果 `<實際輸出>`；
請確認要不要中止／重啟」，然後**停在該分支動作上**（其餘不受影響的 phase 照常繼續）。

### C-1 orchestrator 不得自行中止（無條件）

主動中止一個進行中的 agent，**一律**需要使用者拍板。這條**不因產出是否可保全而改變**——
保全狀況只決定「交給使用者什麼證據」，**不決定「誰有權決定」**。適用於任何主動終結
另一個 agent 的動作：中止、放棄、以「重新來一次」取代它、把它排除在平行集之外。

> **不適用**：agent **自己**收尾（正常結束或 gate FAIL）不是中止，走既有 retry 路徑，
> 完全不受本條影響。

### C-2 中止前必須嘗試保全，並記錄「實際取到什麼」

在向使用者提出中止請求**之前**，依序嘗試下列手段，記錄**實際結果**（不是「我以為應該有」）：

| # | 手段 | 指令 / 動作 | 可用性 |
|---|------|-------------|--------|
| 1 | 主樹 artifact | Read / Glob `handoffs/<slug>-build-phase-<NN>.md` | 一律可用（artifact 走主樹絕對路徑） |
| 2 | 分支 commit | `git branch --list 'athena/phase/<slug>-*'`、`git log --oneline <branch>` | 一律可用（分支主樹可見） |
| 3 | **worktree 路徑發現** | `git worktree list` | 一律可**嘗試**。手動協議下路徑本來就已知；原生 `isolation: "worktree"` 模式下**若** harness 的 worktree 註冊在本 repo 的 git dir，此指令就會列出它 |
| 4 | worktree 工作區快照 | 對手段 3 取得的路徑執行 `git -C <path> status --porcelain` 與 `git -C <path> diff` | 僅在手段 3 取得路徑時可用；`git -C …` 的前綴可能不在預先核准清單內而觸發權限詢問——被擋就記「取不到 + 原因：工具邊界」 |

**保全是「讀取並記錄」，不是 commit。** 上表四項手段全部唯讀，沒有任何一項產生
commit，保全的產物是**紀錄**、不進 git（責任歸屬見 C-6）。

**記錄內容必須是實際值，三種之一**：

- **取到了什麼**：handoff 路徑 / commit hash 與 message / `git status --porcelain` 與
  diff 的摘要（檔案數、行數）
- **「取不到」＋原因**：例「`git worktree list` 未列出該 agent 的 worktree，且分支
  `athena/phase/<slug>-05` 尚無 commit」、例「原因：工具邊界」——
  **不得留空、不得寫「不確定」**
- **部分取到**：逐手段標明哪一項成功、哪一項失敗

### C-3 產出可保全時的時序

```
依查證階梯確認實際狀態
  → 依 C-2 保全並記錄取到的內容
  → 帶保全結果請使用者確認是否中止
  → 使用者同意 → 中止
  → 掛回既有分支續作（不重做，見 C-7）
```

### C-4 取不到產出時：**無法保全 ≠ 禁止中止**

取不到任何產出（零 commit、`git worktree list` 沒列出、工具邊界被擋）時，
**不得**因此禁止中止，也**不得**因此自行中止。必須把**完整狀態**交給使用者，至少三項：

| # | 必須交出 | 內容要求 |
|---|---------|---------|
| 1 | **已知產出** | 有什麼、在哪（路徑 / 分支 / commit）；或明確寫「取不到，原因是 `<X>`」——不得留空、不得寫「不確定」 |
| 2 | **該 agent 的實際狀態** | **必須是依上述查證階梯查證過的結果，並註明是哪一層取得的（artifact / git / harness 工具）。不得二手轉述。** 寫不出「這個結論是從哪一層查到的」就等於沒查證 → 走上面的出口，回報「我無法查證」，**不得**猜一個狀態填進中止請求裡 |
| 3 | **為什麼想中止它** | 具體理由（例：「它宣告要改的檔案與 phase 07 重疊」／「已無新 commit 且無 handoff，我判斷它卡住了」），不得只寫「卡住了」 |

使用者拍板後 orchestrator 才動作：**說停就停，說留就留**。

### C-5 保全紀錄的去處

保全紀錄**不寫成 handoff、不新增檔案**——它是交給使用者那則回報的一段內容，
順序固定為**白話摘要 → 保全紀錄 → 機械欄位**（見 `SKILL.md`「必要輸出」）。

> 本協議每次觸發都是一次 `human_interventions`（`run-trace.md` run 層**既有**欄位），
> 照既有語意計數即可；**不改** run-trace 的 schema、不新增欄位。

### C-6 責任歸屬：orchestrator 永不對 agent 的分支 commit

| 情境 | 誰 commit |
|------|-----------|
| agent 自己收尾（gate PASS 或 FAIL） | **phase agent**（PASS 正常格式 / FAIL `wip:` 前綴），見下節收尾義務——**不變** |
| orchestrator 保全（C-2） | **沒有人 commit** — 四項手段皆唯讀查詢，產物是「紀錄」 |
| 使用者同意中止之後 | **沒有人代為 commit** |

**本協議不新增任何「orchestrator 代替 agent commit」的路徑**，因此不存在第二套與
收尾義務競爭同一分支 commit 語意的機制。

### C-7 中止之後一律接續，不重做

- 掛回**既有分支**：`git worktree add .athena/worktrees/<slug>-<NN>-retry <既有分支>`
  ——分支已存在，**不帶 `-b`**（沿用上一節的 retry 續作協議，不新增機制）
- 接續 agent 的 prompt **必須**指明：「分支上已有的 commit 代表**已完成**的工作，
  從該狀態往下做，**不重做**」
- **分支保留**：中止不觸發任何分支刪除（與「絕不自動刪未 merge 的分支」同向）

### C-8 沒有使用者可問時（`ci` / `cron` / `inbox`）

human gate 不得因此退化成「那就自己決定」，也不得死鎖：

- **不中止**該 agent（保持現狀，不銷毀任何東西）
- **停止**該 run，並把 C-4 的三項完整狀態寫進最終回報
- run 的 `outcome` 用**既有值** `handed-to-human`，因此 handoff 依既有 Retention Policy
  **保留**（未解 → 保留，供 resume 與 Loop 3）；使用者稍後可據此 resume 並拍板

全部沿用既有機制：**不新增** outcome 值、trigger 值、欄位或檔案。

## 平行 Phase 執行

Flow 分析 Dependency Graph，識別可平行的 phase。

### 判定規則

```
Phase A 和 Phase B 可平行，當且僅當：
- A 不依賴 B
- B 不依賴 A
- 兩者的所有前置依賴都已完成
```

> **事前分區保證**：可平行 pair 的 `touches` 宣告（`files` glob + `resources`）
> 互斥已由 plan 階段的 `validate_plan.py --require-touches` 機械保證——
> 這是「事前分區」。Flow 在選取平行集合時**不需**重算 touches 交集；
> 事後的 Conflict Detection（見下節）是第二道防線，不是分區依據。

### Worktree 隔離（平行集的主路徑）

Full Weight 且可平行集合大小 **≥ 2** 時，flow spawn phase agent **一律**帶 Agent 工具的
`isolation: "worktree"` 選項——harness 原生支援，每個 phase agent 得到獨立的 git
worktree（物理隔離，不再共用主 working tree），未變更的 worktree 由 harness 自動清除。
序列 phase（平行集大小 1）**不用** worktree，照現行主樹模式執行——worktree 只為平行集開。

**Pre-Flight 健檢（開工義務）**：

整條 worktree 隔離設計都建立在一個假設上：spawn 帶了 `isolation: "worktree"`，agent
就真的在一個獨立 worktree 的獨立分支上。假設破裂時**沒有任何訊號**——agent 在主樹上
改檔、在錯的分支上 commit、或讀不到被注入的路徑，三種都不報錯，只在稍後才顯現
（merge-back 找不到分支、主樹出現不該有的變更、平行 phase 互相踩到）。

**適用範圍（D-0）**：**只限 worktree 隔離模式**。判準是**這個 agent 有沒有被送進
worktree**，**不是**它是第幾次被 spawn：

| 情境 | 是否套用 | 依據 |
|------|---------|------|
| 平行集 ≥ 2 的首次 spawn（原生 `isolation: "worktree"`／手動 worktree fallback 協議） | **套用** | agent 在 worktree 內，不符時可沿 fallback 鏈退 |
| **續作 spawn**：上文「Phase Retry」的 worktree retry（`git worktree add … <既有分支>`）、verify-fix 的 per-phase 修復 | **套用** | 同樣在 worktree 內；且這是**最脆弱**的建立方式（殘留路徑衝突／`add` 失敗都會讓 agent 留在主樹） |
| 序列 phase / 主樹模式（含主樹模式下的 retry 與 verify-fix） | **不套用** | 沒有「跑錯 worktree」這個失效模式，且不符時無處可退 |

續作 spawn 的健檢**比首次 spawn 更容易判定，不存在「retry 時無法判定」的情形**：worktree
與分支都是 flow 自己用 `git worktree add … <既有分支>` 掛的，**分支名必然已知**（值 =
上一輪 mini-handoff 回報的 `Worktree Branch:`）→ 續作 prompt **必須**同時注入
`Main Tree Branch:`（flow 自己的分支）與 `Expected Branch:`（掛回的那個既有分支），
檢查 1 直接走「必須**等於** `Expected Branch`」這條加嚴路徑。

**注入義務與 agent 殼的推論扣合**：只要 agent 被送進 worktree（首次或續作），flow 就
**必須**注入比對基準；因此「沒有收到 `Main Tree Branch`」對 agent 而言仍然正確地等於
「序列／主樹模式，本節不套用」（`agents/athena-stage-build.md` 的鏡射依賴這個推論）。
漏注入是 **flow 的缺陷**，不是 agent 該自行補救的事——agent 照主樹模式執行即可。

**續作情境下不符的處置差異（唯一一處）**：續作 agent 的 mini-handoff **上一輪就已經在
磁碟上**。不符時除了「不 Edit、不 Write、不 commit」之外，**也不得更新那份既有的
mini-handoff**——原樣留著（它記的是上一輪的真實結果），只以 final response 回
`PRE-FLIGHT MISMATCH`。這樣 flow 看到的仍是「上一輪的舊 verdict + 一個新的正向訊號」，
與下方分辨表第 1 列一致。

phase agent 的**開工第二步**（緊接取 `Started At` 的 `date` 之後、**Edit 任何程式碼之前**；
措辭與上文「Agent Prompt 模板」一致）依序執行並自報：

| # | 檢查 | 指令 | 通過條件 |
|---|------|------|---------|
| 1 | **分支** | `git branch --show-current` | 輸出**非空** **且** ≠ flow 注入的 `Main Tree Branch`。flow 另注入 `Expected Branch` 時（手動協議下 flow 自己用 `-b` 命名，故知道確切名稱）→ 加嚴為**必須等於**它。空輸出（detached HEAD）視為**不通過**——merge-back 協議依賴分支名，無分支則整條路徑失效 |
| 2 | **cwd** | `pwd` | 輸出 ≠ flow 注入的 `<main-repo-root>`（確認自己不在主樹） |
| 3 | **目標檔案存在** | Read 兩類路徑各至少一項 | (a) **主樹 artifact**：注入的 phase card 絕對路徑可讀；(b) **worktree code**：phase card `touches.files` 中已存在於基線的檔案任取一項可讀。該 phase 全為新建檔案時，此項自動視為通過並在自報中註明 `n/a (all-new)` |

> **為什麼檢查 1 的通用條件是「≠ 主樹分支」而不是「= 預期分支」**：harness 原生
> `isolation: "worktree"` 模式下**分支名由 harness 決定**，flow 並不知道（flow 只是
> 不**需要**知道 worktree 的實際路徑與命名）。因此通用條件必須建立在 flow 一定知道
> 的東西上——它自己的分支（`branch_name`，已在 flow「必要輸出」的 Git context 中）。

**三項皆通過** → 在 mini-handoff 加一行自報（**選填語意，不列入 gate 判定**），
然後照現行流程開工：

```
Pre-Flight: OK (branch=<實測>, cwd=<實測>, targets=<ok|n/a (all-new)>)
```

**任一項不通過** → **立即停止**：不 Edit、不 Write、不 commit、**不寫 mini-handoff**，
以 final response 回固定格式（多項不符時每項一行，全部列出）：

```
PRE-FLIGHT MISMATCH — <branch|cwd|target-file>: expected <X>, actual <Y>
```

agent **不得自己修復**（不得自己 `git checkout`、不得換目錄）——修復是 orchestrator
的 fallback 決策，agent 只回報。

**為什麼不寫 mini-handoff（兩個機械理由，不是風格選擇）**：

1. `hooks/auto-commit.sh` 的 `[ -f "$HANDOFF" ] || exit 0`——沒有 handoff 時 hook 直接
   no-op，不可能誤 commit
2. `scripts/render_status.py` 的 loose parse 會把任何 `FAIL` 開頭的 verdict 染紅並標成
   該 phase 的 gate FAIL——那會把「隔離沒生效、work 一個字都還沒動」顯示成「這個 phase
   做壞了」，**語意誤報且不報錯，所以沒人會發現**

因此 final response 裡的 `PRE-FLIGHT MISMATCH` 這一行**本身**就是 flow 可機械分辨的
**正向**訊號——不需要（也不可以）靠「mini-handoff 不存在」來推論它，見下方分辨表；
也**不需要**在 `agent-handoff.md` 新增任何欄位。

**flow 收到訊號後的行為（機械分辨依據）**：

分辨的主鍵是**正向訊號**（某個字串出現了），**不是**「某個檔案不存在」。下表**依序**
比對，先命中者為準：

| # | 訊號（正向可偵測） | 判定 | 路徑 |
|---|------|------|------|
| 1 | final response **以上面那行固定格式回報 `PRE-FLIGHT MISMATCH` 並就此結束**——**不論 mini-handoff 是否存在** | **isolation-setup failure**（無新產出，**不是 gate 事件**） | 既有 **fallback 鏈**（見下方）：降級後重新 spawn |
| 2 | **沒有** `PRE-FLIGHT MISMATCH`，但**有** mini-handoff 且 `Gate Verdict: FAIL` | gate 失敗（有產出可修） | 既有 Phase Retry，最多 2 輪 |
| 3 | 兩者皆無（無 `PRE-FLIGHT MISMATCH`，且無 mini-handoff 或 mini-handoff 沒有 `## Gate Verdict`） | 狀態未知，**不得**逕自判定 | 走上文「干預協議」的查證階梯；查不到就問使用者 |

> **為什麼第 1 列不得加上「無 mini-handoff」這個條件**：mini-handoff **從不在重試之間被
> 刪除**——續作 agent（phase retry 與 verify-fix 的 per-phase 修復）一律是「讀上一次的
> mini-handoff → **更新**它」，唯一的刪除點是 run 收尾的 handoff GC。所以任何**續作**
> spawn 遇到 pre-flight 不符時，上一輪那份 `Gate Verdict: FAIL` 的 mini-handoff 都還在
> 磁碟上：若把「無 mini-handoff」寫進條件，第 1 列在續作情境**永遠不可能命中**，
> pre-flight 不符會被誤路由成 gate 失敗 → **吃掉一輪 retry 額度**（與下面「不計入 2 輪
> 額度」的保證直接矛盾）、**永遠進不了 fallback 鏈**（降級階梯形同死碼），兩輪全燒在同一
> 個壞掉的隔離設定上，最後以「這個 phase 修不好」的錯誤診斷交使用者。
> **缺席推論在 re-spawn 情境下不可靠——一律以正向訊號為主鍵。**
>
> **反向誤判的防線**：第 1 列認的是**固定格式的回報行**
> （`PRE-FLIGHT MISMATCH — <branch|cwd|target-file>: expected <X>, actual <Y>`，且 agent
> 就此結束、無其他產出），**不是**「文中出現過這個字串」——正常收尾的 agent 可能在
> mini-handoff 或 final response 裡**引述**它（討論規則、記錄風險），那不算訊號。
> 判不出來是回報還是引述時 → 落到第 3 列，走查證階梯，**不得**猜。

- pre-flight 不符**不是 gate 事件**：無 gate verdict、**不進 `failures[]`**、
  **不給 taxonomy tag**、**不計入** phase retry 的 2 輪額度（兩條路徑各自獨立）
- 降級上限：**同一 fallback 層級最多重試 1 次**，仍回報 mismatch → **降下一級**
  （原生 worktree → 手動 worktree 協議 → shared-tree）
- shared-tree 層級仍回報 mismatch → **停止 phase loop、回報使用者**（已無級可降）
- **續作 spawn 命中第 1 列時，降級後重新 spawn 的是「同一次續作」**——仍掛回既有分支、
  仍照 C-7「分支上已有的 commit 代表已完成的工作，不重做」，不是把該 phase 從頭做一次；
  該 phase 已用掉的 retry 輪數也不因此改變（pre-flight 不符不計入）

**Phase agent 在 worktree 內的收尾義務**：

1. **無論 gate 結果都要 commit 到 worktree 分支**——分支永遠承載最新狀態：
   - gate PASS → 正常 commit（message 沿用 git-conventions 格式、帶 phase 編號，
     同 post-build 的 per-phase commit 格式）
   - gate FAIL → 以 **`wip:` 前綴** commit（如 `wip: phase-05 smoke test failing`），
     供 repair agent 掛回既有分支續作；**latest gate = FAIL 的分支絕不 merge**
2. 在 mini-handoff 寫入選填欄位 `Worktree Branch:`——值**必須**是
   `git branch --show-current` 的實測輸出，**不准猜命名**（欄位定義見 `agent-handoff.md`）；
   mini-handoff 本身寫進**主樹**的 `handoffs/`（見下方雙路徑規則）

**雙路徑規則（artifact 交接，非協商）**：

worktree 隔離的是 **code**，artifact 一律走**主樹絕對路徑**——worktree 只隔離 git
working tree，不隔離檔案系統可見性。`handoffs/`、`plans/`、`specs/`、`points/` 都是
gitignored 的 runtime artifact，只帶 tracked 檔案的 worktree 裡**不會**出現它們，因此：

- flow spawn phase agent 時，prompt **必須注入主樹絕對路徑**（`<main-repo-root>`）
- **code 讀寫** → 用 phase agent 自己 worktree cwd 的相對路徑
- **artifact 讀寫**（phase 卡 `doing/`、spec sections、前驅 mini-handoff、自己要寫的
  mini-handoff）→ 一律用注入的主樹絕對路徑
- mini-handoff（含 `Worktree Branch:`）直接寫進主樹 `handoffs/`——flow 照常讀，
  harness `isolation: "worktree"` 模式下 flow 因此**不需要**知道 worktree 的實際路徑

**與 auto-commit hook 的互動（行為差異，明確寫死）**：

- 主樹的 `.athena/.flow-context.json` marker **照寫** `parallel_phases`（保險——即使
  worktree 隔離已生效，也不給 hook 任何在主樹誤 commit 的機會）
- worktree 內**沒有** `.athena/.flow-context.json`（untracked 檔案不跟隨 worktree），
  auto-commit hook 在 worktree 內自然 no-op——**phase commit 由 phase agent 自己做**，
  不靠 post-build skill、也不靠 hook（契約見 `flow-context.md`「並行 phase 行為」）

**Merge-back 協議（flow 在主樹執行）**：

全部平行 phase gate PASS **且**兩層 conflict detection（見下節）通過後：

1. 按拓撲序對各 mini-handoff 回報的 `Worktree Branch:` 執行 `git merge --no-ff <branch>`
   ——**僅限 latest gate = PASS 的分支**；latest gate = FAIL 的分支絕不 merge
2. touches 互斥下文字衝突**理應不發生**——若出現 merge conflict，這是**第三層安全網**：
   立即停止、**不嘗試自動解衝突**、交給使用者（依情況歸類 `#ownership` 或 `#plan-gap`）
3. 每個分支 merge 成功後 `git branch -d <branch>`（**`-d` 不是 `-D`**——git 保證已
   merge 才刪得掉）

worktree 模式下，per-phase commit 已由 phase agent 在 worktree 分支完成；主樹的整合點
是 merge commit——flow **不再**對這些平行 phase 執行 post-build commit。

**三層安全網（層次定位）**：

| 層 | 檢查 | 執行點 |
|----|------|--------|
| 第一層 | Ownership Violation（對照各 phase 自己的 touches 宣告） | Conflict Detection |
| 第二層 | 跨 Phase Files Changed 重疊比對 | Conflict Detection |
| 第三層 | merge conflict（物理層，git 自己驗） | Merge-back |

**Fallback 鏈**：

1. **`isolation: "worktree"` 選項不可用** → 手動協議：flow 對每個平行 phase 執行
   `git worktree add .athena/worktrees/<slug>-<NN> -b athena/phase/<slug>-<NN>`，
   phase agent prompt 指明工作目錄為該 worktree 路徑，並照樣注入主樹絕對路徑
   （雙路徑規則不變）；其餘義務（worktree 分支 commit、
   `Worktree Branch:` 回報、merge-back）同上。收尾時 flow 對每個已 merge 的 worktree
   執行 `git worktree remove <path>` + `git worktree prune`。
2. **連 worktree 都不可用**（非 git 環境或其他限制）→ 現行 **shared-tree 模式**：
   touches 事前分區 + 兩層 conflict detection，並照舊寫 `parallel_phases` 進
   flow-context；commit 由 flow 層在全部收斂後依序執行（即本文件其餘段落描述的原行為）。

**Crash 安全（非協商）**：

- flow 進入 phase loop **前**先執行 `git worktree prune`（清掉 crash 殘留的 worktree 註冊）
- GC 只刪**已 merge** 的 `athena/phase/` 分支（`git branch -d` 天然保證）
- **絕不自動刪未 merge 的分支**——殘留的未 merge 分支列給使用者決定去留

### 執行模式

Flow 依「同時可啟動的 phase 數量」與「預估執行時間落差」選擇兩種平行模式：

| 模式 | 觸發條件 | Agent 呼叫方式 | 等待方式 |
|------|---------|---------------|----------|
| **Foreground 平行** | ≤ 2 個可平行 phase，且預估時間相近 | 單一回應中送出多個 `Agent` tool calls（foreground） | 等所有 Agent 同步回傳 |
| **Background 平行** | ≥ 3 個可平行 phase，或時間落差大，或需要「先完成的 phase 提早觸發下游」 | 對每個 phase 呼叫 `Agent(run_in_background: true)` | 透過 harness 完成通知，先完成者先處理 |

> **worktree 模式除外**：「先完成的 phase 提早觸發下游」在 worktree 模式**不適用**——
> 下游 phase 一律等所屬上游平行集**全部 merge-back 完成**後才 spawn，不做 partial
> merge。worktree 模式下 background 平行的價值只剩並行本身與完成通知，不含提早觸發。

兩種模式共同的要求：

1. **同一次回應啟動所有可平行 phase**——不要序列化「先送一個 Agent、等回來再送下一個」，否則喪失平行
2. **完成順序與啟動順序解耦**——讀 mini-handoff 才是判定依據，不靠回傳順序
3. **不在 flow agent 內 `sleep` 輪詢**——background 模式靠 harness 主動通知，foreground 模式靠 tool result 同步返回
4. **平行 spawn 前先鎖卡**——把該平行集合的所有卡片全部 `mv todo/ → doing/` 之後才送出 agents（即鎖）
5. **平行集合登記到 flow-context**——同時 spawn >1 個 phase agent 前，flow 必須把 `parallel_phases:<N>` 寫入 `.athena/.flow-context.json`；全部收斂（所有平行 phase 的 gate 判定與 conflict detection 完成）後移除該欄位（hook 端契約見 `flow-context.md`）。worktree 隔離模式下**照寫**——這是保險，見「Worktree 隔離」段
6. **平行集 ≥ 2 一律 worktree 隔離**——spawn 帶 `isolation: "worktree"`；不可用時走 fallback 鏈（手動 worktree 協議 → shared-tree），見「Worktree 隔離」段

### Background 平行的執行流程

```
04 完成 → flow 識別 {05, 06} 為可平行 phase set
    ↓
flow 先鎖卡與登記：
  mv todo/05-*.md doing/ && mv todo/06-*.md doing/
  寫入 .athena/.flow-context.json：parallel_phases: 2
    ↓
flow 在單一回應中送出：
  Agent(run_in_background=true, prompt=phase-05 …)
  Agent(run_in_background=true, prompt=phase-06 …)
    ↓
flow 進入 "wait & merge" 心智模式：
  - 完成通知抵達 → 讀對應 mini-handoff → 暫存結果
  - 任一 phase Gate FAIL → 立即停 phase loop，不再啟動下游
  - 全部 PASS → 進入 Conflict Detection
    ↓
Conflict Detection（同下節）
    ↓
全部安全 → 各自 commit → mv doing/ → done/ → 移除 flow-context 的 parallel_phases 欄位
    ↓
觸發下游 phase（07 依賴 05 + 06）
```

> **worktree 模式差異**：上圖的「各自 commit」已由各 phase agent 在自己的 worktree
> 分支完成；flow 在「全部安全」後改執行 merge-back（按拓撲序 `git merge --no-ff`
> 各 `Worktree Branch:`，成功後 `git branch -d`），見「Worktree 隔離」段。

### Progress Tracking（搭配 TaskCreate）

平行 phase 數量多時，flow 在啟動前**先用 `TaskCreate` 建立對應 task**，把 phase 編號寫進 `subject`，並在 background Agent 完成通知抵達時 `TaskUpdate` 標記。

- 目的：使用者可從 task list 看到「現在哪些 phase 進行中、哪些已完成、哪些 fail」，而不是等 flow agent 主動回報
- mini-handoff 仍然是真相來源；TaskCreate 只是 UX 投影
- 不要把 mini-handoff 的內容塞進 task description，避免重複

### Conflict Detection（兩層）

平行 phase 完成後，flow 依序執行兩層檢查。這是三層安全網的**前兩層**——第三層是
worktree merge-back 時的 merge conflict（見「Worktree 隔離」段），worktree 與
shared-tree 模式都要跑這兩層：

**第一層：Ownership Violation（對照 touches 宣告）**

逐一把每個 phase 的 mini-handoff `Files Changed` 清單對照該 phase 在
plan.md frontmatter 的 `touches.files` glob 宣告：

| 情況 | 處理 |
|------|------|
| 所有改動檔案都落在自己的 touches 宣告內 | 通過，進入第二層 |
| 任一 phase 改了宣告範圍外的檔案 | **違規** → 停止流程，報告違規 phase 與越界檔案，交給使用者 |

> 第一層能抓到第二層抓不到的案例：「單方漏報彼此重疊」——phase A 越界改了
> B 地盤的檔案，但 B 這次剛好沒改到同一檔案（或漏報了 Files Changed），
> 跨 phase 重疊比對看不到任何交集，唯有對照 A 自己的 touches 宣告才會現形。

**第二層：跨 Phase Files Changed 重疊比對（既有）**

比對所有平行 phase 的 `Files Changed` 清單：

| 情況 | 處理 |
|------|------|
| 無重疊檔案 | 各自 commit，繼續 |
| 有重疊但都是新增（不同檔案名的 new） | 各自 commit，繼續 |
| 有重疊且修改同一檔案 | 停止流程，報告衝突檔案，交給使用者 |

Background 模式下，conflict detection 在「全部完成通知抵達後」才執行；不可在第一個完成的 phase 就 commit，否則衝突檔案會被先 commit 的版本覆寫，後到者得做 merge。

## Phase 拓撲彙整（供 emit-trace，選填）

phase loop 收斂後（所有 phase gate 判定與 conflict detection 完成），flow 把並行觀測
資料彙整起來，供收尾的 emit-trace 步驟填入 build stage 的 `phases` / `conflicts` 欄位
（schema 見 `run-trace.md`「時間與拓撲欄位」）。資料來源：

| 欄位 | 來源 |
|------|------|
| `phases[].id` / `name` | plan.md frontmatter 的 phase 定義 |
| `phases[].started_at` / `ended_at` | 各 phase mini-handoff 的 `## Timing` 區塊（`Started At:` / `Ended At:`，選填） |
| `phases[].mode` | flow 自己知道——spawn 該 phase 時用的是 foreground 還是 background 平行 |
| `phases[].isolation` | flow 自己知道——spawn 該 phase 時用 `"worktree"`（含手動協議）或 `"shared"`（主樹）；選填，缺失即略 |
| `phases[].parallel_group` | flow 自己知道——同一次回應中一起 spawn 的 phase id 集合（**含自己**）；序列執行的 phase 為 `["<NN>"]` |
| `phases[].gate` / `retries` | flow 的 gate 判定與 retry 紀錄 |
| `conflicts[]` | Conflict Detection 的結果：`{"phases":[...],"files":[...],"resolution":"clean"|"user"}` |

規則：**全部選填、缺失即略**——mini-handoff 沒有 Timing 就不帶時間欄位，
彙整或解析失敗安靜降級，絕不影響 gate 判定、commit 順序或 trace 寫入。

## Verification Phase Dedup

當路由包含 verify stage 時，flow 檢查 Dependency Graph 的**最後一個 phase**，避免與 verify stage 重複驗證。

### 判定流程

1. 讀取最後一個 phase 的 phase card
2. 判斷是否為「純驗證 phase」——不包含新增/修改程式碼的實作任務，只有測試執行與品質檢查
3. 若是純驗證 → **跳過該 phase**，由 verify stage 覆蓋
4. 若否（有實作 + 驗證混合）→ 正常執行

### 判斷標準

純驗證 phase 的特徵：
- Phase card 的任務描述中**不含**新增檔案、修改程式碼、建立模組等實作動詞
- **只有**執行測試、檢查覆蓋率、驗證整合、品質審查等驗證動詞
- Smoke test 指令涵蓋的範圍與 verify stage 的驗證內容高度重疊

### 處理方式

- 跳過的 phase 在 Build Handoff 中標記為 `skipped (deferred to verify)`
- phase card 由 flow `mv todo/ → done/` 並在卡片頂部標記 `deferred to verify`，供 verify agent 參考（避免其他執行者重複認領）
- Verify agent 可讀取被跳過的 phase card，了解原計畫的驗證內容

---

## Build Handoff 合成

所有 phase 完成後，flow 自動合成最終的 `handoffs/<slug>-build.md`：

```markdown
# Handoff: build

## Stage
build

## Inputs Used
- handoffs/<slug>-plan.md
- plans/<slug>/done/（各 phase 卡）

## Phase Summary
| Phase | Gate | Commit |
|-------|------|--------|
| 05 - Backend TDD | PASS | abc1234 |
| 06 - Frontend Build | PASS | def5678 |
| 07 - Integration | PASS | ghi9012 |

## Artifacts Produced
[合併所有 phase mini-handoff 的 Files Changed]

## Gate Verdict
PASS — All phases completed successfully

## Risks / Unresolved Issues
[合併所有 phase 的 Spec Deviations 與 Notes]

## Next Recommended Stage
verify
```

## 非協商規則

1. **Phase 定義來自 plan.md 的 YAML frontmatter** — flow 不硬編碼 phase 列表；markdown 表格僅為人類視圖
1a. **位置即狀態、mv 即鎖** — phase 狀態的唯一真相是 `todo/doing/done/` 資料夾位置；spawn 前 mv 到 `doing/`，gate PASS 後 mv 到 `done/`
2. **每個 phase 一個 fresh agent** — 不共享 context
3. **Mini-handoff 是唯一交接管道** — 不靠 agent 記憶
4. **Phase agent 自己跑 smoke test** — 不另開 agent
5. **Gate 沒過不 commit** — 只有 PASS 才觸發 post-build（worktree 分支上的 `wip:` commit 不在此限——那是狀態保全，且 FAIL 分支絕不 merge 進主樹）
6. **Gate 沒過不繼續** — FAIL 停止 phase loop
7. **Phase retry 最多 2 輪** — 超過交給使用者
8. **平行 phase 完成後必須 conflict detection（兩層）** — 先對照各 phase 自己的 touches 宣告（ownership violation），再做跨 phase Files Changed 重疊比對；任一層命中就停
9. **可平行的 phase 必須同一次回應送出** — 不可序列化呼叫，否則喪失平行
10. **不在 flow agent 內 sleep 輪詢** — background 模式靠 harness 主動通知，foreground 模式靠 tool result 同步返回
11. **TaskCreate 只做 UX 投影** — mini-handoff 仍是 gate 判定的唯一真相來源
12. **平行集 ≥ 2 一律 worktree 隔離** — spawn 帶 `isolation: "worktree"`；不可用時依序 fallback：手動 worktree 協議（`.athena/worktrees/` + `athena/phase/` 分支）→ shared-tree 模式。序列 phase（平行集大小 1）不用 worktree
13. **Merge conflict 是第三層安全網** — merge-back（`git merge --no-ff`）遇衝突立即停止、不自動解衝突、交給使用者（`#ownership` 或 `#plan-gap`）
14. **只用 `git branch -d`，不用 `-D`** — 只刪已 merge 的 `athena/phase/` 分支；**絕不自動刪未 merge 的分支**，殘留分支列給使用者決定
15. **phase loop 開始前 `git worktree prune`** — 先清 crash 殘留的 worktree 註冊再開工
16. **Worktree 分支無論 gate 結果都 commit** — PASS 用正常格式、FAIL 用 `wip:` 前綴，分支永遠承載最新狀態；**latest gate = FAIL 的分支絕不 merge**
17. **Artifact 一律走主樹絕對路徑** — worktree 只隔離 code；`handoffs/`、`plans/`、`specs/`、`points/` 的讀寫用 flow 注入的 `<main-repo-root>` 絕對路徑（雙路徑規則）
18. **Worktree 模式下游不提早觸發** — 下游 phase 等所屬上游平行集全部 merge-back 完成後才 spawn，不做 partial merge
