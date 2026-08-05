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
