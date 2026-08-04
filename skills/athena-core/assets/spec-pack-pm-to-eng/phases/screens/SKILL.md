---
name: screens
description: >
  PM → 工程化流水線的階段 2a（前端 track，結構層 · 畫面 / 資訊架構）。讀取已釐清的需求，
  推導前端的「畫面與資訊架構」：畫面清單、導航 flow chart、扁平元件清單、每個畫面的 UI 狀態
  （loading / empty / error / success）。**這是前端結構層唯一階段——前端不畫 class diagram / 元件物件圖**；
  元件怎麼拆與型別契約由下游 ui_contract 與 Nuxt 4 實作承接。UX flow 以設計師的 `design/` HTML 為準，
  screens 只在無 `design/` 時補畫導航 flow chart。前端棧 = **Nuxt 4 + TypeScript strict（禁 any）**。
  由 pm-to-eng-flow 編排器在 target = frontend 或 fullstack 時以全新
  agent 觸發，也可獨立使用。前提：clarify 已 RESOLVED。
---

# screens · 畫面與資訊架構（階段 2 / 前端 track · 結構層）

> 流水線位置：score(gate) → clarify(gate) → **screens**(IA + 畫面 flow chart) → ui_contract → gherkin。
> 這是**前端結構層唯一階段**：定義**有哪些畫面、怎麼導航、畫面上有什麼**；元件怎麼拆與型別契約由下游 ui_contract（Nuxt 4）接手。**前端不畫 class diagram / 元件物件圖**。
> 前端技術棧：**Nuxt 4 + TypeScript strict**（畫面 = `pages/` 檔案式路由，導航 = `navigateTo` / `<NuxtLink>`）。完整規範見 `../pm-to-eng-flow/references/frontend-stack-conventions.md`。
> UX flow 真相：設計師的 `design/` HTML 已含 UX flow；screens 的導航 flow chart 在**無 `design/`** 時補位，有 `design/` 時則作為對照用的 route / 導航地圖。

## 先讀（references/）

- `references/sitemap-guide.md` — 導航圖 / sitemap mermaid 格式、UI 四態約定、**design/ 視覺稿對照原則**。
- `references/screen-breakdown.md` — 畫面 → 扁平元件清單的拆解準則（深層組合樹 / 型別契約交下游 ui_contract + Nuxt 4 實作）。
- `references/example-screen-map.md` — 完整示範（訂單退款）。

## 設計師流程（重要）

本團隊：**設計師先用 Claude Design 產出視覺稿（HTML/CSS，放 `design/`），前端再據此開發**。所以 screens **不是從零想畫面**——
- `design/` 存在 → 畫面 / 版面 / 可見元素以視覺稿為準，clarified.md 提供行為 / 規則 / 權限，兩者**對照**（衝突回報，見 sitemap-guide §0）。
- `design/` 不存在 → 純從 clarified.md 的使用情境推導。

## 輸入

- `specs/<slug>/clarify/clarified.md`（STATUS 必須為 RESOLVED）——行為 / 規則 / 權限真相。
- `specs/<slug>/design/`（選讀，**Claude Design 視覺稿**）——存在時為畫面 / 版面 / 元素真相。

## 輸出

- `specs/<slug>/screens/screen-map.md`
  - 畫面清單（可數、可辨識）
  - 導航圖（畫面之間怎麼走：入口 / 路徑 / 條件跳轉 / 返回；建議 mermaid）
  - 每個畫面的元件清單與 UI 狀態（loading / empty / error / success / 權限差異）
  - NFR 表態節（screen-map 末尾一節，全 track 一次）：a11y / i18n / 效能 / 瀏覽器支援四項，每項寫「採專案預設」或「本期不做 + 原因」或具體值（如「List 頁 >200 筆啟用虛擬捲動」）——強制顯式，不強制詳盡；有畫面級差異者附註於該畫面
- `specs/<slug>/handoffs/screens.md`（依 handoff-contract）

## 執行步驟

