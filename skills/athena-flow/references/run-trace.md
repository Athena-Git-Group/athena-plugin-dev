# Run Trace

> v3 loop-engineering 的**共用基座**。事件驅動圈（2b）每跑一次寫一筆 trace；
> 自我改進圈（3）讀 trace 學習。設計脈絡見 `docs/design/loop-engineering-design.md`。

## 目的

把「整次 `/flow` run 作為一個結果」蒸餾成一筆持久紀錄，取代散落在
`points/`、`handoffs/`、git log、agent 記憶裡的零碎證據。

- **Trace = durable**：機器對流程觀測的唯一真相，append-only，只會長不會爆。
- **Feedback = durable**：人對結果的事後回饋（`.athena/traces/feedback.jsonl`，由 `athena-feedback`
  寫入），平行於 trace、同為 append-only，以 `run_id` 指回原 run。Loop 3 把兩者 JOIN 起來學習。
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
| `started_at` | string | **選填**。ISO-8601 UTC run 開始時間（flow 建 flow-context marker 時寫入，emit-trace 讀取；見 `flow-context.md`。缺失即略） |
| `trigger` | enum | `manual` / `ci` / `pr-review` / `cron` / `inbox`（**source 類別**；手動跑為 `manual`。具體 trigger name 記在 dispatcher state，不進此欄位，以利 Loop 3 聚合） |
| `point` | object | `{ verdict, score, dimensions{} }` |
| `weight` | enum | `Minimal` / `Lightweight` / `Full` |
| `route` | string | 實走路線（如 `point -> build -> verify -> review-ship`） |
| `stages[]` | array | 每個 stage：`{ stage, skill, gate, retries, agents, started_at?, ended_at?, metrics?, phases?, conflicts? }`（`started_at` / `ended_at` **選填** ISO-8601 UTC；`metrics` 選填，見下方 Stage Metrics；`phases` / `conflicts` **選填**、僅 build stage，見下方「時間與拓撲欄位」）|
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

## 時間與拓撲欄位（選填，並行觀測）

讓 Loop 3 能評估並行是否有效的時間與拓撲維度。**所有時間欄位皆為選填、缺失即略、
絕不擋 emit**——emit-trace 解析失敗一律安靜降級（比照 Stage Metrics 的設計哲學），
舊 trace 無此欄位仍合法，不需遷移。

- **run 層 `started_at`**（選填，ISO-8601 UTC）：flow 建 flow-context marker 時寫入，
  emit-trace 讀回（見 `flow-context.md`）。
- **`stages[].started_at` / `stages[].ended_at`**（選填，ISO-8601 UTC）：來自 stage handoff
  的選填 `Started At:` / `Ended At:` 欄位（見 `agent-handoff.md` Timing 段）。
- **build stage 的 `phases`**（選填，陣列）：Full Weight phase loop 的逐 phase 觀測，每筆：

  ```json
  {"id":"05","name":"Backend TDD","started_at":"2026-06-25T14:02:11Z","ended_at":"2026-06-25T14:18:47Z","mode":"foreground","isolation":"worktree","gate":"PASS","retries":0,"parallel_group":["05","06"]}
  ```

  | 欄位 | 說明 |
  |------|------|
  | `id` / `name` | 對應 plan.md frontmatter 的 phase id 與名稱 |
  | `started_at` / `ended_at` | **選填**，來自該 phase mini-handoff 的 `Started At:` / `Ended At:` |
  | `mode` | `"foreground"` / `"background"`（flow 自己知道用哪種模式 spawn） |
  | `isolation` | **選填**，`"worktree"` / `"shared"`——該 phase 是否在獨立 git worktree 中執行（flow 自己知道 spawn 時用哪種隔離，含手動 worktree 協議；缺失即略，舊 trace 不需遷移） |
  | `gate` / `retries` | `"PASS"` / `"FAIL"` 與 retry 次數（flow 的 gate 判定紀錄） |
  | `parallel_group` | 與該 phase **同時 spawn** 的 phase id 集合（**含自己**）；序列執行時為 `["05"]` |

