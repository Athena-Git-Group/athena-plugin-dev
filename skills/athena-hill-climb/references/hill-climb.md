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

## 6. Proposals 檔 — `.athena/hill-climb/<date>-proposals.md`

格式見 `assets/proposals.template.md`。要點：

- 每條提案有 id（P1/P2…）、嚴重度（✅/🟡/💡）、診斷、trace 證據、目標物件、建議改動、驗證方式。
- **不用 PASS/FAIL**——避免被誤當 CI gate。
- 採納欄位讓人勾選；採納後該提案轉成一張 `/athena-flow` intake。

## 7. Metrics — `.athena/hill-climb/metrics.jsonl`

每輪 retro append 一行，讓「hill」可量測：

```json
{"ts":"2026-06-25T02:00:00Z","window_runs":18,"gate_first_pass_rate":0.72,"verify_retry_rate":0.22,"scope_accuracy":0.83,"mean_agents_per_run":5.1,"human_intervention_rate":0.28,"post_ship_defect_rate":0.11,"by_tag":{"integration-mismatch":4,"scope-underestimate":3},"by_kind":{"post-ship-defect":2,"low-coverage":1}}
```

| 指標 | 定義 |
|------|------|
| `gate_first_pass_rate` | 各 stage gate 第一次就 PASS 的比率 |
| `verify_retry_rate` | 進入 verify-retry 的 run 比率 |
| `scope_accuracy` | point verdict 與實際是否 escalate 相符的比率 |
| `mean_agents_per_run` | 平均 agent 數（成本代理指標） |
| `human_intervention_rate` | 有人工中途介入的 run 比率 |
| `post_ship_defect_rate` | 事後缺陷率，定義見下方公式（分母為 0 時為 `null`）|
| `by_tag` | 本窗口各 failure tag 次數 |
| `by_kind` | 本窗口各 feedback kind 次數 |

### `post_ship_defect_rate` 公式

```
post_ship_defect_rate =
    (窗口內 outcome=shipped 且 ≥1 筆 kind ∈ {post-ship-defect, regression}
     且 severity ∈ {blocker, major} 的 distinct run_id 數)
  ÷ (窗口內 outcome=shipped 的 distinct run_id 數)
```

- **窗口**：與其他 metrics 相同（自上次 watermark 後）。
- **分母為 0**（窗口內無 shipped run）→ 值為 `null`，避免「沒 ship 過卻顯示 0% 缺陷」的誤導。
- **只算 `shipped`**：post-ship 顧名思義只對已 ship 的 run 有意義。
- `minor` 不計入分子；`low-coverage`/`perf`/`style` 不是「缺陷」，不進此指標（它們走 `by_kind` 趨勢）。

> 報告必須對照上一輪指標秀趨勢——改動到底爬坡還是退坡。沒有 metric 不算改進。

## 8. 觸發與節奏

- `nightly-retro` cron trigger（見 `athena-trigger-dispatch` 的 `intake: hill-climb`）。
- 或門檻觸發：dispatcher 偵測「自 watermark 後新 trace ≥ N」時呼叫。
- 手動：直接呼叫本 skill。

## 9. 非協商規則

1. **唯讀 trace、只寫 proposal/metrics/state** — 不碰 src/ 或 skill。
2. **只對重複出現的模式立提案** — 一次性失敗不算系統性。
3. **每條診斷附 run_ids 證據**。
4. **每條提案附驗證方式**（skill-eval / re-point / skill-audit）。
5. **每輪更新 metrics 並對照趨勢**。
6. **不自動套用** — 採納提案走 `/athena-flow`（dogfooding）。
7. **資料不足（新 trace < 5）就停**。
</content>
