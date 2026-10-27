---
name: score
description: >
  PM → 工程化流水線的最前置硬閘門。對 PM 需求文件做「可譯性評分」，
  客觀判斷它能否被轉成工程化文件。依 target 載入維度：後端（資料 / API / 規則）或
  前端（情境 / 畫面 / 互動 / 視覺 / 導航）；fullstack 兩套都評。借用 athena-audit-requirement
  的 rubric 與 0–3 計分，但姿態相反：本 stage 是硬閘門，寫機器可解析的 VERDICT。
  BLOCKED → 退回 PM 補件；PASS → 進入 clarify，缺口清單即 clarify 的提問議程。
  由 pm-to-eng-flow 編排器以全新 agent 觸發，也可獨立使用。
---

# score · 可譯性評分（最前置硬閘門）

> 流水線位置：**score(gate) → clarify(gate) → specify(gate) → 結構層 → 契約層 → 規格層**。
> 整條流水線的第一道閘：先確認文件「撐得起轉換」，才讓 clarify 開始，讓後續澄清收斂。

## 與 athena-audit-requirement 的關係（別搞混）

- **借**：rubric 維度 + 0–3 計分結構。
- **不借姿態**：那兩支 audit 是輔導性、不 gate、不寫 verdict、PM-facing；
  **本 stage 是硬閘門、寫機器 verdict、是流水線內的 gate**。

## 輸入

- `specs/<slug>/source/requirement.md`（原始 PM 需求，不可變）
- `target`（由編排器傳入：`backend` / `frontend` / `fullstack`）——決定依哪份 rubric 評分。

## 輸出

- `specs/<slug>/score/score-report.md`
  - **第一行必為** `VERDICT: BLOCKED` / `VERDICT: PASS-WITH-GAPS` / `VERDICT: PASS-CLEAN`
  - 其後：逐維度評分表（每分都引用原文證據或標「未找到」）+ **缺口清單**（所有 `<3` 維度，供 clarify 當議程）
  - fullstack：前端、後端各一張評分表與缺口清單
- `specs/<slug>/handoffs/score.md`（依 `phases/common/rules/handoff-contract.md`）

## SOP

### Phase 1 -- 依 target 評分

1. READ 讀需求原文 `specs/<slug>/source/requirement.md`，並確認編排器傳入的 target（`backend` / `frontend` / `fullstack`）。
2. READ 先讀 `rules/rubric.md`，掌握兩邊共用的設計原則、計分尺度與裁決規則；再依 target 讀對應的維度檔——`target = backend` 讀 `rules/rubric-backend.md`；`target = frontend` 讀 `rules/rubric-frontend.md`；`target = fullstack` 兩份都讀，各自評分、各自產缺口清單。
3. THINK 依剛讀到的維度表逐維度評 0–3 分，**每個分數都要引用需求原文的那一句證據**，找不到就標「未找到」，不得憑感覺打分。
4. THINK 套用 `rules/rubric.md` 的裁決規則（任一「必備」維度 = 0 → `BLOCKED`；全部維度 = 3 → `PASS-CLEAN`；其餘 → `PASS-WITH-GAPS`）決定 VERDICT；fullstack 時任一邊必備維度 = 0 即整體 `BLOCKED`。

### Phase 2 -- 寫產出與收尾

1. WRITE 把 VERDICT 寫在 `specs/<slug>/score/score-report.md` 第一行，其後接逐維度評分表與缺口清單（所有 `<3` 維度）；fullstack 時前端、後端各寫一張評分表與一份缺口清單。
2. WRITE 依 `phases/common/rules/handoff-contract.md` 寫 `specs/<slug>/handoffs/score.md`。

## 完成判準（硬閘門）

- `BLOCKED` → 編排器**停流程、退回 PM 補件**，不得進入 clarify。
- `PASS-WITH-GAPS` / `PASS-CLEAN` → 進入 clarify；缺口清單交給 clarify 當提問議程。
- `score-report.md` 第一行必為 `VERDICT:` 標記，編排器只認這一行。

## 非協商規則

1. **客觀、引證據** — 每個維度分數都要有原文依據或「未找到」標記，不憑感覺。
2. **規則式裁決** — 依 `rules/rubric.md` 的裁決規則決定 VERDICT，不自訂加權總分。
3. **必備維度缺（=0）即 BLOCKED** — 不放水讓撐不起的文件硬進 clarify。
4. `score-report.md` 第一行必為 `VERDICT:` 標記，編排器只認這一行。
5. **只評分、不腦補** — 缺的標缺，不替 PM 補內容。
