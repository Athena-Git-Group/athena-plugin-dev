# Run Trace

> v3 loop-engineering 的**共用基座**。事件驅動圈（2b）每跑一次寫一筆 trace；
> 自我改進圈（3）讀 trace 學習。設計脈絡見 `docs/design/loop-engineering-design.md`。

## 目的

把「整次 `/flow` run 作為一個結果」蒸餾成一筆持久紀錄，取代散落在
`points/`、`handoffs/`、git log、agent 記憶裡的零碎證據。

- **Trace = durable**：歷史的唯一真相，append-only，只會長不會爆。
- **Handoff = ephemeral**：stage 間的交接草稿，run 結束即回收（見下方 Retention Policy）。

## 檔案位置

```
.athena/traces/runs.jsonl        # append-only，一行一個 run（JSON Lines）
```

- runtime artifact，gitignore，consumer 專案本地累積，不進 plugin repo。
- 體積過大時按月 rotate：`.athena/traces/2026-06.jsonl`（可選，Step 1 先單檔）。

## 何時寫入

flow 在 run 結束前，以 **flow-inline 步驟**（不開 agent，因為這些資料此刻全在 flow context 裡）
序列化出一筆 trace 並 append。這個步驟同時是 handoff 的 **GC 點**（先 emit trace，再刪 handoff）。

無論結局是 `shipped` / `done` / `stopped@<stage>` / `handed-to-human`，**都要寫一筆 trace**。

## Trace Schema

| 欄位 | 型別 | 說明 |
|------|------|------|
| `run_id` | string | 全域唯一，建議 `<date>-<slug>-<seq>` |
| `slug` | string | 對應 point-report 的 slug |
| `ts` | string | ISO-8601 完成時間 |
| `trigger` | enum | `manual` / `ci` / `pr-review` / `cron` / `inbox`（**source 類別**；手動跑為 `manual`。具體 trigger name 記在 dispatcher state，不進此欄位，以利 Loop 3 聚合） |
| `point` | object | `{ verdict, score, dimensions{} }` |
| `weight` | enum | `Minimal` / `Lightweight` / `Full` |
| `route` | string | 實走路線（如 `point -> build -> verify -> review-ship`） |
| `stages[]` | array | 每個 stage：`{ stage, skill, gate, retries, agents }` |
| `failures[]` | array | 每筆：`{ tag, stage, affected_phase?, note }`（`tag` 見 Failure Taxonomy） |
| `human_interventions` | int | 使用者中途修正 / 否決次數 |
| `outcome` | enum | `shipped` / `done` / `stopped@<stage>` / `handed-to-human` |

### 範例（成功 run）

```json
{"run_id":"2026-06-25-member-export-01","slug":"member-export","ts":"2026-06-25T14:40:00Z","trigger":"manual","point":{"verdict":"PASS-BUILD-WITH-VERIFY","score":11,"dimensions":{"requirement_clarity":1,"domain_rule_complexity":1,"impact_radius":3,"contract_schema_change":3,"regression_risk":3,"knowledge_dependency":0}},"weight":"Lightweight","route":"point -> build -> verify -> review-ship","stages":[{"stage":"build","skill":"team-build","gate":"PASS","retries":0,"agents":1},{"stage":"verify","skill":"team-verify","gate":"PASS","retries":0,"agents":1}],"failures":[],"human_interventions":0,"outcome":"shipped"}
```

### 範例（失敗 run，帶 taxonomy + affected_phase）

```json
{"run_id":"2026-06-25-approval-01","slug":"approval-workflow","ts":"2026-06-25T16:10:00Z","trigger":"manual","point":{"verdict":"PASS-SPEC-FIRST","score":19,"dimensions":{}},"weight":"Full","route":"point -> spec -> plan -> build -> verify","stages":[{"stage":"build","skill":"team-build","gate":"PASS","retries":1,"agents":3},{"stage":"verify","skill":"team-verify","gate":"FAIL","retries":2,"agents":1}],"failures":[{"tag":"integration-mismatch","stage":"verify","affected_phase":"06","note":"frontend calls /api/approval, backend exposes /api/approvals"}],"human_interventions":1,"outcome":"handed-to-human"}
```

