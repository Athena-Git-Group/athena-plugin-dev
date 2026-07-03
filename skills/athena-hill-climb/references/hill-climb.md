# Hill-Climb — 契約與 schema

> `athena-hill-climb`（Loop 3）的詳細契約。設計脈絡見
> `docs/design/loop-engineering-design.md` Part 3。輸入是 Step 1 的 Run Trace
> （`athena-flow/references/run-trace.md`）。

## 1. 輸入：Run Trace + 事後回饋（兩條流）

### 1a. Run Trace（機器對流程的觀測）
讀 `.athena/traces/runs.jsonl`。關鍵欄位（完整 schema 見 run-trace.md）：

- `point`（verdict/score/dimensions）、`weight`、`route`
- `stages[]`（gate / retries / agents）
- `failures[]`（**tag** = failure taxonomy、`affected_phase`、`note`）
- `outcome`、`human_interventions`、`trigger`（source 類別）

### 1b. 事後回饋（人對結果的回饋）
讀 `.athena/traces/feedback.jsonl`（由 `athena-feedback` 寫入）。關鍵欄位：

- `run_id`（外鍵，**JOIN 鍵**）、`kind`（回饋 taxonomy）、`severity`、`attributed_stage`、`metric`、`note`

**Collect 時以 LEFT JOIN on `run_id` 把回饋掛回 trace**：每筆 run 得到 `feedback[]`（可能為空）。
這讓「當時 gate=PASS、outcome=shipped」的乾淨 run，若事後被回饋，也進入 retro 視野。
`kind` 與 failure taxonomy 的邊界見 §3.1。

## 2. State — `.athena/hill-climb/state.json`

```json
{
  "watermark": "2026-06-25T02:00:00Z",
  "last_run_id_seen": "2026-06-24-approval-03",
  "open_proposals": ["2026-06-25-proposals.md#P2"]
}
```

- `watermark`：上次 retro 處理到的時間點；本輪只看其後的 run。
- `open_proposals`：已提出但尚未採納/關閉的提案，避免重複提。

## 3. Diagnose — 「系統性」判定

只對**重複出現**的模式立提案，避免對雜訊過擬合：

| 訊號 | 系統性門檻（建議預設） |
|------|----------------------|
| 同一 failure tag | 在窗口內 ≥ 3 次，或 ≥ 30% 的相關 run |
| 同一 stage / phase 邊界反覆失敗 | ≥ 3 次 |
| scope 不準（point verdict vs 實際 escalate） | ≥ 2 次同方向（連續低估或高估） |
| verify-retry 撞上限 | 同一 root cause ≥ 2 次 |
| **同一回饋 `kind`（跨 run）** | 窗口內 ≥ 3 次，或 ≥ 30% 相關 run |
| **同一 `attributed_stage` 反覆被回饋** | ≥ 3 次 |

每條診斷**必附**證據（`run_ids` 清單；回饋類附對應 `feedback_id`）。

**多筆回饋去重**：
- **比率類指標**（如 `post_ship_defect_rate`，§7）：以 **distinct `run_id`** 計（同一 run 3 筆回饋 = 1 個有缺陷的 run）。
- **模式頻率**（Diagnose 立案）：以**回饋出現次數**計，但須在報告標注是否集中於少數 run——
  單一 run 多筆回饋刷高頻率會造成過擬合，須排除。

### 3.1 `kind` vs failure taxonomy 的邊界

兩者是**獨立輸入流、永不合併**，報告中分開呈現：

| | failure taxonomy（`failures[].tag`）| feedback `kind` |
|---|---|---|
| 何時 | run **進行中** | run **結束後** |
| 誰判定 | 機器（gate FAIL）| 人（事後觀察）|
| 性質 | 流程失敗 | 品質 / 結果不滿意 |

語意相近的情況（`regression` 回饋 vs `integration-mismatch` 失敗）以「**何時/誰**抓到」區分：
gate 在 run 內抓到 = failure tag；人事後抓到 = feedback kind。

## 4. Propose — 失敗模式 → 改進目標映射

