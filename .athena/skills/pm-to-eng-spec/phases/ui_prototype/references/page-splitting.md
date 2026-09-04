# 頁面切分 · 入口頁 · flow 覆蓋判準

> `ui_prototype` phase 決定「要生幾頁、哪些畫面各自成頁、哪些用同頁狀態切換」時的判準。
> 本檔為本 repo 原創，判準借鑑自 CH3-SDD-workflow `skills/ui-plan` 的
> 「高保真靜態頁面切分與 Flow 覆蓋判準」（未複製原檔，授權標註見 pack 根 `VENDORED.md`）。

## 判準 1 · 入口頁固定為 `index.html`，且它本身是產品（MUST）

多頁雛形一律以 `specs/<slug>/ui_prototype/index.html` 為入口。
入口頁必須是**產品流程的第一個真實畫面**（列表頁、儀表板、搜尋頁、登入後首頁……），
不是 sitemap、不是說明頁、不是純連結目錄。

單頁就能承載整個 flow 的需求，也**至少要有** `index.html` 一頁且可操作。

✅ 好的（入口頁承擔真實產品任務）

```md
index.html          → 設備清單（搜尋 + 篩選 + 進入詳情）
equipment.html      → 設備詳情與維護紀錄
maintenance.html    → 新增維護紀錄表單與送出結果
```

❌ 壞的（入口頁退化成檔案目錄）

```md
index.html
- Link: equipment.html
- Link: maintenance.html
```

## 判準 2 · 一頁一主任務；狀態變化用同頁切換（MUST）

切分的單位是**使用者的主任務**，不是 UI 狀態：

- 主任務不同（瀏覽 / 編輯 / 結果確認）→ **各自一頁**。
- 同一主任務的 UI 四態（loading / empty / error / success）→ **同頁**以原生 JS 切換，
  不要為每個狀態各開一個 `.html`。
- modal / drawer 掛在它所屬的頁面上（沿用 `screen-map.md` 的歸屬），不獨立成頁。

命名：`<screen>.html` 用 `screen-map.md` 的畫面代號的 kebab-case（例如
「設備維護紀錄」→ `maintenance-log.html`），讓對應表能逐列比對。

✅ `equipment.html` 內以 `data-state="empty|loading|error|ready"` 切換四態
❌ `equipment-loading.html` / `equipment-empty.html` / `equipment-error.html` 三個檔

## 判準 3 · 覆蓋從入口到主要結果的完整流程（MUST）

雛形至少要覆蓋本次需求的**主流程入口 → 關鍵中間狀態 → 主要結果**，
外加至少一條**失敗 / 錯誤路徑**（素材取自 `spec.md`「邊界情況」段）。

頁數需要裁切時，**優先保完整流程**，不是保視覺最吸睛的片段。
被裁掉的畫面寫進 `ui-plan.md` 的「已知落差」並在 handoff 列出理由。

✅ 「1. 查詢設備 → 2. 檢視詳情 → 3. 填維護紀錄 → 4. 送出成功 ／ 4b. 驗證失敗回饋」
❌ 「只做一張漂亮的送出成功頁，沒有入口、沒有表單、沒有失敗路徑」

## 判準 4 · 對應表是切分的證據（MUST，本 pack 特有）

`ui-plan.md` 必須有一張逐列對應表，讓 review 者不看 HTML 就能查覆蓋：

```md
| screen-map 畫面 | 雛形檔案 | 主任務 | 承接的 UI 狀態 | ui-contract 元件 |
|-----------------|---------|--------|---------------|-----------------|
| 設備清單 | `index.html` | 查詢與篩選 | loading / empty / ready | SearchBar, EquipmentTable |
| 設備詳情 | `equipment.html` | 檢視與進入維護 | ready / error | EquipmentCard, MaintenanceList |
```

- `screen-map.md` 的每個畫面都要出現在左欄；沒有對應檔案的，該列寫
  「同頁狀態切換於 `<file>`」或「未涵蓋 — <理由>」。
- 右欄的元件名必須真的出現在 `ui-contract.md`，不自行發明元件名。

## 判準 5 · 雛形必須可操作（SHOULD）

不連真後端，但要讓 review 者能**操作**：按鈕可點、頁面可互跳、表單可輸入、
狀態可切換、錯誤提示會出現。互動一律用原生 JS（`onclick`、`location.href`、
`classList` / `data-state` 切換），不引框架、不引 CDN。

✅ 可操作的最小片段

```html
<button onclick="location.href='equipment.html?id=EQ-001'">檢視設備</button>
<p class="error" hidden id="err">請先輸入設備編號</p>
```

❌ 截圖式頁面：`<img src="screen.png">` + 「之後大概長這樣」

## 判準 6 · 有視覺稿時，切分以稿為準（MUST）

`specs/<slug>/design/` 存在時，頁面邊界、版面與元素以視覺稿為準；
`screen-map.md` 提供導航與狀態、`ui-contract.md` 提供綁定與驗證。
三者不一致處在 `ui-plan.md` 標 `待釐清` / `待補設計`，**不擅自選邊**。
視覺稿目錄是唯讀的：本階段對它零改動，雛形檔案也不放進該目錄。
