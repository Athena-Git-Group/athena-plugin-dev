---
name: screens
description: >
  PM → 工程化流水線的前端 track（結構層 · 畫面 / 資訊架構）。讀取已釐清的需求，
  推導前端的「畫面與資訊架構」：畫面清單、導航 flow chart、扁平元件清單、每個畫面的 UI 狀態
  （loading / empty / error / success）。**這是前端結構層唯一階段——前端不畫 class diagram / 元件物件圖**；
  元件怎麼拆與型別契約由下游 ui_contract 與 Nuxt 4 實作承接。UX flow 以設計師的 `design/` HTML 為準，
  screens 只在無 `design/` 時補畫導航 flow chart。前端棧 = **Nuxt 4 + TypeScript strict（禁 any）**。
  由 pm-to-eng-flow 編排器在 target = frontend 或 fullstack 時以全新
  agent 觸發，也可獨立使用。前提：specify 已 READY。
---

# screens · 畫面與資訊架構（前端 track · 結構層）

> 流水線位置：score(gate) → clarify(gate) → specify(gate) → **screens**(IA + 畫面 flow chart) → ui_contract → gherkin。
> 這是**前端結構層唯一階段**：定義**有哪些畫面、怎麼導航、畫面上有什麼**；元件怎麼拆與型別契約由下游 ui_contract（Nuxt 4）接手。**前端不畫 class diagram / 元件物件圖**。
> 前端技術棧：**Nuxt 4 + TypeScript strict**（畫面 = `pages/` 檔案式路由，導航 = `navigateTo` / `<NuxtLink>`）。完整規範見 `../common/rules/frontend-stack-conventions.md`。
> UX flow 真相：設計師的 `design/` HTML 已含 UX flow；screens 的導航 flow chart 在**無 `design/`** 時補位，有 `design/` 時則作為對照用的 route / 導航地圖。

## 設計師流程（重要）

本團隊：**設計師先用 Claude Design 產出視覺稿（HTML/CSS，放 `design/`），前端再據此開發**。所以 screens **不是從零想畫面**——
- `design/` 存在 → 畫面 / 版面 / 可見元素以視覺稿為準，spec.md 提供行為 / 規則 / 權限，兩者**對照**（衝突回報，見 `templates/sitemap-guide.md` §0）。
- `design/` 不存在 → 純從 spec.md 的使用者故事與情境推導。

## 輸入

- `specs/<slug>/specify/spec.md`（首行 STATUS 必須為 READY）——行為 / 規則 / 權限真相
  （使用者故事、故事專屬 FR / NFR、全域需求、邊界情況）。
- `specs/<slug>/design/`（選讀，**Claude Design 視覺稿**）——存在時為畫面 / 版面 / 元素真相。

## 輸出

- `specs/<slug>/screens/screen-map.md`
  - 畫面清單（可數、可辨識）
  - 導航圖（畫面之間怎麼走：入口 / 路徑 / 條件跳轉 / 返回；建議 mermaid）
  - 每個畫面的元件清單與 UI 狀態（loading / empty / error / success / 權限差異）
  - NFR 表態節（screen-map 末尾一節，全 track 一次）：a11y / i18n / 效能 / 瀏覽器支援四項，每項寫「採專案預設」或「本期不做 + 原因」或具體值（如「List 頁 >200 筆啟用虛擬捲動」）——強制顯式，不強制詳盡；有畫面級差異者附註於該畫面
- `specs/<slug>/handoffs/screens.md`（依 `phases/common/rules/handoff-contract.md`）

## SOP

### Phase 1 -- 盤點來源、定畫面清單

1. READ 讀 `specify/spec.md`（首行 STATUS 必須為 READY），取得行為 / 規則 / 權限真相；檢查 `specs/<slug>/design/` 是否存在 Claude Design 視覺稿。`spec.md` 缺失、為空或首行非 `STATUS: READY` 時，回報並中止——不得改讀 `clarify/` 的訪談產出或 `source/requirement.md` 自行腦補。
2. THINK 決定本次走「有稿對照」或「無稿推導」：有稿時以稿盤點畫面與可見元素、spec.md 補行為與權限；無稿時純由 spec.md 的使用者故事與情境推導畫面。
3. WRITE 先讀 `templates/sitemap-guide.md` §1 的畫面清單表格式，列出可數、可辨識的畫面，標 route（**Nuxt `pages/` 檔案式路由**，如 `pages/equipments/index.vue` → `/equipments`、`pages/equipments/[id].vue` → `/equipments/:id`）、進入點、是否需登入（`definePageMeta` / `auth` middleware）；modal / drawer 標明掛在哪個畫面。