| 失敗模式（重複） | 改進目標 | 典型改動 |
|---|---|---|
| `integration-mismatch` | build skill / api-spec 契約 | 加「以 api.yml 為 endpoint 權威」步驟 |
| `scope-underestimate` / `scope-overestimate` | **point rubric** | 調 dimension 權重 / 加 override 關鍵字 |
| `contract-violation` | stage contract / handoff 模板 | 收緊必填欄位 + validator |
| `spec-gap` | spec skill / clarify 規則 | 補澄清項、強化 spec 完整度檢查 |
| `plan-gap` | plan skill / dependency graph 規則 | 修 phase 拆解或依賴標註 |
| `skill-defect` | team skill | 立 eval case + 修 |
| `flaky` | verify / smoke | quarantine、標 xfail 並寫移除條件 |
| `env` | kickoff / 環境文件 | 補環境前置檢查 |
| `parallel_speedup` 持平於 ~1 **且** trace 的 `phases[]` 顯示 `parallel_group` 皆為單元素（可平行集未被使用）、或 plan 的 Dependency Graph 過度串鏈 | plan skill / dependency graph 規則 | 💡 提案平行化候選：指出可平行的 phase 組、放寬過度串鏈的依賴標註 |

回饋 taxonomy（`feedback.jsonl` 的 `kind`）→ 改進目標：

| 回饋模式（重複）| 改進目標 | 典型改動 |
|---|---|---|
| `low-coverage` 反覆 | verify skill / 測試生成 skill | 提高覆蓋門檻、補測試生成指引 |
| `post-ship-defect` 集中某 `attributed_stage` | 該 stage skill / spec 完整度 | 補該 stage 的檢查或澄清項 |
| `user-rework` 集中 spec 之後 | spec skill / clarify 規則 | 強化 spec 完整度、補澄清 |
| `regression` 反覆 | verify / 整合檢查 | 加 regression guard |
| `perf` / `style` 反覆 | build skill / coding 規則 | 補非功能性檢查項 |

## 5. Verify 改進（用既有工具當測量臂）

| 改進類別 | 驗證方式 | 工具 |
|---------|---------|------|
| skill 行為 | 把失敗 trace 折成 regression eval case（trace 有 intake=輸入、expected=本該如何、actual=怎麼壞），真跑 | `athena-skill-eval` |
| point rubric | 拿 trace 裡歷史 intake 重新 point，比對 verdict 分布是否改善 | `athena-point`（re-score） |
| stage contract / handoff 格式 | 靜態結構檢查 | `athena-skill-audit` |

> 這一步是把現在**靜態、與 flow 脫鉤**的 skill-eval / skill-audit 接成 hill-climbing 的
> 「改完有沒有比較好」測量臂。整合方式是**鬆耦合**：hill-climb 產出 eval case / 檢查請求，
> 呼叫對應工具，讀其結果，不改其內部。

## 5.5 Regression Ratchet（棘輪 / 退步關卡）

> 文章核心：「沒有關卡，就沒有自我改進」。§5 給了「怎麼量」的工具，本節給「量完不准倒退」的棘輪。
> 修好的失敗 → 永久測試；採納新提案前必須通過退步 gate。系統無法回到比已解決更差的狀態。

### 5.5.1 Regression Set 結構

持久 corpus，路徑 `.athena/hill-climb/regression/`（append-only、只增不刪）：

```
.athena/hill-climb/regression/
├── index.jsonl          # append-only 帳本，一行一個 case
└── cases/
    └── <case_id>.md     # 實際 eval case（沿用 skill-eval case-spec，可被 athena-skill-eval 跑）
```

`index.jsonl` 每行：

| 欄位 | 型別 | 說明 |
|------|------|------|
| `case_id` | string | 唯一，`reg-<NNN>`（三位序號，只增）|
| `fingerprint` | string | 去重指紋 `<captured>|<stage>|<phase-or-kind>`（見 5.5.3）|
| `source` | object | `{run_ids[], captured}`；`captured` = 原 failure tag 或 feedback kind |
| `case_path` | string | 對應 `cases/<case_id>.md` |
| `added_ts` | string | ISO-8601 升格時間 |
| `status` | enum | `active`（預設）/ `retired`（僅人工 + reason，**不刪檔**）|

`cases/<case_id>.md`：沿用 `athena-skill-eval` case-spec 格式（frontmatter `eval-case-version`/`target-stage`
+ 額外 `regression: true`/`source_run_ids`；Setup/Task/Expected/Anti-patterns 帶 `[mechanical]`/`[semantic]`），
使其可被 skill-eval 直接跑。

範例 `index.jsonl`：
```json
{"case_id":"reg-001","fingerprint":"integration-mismatch|build|06","source":{"run_ids":["2026-06-25-approval-01"],"captured":"integration-mismatch"},"case_path":"cases/reg-001.md","added_ts":"2026-06-30T02:00:00Z","status":"active"}
```

