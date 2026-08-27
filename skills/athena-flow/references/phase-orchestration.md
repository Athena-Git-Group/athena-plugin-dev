# Phase Orchestration

## 適用條件

Phase loop **僅在 Full Weight 流程中執行**（`PASS-SPEC-FIRST`）。

若路由為 `PASS-DIRECT-BUILD` 或 `PASS-BUILD-WITH-VERIFY`：
- **不進入 phase loop** — 沒有 `plan.md`，沒有 Dependency Graph
- Build 以 Lightweight 模式執行（見 `stage-contracts.md`「build（Minimal / Lightweight — 單一 agent）」段落）
- 本文件的所有規則不適用於 Lightweight 模式

兩個情境專屬協議已獨立成檔，**按需另讀**：
- 平行集 ≥ 2 的 spawn 前 → `worktree-isolation.md`（D-0 適用表、pre-flight 健檢、fallback 階梯、merge-back、雙路徑規則、crash 安全）
- 想中止 / 判定 agent 失效 / 重新 spawn 前 → `intervention-protocol.md`（查證階梯、C-1~C-8）

---

## 概述：Phase 與 Stage 的關係

Flow 讀取 `plans/<slug>/plan.md` 的 Dependency Graph，將 **implementation phases**
（通常 Phase 05-07）拆解為 Build stage 內的獨立 sub-stage，逐一（或平行）調度。
每個 phase 獲得與 standard stage 同等級的 fresh agent、mini-handoff、smoke test gate
與 per-phase commit。

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
```

> **Worktree 隔離模式**（平行集 ≥ 2）：平行 spawn 前另讀 `worktree-isolation.md`
> 的「注入義務」段，照其注入段落附加到本模板末尾（主樹絕對路徑、`Main Tree Branch:`
> / `Expected Branch:`、pre-flight 三項健檢、雙路徑規則、收尾 commit 義務）。

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

1. Flow 讀取該 phase 的 mini-handoff → 取得失敗原因
2. 開 fresh agent（repair mode）：載入 build skill + phase card + 失敗的 mini-handoff
3. Agent 修復 → 重跑 smoke test → **更新** mini-handoff
4. Flow 再檢查 Gate Verdict：PASS → post-build commit → 繼續下一個 phase；
   FAIL → 再 retry 一次（**最多 2 輪**）；超過 2 輪 → 停止流程，交給使用者

**Worktree 模式的 retry（續作 spawn）**：repair agent 用手動 worktree 協議掛回**既有分支**
續作——`git worktree add .athena/worktrees/<slug>-<NN>-retry <Worktree Branch>`（分支已
存在，**不帶 `-b`**）。prompt 照 `worktree-isolation.md`「注入義務」注入主樹絕對路徑、
`Main Tree Branch:` 與 `Expected Branch:`（= 掛回的既有分支），repair agent 過 pre-flight
後修復、commit（PASS 正常格式 / 仍 FAIL 用 `wip:` 前綴）、重跑 gate、更新主樹的
mini-handoff；flow 收尾 `git worktree remove` + `git worktree prune`。輪數上限沿用 2 輪；
**latest gate = FAIL 的分支絕不 merge**。

> **「掛回既有分支的續作」只有 phase retry 這一種——verify-fix 的 per-phase 修復不是**：
> phase retry 發生在 merge-back 之前、分支必然還在；verify-fix 發生在 merge-back 之後、
> 分支已刪，一律在主樹的 flow 分支上執行。判準與四條時序理由見 `worktree-isolation.md`
> 的 D-0 表與「verify-fix 的 per-phase 修復」專段。

## Agent 干預協議

Orchestrator 想**主動介入另一個 agent**（中止、判定失效／卡死／放棄、重新 spawn 同一
stage 或 phase、把 phase 移出平行集、依其狀態向使用者做結論性回報）之前，**必讀**
`intervention-protocol.md`——查證階梯、查不到時的出口、C-1~C-8 全在該檔。
gate FAIL 的正常收尾走上面的 Phase Retry，與干預協議是兩條不同路徑。

## 平行 Phase 執行

Flow 分析 Dependency Graph，識別可平行的 phase。

### 判定規則

Phase A 和 Phase B 可平行，**當且僅當**：A 不依賴 B、B 不依賴 A、且兩者的所有前置依賴都已完成。

> **事前分區保證**：可平行 pair 的 `touches` 宣告（`files` glob + `resources`）
> 互斥已由 plan 階段的 `validate_plan.py --require-touches` 機械保證——
> 這是「事前分區」。Flow 在選取平行集合時**不需**重算 touches 交集；
> 事後的 Conflict Detection（見下節）是第二道防線，不是分區依據。

### Worktree 隔離（平行集的主路徑）

平行集 ≥ 2 時 **spawn 一律帶 `isolation: "worktree"`**；spawn 前**必讀**
`worktree-isolation.md`——D-0 適用表、pre-flight 三項健檢與 `PRE-FLIGHT MISMATCH`
分辨表、fallback 階梯（原生 → 手動協議 → shared-tree）、收尾 commit 義務、
雙路徑規則、merge-back 協議、crash 安全全在該檔。序列 phase（平行集大小 1）不用 worktree。

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
5. **平行集合登記到 flow-context**——同時 spawn >1 個 phase agent 前，flow 必須把 `parallel_phases:<N>` 寫入 `.athena/.flow-context.json`；全部收斂（所有平行 phase 的 gate 判定與 conflict detection 完成）後移除該欄位（hook 端契約見 `flow-context.md`）。worktree 隔離模式下**照寫**——這是保險，見 `worktree-isolation.md`「與 auto-commit hook 的互動」
6. **平行集 ≥ 2 一律 worktree 隔離**——spawn 帶 `isolation: "worktree"`；不可用時走 fallback 鏈（手動 worktree 協議 → shared-tree），見 `worktree-isolation.md`

### Background 平行的執行流程

以 04 完成後可平行的 {05, 06} 為例：

1. 鎖卡與登記：`mv todo/05-*.md doing/ && mv todo/06-*.md doing/`；寫入 flow-context `parallel_phases: 2`
2. 單一回應送出全部 `Agent(run_in_background=true, …)`
3. "wait & merge"：完成通知抵達 → 讀對應 mini-handoff → 暫存；任一 phase Gate FAIL → 立即停 phase loop、不再啟動下游
4. 全部 PASS → Conflict Detection（下節）→ 全部安全 → 各自 commit → `mv doing/ → done/` → 移除 `parallel_phases` 欄位 → 觸發下游 phase（07）

> **worktree 模式差異**：第 4 步的「各自 commit」已由各 phase agent 在 worktree 分支完成；
> flow 在「全部安全」後改執行 merge-back，見 `worktree-isolation.md`「Merge-back 協議」。

### Progress Tracking（搭配 TaskCreate）

平行 phase 數量多時，flow 啟動前先用 `TaskCreate` 建立對應 task（phase 編號寫進 `subject`），
完成通知抵達時 `TaskUpdate` 標記——純 UX 投影，mini-handoff 仍是真相來源；
不把 mini-handoff 內容塞進 task description。

### Conflict Detection（兩層）

平行 phase 完成後，flow 依序執行兩層檢查。這是三層安全網的**前兩層**——第三層是
worktree merge-back 時的 merge conflict（見 `worktree-isolation.md`「Merge-back 協議」），
worktree 與 shared-tree 模式都要跑這兩層：

**第一層：Ownership Violation（對照 touches 宣告）**

逐一把每個 phase 的 mini-handoff `Files Changed` 清單對照該 phase 在
plan.md frontmatter 的 `touches.files` glob 宣告：

| 情況 | 處理 |
|------|------|
| 所有改動檔案都落在自己的 touches 宣告內 | 通過，進入第二層 |
| 任一 phase 改了宣告範圍外的檔案 | **違規** → 停止流程，報告違規 phase 與越界檔案，交給使用者 |

> 一句理由：第一層能抓「單方漏報彼此重疊」——A 越界改了 B 地盤但 B 沒改到同一檔案時，
> 跨 phase 比對看不到交集，唯有對照 A 自己的 touches 宣告才會現形。

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

當路由包含 verify stage 時，flow 讀 Dependency Graph **最後一個 phase** 的 phase card，
判斷是否為「純驗證 phase」：任務描述**不含**實作動詞（新增檔案、修改程式碼、建立模組），
**只有**驗證動詞（執行測試、檢查覆蓋率、驗證整合、品質審查），且 smoke test 範圍與
verify stage 高度重疊。是 → **跳過該 phase**，由 verify stage 覆蓋；否（實作 + 驗證混合）→ 正常執行。

跳過的處理：Build Handoff 標記 `skipped (deferred to verify)`；phase card 由 flow
`mv todo/ → done/` 並在卡片頂部標記 `deferred to verify`（避免重複認領，
verify agent 可讀該卡了解原計畫的驗證內容）。

---

## Build Handoff 合成

所有 phase 完成後，flow 自動合成最終的 `handoffs/<slug>-build.md`——
模板見 `agent-handoff.md`「變體差異表」的 **Build 合成** 列
（build 合成特有 `## Phase Summary` 段：Phase/Gate/Commit 表，置於 Inputs Used 後）。

