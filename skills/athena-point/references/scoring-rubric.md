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

- 0-4: `Trivial`
- 5-7: `Direct Build`
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

## Codemap-Assisted Cues

當 `graphify-out/graph.json` 存在（且 graphify CLI 可用，或可以被動讀 `GRAPH_REPORT.md` /
`graph.json`），point subagent 可依以下線索對三個維度做 **±1** 微調。
詳細允許清單與禁止清單見 `references/codemap-guidelines.md`。

**硬性限制**：每個維度最多 ±1；codemap 線索**不得**單獨翻轉 route。
Route 仍由本檔最上方的閾值表與 Override Rules 決定。
亦即：rubric 算出來原本要走 Direct Build，不能單靠 codemap 線索就升級成 Spec First；
必須其他維度也獨立 cross 閾值，route 才會改變。

### Impact Radius（codemap 線索）

對該需求影響範圍執行 `graphify query` 或 `graphify explain <target-entity>`：

- **+1**：query 顯示目標節點 fan-in ≥ 10（被廣泛引用的核心模組），或跨 ≥ 3 個社群（community）
- **+1**：`graphify path` 顯示目標到關鍵模組的最短路徑 ≤ 2 hops（高耦合）
- **-1**：query 顯示目標是 leaf 節點（fan-in 0-1，僅單一檔案使用）
- **-1**：目標僅落在單一 community 內，且該 community 規模 < 5 nodes

### Contract / Schema Change（codemap 線索）

對被修改的介面執行 `graphify explain <interface>`：

- **+1**：explain 結果顯示該介面有 `implements` / `references` 邊指向多個下游節點（外部消費者多）
- **+1**：`graphify query` 顯示介面欄位被 API route 或 schema 檔案大量引用
- **-1**：介面僅有單一內部消費者，且無 `INFERRED` 邊指出隱性耦合
- **-1**：explain 結果顯示該介面是 private helper（沒有 cross-community 邊）

### Regression Risk（codemap 線索）

對目標路徑或目標節點執行 `graphify query` 與 `graphify path`：

- **+1**：目標位於 god node 列表（GRAPH_REPORT.md 的 God Nodes section），或 fan-out ≥ 8
- **+1**：`graphify query` 顯示 `AMBIGUOUS` 或 `INFERRED` 邊密集出現在目標附近（語意不確定的隱性耦合多）
- **-1**：目標完全隔離（無 outgoing 邊）或只有 test 檔案引用
- **-1**：目標位於明確標註的 utility / formatter community，且 cohesion 高

### 過期 codemap 的調整

若 codemap 被判定為 stale（`graph.json` mtime < 最後 commit time）：

- 線索仍可採用，但**只能**做負方向微調（-1），不可上調分數
- 必須在 `Why` 欄位註記「codemap stale, 線索僅做保守參考」
- 若所有 codemap 線索都指向同一個維度上調，可選擇放棄該線索並改回原 rubric 分數