## Failure Taxonomy

`failures[].tag` 必須是以下 enum 之一（讓 Loop 3 能跑統計，而非讀自由文字）：

| Tag | 意義 |
|-----|------|
| `spec-gap` | 規格模糊 / 缺漏，導致 build 或 verify 失敗 |
| `plan-gap` | phase 拆解錯誤（缺依賴、邊界劃錯、漏 phase） |
| `skill-defect` | team skill 對清楚的輸入產出錯誤 |
| `contract-violation` | handoff 缺必填欄位 / 格式不符契約 |
| `integration-mismatch` | 跨 phase 介面不符（endpoint 命名、payload 形狀等） |
| `flaky` | smoke / verify 非確定性，重跑結果不同 |
| `scope-underestimate` | point 低估（如 trivial 路由但實際需要 spec） |
| `scope-overestimate` | point 高估（如 full 路由給一行改動） |
| `env` | 環境 / 工具失敗，非邏輯問題 |
| `unclassified` | **保留 fallback**：FAIL 未帶 tag 時由 emit-trace 補登。非正式分類，代表「待 triage」，Loop 3 應優先回頭補標 |

> gate verdict 在 FAIL 時必須帶上對應的 taxonomy tag，契約見 `agent-handoff.md`。
> trace 的 `failures[]` 直接彙整自各 stage handoff 的 FAIL tag；缺 tag 時補 `unclassified`（向後相容）。

## Handoff Retention Policy

handoff 不是歷史紀錄，是 ephemeral scratch。emit-trace 後依結局回收：

| run 結局 | handoffs 處置 | 理由 |
|---|---|---|
| `shipped` / `done`（乾淨完成） | **emit trace → 刪除該 slug 的 handoffs** | 乾淨 run 無學習價值，trace 的 `gate=PASS` 已足夠 |
| `stopped@<stage>` / `handed-to-human`（未解） | **保留** | (a) 下次靠它 resume；(b) Loop 3 學失敗的原料 |
| 失敗已解（重跑後 ship，或 hill-climb 已折成 eval case） | 刪除 | 學完即回收 |

### GC 規則（非協商）

1. **先 emit trace，再刪 handoff** — 確保該留的已蒸餾進 trace，刪檔才安全。
2. **只刪「已有對應 `shipped`/`done` trace」的 run** — 絕不刪 in-flight 或未解 run 的 handoff。
3. **以 slug 為刪除單位** — 一次刪一個 run 的所有 handoff（含 mini-handoff），不誤觸其他 run。
4. **保留目錄** — 刪檔不刪 `handoffs/` 目錄本身，flow 後續還要寫入。

### 可選團隊 knob

`.athena/` 設定（Step 1 預設 `keep-failures-only`）：

- `keep-failures-only`（預設）：乾淨完成即刪，失敗 / 未解保留
- `keep-last-N`：保留最近 N 個 run 的 handoff，其餘刪
- `keep-all`：不自動 GC（回到舊行為）

### 掃尾保險

crash / 使用者放棄的 run，handoff 會殘留。由 Trigger Dispatcher（Loop 2b）的 housekeeping tick
回收：「刪掉已有 `shipped` trace 且超過 X 天的 handoff」。Step 1 尚無 dispatcher 時，由下一次
同 slug 的 run 或人工清理。

## 非協商規則

1. **每次 run 都寫一筆 trace** — 不論成敗，emit-trace 是 flow 的強制收尾步驟。
2. **trace 是 append-only** — 不回頭改寫既有行；修正以新行表示。
3. **failures[].tag 必須是 enum 值** — 自由文字放 `note`，不放 `tag`。
4. **先 emit trace 再 GC handoff** — 順序不可顛倒。
5. **GC 絕不刪 in-flight / 未解 run** — 見上方 GC 規則第 2 條。
6. **schema 向後相容** — 新增欄位用 additive 方式；既有欄位語意一旦被 2b/3 依賴就不改名。
</content>