## 非協商規則

1. **Phase 定義來自 plan.md 的 YAML frontmatter** — flow 不硬編碼 phase 列表；markdown 表格僅為人類視圖
2. **位置即狀態、mv 即鎖** — phase 狀態的唯一真相是 `todo/doing/done/` 資料夾位置；spawn 前 mv 到 `doing/`，gate PASS 後 mv 到 `done/`
3. **每個 phase 一個 fresh agent** — 不共享 context
4. **Mini-handoff 是唯一交接管道** — 不靠 agent 記憶
5. **Phase agent 自己跑 smoke test** — 不另開 agent
6. **Gate 沒過不 commit** — 只有 PASS 才觸發 post-build（worktree 分支上的 `wip:` commit 不在此限——那是狀態保全，且 FAIL 分支絕不 merge，見 `worktree-isolation.md`）
7. **Gate 沒過不繼續** — FAIL 停止 phase loop
8. **Phase retry 最多 2 輪** — 超過交給使用者
9. **平行 phase 完成後必須 conflict detection（兩層）** — 先對照各 phase 自己的 touches 宣告（ownership violation），再做跨 phase Files Changed 重疊比對；任一層命中就停
10. **TaskCreate 只做 UX 投影** — mini-handoff 仍是 gate 判定的唯一真相來源

> 平行 spawn／輪詢禁令的權威文字見本檔「執行模式」共同要求 1、3；worktree 專屬非協商規則
> （隔離、merge-back、分支刪除、crash 安全）見 `worktree-isolation.md`；
> 干預規則見 `intervention-protocol.md`。