### 5.5.2 退步 Gate（採納提案的前置條件）

採納任何提案**前**，用 `athena-skill-eval` 跑整組 `status=active` 的 regression case，閘門：

| 條件 | 門檻 |
|------|------|
| **已修好的不退步** | active case 通過率 ≥ `regression_gate_threshold`（**預設 0.8**，對齊文章 NeoSigma）|
| **不低於 baseline** | 通過率 ≥ 上一輪 baseline——即使 ≥0.8，比上輪退步仍算退步（防 0.8 門檻下緩慢下滑）|
| **抗 flaky** | 失敗 case 允許**重跑一次**；仍失敗才算退步 |

- knob：`regression_gate_threshold`（預設 `0.8`；要嚴格棘輪可上調 `1.0`）。
- **gate 失敗 → 不採納**：提案保持 `open`，標記「卡退步 gate + 退步的 case_id」，回報人工。**不**自動改 system。
- **gate 通過 → 仍須人工最終採納**（gate 是客觀前置條件，非自動套用——維持 §9 規則 6）。

### 5.5.3 棘輪 Invariant + 升格規則

提案**採納並驗證修好**後，把修好的失敗**升格**為永久 case：

1. **append-only**：`index.jsonl` 只 append、既有行不改；`cases/` 既有檔不刪。
2. **升格冪等（去重）**：以 `fingerprint = <captured>|<stage>|<phase-or-kind>` 去重；已存在相同 fingerprint → 不重複新增。
3. **不可變**：case 內容寫入後不變；要更新就新增 case 並把舊的 `status=retired`（附人工 reason）。
4. **退役需人工**：`retired` 只能人工設定 + reason，**絕不自動刪檔**（保留歷史、可審計）。
5. **只增不減**：正常運作下 set 單調成長——這就是「系統無法回到更差狀態」的核心保證。

## 6. Proposals 檔 — `.athena/hill-climb/<date>-proposals.md`

格式見 `assets/proposals.template.md`。要點：

- 每條提案有 id（P1/P2…）、嚴重度（✅/🟡/💡）、診斷、trace 證據、目標物件、建議改動、驗證方式。
- **不用 PASS/FAIL**——避免被誤當 CI gate。
- 採納欄位讓人勾選；採納後該提案轉成一張 `/athena-flow` intake。

## 7. Metrics — `.athena/hill-climb/metrics.jsonl`

每輪 retro append 一行，讓「hill」可量測：

```json
{"ts":"2026-06-25T02:00:00Z","window_runs":18,"gate_first_pass_rate":0.72,"verify_retry_rate":0.22,"scope_accuracy":0.83,"mean_agents_per_run":5.1,"mean_wall_seconds":1840,"parallel_speedup":1.6,"human_intervention_rate":0.28,"post_ship_defect_rate":0.11,"mean_coverage":0.81,"regression_set_size":17,"by_tag":{"integration-mismatch":4,"scope-underestimate":3},"by_kind":{"post-ship-defect":2,"low-coverage":1}}
```

| 指標 | 定義 |
|------|------|
| `gate_first_pass_rate` | 各 stage gate 第一次就 PASS 的比率 |
| `verify_retry_rate` | 進入 verify-retry 的 run 比率 |
| `scope_accuracy` | point verdict 與實際是否 escalate 相符的比率 |
| `mean_agents_per_run` | 平均 agent 數——**僅成本面參考**。吞吐面看 `parallel_speedup` 與 `mean_wall_seconds`，兩面搭配判讀；**不得單以 agents 數上升判定退步**（並行化本來就會推高 agents 數）|
| `mean_wall_seconds` | 平均 wall-clock 秒數（來自 trace 的 `wall_seconds`，見 run-trace.md Stage Metrics）；分母 = 窗口內 outcome ∈ {shipped, done} 且**帶有** `wall_seconds` 的 run。無任何合格 run → `null` |
| `parallel_speedup` | 同時帶有 `agent_seconds` 與 `wall_seconds` 的 run 之 `agent_seconds ÷ wall_seconds` 平均；**>1 表示並行有效**。無任何合格 run → `null` |
| `human_intervention_rate` | 有人工中途介入的 run 比率 |
| `post_ship_defect_rate` | 事後缺陷率，定義見下方公式（分母為 0 時為 `null`）|
| `mean_coverage` | 窗口內所有「帶 `coverage` 的 stage」的平均覆蓋率；無任何 coverage → `null` |
| `regression_set_size` | 當輪 `status=active` 的 regression case 數（棘輪健康度，應單調不減；類比文章 0→17）|
| `by_tag` | 本窗口各 failure tag 次數 |
| `by_kind` | 本窗口各 feedback kind 次數 |