1. **盤點來源** — 讀 clarified.md（STATUS 必須 RESOLVED）；檢查 `design/` 有無 Claude Design 視覺稿。有稿 → 以稿盤畫面與元素，clarified.md 補行為 / 權限；無稿 → 從使用情境推導。
2. **萃取畫面清單** — 列出可數、可辨識的畫面，標 route（**Nuxt `pages/` 檔案式路由**，如 `pages/equipments/index.vue` → `/equipments`、`pages/equipments/[id].vue` → `/equipments/:id`）、進入點、是否需登入（`definePageMeta` / `auth` middleware）；modal / drawer 標明掛在哪個畫面。（`sitemap-guide.md` §1）
3. **畫導航 flow chart** — **有 `design/` 視覺稿時**：UX flow 以稿為準，本步僅整理「畫面 ↔ route」對照地圖（可省略重畫流程圖，或畫精簡版對照稿）。**無 `design/` 時**：補畫 mermaid `flowchart`，節點=畫面、邊=帶標籤的導航動作 / 條件；檢查無死路、無孤兒。（§2）
4. **列扁平元件清單** — 每畫面分「顯示元素 / 可操作元素」，可操作元素標出現 / 啟用條件與權限（下游 gherkin 場景來源）。**不做組合樹 / 元件物件圖**（元件拆分與型別契約交 ui_contract + Nuxt 4 實作）。（`screen-breakdown.md`）
5. **標 UI 四態** — 每個會載入資料的畫面標 loading / empty / error / success（不適用者明標 N/A + 原因）+ 權限差異。（§3）
6. **對照回報** — design/ 與 clarified.md 不一致處（稿有需求沒提 / 需求要稿沒畫）標 `待釐清` / `待補設計`，**不擅自選邊**。
7. **NFR 表態** — 於 screen-map 末尾列 a11y / i18n / 效能 / 瀏覽器四項，逐項顯式表態（採專案預設 / 本期不做 + 原因 / 具體值）。不確定的標「待釐清」，不留白。
8. **輸出** — 寫 `screens/screen-map.md` + `handoffs/screens.md`（畫面數、關鍵 IA 決策、待釐清 / 待補設計清單）。

## 完成判準

- [ ] clarified.md 的每個使用情境都有對應畫面 / route（Nuxt `pages/` 路徑）。
- [ ] UX flow 已對照 `design/`（有稿時）；無稿時導航 flow chart 每條邊有標籤、無死路、無孤兒。
- [ ] 每個會載入資料的畫面標齊 UI 四態（不適用者標 N/A + 原因）。
- [ ] 每個可操作元素標了出現 / 啟用條件與權限差異。
- [ ] design/ 有稿時：畫面 / 元素與視覺稿一致，不一致處已標 `待釐清` / `待補設計` 回報——**未擅自選邊**。
- [ ] screen-map 有 NFR 表態節，a11y / i18n / 效能 / 瀏覽器四項皆顯式（無留白），不做者附原因。
- [ ] handoff 含畫面數、關鍵 IA 決策、待釐清 / 待補設計清單。

## references/

- `sitemap-guide.md` — 導航圖格式、UI 四態約定、design/ 對照原則。
- `screen-breakdown.md` — 畫面 → 扁平元件清單準則。
- `example-screen-map.md` — 完整示範（訂單退款）。

## 非協商規則

1. 只依 clarified.md（行為）+ design/ 視覺稿（畫面）設計，**不自行擴張需求 / 設計皆未提及的畫面或功能**。
2. **不擅自選邊** — clarified.md 與 design/ 衝突時，標記回報，不替使用者裁決。
3. 本階段只做 IA + 扁平元件清單，**不做組合樹 / props / 元件物件圖**（前端不畫 class diagram；元件拆分與型別契約是 ui_contract + Nuxt 4 實作的事）。
4. route / 導航一律以 **Nuxt 4 慣例**描述（`pages/` 檔案式路由、`navigateTo`、`<NuxtLink>`、`definePageMeta`），不用 vue-router 手寫設定字樣（見 frontend-stack-conventions）。
5. clarified.md 的 STATUS 非 RESOLVED 時，回報並中止。
6. 探索既有前端 codebase 時優先用 graphify；探索結果回頭跟使用者確認，不擅自當定論。
