---
name: ui_prototype
description: >
  PM → 工程化流水線的前端 / fullstack track 階段（上游為 ui_contract，下游為 gherkin）。
  把 screen-map 與 ui-contract 落地成可點擊的**高保真靜態 HTML 雛形**：先定稿
  ui-plan.md（介面範圍、視覺方向、頁面清單與換頁關係、假資料原則、狀態與資訊揭露），
  再依它生出 index.html 與各畫面頁。畫面內容必須是**產品本身**而不是說明文件；
  假資料一律取自 spec.md 的「資料維度與範例資料」段（與 gherkin 同源）。
  只產靜態 HTML/CSS 與必要的原生 JS 互動——不產 Vue / Nuxt 元件、不接真 API、不進 src/。
  設計師視覺稿目錄（`specs/<slug>/design/`）是**唯讀輸入**，本階段對它零改動。
  backend track 不執行本階段。
  本 phase 為本 repo 原創（非 vendored），判準借鑑自 CH3-SDD-workflow 的 ui-plan skill，
  授權標註見 pack 根目錄的 VENDORED.md。
---

# ui_prototype · 高保真靜態雛形（前端 / fullstack track · 無 gate）

> 流水線位置：score(gate) → clarify(gate) → specify(gate) → 結構層 → 契約層
> （`screens` → `ui_contract`）→ **`ui_prototype`** → `gherkin`。
> **本階段不是 gate**：它不擋 `gherkin`；artifact 缺失才由編排器判
> `FAIL — ui_prototype 產出缺失 #skill-defect`。
> **只在 target = frontend / fullstack 執行**；backend track 完全不觸發本階段。

## 兩種 HTML 的職責分離（先讀懂這張表，這是本階段最容易做錯的地方）

| 路徑 | 誰提供 | 角色 | 何時存在 |
|------|--------|------|---------|
| `specs/<slug>/design/` | **人**（設計師用 Claude Design 畫的視覺稿） | **輸入**：畫面 / 版面 / 元素的視覺真相 | 選用，可能不存在 |
| `specs/<slug>/ui_prototype/` | **本階段** | **輸出**：可點擊的高保真靜態雛形 | 前端 / fullstack track 必有 |

兩者都是 HTML，但方向相反：

- 設計師視覺稿目錄是**唯讀**的。本階段**不得**對 `specs/<slug>/design/`
  做任何修改、新增或刪除，也不得把雛形檔案放進該目錄。
- 本階段的 artifact 只落在 `specs/<slug>/ui_prototype/`，屬 spec stage 的 Write 範圍
  （spec 殼的路徑式白名單涵蓋 `specs/**`，含 `.html`）。
- 本階段是 `screens` / `ui_contract` 的**下游**：`screens` **不會**讀本階段的 artifact
  （否則就是雞生蛋——雛形要等畫面清單定了才畫）。雛形只往下游流：
  `gherkin` 前端 track 可選讀它做視覺斷言。

## 定位（為什麼獨立成一個 phase）

`screen-map.md` 與 `ui-contract.md` 是**文字契約**：說清楚有哪些畫面、有哪些元件與綁定，
但沒有任何人能「看到」它。本階段把文字契約變成**可點擊的產品雛形**，讓 PM / 設計師 /
前端在寫任何一行 Nuxt 程式碼之前就能 review 節奏、資訊密度與流程完整性。

它仍然是 spec stage 的一部分——**雛形不是實作**：不接真 API、不建置、不進 `src/`。

## 先讀（references/）

- `references/page-splitting.md` — 頁面切分、入口頁與 flow 覆蓋判準（先讀）。
- `references/prototype-boundary.md` — 雛形 vs 實作計畫的邊界判準（哪些資訊該留在
  `ui-plan.md`、哪些才能進畫面）。
- `references/prototype-skeleton.md` — 入口頁 / 內頁的骨架與內容密度要求（含可照抄的片段）。
- （選讀增益）`.agents/constitution/` 若存在（`CONSTITUTION.md`、`shared.md`、
  `skills/ui-plan/*.md`），把其中規則視為額外約束套用。
  **缺這個目錄是常態，缺檔照常執行本 phase，不得因此停止、不得回報缺失。**

## 輸入

- `specs/<slug>/specify/spec.md`（**唯一需求真源**；首行 STATUS 必須為 `READY`）——
  **特別是其「資料維度與範例資料」段**：雛形的假資料一律取自這裡（與 `gherkin` 同源，
  **不另造第三份假資料**）；「邊界情況」提供錯誤 / 空 / 衝突狀態的素材。
