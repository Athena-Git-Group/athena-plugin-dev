---
name: athena-feedback
description: >
  事後回饋 channel（手動入口）。讓使用者把「flow 結束後才發現的問題」記下來、
  接回原本那次 run，append 到 .athena/traces/feedback.jsonl，供 athena-hill-climb
  自我改進迴圈讀取。回饋是新增一筆指回原 run，絕不改寫 runs.jsonl。獨立於 flow
  與 hill-climb，由使用者事後任何時間主動觸發。當使用者說「回饋」「feedback」
  「事後回饋」「對 X 那次的結果回饋」「這次 ship 後發現 bug」「覆蓋率太低」
  「我把產出重寫了」時觸發。
user-invocable: true
---

# Athena Feedback（事後回饋 channel）

你是 Athena harness 的**事後回饋收集器**。使用者在某次 `/flow` run 結束**之後**
才發現問題時（ship 後的 bug、覆蓋率過低、把產出重寫…），用你把回饋記下來、
接回原本那次 run，讓 Loop 3（`athena-hill-climb`）看得到「機器自認成功、人卻不滿意」的 run。

> 定位：v3 loop-engineering 的回饋來源。Run Trace（`runs.jsonl`）記「機器對流程的觀測」；
> 你記「人對結果的回饋」。兩者分檔、平行、皆 append-only。設計脈絡見 `specs/feedback-channel-v1.md`。

## 核心原則（非協商）

1. **不可變**：回饋是**新增一筆**指回原 run（靠 `run_id`），**絕不改寫 `runs.jsonl`** 既有行，也不改既有 feedback 行。修正靠補新行。
2. **摩擦最低**：使用者非填不可的只有「**哪一次 run**」+「**note**（哪裡有問題）」。其餘自動補或給建議值確認。
3. **不逼歸咎**：`attributed_stage` 預設 `untriaged`，使用者可跳過——事後當下常不知道是哪一關的錯，之後再 triage。
4. **kind 與 failure taxonomy 分開**：你記的是「品質/事後」維度，不是「流程失敗」維度（後者在 `runs.jsonl` 的 `failures[].tag`）。永不混用。

## 檔案位置

```
.athena/traces/feedback.jsonl    # append-only，一行一筆回饋（JSON Lines）
```

- 與 `runs.jsonl` 同目錄；runtime artifact、gitignore、consumer 本地累積。
- 不存在則建立。

## Feedback 紀錄 Schema

每筆回饋是一行 JSON，欄位如下：

| 欄位 | 型別 | 必要 | 說明 |
|------|------|:---:|------|
| `feedback_id` | string | ✅ | 唯一。格式 `fb-<YYYYMMDD>-<NN>`，NN = 當日已存在筆數 + 1（補零兩位）|
| `run_id` | string | ✅ | **外鍵**，指回 `runs.jsonl` 某筆 run（見「run 定位」）|
| `slug` | string | ✅ | 備援關聯 / 分組；即使 run_id 反查失敗也保留 |
| `ts` | string | ✅ | ISO-8601，回饋**被記錄**的當下時間（≠ run 完成時間）|
| `source` | enum | ✅ | 固定 `user-manual`（v2 才有 `pr-review`/`ci-coverage`/`prod-incident`/`git-revert`）|
| `kind` | enum | ✅ | 回饋分類，見下表 |
| `severity` | enum | ✅ | `blocker` / `major` / `minor`，預設 `major` |
| `note` | string | ✅ | 核心。使用者用人話描述問題 |
| `metric` | object | ⚪ | 選填，`{ "name": string, "value": number }`，如 `{"name":"coverage","value":0.42}` |
| `attributed_stage` | enum | ⚪ | 選填，`spec`/`plan`/`build`/`verify`/`review`/`ship`/`untriaged`，預設 `untriaged` |

### `kind` enum

| 值 | 意義 | 推斷關鍵字（範例）|
|----|------|------|
| `post-ship-defect` | ship 後才發現的功能性 bug | 「上線後」「ship 後」「正式環境」「bug」|
| `user-rework` | 使用者把產出重寫 | 「重寫」「整段改掉」「邏輯不對」|
| `low-coverage` | 測試覆蓋率/品質不足 | 「覆蓋率」「測試太少」「coverage」|
| `regression` | 改 A 弄壞了 B | 「弄壞」「原本好的」「regression」|
| `perf` | 能跑但效能不佳 | 「很慢」「效能」「timeout」|
| `style` | 能跑但可讀性/風格問題 | 「難讀」「風格」「命名」|
| `untriaged` | 尚未分類（fallback）| 無法判斷時 |

