# Event Triggers — 契約與 schema

> `athena-trigger-dispatch`（Loop 2b）的詳細契約。設計脈絡見
> `docs/design/loop-engineering-design.md` Part 2b。

## 1. `triggers.yml` schema

放在 consumer 專案的 `.athena/triggers.yml`（runtime 設定，由團隊維護）。

```yaml
triggers:
  - name: <唯一名稱>          # 必要，dedup/state 以此為 key 之一
    source: ci | pr-review | cron | inbox   # 必要，決定用哪個 adapter 探測
    when: <條件運算式>          # 必要（cron 為 crontab 字串）
    guard: <前置條件>           # 選填，不滿足直接跳過（如 branch glob）
    poll: <duration>           # 選填，活躍時的輪詢間隔（預設 270s）；cron 忽略
    intake: fix | address-review | from-file | hill-climb   # 必要，決定 intake 模板
    autonomy: notify | auto-to-gate | auto-full   # 選填，預設 notify
    enabled: true | false      # 選填，預設 true
```

### 欄位語意

| 欄位 | 說明 |
|------|------|
| `name` | 全 registry 唯一；dedup state 的主鍵 |
| `source` | 探測 adapter（見 §2） |
| `when` | 命中條件（見 §3 運算式） |
| `guard` | 前置過濾，先於 `when` 評估；不滿足不算事件 |
| `poll` | 活躍時輪詢間隔；閒置時 dispatcher 自動拉長（見 §6） |
| `intake` | 命中後用哪個模板把事件包成需求敘述（見 §5） |
| `autonomy` | 命中後的行動等級（見 §4） |

## 2. Source Adapters（唯讀探測）

| source | 探測方式（唯讀 CLI） | event id（dedup 用） |
|--------|---------------------|---------------------|
| `ci` | `gh run list --json databaseId,status,conclusion,headBranch` / `gh pr checks` | `run-<databaseId>` |
| `pr-review` | `gh pr view <n> --json reviews,state` 或 `gh pr list --json number,reviewDecision` | `pr-<number>-review-<reviewId>` |
| `cron` | 比對目前時間與 crontab 字串（由 ScheduleWakeup/cron routine 帶入） | `cron-<name>-<fire-ts>` |
| `inbox` | 列 `.athena/inbox/` 下的新檔 | `inbox-<filename>` |

> **探測階段只讀不寫**——不在 tick 評估時做任何 git 操作或檔案寫入（state.json 更新除外）。

### Inbox 縫（純原生但 webhook-ready）

`source: inbox` 監看 `.athena/inbox/` 的檔案佇列。今天由人或本地腳本丟檔；
日後若要接 GitHub Action / webhook，外部只要把事件**寫成檔案丟進 inbox**，dispatcher
完全不用改。處理完的檔案移到 `.athena/inbox/.done/`（即 dedup，也避免重複處理）。

## 3. `when` / `guard` 運算式

簡單、好解析、無歧義即可（dispatcher 用字串比對，不需完整表達式引擎）：

```
status == failed
reviewDecision == CHANGES_REQUESTED
conclusion == failure && headBranch matches feature/*
```

- 支援：`==`、`!=`、`matches <glob>`、`&&`。
- `guard` 同語法，典型用途：`branch matches feature/*`、`author != dependabot`。
- `cron` 的 `when` 是 crontab 字串（如 `0 2 * * 1`），不走此運算式。

## 4. Autonomy 等級（安全核心）

| 等級 | 行動 | 安全邊界 |
|------|------|---------|
| `notify`（**預設**） | `PushNotification` / `TaskCreate` 通知人，**不啟動 flow** | 零自動寫入 |
| `auto-to-gate` | 呼叫 `/athena-flow`，intake 明確要求**停在 ship 前** | 自動改 code 但**絕不 push/merge**，等人確認 |
| `auto-full` | 呼叫 `/athena-flow` 跑完整流程含 ship | 僅限高度信任、低風險類別，需顯式設定 |

**規則**：未指定 `autonomy` 一律 `notify`。`auto-to-gate` / `auto-full` 是顯式 opt-in。
建議新 trigger 一律先跑一陣子 `notify`，觀察 dedup/guard 無誤觸後再放寬。