- **build stage 的 `conflicts`**（選填，陣列）：conflict detection 的結果，每筆：

  ```json
  {"phases":["05","06"],"files":["src/router.ts"],"resolution":"user"}
  ```

  `resolution`：`"clean"`（無實質重疊，各自 commit）/ `"user"`（重疊修改同檔，交使用者）。

### 範例（build stage 帶 phases 的完整 trace 行）

```json
{"run_id":"2026-08-05-approval-02","slug":"approval-workflow","ts":"2026-08-05T15:10:00Z","started_at":"2026-08-05T14:00:00Z","trigger":"manual","point":{"verdict":"PASS-SPEC-FIRST","score":19,"dimensions":{}},"weight":"Full","route":"point -> spec -> plan -> build -> verify -> review -> ship","stages":[{"stage":"build","skill":"team-build","gate":"PASS","retries":0,"agents":3,"started_at":"2026-08-05T14:00:30Z","ended_at":"2026-08-05T14:50:00Z","phases":[{"id":"05","name":"Backend TDD","started_at":"2026-08-05T14:02:11Z","ended_at":"2026-08-05T14:18:47Z","mode":"foreground","isolation":"worktree","gate":"PASS","retries":0,"parallel_group":["05","06"]},{"id":"06","name":"Frontend Build","started_at":"2026-08-05T14:02:15Z","ended_at":"2026-08-05T14:25:03Z","mode":"foreground","isolation":"worktree","gate":"PASS","retries":0,"parallel_group":["05","06"]},{"id":"07","name":"Integration","started_at":"2026-08-05T14:26:00Z","ended_at":"2026-08-05T14:49:12Z","mode":"foreground","isolation":"shared","gate":"PASS","retries":0,"parallel_group":["07"]}],"conflicts":[{"phases":["05","06"],"files":[],"resolution":"clean"}],"metrics":{"wall_seconds":4200,"agent_seconds":3756,"max_parallel_width":2}},{"stage":"verify","skill":"team-verify","gate":"PASS","retries":0,"agents":1,"started_at":"2026-08-05T14:51:00Z","ended_at":"2026-08-05T15:05:00Z"}],"failures":[],"human_interventions":0,"outcome":"shipped"}
```

## Stage Metrics（選填）

`stages[].metrics` 是**選填**物件，承載該 stage 的客觀量化數字（覆蓋率、lint 數…）。
與 `gate` 並列——`gate` 是二元 PASS/FAIL 裁決，`metrics` 是同一關的量化觀測，
**不參與 gate 判定**。由 flow emit-trace 從各 stage handoff 的 `## Metrics` 區塊自動蒐集
（見 `agent-handoff.md`）。

- **所有 value 必須是數字**（才能跨 run 聚合）；文字描述不放這裡。
- additive、向後相容——舊 trace 無此欄位仍合法；stage 沒提供 metrics 也合法。

已知 key 詞彙（snake_case）：

| key | 型別 | 說明 |
|-----|------|------|
| `coverage` | number 0..1 | 測試覆蓋率（比例，非百分比字串）|
| `lint_warnings` | integer ≥0 | lint 警告數 |
| `lint_errors` | integer ≥0 | lint 錯誤數（選填）|
| `tests_passed` / `tests_failed` | integer ≥0 | 測試通過/失敗數（選填）|
| `wall_seconds` | number ≥0 | **選填**。run 牆鐘時間（`ts` − run 層 `started_at`，秒）|
| `agent_seconds` | number ≥0 | **選填**。agent 工作時間總和（`phases` 各 phase 時長加總；缺 `phases` 時退回各 stage `started_at`/`ended_at` 時長加總）|
| `max_parallel_width` | integer ≥1 | **選填**。最大 `parallel_group` 大小（並行寬度）|

> 上述三個 key **不來自 handoff 的 `## Metrics` 區塊**，由 emit-trace 從時間與拓撲欄位
> 自行計算，慣例掛在 build stage 的 `metrics`。任一來源欄位缺失就略過該 key（安靜降級），
> 絕不擋 emit。

> **前向相容**：允許其他 snake_case + 數字 value 的 key；未知 key 消費端（hill-climb）忽略不報錯。