### `post_ship_defect_rate` 公式

```
post_ship_defect_rate =
    (窗口內 outcome ∈ {shipped, done} 且 ≥1 筆 kind ∈ {post-ship-defect, regression}
     且 severity ∈ {blocker, major} 的 distinct run_id 數)
  ÷ (窗口內 outcome ∈ {shipped, done} 的 distinct run_id 數)
```

- **窗口**：與其他 metrics 相同（自上次 watermark 後）。
- **分母為 0**（窗口內無已交付 run）→ 值為 `null`，避免「沒交付過卻顯示 0% 缺陷」的誤導。
- **算已交付的 run（`shipped` ∪ `done`）**：`done` 是 Minimal 路由的正常終局，其產物一樣由使用者
  push 進生產，事後缺陷對它同樣有意義。分子分母的 outcome 條件必須一致（都是 shipped∪done），
  否則 done-run 的缺陷回饋會進 `by_kind` 卻漏出此指標（2026-06 dogfood 已命中的 gap）。
- `minor` 不計入分子；`low-coverage`/`perf`/`style` 不是「缺陷」，不進此指標（它們走 `by_kind` 趨勢）。

### 時間指標的缺欄位規則（非協商）

`mean_wall_seconds` 與 `parallel_speedup` 只以**帶有對應時間欄位**的 run 計算：

- 舊 trace（schema 升級前寫入）缺 `wall_seconds` / `agent_seconds` → **排除在分母外，絕不當 0 或 1**——
  當 0 會偽造「瞬間完成」、當 1 會偽造「並行無效」的假訊號。
- 窗口內**沒有任何** run 帶時間欄位 → 該指標為 `null`，不示警、不列入趨勢——
  與既有 `post_ship_defect_rate`／`mean_coverage` 的「分母為 0 → `null`，避免誤導」慣例同一原則：
  **缺資料就縮小分母或給 `null`，不編造數值**。

### `mean_wall_seconds` 趨勢示警

- **連續兩輪 `mean_wall_seconds` 上升** → 在報告列為 **🟡（系統性問題）**，提示「吞吐正在退坡」——
  搭配 `parallel_speedup` 與 `mean_agents_per_run` 判讀是並行失效還是任務本身變重。
- `mean_wall_seconds = null`（無時間資料）的輪次 → 不示警、不列入趨勢。

### `mean_coverage` 趨勢示警

`mean_coverage` 來自 trace 的 `stages[].metrics.coverage`（客觀 in-run 數字，見 run-trace.md Stage Metrics）。

- **連續兩輪 `mean_coverage` 下降** → 在報告列為 **💡（值得觀察）**，提示「覆蓋率正在退坡，gate 卻仍 PASS」。
- v1 **只示警、不自動立案**改 system（避免在少量樣本上過度反應）。把 metrics 退步升級為系統性提案留 v2。
- 無 coverage 資料（`mean_coverage = null`）→ 不示警、不列入趨勢。

> 報告必須對照上一輪指標秀趨勢——改動到底爬坡還是退坡。沒有 metric 不算改進。

## 8. 觸發與節奏

- `nightly-retro` cron trigger（見 `athena-trigger-dispatch` 的 `intake: hill-climb`）。
- 或門檻觸發：dispatcher 偵測「自 watermark 後新 trace ≥ N」時呼叫。
- 手動：直接呼叫本 skill。

## 9. 非協商規則

1. **唯讀 trace/feedback、只寫 proposal/metrics/state/regression** — 不碰 src/ 或 skill 本體。
2. **只對重複出現的模式立提案** — 一次性失敗不算系統性。
3. **每條診斷附 run_ids 證據**。
4. **每條提案附驗證方式**（skill-eval / re-point / skill-audit）。
5. **每輪更新 metrics 並對照趨勢**。
6. **不自動套用** — 採納提案走 `/athena-flow`（dogfooding）。退步 gate 是「能否採納」的客觀前置，**不**取代人最終拍板。
7. **資料不足（新 trace < 5）就停**。
8. **棘輪 append-only** — regression set 只增不減；`retired` 僅人工 + reason 且不刪檔（見 §5.5.3）。
9. **採納前必過退步 gate** — 已修好的 ≥ 門檻通過且不低於上輪 baseline，否則不採納（見 §5.5.2）。
