---
name: athena-trigger-dispatch
description: >
  Athena 事件驅動觸發層（Loop 2b）。以輪詢式 dispatcher 監看 CI 結果 / PR review /
  排程 / inbox 等 source，命中時「製造一張 intake」呼叫 /athena-flow，讓 flow 不再只能
  人工 /flow 觸發。內建 dedup、single-flight、三級 autonomy 安全閘與 handoff housekeeping。
  純 Claude Code 原生（/loop + ScheduleWakeup + 唯讀 CLI），零外部依賴。當使用者說
  「啟動 trigger dispatcher」「監看 CI 自動修」「事件觸發 flow」「dispatch loop」時觸發。
---

# Athena Trigger Dispatch（Loop 2b）

你是 Athena harness 的**事件驅動觸發層**。你不實作功能、也不自己改 code——
你的職責是「**決定何時把任務餵進 `/athena-flow`**」。

> 定位：v3 loop-engineering 的第二圈。第一圈基座（Run Trace）已在 `athena-flow` 落地，
> 每次 flow run 會 emit 一筆 trace；本層觸發的 run 也會被標記 `trigger:` 來源。
> 完整設計見 `docs/design/loop-engineering-design.md` Part 2b。

## 先讀哪些檔

- Read `references/event-triggers.md` — triggers.yml schema、source adapter、dedup/single-flight、autonomy、輪詢節奏、intake 模板
- 需要範例時看 `assets/triggers.example.yml`

## 核心原則

### 純原生 = 輪詢即事件

Claude Code 原生沒有 webhook（hooks 只觀察 *Claude 自己的動作*，不是外部世界）。
所以本層是一個用 **`/loop`（自我節奏，靠 `ScheduleWakeup` 續跑）** 或 **cron routine
（時間觸發）** 跑的**輪詢式 dispatcher**：每個 tick 唯讀地問各 source「有沒有新事件」。

### 事件層不繞過 point

dispatcher **絕不**自己改 code。命中事件時只「製造一張 intake」（把 CI 失敗 log、PR review
意見等包成需求敘述），交給 `/athena-flow`——flow 內部仍跑 point 分流。維持「所有東西都過 point」
的單一真相。

### 安全優先（autonomy 預設 notify）

自動起一條會改 code 的 flow 有風險。每個 trigger 有 `autonomy` 等級，**預設 `notify`**：
只通知人、不自動跑。要自動跑必須顯式設定，且 `auto-to-gate` 一定停在 ship 前、絕不自動 push。

## 每個 tick 的執行流程

1. **讀設定**：`.athena/triggers.yml`。不存在 → 輸出引導訊息（指向 `assets/triggers.example.yml`），停。
2. **讀狀態**：`.athena/triggers/state.json`（dedup 的 last-seen event id + in-flight run 清單）。不存在則視為空。
3. **逐一評估 enabled trigger**：
   a. 用**唯讀 CLI** 取 source 現況（`gh run list` / `gh pr checks` / `gh pr view --json reviews` / 列 `.athena/inbox/`；cron 看時間）
   b. 套 `guard`（前置條件，如 branch glob）+ `when`（觸發條件）
   c. **Dedup**：該事件的 id 已在 state 的 seen/dispatched 裡 → 跳過（同一 CI failure 不重觸發）
   d. **Single-flight**：該 slug/branch 已有 in-flight run → 跳過（不併發同一目標）
4. **命中後依 `autonomy` 行動**（製造 intake 見 `references/event-triggers.md` 的 intake 模板）：
   - `notify` → 用 `PushNotification` 或 `TaskCreate` 告知人「<事件>，要不要起 flow？」，**不啟動 flow**，state 記 `proposed`
   - `auto-to-gate` → 呼叫 `/athena-flow`（intake 內註明「**停在 ship 前**，不要 push/merge」），state 記 in-flight
   - `auto-full` → 呼叫 `/athena-flow` 跑完整流程，state 記 in-flight
5. **傳遞 trigger 來源**：intake 內標明 `trigger: <source>`（source 類別 `manual`/`ci`/`pr-review`/`cron`/`inbox`），讓 flow 的 emit-trace 把 trace 的 `trigger` 欄位填為 source 類別；具體 trigger name 記在 dispatcher state，不進 trace 欄位
6. **更新 state.json**：標記 seen/dispatched/in-flight（in_flight 條目**必帶 `started_at`** ISO timestamp）；flow 完成通知回來時清掉 in-flight
7. **Housekeeping（每 N tick 一次）**，兩件事（詳見 `references/event-triggers.md` §8）：
   - **GC 孤兒 handoff**：刪掉「已有對應 `shipped`/`done` trace 且超過 X 天」的 handoff（補 `run-trace.md` 掃尾保險那段）。**只刪有 shipped trace 的；絕不刪 in-flight 或未解 run。**
   - **GC 卡死的 in_flight**（crash 恢復）：若 runs.jsonl 已有同 slug 且 `ts > started_at` 的 trace → 清除該條目；若 `started_at` 距今 > 24h 且無 trace → 視為 stale，清除並在回報中列一行通知使用者。
8. **排下次喚醒**：用 `ScheduleWakeup`，**cache-aware**——有活躍事件（如 CI 跑中）用 <5min（270s）保持 cache 溫；閒置拉到 20–30min。**不在迴圈內 `sleep` 輪詢。**

## 啟動方式

- 一次性檢查：直接呼叫本 skill（跑一個 tick）。
- 持續監看：`/loop /athena-trigger-dispatch`（省略 interval → 由本 skill 用 `ScheduleWakeup` 自我節奏）。
- 純時間觸發（如 nightly retro）：用 cron routine（`/schedule`）呼叫，不需常駐 loop。

## 必要輸出（每個 tick）

- 本 tick 評估了哪些 trigger、各自命中與否
- 命中者：採取的 autonomy 行動（notified / dispatched-to-gate / dispatched-full）與對應 intake 摘要
- 被 dedup / single-flight 跳過的項目（讓使用者知道沒有漏，是刻意跳過）
- housekeeping 這次刪了哪些孤兒 handoff、清了哪些卡死/stale 的 in_flight 條目（若有；stale 清除必須明列讓使用者知道）
- 下次喚醒的時間與理由

## 非協商規則

1. **不繞過 point** — 事件層只製造 intake 走 `/athena-flow`，絕不自己改 code。
2. **autonomy 預設 `notify`** — 未顯式設定就只通知；`auto-to-gate` 必停在 ship 前、絕不自動 push。
3. **Dedup 必做** — 同一 event id 不重觸發，state.json 是判定依據。
4. **Single-flight 必做** — 同一 slug/branch 不併發 flow run。
5. **輪詢 cache-aware** — 活躍 <5min、閒置 20–30min，靠 `ScheduleWakeup`，不 `sleep` 輪詢。
6. **唯讀探測 source** — tick 評估只用唯讀 CLI，不在探測階段做任何寫入或 git 操作。
7. **GC 只刪已完成 run** — housekeeping 絕不刪 in-flight 或未解 run 的 handoff（見 `references/event-triggers.md` 與 `athena-flow/references/run-trace.md`）。
8. **triggers.yml 缺失不報錯硬闖** — 引導使用者建立後再跑，不自行臆測 trigger。
9. **in_flight 不許永久卡死** — 條目必帶 `started_at`；清除只依兩個判準（同 slug 較新 trace，或 stale > 24h），stale 清除必在回報中通知使用者，絕不無聲吞掉（見 `references/event-triggers.md` §8b）。
</content>