### 範例（stage 帶 metrics）
```json
{"stage":"verify","skill":"team-verify","gate":"PASS","retries":0,"agents":1,"metrics":{"coverage":0.82,"lint_warnings":0}}
```

> **這條線 vs 事後回饋**：`metrics` 是「機器在 run 內的客觀觀測」，歸 trace；
> 人對結果的主觀回饋（ship 後 bug 等）走 `feedback.jsonl`，兩者機制不混用。

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

### enum 擴充的向後相容宣告

- **additive**：本 enum 只增不改。既有 tag 的拼寫與意義一字未變
- **舊 trace 仍合法**：`.athena/traces/runs.jsonl` 既有紀錄**不需回填、不需遷移**。
  舊 run 沒有後來才加的 tag 是正常的，不是資料缺陷
- **無 schema 校驗器**：`hooks/` 與 `scripts/` 對本 enum 零消費點，
  新增 tag 不會讓任何工具報錯（代價：漏同步也不會報錯，見下方同步義務）
- `by_tag` 是**開放 map**（見上方前向相容條款），統計端以實際出現的 tag 為準
- fallback 行為不變：未帶 tag 一律補 `unclassified`；新增 tag 不會成為新的 fallback

### enum 擴充的分層治理

本 enum 是 **plugin 層的核心契約，本檔（`run-trace.md`）為唯一權威來源**。
擴充權限**分層**授予：

| 層 | 誰可以擴充 | 走什麼程序 |
|----|-----------|-----------|
| plugin 核心契約（本 enum） | plugin 自身的變更流程 | point → spec → plan → build，改本檔 |
| 團隊 skill（`.athena/skills/*`） | **不得自行發明 tag** | 透過 hill-climb 提案；提案通過後由 plugin 流程落到本檔 |

**團隊 skill 不得自行發明 tag。** 團隊遇到現有 tag 都不貼切的失敗，先用最接近的 tag
並在 Gate Verdict 原因裡寫清楚，再透過 hill-climb 提案擴充。因此團隊規則裡
「不得私自發明 tag」的要求對**團隊層持續完全有效**，與本檔的擴充程序不衝突：
兩者管的是不同層，不是同一條規則的兩種說法。

**新增 tag 時的同步義務**：本 enum 的每一個 tag，都必須在
`skills/athena-hill-climb/references/hill-climb.md` §4 映射表有對應列，
否則 Loop 3 統計得到那個 tag 卻查不到要改什麼。此處漏同步過去已真實發生過，
且因為沒有校驗器而**不會報錯**——加 tag 就要同時加映射列。

## Handoff Retention Policy

handoff 不是歷史紀錄，是 ephemeral scratch。emit-trace 後依結局回收：

| run 結局 | handoffs 處置 | 理由 |
|---|---|---|
| `shipped` / `done`（乾淨完成） | **emit trace → 刪除該 slug 的 handoffs** | 乾淨 run **在當下**無已知學習價值，trace 的 `gate=PASS` 已足夠（但見下方 ⚠️）|
| `stopped@<stage>` / `handed-to-human`（未解） | **保留** | (a) 下次靠它 resume；(b) Loop 3 學失敗的原料 |
| 失敗已解（重跑後 ship，或 hill-climb 已折成 regression case） | 刪除 **handoff** | 折成**持久 regression case** 後 handoff 回收；**case 本身留存於 `.athena/hill-climb/regression/`（棘輪，只增不刪，見 hill-climb.md §5.5）**，不隨 handoff 消失 |

> ⚠️ **事後回饋與此政策的張力（v1 已知限制）**：乾淨 ship 的 run **在當下**看似無學習價值，
> 但事後可能透過 `feedback.jsonl` 取得回饋（ship 後的 bug、覆蓋率過低…），屆時就**有**學習價值了。
> v1 **不**為此延後 GC——shipped run 的 handoff 照舊立即刪。**後果**：回饋到達時該 run 的 handoff
> 深度證據已不在，Loop 3 只能靠 trace + 回饋的 `note` 診斷。
> **v2 補救**：對 shipped run 加 handoff retention 寬限窗（保留 N 天供事後回饋期內診斷）。

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
