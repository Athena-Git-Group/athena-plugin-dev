# Run Trace Extensions（治理＋選填欄位細則）

## 讀取時機

**有 Timing / Metrics / phases 資料要彙整時**（Full 且 handoff 帶選填欄位）、
或**擴充 taxonomy enum 時**才讀本檔。run 期的操作核心（何時寫、schema、emit 程序、
GC、taxonomy enum）在 `run-trace.md`；本檔全部內容遵守同一降級原則——
**選填欄位缺就略、解析失敗安靜降級、絕不擋 emit**。

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

## Phase 拓撲彙整（供 emit-trace，選填）

phase loop 收斂後（所有 phase gate 判定與 conflict detection 完成），flow 把並行觀測
資料彙整起來，供收尾的 emit-trace 步驟填入 build stage 的 `phases` / `conflicts` 欄位
（schema 見上方「時間與拓撲欄位」）。資料來源：

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

## Stage Metrics 蒐集細則（選填）

`stages[].metrics` 是**選填**物件，承載該 stage 的客觀量化數字（覆蓋率、lint 數…）。
與 `gate` 並列——`gate` 是二元 PASS/FAIL 裁決，`metrics` 是同一關的量化觀測，
**不參與 gate 判定**。由 flow emit-trace 從各 stage handoff 的 `## Metrics` 區塊自動蒐集
（見 `agent-handoff.md`）。

- **所有 value 必須是數字**（才能跨 run 聚合）；文字描述不放這裡。
- additive、向後相容——舊 trace 無此欄位仍合法；stage 沒提供 metrics 也合法。

### emit-trace 蒐集程序（flow 收尾時執行）

對每個 stage 的 handoff 找 `## Metrics` JSON 區塊，四種情況：

| 情況 | 處置 |
|------|------|
| **有且合法**（合法 JSON 且 value 皆數字） | 放進該 stage 的 `metrics` |
| **沒有** | 該 stage 不帶 `metrics`（合法） |
| **有但壞掉**（非法 JSON／含非數字 value） | **安靜跳過**，該 stage 不帶 metrics |
| **Full Weight phase 彙整** | 同名 metric 跨 phase 合併——`coverage` 取**最後一個 phase**（最終態）；計數類（`lint_*`／`tests_*`）取**加總** |

> **非協商**：metrics 蒐集是 emit-trace 裡最低優先的附加動作；解析失敗只代表「少記一個數字」，
> **絕不**影響 trace 寫入或 run 結局。metrics 不參與任何 gate 判定。

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

## Trace 範例（成功 run，補充 `run-trace.md` 的失敗範例）

```json
{"run_id":"2026-06-25-member-export-01","slug":"member-export","ts":"2026-06-25T14:40:00Z","trigger":"manual","point":{"verdict":"PASS-BUILD-WITH-VERIFY","score":11,"dimensions":{"requirement_clarity":1,"domain_rule_complexity":1,"impact_radius":3,"contract_schema_change":3,"regression_risk":3,"knowledge_dependency":0}},"weight":"Lightweight","route":"point -> build -> verify -> review-ship","stages":[{"stage":"build","skill":"team-build","gate":"PASS","retries":0,"agents":1},{"stage":"verify","skill":"team-verify","gate":"PASS","retries":0,"agents":1}],"failures":[],"human_interventions":0,"outcome":"shipped"}
```

## Retention 與事後回饋的張力（v1 已知限制）

> ⚠️ 乾淨 ship 的 run **在當下**看似無學習價值，但事後可能透過 `feedback.jsonl` 取得回饋
> （ship 後的 bug、覆蓋率過低…），屆時就**有**學習價值了。v1 **不**為此延後 GC——
> shipped run 的 handoff 照舊立即刪。**後果**：回饋到達時該 run 的 handoff 深度證據已不在，
> Loop 3 只能靠 trace + 回饋的 `note` 診斷。
> **v2 補救**：對 shipped run 加 handoff retention 寬限窗（保留 N 天供事後回饋期內診斷）。

## Failure Taxonomy enum 擴充治理

（enum 本體與 `rule-conflict` 判準邊界留在 `run-trace.md` 操作核心，run 期直接讀那份。）

### enum 擴充的向後相容宣告

- **additive**：本 enum 只增不改。既有 tag 的拼寫與意義一字未變
- **舊 trace 仍合法**：`.athena/traces/runs.jsonl` 既有紀錄**不需回填、不需遷移**。
  舊 run 沒有後來才加的 tag 是正常的，不是資料缺陷
- **無 schema 校驗器**：`hooks/` 與 `scripts/` 對本 enum 零消費點，
  新增 tag 不會讓任何工具報錯（代價：漏同步也不會報錯，見下方同步義務）
- `by_tag` 是**開放 map**（見上方前向相容條款），統計端以實際出現的 tag 為準
- fallback 行為不變：未帶 tag 一律補 `unclassified`；新增 tag 不會成為新的 fallback

### enum 擴充的分層治理

本 enum 是 **plugin 層的核心契約，`run-trace.md` 為唯一權威來源**。
擴充權限**分層**授予：

| 層 | 誰可以擴充 | 走什麼程序 |
|----|-----------|-----------|
| plugin 核心契約（enum 本體） | plugin 自身的變更流程 | point → spec → plan → build，改 `run-trace.md` |
| 團隊 skill（`.athena/skills/*`） | **不得自行發明 tag** | 透過 hill-climb 提案；提案通過後由 plugin 流程落到 `run-trace.md` |

**團隊 skill 不得自行發明 tag。** 團隊遇到現有 tag 都不貼切的失敗，先用最接近的 tag
並在 Gate Verdict 原因裡寫清楚，再透過 hill-climb 提案擴充。因此團隊規則裡
「不得私自發明 tag」的要求對**團隊層持續完全有效**，與擴充程序不衝突：
兩者管的是不同層，不是同一條規則的兩種說法。

**新增 tag 時的同步義務**：enum 的每一個 tag，都必須在
`skills/athena-hill-climb/references/hill-climb.md` §4 映射表有對應列，
否則 Loop 3 統計得到那個 tag 卻查不到要改什麼。此處漏同步過去已真實發生過，
且因為沒有校驗器而**不會報錯**——加 tag 就要同時加映射列。