## 5. Intake 模板（把事件包成需求敘述餵 /flow）

dispatcher 命中後產生一段需求敘述，前置一行 `trigger: <source>`（source 類別
`manual`/`ci`/`pr-review`/`cron`/`inbox`，供 flow 的 emit-trace 填 `trace.trigger`）。
具體 trigger `name` 記在 dispatcher state，**不**進 trace 欄位，以利 Loop 3 用 source 類別聚合。

| intake | 內容骨架 |
|--------|---------|
| `fix` | 「CI run `<id>` 在分支 `<branch>` 失敗。失敗 job/test：`<name>`。Log 摘要：`<excerpt>`。請定位並修復。」→ point 通常判 TRIVIAL/DIRECT-BUILD |
| `address-review` | 「PR #`<n>` 被要求修改。Reviewer 意見：`<comments>`。請逐條處理。」 |
| `from-file` | 直接用 inbox 檔案內容當需求敘述（檔案自帶格式） |
| `hill-climb` | 「執行 retro：分析自上次 watermark 後的 trace。」→ 觸發 `athena-hill-climb`（Loop 3，Step 3 才有） |

> intake 只描述「要做什麼」，**不預設複雜度與路由**——那是 point 的工作。

## 6. 輪詢節奏（cache-aware）

Anthropic prompt cache TTL 約 5 分鐘。輪詢間隔選擇：

| 情境 | 間隔 | 理由 |
|------|------|------|
| 有活躍事件（CI 跑中、剛 dispatch、等完成通知） | 270s（<5min） | 保持 cache 溫，省成本 |
| 閒置（無進行中事件） | 1200–1800s（20–30min） | 一次 cache miss 換長間隔，不空轉 |

- 用 `ScheduleWakeup` 自我節奏，**不在迴圈內 `sleep` 輪詢**。
- 別固定 300s——那是最差解（付了 cache miss 又沒攤平）。
- background flow run 的完成靠 harness 通知，不主動 poll flow 自身狀態。

## 7. Dispatcher State — `.athena/triggers/state.json`

```json
{
  "triggers": {
    "ci-red-on-pr": {
      "seen": ["run-1234", "run-1240"],
      "dispatched": ["run-1234"],
      "last_tick": "2026-06-25T14:40:00Z"
    }
  },
  "in_flight": [
    { "slug": "ci-fix-run-1234", "branch": "feature/x", "trigger": "ci-red-on-pr", "started": "2026-06-25T14:41:00Z" }
  ]
}
```

- `seen` / `dispatched`：dedup 依據（可定期裁剪保留最近 N 筆）。
- `in_flight`：single-flight 依據；flow 完成通知到達後移除對應項。

## 8. Housekeeping GC（接 Step 1 的掃尾保險）

每 N tick 跑一次，回收 crash/放棄 run 留下的孤兒 handoff：

1. 讀 `.athena/traces/runs.jsonl`，找出 outcome 為 `shipped`/`done` 的 run。
2. 對 `handoffs/` 內的散檔，若其 slug **已有對應 shipped/done trace** 且**超過 X 天**（預設 7）→ 刪除。
3. **絕不刪** in-flight（在 state.in_flight）或無 shipped trace（可能未解）的 run 的 handoff。

規則與 `athena-flow/references/run-trace.md` 的 Handoff Retention Policy 一致。

## 9. 非協商規則

1. **唯讀探測** — tick 評估只用唯讀 CLI，不寫入（state.json 除外）、不做 git 操作。
2. **Dedup by event id** — 同 id 不重觸發。
3. **Single-flight by slug/branch** — 不併發同一目標。
4. **autonomy 預設 notify、auto-* 顯式 opt-in、絕不自動 push（除非 auto-full）**。
5. **intake 不預設路由** — 一律交 point 分流。
6. **GC 只刪已完成 run** — 見 §8。
7. **triggers.yml / state.json 缺失採安全預設** — 缺 triggers.yml 引導後停；缺 state 視為空（首次全部當新事件，但仍依 autonomy，預設只 notify 不會誤改 code）。
</content>
