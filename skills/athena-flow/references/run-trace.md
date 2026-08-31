# Run Trace（操作核心）

> v3 loop-engineering 的**共用基座**。事件驅動圈（2b）每跑一次寫一筆 trace；
> 自我改進圈（3）讀 trace 學習。設計脈絡見 `docs/design/loop-engineering-design.md`。
> 治理段、選填時間拓撲細則與 Metrics 蒐集細表在 `run-trace-extensions.md`（按需另讀）。

## 目的

把「整次 `/flow` run 作為一個結果」蒸餾成一筆持久紀錄，取代散落在 `points/`、`handoffs/`、
git log、agent 記憶裡的零碎證據。**Trace = durable**（機器對流程觀測的唯一真相，append-only）；
**Feedback = durable**（`.athena/traces/feedback.jsonl`，由 `athena-feedback` 寫入、同為
append-only，以 `run_id` 指回原 run，Loop 3 把兩者 JOIN 起來學習）；
**Handoff = ephemeral**（stage 間的交接草稿，run 結束即回收，見下方 Retention Policy）。

## 檔案位置

`.athena/traces/runs.jsonl`——append-only，一行一個 run（JSON Lines）。runtime artifact，
gitignore，consumer 專案本地累積，不進 plugin repo；體積過大時按月 rotate（可選，Step 1 先單檔）。

## 何時寫入

flow 在 run 結束前，以 **flow-inline 步驟**（不開 agent，因為這些資料此刻全在 flow context 裡）
序列化出一筆 trace 並 append。這個步驟同時是 handoff 的 **GC 點**（先 emit trace，再刪 handoff）。
依回報協議（`rules/回報協議與read-back綁定.md`），本步驟在 **run 最終訊息輸出之後**才執行。

無論結局是 `shipped` / `done` / `stopped@<stage>` / `handed-to-human`，**都要寫一筆 trace**。

## Trace Schema

| 欄位 | 型別 | 說明 |
|------|------|------|
| `run_id` | string | 全域唯一，建議 `<date>-<slug>-<seq>` |
| `slug` | string | 對應 point-report 的 slug |
| `ts` | string | ISO-8601 完成時間 |
| `started_at` | string | **選填**。ISO-8601 UTC run 開始時間（flow 建 flow-context marker 時寫入，emit-trace 讀取；見 `flow-context.md`。缺失即略） |
| `trigger` | enum | `manual` / `ci` / `pr-review` / `cron` / `inbox`（**source 類別**；手動跑為 `manual`。具體 trigger name 記在 dispatcher state，不進此欄位，以利 Loop 3 聚合） |
| `point` | object | `{ verdict, score, dimensions{} }` |
| `weight` | enum | `Minimal` / `Lightweight` / `Full` |
| `route` | string | 實走路線（如 `point -> build -> verify -> review-ship`） |
| `stages[]` | array | 每個 stage：`{ stage, skill, gate, retries, agents, started_at?, ended_at?, metrics?, phases?, conflicts? }`（`started_at` 之後全部**選填**；細則見 `run-trace-extensions.md`）|
| `failures[]` | array | 每筆：`{ tag, stage, affected_phase?, note }`（`tag` 見 Failure Taxonomy） |
| `human_interventions` | int | 使用者中途修正 / 否決次數 |
| `outcome` | enum | `shipped` / `done` / `stopped@<stage>` / `handed-to-human` |

### 範例（失敗 run，帶 taxonomy + affected_phase；成功 run 範例見 `run-trace-extensions.md`）

```json
{"run_id":"2026-06-25-approval-01","slug":"approval-workflow","ts":"2026-06-25T16:10:00Z","trigger":"manual","point":{"verdict":"PASS-SPEC-FIRST","score":19,"dimensions":{}},"weight":"Full","route":"point -> spec -> plan -> build -> verify","stages":[{"stage":"build","skill":"team-build","gate":"PASS","retries":1,"agents":3},{"stage":"verify","skill":"team-verify","gate":"FAIL","retries":2,"agents":1}],"failures":[{"tag":"integration-mismatch","stage":"verify","affected_phase":"06","note":"frontend calls /api/approval, backend exposes /api/approvals"}],"human_interventions":1,"outcome":"handed-to-human"}
```

## 選填欄位（時間拓撲、Metrics）的降級原則