- `specs/<slug>/screens/screen-map.md`（**必要**）——畫面清單、導航、每畫面的元件與 UI 四態。
- `specs/<slug>/ui_contract/ui-contract.md`（**必要**）——元件、綁定、驗證與呈現格式。
- `specs/<slug>/design/`（選讀，**設計師 Claude Design 視覺稿 · 唯讀輸入**）——
  存在時**視覺方向以稿為準**，雛形是稿面的可點擊化；不一致處標 `待釐清` / `待補設計`，
  **不擅自選邊**（沿用 `screens` 非協商規則 2 的既有形狀）。

## 輸出

- `specs/<slug>/ui_prototype/ui-plan.md` — 控制平面，必含節：
  介面範圍 / 視覺方向 / 頁面清單與換頁關係 / 假資料原則 / 狀態與資訊揭露 /
  與 `screen-map` · `ui-contract` 的對應表 / 已知落差。
- `specs/<slug>/ui_prototype/index.html` — 入口頁（**產品入口本身**，不是 sitemap 或連結目錄）。
- `specs/<slug>/ui_prototype/<screen>.html` — 每個關鍵畫面一頁，或在同頁以狀態切換承接
  （判準見 `references/page-splitting.md`）。
- `specs/<slug>/handoffs/ui_prototype.md`（依 handoff-contract）——含頁面數、
  flow 覆蓋對照、`待釐清` / `待補設計` 清單、未涵蓋的畫面與理由。

## 執行步驟

1. [ ] 確認 target = frontend / fullstack。backend → **不執行本階段**，直接回報「不適用本 track」。
2. [ ] 確認 `specify/spec.md` 首行為 `STATUS: READY`，且 `screens/screen-map.md`、
       `ui_contract/ui-contract.md` 皆存在非空；否則回報並中止。
3. [ ] 盤點視覺方向：檢查 `specs/<slug>/design/` 有無視覺稿。
       有稿 → 版面 / 色彩 / 元素以稿為準；無稿 → 依 `ui-contract` 的元件與
       `references/prototype-skeleton.md` 的密度要求自訂一致的視覺語言。
4. [ ] 盤點假資料：從 `spec.md`「資料維度與範例資料」段抄出每個核心實體的範例資料
       （**逐筆照抄，不改值、不另造**）。上游筆數不足時照實用，缺的標 `待補資料`。
5. [ ] **先定稿 `ui-plan.md`**：頁面清單（每頁對應 `screen-map` 的哪個畫面）、每頁主任務、
       進入條件、主要操作、成功流轉、失敗回饋、換頁關係、狀態切換策略、
       以及與 `screen-map` · `ui-contract` 的逐項對應表。
6. [ ] 依 `ui-plan.md` 生 `index.html`：入口頁本身要是產品的一部分
       （判準見 `references/page-splitting.md` 判準 1）。
7. [ ] 依 `ui-plan.md` 生其餘 `<screen>.html`，覆蓋**從入口到主要結果**的完整流程，
       含關鍵中間狀態（loading / empty / error / success 以純前端方式呈現）。
8. [ ] 逐頁自檢 `references/prototype-boundary.md`：畫面上**只有**使用者真的會看到的內容；
       備註、元件樹、TODO、review 說明一律留在 `ui-plan.md`。
9. [ ] 覆蓋回查：`ui-plan.md` 列的每個關鍵畫面都有對應 `.html`，或已在同頁狀態切換中
       被清楚承接；有遺漏立即補齊，補不了的列入 handoff。
10. [ ] `design/` 與 `spec.md` / `ui-contract` 不一致處標 `待釐清` / `待補設計`，不替使用者裁決。
11. [ ] 寫 `handoffs/ui_prototype.md`。

## 缺口升級協議（headless；本 pack 無互動訪談、無 slash 委派）

本 pack 在 spec stage shell 內執行，**不能**互動提問，也**不能**呼叫其他 skill 的
slash 指令。缺口一律走既有的檔案協議，**不另立第二套協議、不另開新檔**：

1. 只有**會改變頁面邊界、主流程主幹、視覺方向或可見資訊**的缺口才算高影響。
2. 高影響缺口每輪只取最高影響的 **1–3 題**，以 PM-friendly 措辭**追寫（append）**到既有的
   `specs/<slug>/clarify/questions.md`
   （**三支共用此檔**：clarify / specify / ui_prototype；題號 `Q<n>` 全檔連號、標題行標 `[<phase>]` 來源——**題號與標記契約見 pack 根 `SKILL.md`「`clarify/questions.md` 共用契約」**），
   附建議選項與影響說明。
3. 低影響缺口（次要文案、次級互動、可延後的呈現選項）在畫面上以合理預設呈現，
   並在 `ui-plan.md` 的「已知落差」節記一行，**不升級**。