### Phase 2 -- 畫導航、列元件、標狀態

1. WRITE 先讀 `templates/sitemap-guide.md` §2：有 `design/` 視覺稿時，UX flow 以稿為準，本步僅整理「畫面 ↔ route」對照地圖（可省略重畫流程圖，或畫精簡版對照稿）；無 `design/` 時補畫 mermaid `flowchart`，節點=畫面、邊=帶標籤的導航動作 / 條件，檢查無死路、無孤兒。
2. WRITE 先讀 `rules/screen-breakdown.md`，為每個畫面分「顯示元素 / 可操作元素」列扁平清單，可操作元素標出現 / 啟用條件與權限（下游 gherkin 場景來源）；**不做組合樹 / 元件物件圖**，元件拆分與型別契約交 ui_contract + Nuxt 4 實作。
3. WRITE 先讀 `templates/sitemap-guide.md` §3，為每個會載入資料的畫面標齊 loading / empty / error / success 四態（不適用標 N/A + 原因）與權限差異。
4. THINK 對照 `design/` 與 spec.md 的不一致處（稿有需求沒提 / 需求要稿沒畫），標 `待釐清` / `待補設計`，不擅自選邊。

### Phase 3 -- NFR 表態與輸出

1. WRITE 於 screen-map 末尾列 a11y / i18n / 效能 / 瀏覽器支援四項，逐項顯式表態（採專案預設 / 本期不做 + 原因 / 具體值）；不確定的標「待釐清」，不留白。
2. WRITE 參考 `templates/example-screen-map.md` 的完整示範，把以上結果寫成 `specs/<slug>/screens/screen-map.md`，並依 `phases/common/rules/handoff-contract.md` 寫 `specs/<slug>/handoffs/screens.md`（含畫面數、關鍵 IA 決策、`待釐清` / `待補設計` 清單）。

## 完成判準

- spec.md 的每個使用者故事 / 使用情境都有對應畫面 / route（Nuxt `pages/` 路徑）。
- UX flow 已對照 `design/`（有稿時）；無稿時導航 flow chart 每條邊有標籤、無死路、無孤兒。
- 每個會載入資料的畫面標齊 UI 四態（不適用者標 N/A + 原因）。
- 每個可操作元素標了出現 / 啟用條件與權限差異。
- design/ 有稿時：畫面 / 元素與視覺稿一致，不一致處已標 `待釐清` / `待補設計` 回報——未擅自選邊。
- screen-map 有 NFR 表態節，a11y / i18n / 效能 / 瀏覽器四項皆顯式（無留白），不做者附原因。
- handoff 含畫面數、關鍵 IA 決策、`待釐清` / `待補設計` 清單。

## 非協商規則

1. **不擅自擴張範圍** — 只依 spec.md（行為）+ design/ 視覺稿（畫面）設計，不自行擴張需求 / 設計皆未提及的畫面或功能。
2. **不擅自選邊** — spec.md 與 design/ 衝突時，標記回報，不替使用者裁決。
3. 本階段只做 IA + 扁平元件清單，**不做組合樹 / props / 元件物件圖**（前端不畫 class diagram；元件拆分與型別契約是 ui_contract + Nuxt 4 實作的事）。
4. route / 導航一律以 **Nuxt 4 慣例**描述（`pages/` 檔案式路由、`navigateTo`、`<NuxtLink>`、`definePageMeta`），不用 vue-router 手寫設定字樣（見 `phases/common/rules/frontend-stack-conventions.md`）。
5. `specify/spec.md` 的 STATUS 非 READY 時，回報並中止。
6. 探索既有前端 codebase 時優先用 graphify；探索結果回頭跟使用者確認，不擅自當定論。
7. `specs/<slug>/specify/spec.md` **缺失、為空、或首行非 `STATUS: READY`** 時，**回報並中止**——
   **不得**改讀 `clarify/` 的訪談產出、**不得**回頭讀 `source/requirement.md` 自行腦補、
   **不得**產出空 artifact 後宣告完成。
