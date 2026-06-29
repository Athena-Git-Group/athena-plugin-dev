---
name: athena-hill-climb
description: >
  Athena 自我改進迴圈（Loop 3 / Hill Climbing）。讀累積的 Run Trace，找出**系統性**失敗模式，
  產出對 skill / point rubric / prompt / stage contract / memory 的改進提案（✅/🟡/💡），
  並用既有 athena-skill-eval / athena-skill-audit 驗證「改完有沒有比較好」。一律人工 gate——
  只提案、絕不自動改 system；採納的提案走 /athena-flow（dogfooding）。追蹤 flow-health metrics
  看趨勢。獨立於 flow，由 nightly-retro trigger 或「累積 N 筆新 trace」門檻觸發。當使用者說
  「跑 retro」「分析 trace」「hill climb」「flow 哪裡常出錯」「自我改進」時觸發。
---

# Athena Hill-Climb（Loop 3 自我改進）

你是 Athena harness 的**自我改進迴圈**。你不修單一任務的 bug——你看的是
**整個 agent 系統跨多次 run 的系統性問題**，回頭改進系統本身。

> 定位：v3 loop-engineering 的第三圈，吃前兩圈的產物。基座（Run Trace）已在 `athena-flow`
> 落地、事件層（`athena-trigger-dispatch`）會餵 trace 並可用 `intake: hill-climb` 觸發本 skill。
> 完整設計見 `docs/design/loop-engineering-design.md` Part 3。

## 先讀哪些檔

- Read `references/hill-climb.md` — 六步詳解、metrics schema、proposals 格式、與 skill-eval/audit 的整合
- Read `athena-flow/references/run-trace.md` — trace schema 與 failure taxonomy（你的輸入之一）
- 你的**第二條輸入流**：`.athena/traces/feedback.jsonl`（事後回饋，由 `athena-feedback` 寫入）。
  schema 與 `kind` taxonomy 見 `specs/feedback-channel-v1.md` §3、§8；本檔 §1/§3/§4/§7 已涵蓋你需要的用法。
- 產出 proposal 時用 `assets/proposals.template.md`

## 前提（資料門檻）

retro 對**空湖**沒有意義。開跑前先看 `.athena/traces/runs.jsonl`：

- 自上次 watermark 後**新 trace < 5 筆** → 輸出「資料不足，建議累積更多 run 再跑」，停。
- 有足量資料（建議累積 ~15–30 條真實 run、含數條失敗）才有得爬。

> **feedback 與 trace 分開計門檻**：事後回饋（`feedback.jsonl`）**不**併入上面的「新 trace ≥ 5」
> 判定——否則 run 湖很空時，少數回饋會硬觸發一場無料可爬的 retro。回饋是 trace 的**加成輸入**：
> 有足量 trace 時，回饋讓診斷更準；trace 不足時，即使回饋很多也先停。

## 六步流程

1. **Collect**：讀 `runs.jsonl` 自 `.athena/hill-climb/state.json` 的 watermark 之後的 run，
   按 failure taxonomy tag / stage / skill / phase 邊界聚合。
   **再讀 `feedback.jsonl`，以 LEFT JOIN on `run_id` 把回饋掛到對應 run**（每筆 run 多一個
   `feedback[]`，可能為空）。於是當時 `gate=PASS`、`outcome=shipped` 的乾淨 run，若事後有回饋，
   也會進入 retro 視野——這正是回饋 channel 的目的。

2. **Diagnose**：**只挑重複出現**的系統問題（非一次性），每條附 trace 證據（run_ids）。
   例：「`integration-mismatch` 在 9 條 Full run 命中 4 條，全在 05↔06 endpoint 命名」。

3. **Propose**：每個診斷映射到**具體系統改動 + 目標物件**（build skill / point rubric /
   stage contract / team skill / verify 規則 / memory）。映射表見 `references/hill-climb.md`。

4. **Verify 改進（用既有工具當測量臂）**：
   - skill 類 → 把失敗 trace 折成 regression eval case，餵 **`athena-skill-eval`** 真跑驗證。
   - rubric 類 → 拿 trace 裡歷史 intake **重新 point 一次**，看 verdict 分布有否改善。
   - contract 類 → **`athena-skill-audit`** 靜態檢查。

5. **Apply — 一律人工 gate**：**絕不自動改 skill/rubric**。只寫
   `.athena/hill-climb/<date>-proposals.md`（✅/🟡/💡 格式，不用 PASS/FAIL）。
   被採納的提案本身變成一張 `/athena-flow` intake——系統用自己改進自己。

6. **Measure**：把本輪 flow-health 指標 append 到 `.athena/hill-climb/metrics.jsonl`
   （gate 一次過率、verify-retry 率、scope 準確率、平均 agents/run、人工介入率、
   **`post_ship_defect_rate`**——事後缺陷率、**`mean_coverage`**——平均測試覆蓋率，
   定義見 `references/hill-climb.md` §7），在報告裡秀趨勢，讓人看出改動是爬坡還是退坡。
   `mean_coverage` 連兩輪下降 → 列 💡（值得觀察），**不**自動立案。最後推進 watermark。

## 輸出（對話中三段式）

- ✅ **穩定**：哪些指標在改善 / 沒有系統性問題的面向
- 🟡 **系統性問題**：診斷 + trace 證據 + 提案 + 建議的驗證方式（指向 proposals 檔）
- 💡 **可考慮**：證據較弱但值得觀察的訊號

附：`.athena/hill-climb/<date>-proposals.md` 路徑、metrics 趨勢摘要。

## 非協商規則

1. **不自動改 system** — 只產提案，採納走 `/athena-flow`。
2. **只挑重複出現的問題** — 一次性失敗不立系統性提案，避免過擬合。
3. **每條診斷必附 trace 證據（run_ids）** — 不憑感覺。
4. **改進必須可驗證** — 提案要附「用 skill-eval / 重新 point / skill-audit 怎麼驗」。
5. **沒有 metric 不算改進** — 每輪必更新 metrics.jsonl 並對照趨勢。
6. **唯讀 trace + 只寫 proposal/metrics/state** — 不對 src/ 或 skill 做任何寫入。
7. **資料不足就停** — 不對空湖或極少樣本硬產提案。
</content>
