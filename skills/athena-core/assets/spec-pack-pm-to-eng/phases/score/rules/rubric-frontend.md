# 可譯性評分 rubric — 前端維度（Frontend）

> 共用的設計原則、計分尺度、裁決規則見 `rubric.md`。本檔只放前端維度與 0–3 錨點。
> 前端維度 = screens / ui_contract / gherkin（前端）三產物輸入需求的聯集。
> 維度承襲 `athena-audit-requirement-frontend` 的視角（情境 / 畫面 / 互動 / 視覺 / 導航）。

## 七個維度

| # | 維度 | 餵給 | 必備 | 評什麼 |
|---|------|------|------|--------|
| 1 | Use Scenarios 使用情境 | screens, gherkin | ✅ | 誰在什麼情境用、想達成什麼（user goal / flow） |
| 2 | Screen Inventory 畫面清單 | screens | ✅ | 有哪些畫面 / 頁面，是否可數、可辨識 |
| 3 | Navigation 導航行為 | screens | ✅ | 畫面之間怎麼走：入口 / 路徑 / 條件跳轉 / 返回 |
| 4 | Interactive Elements 互動元素 | ui_contract, gherkin | ✅ | 每個畫面有哪些可操作元件、各觸發什麼後果 |
| 5 | UI States & Data Binding 狀態與資料綁定 | screens, ui_contract | — | loading / empty / error / success；每畫面顯示/送出什麼資料 |
| 6 | Visual Acceptance 視覺驗收 | gherkin | — | 版面 / 文案 / 可見狀態的可驗證判準 |
| 7 | Terminology Consistency 術語一致性 | 全部 | — | 同一概念前後同名、無互相矛盾 |

> 必備維度（BLOCKED 判定依據）：1 Use Scenarios、2 Screen Inventory、3 Navigation、4 Interactive Elements。

## 各維度 0–3 錨點

**1. Use Scenarios 使用情境**
- 0：看不出誰在用、想達成什麼。1：模糊提及。2：主要情境可辨、部分缺。3：角色 × 目標 × 情境清楚。

**2. Screen Inventory 畫面清單**
- 0：看不出任何畫面。1：暗示有畫面但不可數。2：主要畫面可列、仍有缺。3：畫面清單可數可辨識。

**3. Navigation 導航行為**
- 0：完全沒講畫面怎麼走。1：隱約。2：主要路徑可推，條件跳轉 / 返回缺。3：入口 / 路徑 / 條件 / 返回清楚。

**4. Interactive Elements 互動元素**
- 0：看不出可操作元件。1：提到按鈕但無觸發後果。2：主要互動可列、部分後果缺。3：每個互動與其觸發後果清楚。

**5. UI States & Data Binding 狀態與資料綁定**
- 0：無。1：只提 happy 畫面。2：部分狀態（loading/empty/error）或部分資料來源。3：狀態齊備且每畫面顯示/送出資料綁定清楚。

**6. Visual Acceptance 視覺驗收**
- 0：無可驗證視覺判準。1：零星。2：部分畫面有版面 / 文案判準。3：可見狀態的驗收判準齊備。

**7. Terminology Consistency 術語一致性**
- 0：同概念多名且互相矛盾。1：明顯不一致。2：少數不一致。3：術語前後一致、無矛盾。