4. 本階段**不是 gate**：升級缺口後仍把可做的頁面做完，不留半套，本階段不自行中止流水線。
   **編排器的裁決已明定**（pack 根 `SKILL.md` 執行程序第 5 步的註記、Gate Verdict 映射表
   對應列、非協商規則 9）：本階段追寫 `questions.md` **不改變 Gate Verdict、不停止**，
   但編排器**必須**把「追寫 N 題待澄清」記進最終 handoff 的 Risks，不得靜默吞掉。

## 完成判準

- [ ] `ui-plan.md` 先定稿，且七節（介面範圍 / 視覺方向 / 頁面清單與換頁關係 / 假資料原則 /
      狀態與資訊揭露 / 對應表 / 已知落差）皆存在非空。
- [ ] `index.html` 存在非空，且它本身是產品入口，不是 sitemap / 說明頁 / 純連結目錄。
- [ ] `screen-map.md` 的每個關鍵畫面都有對應 `.html`，或在同頁以狀態切換被承接
      （對應表逐列可查）。
- [ ] 雛形覆蓋從入口到主要結果的完整流程，含關鍵中間狀態與至少一條失敗 / 錯誤路徑。
- [ ] 可操作：按鈕可點、頁面可互跳、表單可輸入、狀態切換可見（純前端假資料）。
- [ ] 假資料逐筆對得上 `spec.md`「資料維度與範例資料」段，**未自造第三份資料**。
- [ ] 畫面上沒有分析備註 / 元件樹 / TODO / review 說明（那些在 `ui-plan.md`）。
- [ ] 沒有 Vue / Nuxt 元件檔、沒有 build 設定、沒有真 API 呼叫、沒有 `src/` 下的檔案。
- [ ] `design/` 有稿時：版面與元素與稿一致，不一致處已標 `待釐清` / `待補設計`——**未擅自選邊**。
- [ ] handoff 含頁面數、flow 覆蓋對照、待釐清清單。

## 斷點續跑

`specs/<slug>/ui_prototype/ui-plan.md` 存在非空、且該目錄下**至少一個 `.html` 存在非空**
→ 本 phase **跳過不重跑**（沿用 wrapper 執行程序第 0 步）。
只有 `ui-plan.md` 而無任何 `.html` → 從執行步驟 6 續跑，不重寫 `ui-plan.md`。

## references/

- `page-splitting.md` — 頁面切分 / 入口頁 / flow 覆蓋判準。
- `prototype-boundary.md` — 雛形 vs 實作計畫的邊界判準（`ui-plan.md` 與 `.html` 各放什麼）。
- `prototype-skeleton.md` — 入口頁 / 內頁的骨架與內容密度要求（說明 + 可照抄片段）。

## 非協商規則

1. **先 plan 再 HTML** —— `ui-plan.md` 必須先定稿，`.html` 依它生成。
   **不得**先隨手畫 HTML 再回頭補 plan（單一溯源會不成立）。
2. **畫面是產品，不是文件** —— `.html` 只放使用者真的會看到的內容；分析備註、元件樹、
   實作 TODO、欄位解說一律留在 `ui-plan.md`。
3. **假資料同源** —— 一律取自 `spec.md`「資料維度與範例資料」段，逐筆照抄、不改值；
   **不另造第三份假資料**（第一份在 `spec.md`、第二份是 `gherkin` 的 `例子` 表）。
4. `specs/<slug>/design/` 是**唯讀輸入**：本階段**不得**對它做任何修改、新增或刪除，
   雛形檔案也不得放進該目錄。與稿不一致處標 `待釐清` / `待補設計`，**不擅自選邊**。
5. **本階段的 artifact 不回流上游** —— `screens` / `ui_contract` 不讀 `ui_prototype/`；
   雛形只往下游流（`gherkin` 選讀）。不得要求上游 phase 依賴本階段的結果。
6. **只做靜態雛形** —— 靜態 HTML/CSS + 必要的原生 JS；**不產** Vue / Nuxt 元件、
   不接真 API、不加建置設定、不寫入 `src/`、不安裝任何套件、不觸外部網路
   （字型 / 圖片一律用系統字型與純 CSS 佔位，不引 CDN）。
7. **backend track 不執行本階段** —— target = backend 時不建目錄、不產任何檔。
8. `specs/<slug>/screens/screen-map.md` 或 `specs/<slug>/ui_contract/ui-contract.md`
   缺失或為空時，**回報並中止**——不得憑 `spec.md` 自行推導畫面清單。
9. `specs/<slug>/specify/spec.md` **缺失、為空、或首行非 `STATUS: READY`** 時，**回報並中止**——
   **不得**改讀 `clarify/` 的訪談產出、**不得**回頭讀 `source/requirement.md` 自行腦補、
   **不得**產出空 artifact 後宣告完成。
10. `.agents/constitution/` 是**選讀增益**：存在則套用，**缺檔照常執行**，不得因缺它停止或 FAIL。