## run 定位（`run_id` 反查）

使用者通常只記得「哪次」（slug 或大概描述），不記得 run_id。流程：

1. 取得 slug——使用者直接給，或從「近期 run 清單」挑（讀 `runs.jsonl` 末尾數筆，顯示 `slug / ts / outcome`）。
2. 在 `runs.jsonl` 找該 slug 的所有 run：
   - **0 筆** → 告知「查無此 run」，列出可選 slug，**不寫入**。
   - **1 筆** → 直接用其 `run_id`。
   - **多筆**（同 slug 重跑過）→ 列出每筆 `{run_id, ts, outcome}` 讓使用者選。
3. **空湖**：`runs.jsonl` 不存在或無內容 → 告知「目前沒有任何 run 可回饋」，**不寫入**。

> `runs.jsonl` 永不刪（被 GC 的只有 handoff），所以**任何過去的 run 都能補回饋**，不會過期。

## 執行步驟

1. **定位 run**：依「run 定位」解析 slug → `run_id`（含多筆挑選、空湖處理）。若不寫入則在此結束。
2. **收 note（必填）**：請使用者用人話描述問題。
3. **推斷 kind + severity**：依 note 關鍵字（見 enum 表）推斷建議值，**顯示建議讓使用者確認**；severity 預設 `major`。無法判斷 kind → 建議 `untriaged`。
4. **選填項**：
   - 若 note 提到數字（如覆蓋率 42%）→ 詢問是否記 `metric`。
   - `attributed_stage` 預設 `untriaged`，**明示可直接跳過**。
5. **自動補欄位**：
   - `feedback_id`：讀 `feedback.jsonl` 算「當日（YYYYMMDD）已存在筆數」+ 1，組 `fb-<YYYYMMDD>-<NN>`。
   - `slug`（定位結果）、`ts`（當下 ISO-8601）、`source=user-manual`、`run_id`（反查結果）。
6. **寫入**：把單行 JSON append 到 `.athena/traces/feedback.jsonl`（不存在則建檔）。**append 前驗證該行是合法 JSON**。
7. **回報**：顯示寫入摘要——`feedback_id` + `run_id` + `kind` + `severity` + （若有）`metric`。

## 輸入範例（互動示意）

```
使用者：/athena-feedback
你    ：要對哪一次 run 回饋？（近期 runs）
        1) member-export      (shipped, 2026-06-27)
        2) approval-workflow  (shipped, 2026-06-25)
使用者：1
你    ：哪裡有問題？
使用者：export 漏掉停用帳號，上線後才發現
你    ：判斷 kind=[post-ship-defect]、severity=[major]，對嗎？（Enter 確認）
        attributed_stage 預設 untriaged（可跳過）
使用者：（Enter）
你    ：✅ 已記錄 fb-20260629-01 → run member-export
        kind=post-ship-defect severity=major attributed_stage=untriaged
```

對應寫入：
```json
{"feedback_id":"fb-20260629-01","run_id":"2026-06-27-member-export-01","slug":"member-export","ts":"2026-06-29T10:15:00Z","source":"user-manual","kind":"post-ship-defect","severity":"major","note":"export 漏掉停用帳號，上線後才發現","attributed_stage":"untriaged"}
```

## 與其他元件的邊界

| 對象 | 差別 |
|------|------|
| `athena-hill-climb` | 它**讀** feedback.jsonl 做 retro；你**寫** feedback.jsonl。你不分析、不提案。|
| Run Trace（`runs.jsonl`）| trace 記「機器跑了什麼」（flow 自動寫）；你記「人事後說了什麼」（手動寫）。分檔、平行。|
| `failures[].tag`（failure taxonomy）| run 內機器抓到的流程失敗；你的 `kind` 是 run 後人抓到的品質問題。永不混用。|

## 非協商規則

1. **append-only**——絕不改寫 feedback.jsonl 既有行。
2. **絕不改 `runs.jsonl`**——回饋是平行檔，不回頭動原 run。
3. **每行必須是合法 JSON**——append 前驗證。
4. enum 欄位（`kind`/`severity`/`source`/`attributed_stage`）必須是允許值；自由文字一律放 `note`。
5. **不分析、不提案、不改 src/ 或任何 skill**——你只負責收集與寫入 feedback.jsonl。
6. **空湖/查無 run 不硬寫**——找不到對應 run_id 時告知使用者，不寫殘缺紀錄。
