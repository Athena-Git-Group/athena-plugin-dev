# Phase 07: Frontend E2E（mock mode）

## 審查進度

- [ ] 07.1 相關規格已審查 — **簽名**: ___
- [ ] 07.2 交付物已審查 — **簽名**: ___

## 目的 (What)

以 Phase 06 建好的前端為對象，用 `/athena-frontend-e2e-activity-testplan`
從 Activity Diagrams + Feature Files 產出**正式的 E2E 測試計畫**，
並以 Chrome 在 **MSW mock 模式**下逐步執行，直到全數通過。

與 Phase 06 的 Chrome Test Guard 的差異：Guard 是 build 階段的快速煙霧驗證；
本 Phase 產出**結構化、可重用的測試計畫**——Phase 08 會用同一份計畫換 real backend 重跑。

**IMPL_IMPACT 感知**：若 Phase 06 走 Targeted Fix，本 Phase 仍必須完整重跑測試計畫
（局部修復不可只做局部驗證）。

**依賴**：Phase 06 必須在 `done/` 中。
**可與 Phase 05 平行**：本 Phase 只依賴 06，與後端 track 互不依賴。

## 相關規格

| # | 規格 | 來源 | 說明 |
|---|------|------|------|
| 1 | Activity Diagrams | Phase 01 交付 | 測試計畫的結構依據（路線、分支順序） |
| 2 | Feature Files（含 Examples） | Phase 03 交付 | `When` = 使用者操作、`Then` = 預期回饋 |
| 3 | api.yml | Phase 04 交付 | MSW mock data 的契約基準 |

## 交付物

carry-on Step 07.2 觸發時：

### 1. 產出測試計畫

LOAD `/athena-frontend-e2e-activity-testplan`，從 Activity Diagrams + Feature Files 推導：

1. 列出所有頁面路徑
2. 每頁面從 `.feature` 的 `When` 提取所有使用者操作（點擊、填寫、提交、導航）
3. 每頁面從 `.feature` 的 `Then` 提取預期回饋（Toast、redirect、UI 狀態、資料顯示）
4. 按 Activity Diagram 流程順序排成端到端操作序列

**每個可互動的 UI 元素都必須被測試計畫覆蓋。**

### 2. 啟動 dev server（mock 模式）

```bash
cd ${PROJECT_ROOT}/frontend && npm run dev &
```

確認 `NEXT_PUBLIC_MOCK_API=true`（MSW 攔截生效），等待 server ready。

### 3. Chrome 逐步執行測試計畫

使用 `mcp__claude-in-chrome__*` 工具，按測試計畫逐步操作：

1. 每個頁面：`navigate` → 確認載入成功（無白屏）
2. 讀取 console messages：確認無 error 層級訊息
3. 每個可互動元素：實際點擊 / 填寫 / 提交
4. 每個操作後的預期回饋：確認 UI 正確更新

**測試計畫中的每個步驟都必須實際執行，不可跳過。**

### 4. 發現 bug → 立即修復 → 重新驗證

- console error → 定位 → 修改程式碼 → 重新整理 → 驗證修復
- UI 不如預期 → 修改元件 → 重新整理 → 驗證修復
- **修復後必須從頭重跑受影響的測試步驟**，確認無級聯破壞
- 重複此迴圈直到所有步驟全部通過

### 5. 全部通過後停止 dev server

| # | 交付物 | 路徑 | 狀態 |
|---|--------|------|------|
| 07.1 | E2E 測試計畫 | `${PLAN_DIR}/e2e-testplan.md` | PENDING |
| 07.2 | Chrome E2E 結果（mock mode） | 全通過 | PENDING |

### 驗收點

- [ ] 測試計畫覆蓋所有頁面與所有可互動元素
- [ ] Chrome E2E mock 模式全數通過
- [ ] console 無 error 層級訊息
- [ ] 測試計畫已存檔（Phase 08 換 real backend 重跑用）
