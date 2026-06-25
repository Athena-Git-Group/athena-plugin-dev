# Hill-Climb — 契約與 schema

> `athena-hill-climb`（Loop 3）的詳細契約。設計脈絡見
> `docs/design/loop-engineering-design.md` Part 3。輸入是 Step 1 的 Run Trace
> （`athena-flow/references/run-trace.md`）。

## 1. 輸入：Run Trace

讀 `.athena/traces/runs.jsonl`。關鍵欄位（完整 schema 見 run-trace.md）：

- `point`（verdict/score/dimensions）、`weight`、`route`
- `stages[]`（gate / retries / agents）
- `failures[]`（**tag** = failure taxonomy、`affected_phase`、`note`）
- `outcome`、`human_interventions`、`trigger`（source 類別）

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

每條診斷**必附** trace 證據（`run_ids` 清單）。

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
{"ts":"2026-06-25T02:00:00Z","window_runs":18,"gate_first_pass_rate":0.72,"verify_retry_rate":0.22,"scope_accuracy":0.83,"mean_agents_per_run":5.1,"human_intervention_rate":0.28,"by_tag":{"integration-mismatch":4,"scope-underestimate":3}}
```

| 指標 | 定義 |
|------|------|
| `gate_first_pass_rate` | 各 stage gate 第一次就 PASS 的比率 |
| `verify_retry_rate` | 進入 verify-retry 的 run 比率 |
| `scope_accuracy` | point verdict 與實際是否 escalate 相符的比率 |
| `mean_agents_per_run` | 平均 agent 數（成本代理指標） |
| `human_intervention_rate` | 有人工中途介入的 run 比率 |
| `by_tag` | 本窗口各 failure tag 次數 |

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