**選填欄位缺就略、解析失敗安靜降級、絕不擋 emit**——run 期真正需要的判斷只有
「要不要略過」。`stages[].started_at/ended_at`、build stage 的 `phases`/`conflicts`、
`stages[].metrics` 的欄位細則、蒐集程序與 phase 拓撲彙整表，全部見
`run-trace-extensions.md`（有該類資料要彙整時才讀）。

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
| `review-finding` | review 階段提出需修正的品質/正確性問題（handoff 顯示為 `request-changes`）；與 verify FAIL 的區別靠 `stages[].stage` 而非 tag |
| `rule-conflict` | 兩條**各自有效**的規則互斥，agent 無法同時遵守（遵守任一邊必然違反另一邊）。來源可能跨層：harness 內建行為、flow 規則、stage 或團隊 skill 規則 |
| `env` | 環境 / 工具失敗，非邏輯問題 |
| `unclassified` | **保留 fallback**：FAIL 未帶 tag 時由 emit-trace 補登。非正式分類，代表「待 triage」，Loop 3 應優先回頭補標 |

> gate verdict 在 FAIL 時必須帶上對應的 taxonomy tag，契約見 `agent-handoff.md`。
> trace 的 `failures[]` 直接彙整自各 stage handoff 的 FAIL tag；缺 tag 時補 `unclassified`（向後相容）。
> enum 只增不改；擴充治理與向後相容宣告見 `run-trace-extensions.md`。

### `rule-conflict` 的判準邊界

這個 tag 最容易被誤用成「什麼都塞得下」的第二個 fallback。用下列**決定性問句**
與相鄰 tag 區分，每題答案唯一：

| 對照 | 決定性問句 | 答案 → tag |
|------|-----------|-----------|
| vs `env` | 「**把互斥的兩條規則之一移除**後，agent 用當前工具就能完成嗎？」 | 能 → `rule-conflict`（是規則打架，工具沒壞）；不能（工具／環境根本不允許） → `env` |
| vs `contract-violation` | 「沒被遵守的是**一條**契約，還是**兩條都有效**的規則互相不容？」 | 一條 → `contract-violation`；兩條 → `rule-conflict` |
| vs `spec-gap` | 「規則是**缺**（沒說這種情況怎麼辦），還是**多且互斥**（兩邊都說了、而且說反了）？」 | 缺 → `spec-gap`；互斥 → `rule-conflict` |

**使用義務**（沿用既有 gate 契約，不新增 handoff 欄位）：FAIL 時 Gate Verdict 帶
`#rule-conflict`，並在**同一則 Gate Verdict 的原因文字**中列出互斥的兩條規則來源，
各自附上 `檔案:行號`。tag 欄位只放 tag，兩個來源寫在原因裡（例：
`FAIL — X 要求 A、Y 要求非 A，無法同時遵守（foo.md:12 / bar.md:34） #rule-conflict`）。
**舉不出兩個來源就不該用這個 tag**——只有一條規則沒被遵守是 `contract-violation`，
規則沒說怎麼辦是 `spec-gap`。

## Handoff Retention Policy

handoff 不是歷史紀錄，是 ephemeral scratch。emit-trace 後依結局回收：

| run 結局 | handoffs 處置 | 理由 |
|---|---|---|
| `shipped` / `done`（乾淨完成） | **emit trace → 刪除該 slug 的 handoffs** | 乾淨 run **在當下**無已知學習價值，trace 的 `gate=PASS` 已足夠（但見下方 ⚠️）|
| `stopped@<stage>` / `handed-to-human`（未解） | **保留** | (a) 下次靠它 resume；(b) Loop 3 學失敗的原料 |
| 失敗已解（重跑後 ship，或 hill-climb 已折成 regression case） | 刪除 **handoff** | 折成**持久 regression case** 後 handoff 回收；**case 本身留存於 `.athena/hill-climb/regression/`（棘輪，只增不刪，見 hill-climb.md §5.5）**，不隨 handoff 消失 |

> ⚠️ 事後回饋與此政策存在張力（v1 已知限制：shipped run 照舊立即刪，回饋到達時
> 深度證據已不在）——完整說明與 v2 補救方向見 `run-trace-extensions.md`。

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

1. **每次 run 都寫一筆 trace** — 不論成敗，emit-trace 是 flow 的強制收尾步驟（在 run 最終訊息之後執行）。
2. **trace 是 append-only** — 不回頭改寫既有行；修正以新行表示。
3. **failures[].tag 必須是 enum 值** — 自由文字放 `note`，不放 `tag`。
4. **先 emit trace 再 GC handoff** — 順序不可顛倒。
5. **GC 絕不刪 in-flight / 未解 run** — 見上方 GC 規則第 2 條。
6. **schema 向後相容** — 新增欄位用 additive 方式；既有欄位語意一旦被 2b/3 依賴就不改名。
