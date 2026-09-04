# 入口頁 / 內頁的骨架與內容密度要求

> `ui_prototype` phase 寫 `.html` 時的骨架與密度判準。
> 本檔為本 repo 原創：CH3-SDD-workflow `skills/ui-plan` 的 6 份 HTML template
> **未逐檔複製進本 pack**（澄清結論 Q1 = B「改寫吸收」），改以**說明 + 最小片段**表述
> ——片段是拿來對齊結構與密度的，不是拿來整頁照抄的骨架檔。
> 授權標註見 pack 根 `VENDORED.md`。

## 共通：每一頁都要有的東西

1. 完整文件外殼：`<!DOCTYPE html>`、`<html lang="zh-Hant">`、`<meta charset="UTF-8">`、
   `<meta name="viewport" content="width=device-width, initial-scale=1.0">`、
   `<title>` 寫**產品畫面名稱**（不是「畫面三」這種編號）。
2. **樣式內嵌**在同一份 `.html` 的 `<style>`：一頁一檔、離線可開、不引外部資源
   （不 CDN、不共用 `.css`，避免多檔相對路徑在 review 時斷鏈）。
3. 以 CSS 自訂屬性集中視覺 token，讓多頁視覺一致：

```html
<style>
  :root {
    --bg: #0f1115; --panel: #171a21; --primary: #4f8cff;
    --text: #e8ecf3; --muted: #93a0b4; --danger: #ff6b6b; --ok: #37d67a;
    --radius: 16px; --gap: 20px;
  }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: system-ui, "Noto Sans TC", sans-serif;
         background: var(--bg); color: var(--text); }
  .panel { background: var(--panel); border-radius: var(--radius); padding: 24px; }
</style>
```

   有 `specs/<slug>/design/` 視覺稿時，token 值取自稿面（色彩 / 圓角 / 間距），
   不自行另定一套；無稿時用上例這類一致的暗色或淺色語彙，全頁面共用同一組 token。
4. 響應式最低要求：主要容器用 `width: min(1200px, 100% - 32px)` 這類寫法，
   窄視窗不橫向溢出。不要求完整斷點設計。
5. 可讀性最低要求：正文 ≥ 14px、行高 ≥ 1.5、互動元素有 hover / focus 可見樣式。

## 入口頁（`index.html`）的密度要求

入口頁是**產品的第一個真實畫面**（見 `page-splitting.md` 判準 1），至少要有：

- 一個標題區：產品 / 功能名稱 + 一句價值敘述（產品語氣，不是文件語氣）。
- **主要工作區**：真的承載主任務的內容——清單、儀表板、搜尋結果、卡片群。
  裡面必須放 `spec.md` 的**範例資料**（≥ 3 筆時就放 3 筆，不要只放 1 筆示意）。
- 至少一個**主 CTA**，點了會導到下一頁。
- 導航線索：使用者能看出還有哪些畫面（頂欄 / 側欄 / 卡片入口），
  但**不是**單純的連結清單。

```html
<header class="topbar">
  <strong>設備維護</strong>
  <nav><a href="index.html">設備清單</a><a href="maintenance-log.html">維護紀錄</a></nav>
</header>
<section class="panel">
  <h1>快速找到需要保養的設備</h1>
  <p class="muted">依區域與狀態篩選，直接進入維護紀錄填寫</p>
  <input placeholder="搜尋設備編號或名稱" />
  <button onclick="location.href='equipment.html?id=EQ-001'">檢視設備</button>
</section>
<table class="panel">
  <tr><th>設備編號</th><th>名稱</th><th>狀態</th></tr>
  <tr><td>EQ-001</td><td>空壓機 A</td><td><span class="tag warn">待保養</span></td></tr>
  <tr><td>EQ-002</td><td>輸送帶 B</td><td><span class="tag ok">正常</span></td></tr>
  <tr><td>EQ-003</td><td>冷卻塔 C</td><td><span class="tag danger">異常</span></td></tr>
</table>
```

（表格內的值一律換成 `spec.md`「資料維度與範例資料」段的真實範例資料。）

## 內頁（`<screen>.html`）的密度要求

至少要有：

- 頂欄（含返回入口的路徑）+ 畫面標題 + 目前狀態。
- 主要內容面板：`ui-contract.md` 列的元件都要在畫面上找得到對應區塊。
- 次要資訊面板（明細、歷程、關聯資料）——避免整頁只有一張表單。
- 主要操作與**失敗回饋**：驗證訊息、衝突提示、送出結果至少各一處。
- UI 四態以同頁切換承接（見下節）。

## 狀態切換的最小模式

用 `data-state` + 原生 JS 切換，不引框架：

```html
<section id="list" data-state="ready">
  <div data-when="loading" class="skeleton">載入中…</div>
  <div data-when="empty" class="muted">目前沒有符合條件的設備</div>
  <div data-when="error" class="danger">讀取失敗，請重新整理</div>
  <div data-when="ready"><!-- 真實假資料內容 --></div>
</section>
<button onclick="setState('empty')">模擬無資料</button>
<script>
  function setState(s) { document.getElementById('list').dataset.state = s; }
</script>
<style>
  [data-when] { display: none; }
  [data-state="loading"] [data-when="loading"],
  [data-state="empty"]   [data-when="empty"],
  [data-state="error"]   [data-when="error"],
  [data-state="ready"]   [data-when="ready"] { display: block; }
</style>
```

「模擬」用的切換按鈕可以留在畫面上（review 需要），但要做成小型次要控制項
（例如頁尾的一排 chip），**不得**寫成「TODO / 說明文字」——那違反
`prototype-boundary.md` 判準 2。

## 假資料的擺法

- 資料常數集中在頁尾一個 `<script>` 的 `const DEMO = [...]`，或直接寫進 HTML 表格。
- 每筆資料的欄位與值都對得上 `spec.md`「資料維度與範例資料」段（逐筆照抄、不改值）。
- 上游筆數不足 3 筆時照實放，並在 `ui-plan.md` 的「已知落差」記一行 `待補資料`，
  **不自行編造**。

## 自檢（每頁寫完問一次）

- [ ] 離線用瀏覽器直接開得起來、沒有 404、沒有外部請求。
- [ ] 主 CTA 點下去有反應（換頁或狀態變化）。
- [ ] 畫面上沒有規格條號、TODO、元件樹、review 說明。
- [ ] 表格 / 清單裡是真的範例資料，不是 `foo` / `bar` / `Lorem ipsum`。
- [ ] 窄視窗（~400px）不橫向溢出。
