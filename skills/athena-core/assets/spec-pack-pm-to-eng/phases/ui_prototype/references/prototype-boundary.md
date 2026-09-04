# 雛形 vs 實作計畫的邊界判準

> `ui_prototype` phase 判斷「哪些資訊該留在 `ui-plan.md`、哪些才能進 `.html` 畫面、
> 哪些根本不屬於 spec stage」時的判準。
> 本檔為本 repo 原創，判準借鑑自 CH3-SDD-workflow `skills/ui-plan` 的
> 「靜態網站雛形與實作計畫邊界判準」（未複製原檔，授權標註見 pack 根 `VENDORED.md`）。

## 三層邊界一覽

| 層 | 檔案 | 放什麼 | 不放什麼 |
|----|------|--------|---------|
| 控制平面 | `ui_prototype/ui-plan.md` | 介面範圍、視覺方向、頁面清單與換頁關係、假資料原則、狀態與資訊揭露、對應表、已知落差 | 完整 HTML、CSS 全文 |
| 產品雛形 | `ui_prototype/*.html` | 使用者真的會看到的標題、欄位、狀態、CTA、錯誤訊息、結果摘要、假資料 | 分析備註、元件樹、TODO、review 說明、規格條號 |
| 實作（**不屬本階段**） | build stage 的 `src/` | Vue / Nuxt 元件、composable、真 API、build 設定、套件安裝 | — |

## 判準 1 · 先 plan 後 HTML，單一溯源（MUST）

`ui-plan.md` 定稿後才生 `.html`。**不得**先隨手畫幾頁 HTML 再回頭補 plan——
那會讓「頁面為什麼這樣切」失去溯源，改一次流程就要同時改所有檔案。

流程衝突時的修正方向固定為：先改 `ui-plan.md`，再依它改 `.html`。

✅ 「1. 定稿 ui-plan.md（定義三頁與換頁關係）→ 2. 依 plan 生三頁 HTML」
❌ 「1. 先做三頁 HTML → 2. 之後看要不要補 ui-plan.md」

## 判準 2 · HTML 只放產品內容（MUST）

畫面上出現的每一段文字都必須是**產品真的會顯示給使用者的內容**。
給開發者 / reviewer 看的資訊一律留在 `ui-plan.md`。

✅ 產品語氣

```html
<h1>確認維護紀錄後送出</h1>
<p>送出後將更新設備狀態，並通知該區域負責人</p>
<button>送出維護紀錄</button>
```

❌ 把說明文件塞進畫面

```html
<h1>畫面三：維護紀錄表單</h1>
<p>這頁的主要目的是讓使用者填寫紀錄，對應 FR-004。</p>
<p>TODO: 之後要換成真正的產品 UI。</p>
```

例外：純示意的假資料標記（例如表格角落的「示範資料」小字）可保留一處，
但**不得**逐欄加註解。

## 判準 3 · 雛形不是實作（MUST）

- 只有靜態 HTML/CSS + 必要的原生 JS；**不產** `.vue` / `.ts` 元件檔。
- 不呼叫真 API（`fetch` 只能打本頁內的假資料常數，或直接省略）。
- 不加 `package.json`、build 設定、lint 設定；不安裝套件。
- 不引外部 CDN（字型、CSS 框架、圖示庫皆不引）——離線開檔就要能看。
- 圖片用純 CSS 佔位塊或 inline SVG，不引外部圖檔。

✅ `<div class="thumb" aria-label="設備照片"></div>` + CSS 漸層佔位
❌ `<script src="https://cdn.tailwindcss.com"></script>`

## 判準 4 · 元件命名與契約對齊，但不做元件拆分（MUST，本 pack 特有）

雛形的區塊命名（class / `data-*`）**沿用** `ui-contract.md` 的元件名，
讓下游前端一眼對得上；但本階段**不做**元件拆分決策、不定 props 型別、
不畫組合樹——那是 `ui_contract` 已經做完的事與 build stage 的實作決策。

✅ `<section class="EquipmentTable" data-state="ready">`（名稱來自 ui-contract）
❌ 在 HTML 註解裡寫「這裡應該拆成 EquipmentTable / EquipmentRow 兩個元件，props 為……」

## 判準 5 · 落差顯式，不靜默補完（MUST）

上游沒給的資訊（文案、狀態、權限差異、視覺方向）**不腦補成既定事實**：

- 畫面上以合理預設呈現，並在 `ui-plan.md` 的「已知落差」節記一行
  （落差內容 / 目前用什麼預設 / 影響哪一頁）。
- 會改變頁面邊界或主流程的落差，走 SKILL.md 的「缺口升級協議」追寫
  `clarify/questions.md`。
- `design/` 與 `spec.md` / `ui-contract.md` 不一致處標 `待釐清` / `待補設計`，不替使用者裁決。
