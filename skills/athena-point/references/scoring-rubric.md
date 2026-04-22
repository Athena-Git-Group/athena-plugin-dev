# Athena Point Scoring Rubric

總分 0-30，共 6 個維度，每項 0-5 分。

## 1. Requirement Clarity

- 0: 已明確指出問題、預期行為、邊界
- 1: 有少量缺漏，但不影響直接實作
- 3: 有重要細節未定義
- 5: 敘述模糊，存在多種合理解釋

## 2. Domain Rule Complexity

- 0: 純呈現、純文案、純明確 bug fix
- 1: 單一簡單規則
- 3: 多條業務規則或例外情境
- 5: 涉及政策、流程、權限、審核、計費、對帳或法規

## 3. Impact Radius

- 0: 單一元件、單一路徑、單一模組
- 1: 單層多檔案
- 3: 跨模組或跨前後端
- 5: 影響多角色、多流程或共享核心能力

## 4. Contract / Schema Change

- 0: 無 contract 或 schema 變更
- 1: 內部非公開欄位微調
- 3: API payload 或 UI contract 有變更
- 5: 新 endpoint、新 entity、新 schema migration

## 5. Regression Risk

- 0: 低風險，容易驗證
- 1: 有局部回歸可能
- 3: 容易破壞既有行為
- 5: 高機率影響核心流程或難以觀察的隱性行為

## 6. Knowledge Dependency

- 0: 不依賴外部知識來源
- 1: 只需參考少量已知規格
- 3: 需要查產品規格、PM ticket 歷史或內部說明
- 5: 若不查知識庫就無法客觀判斷

## Route Thresholds

- 0-7: `Direct Build`
- 8-14: `Build With Verify`
- 15-30: `Spec First`

## Override Rules

以下任一命中，直接升級為 `Spec First`：

- Requirement Clarity >= 4
- Contract / Schema Change >= 4
- Knowledge Dependency >= 4
- Domain Rule Complexity >= 4

以下任一命中，至少升級為 `Build With Verify`：

- Impact Radius >= 3
- Regression Risk >= 3

## Knowledge-First Heuristics

若需求包含以下訊號，優先查知識庫再評分：

- 「應該 / 不應該」且未附規則來源
- 「依照 PM / 文件 / 規範 / 既有行為」
- 權限、角色、審批、計費、優惠、退款、報表、風控
- 與過去 ticket、產品公告、內部 SOP 有關
