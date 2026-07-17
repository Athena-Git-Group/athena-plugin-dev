---
name: score
description: >
  PM → 工程化流水線的階段 0（最前置硬閘門）。對 PM 需求文件做「可譯性評分」，
  客觀判斷它能否被轉成工程化文件。依 target 載入維度：後端（資料 / API / 規則）或
  前端（情境 / 畫面 / 互動 / 視覺 / 導航）；fullstack 兩套都評。借用 athena-audit-requirement
  的 rubric 與 0–3 計分，但姿態相反：本 stage 是硬閘門，寫機器可解析的 VERDICT。
  BLOCKED → 退回 PM 補件；PASS → 進入 clarify，缺口清單即 clarify 的提問議程。
  由 pm-to-eng-flow 編排器以全新 agent 觸發，也可獨立使用。
---

# score · 可譯性評分（階段 0 / 最前置硬閘門）

> 流水線位置：**score(gate) → clarify(gate) → 結構層 → 契約層 → 規格層**。
> 整條流水線的第一道閘：先確認文件「撐得起轉換」，才讓 clarify 開始，讓後續澄清收斂。

## target 決定維度

- `backend` → 載入 `references/rubric-backend.md`（餵 db_table / api / gherkin）
- `frontend` → 載入 `references/rubric-frontend.md`（餵 screens / ui_contract / gherkin）
- `fullstack` → 兩份都載入，各自評分、各自產缺口清單；任一邊必備 = 0 → 整體 BLOCKED

## 與 athena-audit-requirement 的關係（別搞混）

- **借**：rubric 維度 + 0–3 計分結構。
- **不借姿態**：那兩支 audit 是輔導性、不 gate、不寫 verdict、PM-facing；
  **本 stage 是硬閘門、寫機器 verdict、是流水線內的 gate**。

## 先讀

- Read `references/rubric.md` — 共用核心（設計原則、計分尺度、裁決規則）。
- 依 target 載入維度檔：`references/rubric-backend.md` / `references/rubric-frontend.md`（fullstack 兩份）。

## 輸入

- `specs/<slug>/source/requirement.md`（原始 PM 需求，不可變）

## 輸出

- `specs/<slug>/score/score-report.md`
  - **第一行必為** `VERDICT: BLOCKED` / `VERDICT: PASS-WITH-GAPS` / `VERDICT: PASS-CLEAN`
  - 其後：逐維度評分表（每分都引用原文證據或標「未找到」）+ **缺口清單**（所有 `<3` 維度，供 clarify 當議程）
  - fullstack：前端、後端各一張評分表與缺口清單
- `specs/<slug>/handoffs/score.md`（依 handoff-contract）

## 執行步驟

1. 確認 target（backend / frontend / fullstack）。
2. 讀需求原文。
3. 依對應 rubric 逐維度評 0–3，**每個分數都引用原文證據**或標「未找到」。
4. 套用 rubric 的裁決規則 → 決定 VERDICT。
5. 寫 `score-report.md`（VERDICT 開頭 + 評分表 + 缺口清單）。
6. 寫 `handoffs/score.md`。

## 閘門語意（硬閘門）

- `BLOCKED` → 編排器**停流程、退回 PM 補件**，不得進入 clarify。
- `PASS-WITH-GAPS` / `PASS-CLEAN` → 進入 clarify；缺口清單交給 clarify 當提問議程。

## 非協商規則

1. **客觀、引證據** — 每個維度分數都要有原文依據或「未找到」標記，不憑感覺。
2. **規則式裁決** — 依 rubric 規則決定 VERDICT，不自訂加權總分。
3. **必備維度缺（=0）即 BLOCKED** — 不放水讓撐不起的文件硬進 clarify。
4. `score-report.md` 第一行必為 `VERDICT:`，編排器只認這一行。
5. **只評分、不腦補** — 缺的標缺，不替 PM 補內容。
