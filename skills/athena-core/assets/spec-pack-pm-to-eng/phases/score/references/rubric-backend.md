# 可譯性評分 rubric — 後端維度（Backend）

> 共用的設計原則、計分尺度、裁決規則見 `rubric.md`。本檔只放後端維度與 0–3 錨點。
> 後端維度 = db_table / api / gherkin 三產物輸入需求的聯集。

## 七個維度

| # | 維度 | 餵給 | 必備 | 評什麼 |
|---|------|------|------|--------|
| 1 | Entity Identifiability 實體可辨識性 | db_table | ✅ | 主要資料對象與其屬性可否從文中推出 |
| 2 | Relationship & State 關係與狀態 | db_table | — | 實體間關聯、資料生命週期 / 狀態流轉是否說明 |
| 3 | API Boundary 行為與邊界 | api | ✅ | 每個動作能否切成獨立 command/query，含輸入/輸出 |
| 4 | Business Rule Completeness 規則完整性 | api, gherkin | ✅ | 規則是否窮盡：含 happy / unhappy / edge case |
| 5 | Validation & Acceptance 驗證與驗收 | api, gherkin | — | 欄位驗證（格式/範圍/唯一性）+ 每個行為的成功/失敗判準 |
| 6 | Scope & Integration 範圍與整合點 | 全部 | ✅ | 「要做/不做」是否明確；外部系統 / 依賴 / side effects 是否標明 |
| 7 | Terminology Consistency 術語一致性 | 全部 | — | 同一概念前後同名、無互相矛盾 |

> 必備維度（BLOCKED 判定依據）：1 Entity、3 API Boundary、4 Business Rule、6 Scope & Integration。

## 各維度 0–3 錨點

**1. Entity Identifiability 實體可辨識性**
- 0：看不出任何資料對象。1：提到名詞但無屬性。2：主要實體 + 部分屬性可推，仍有缺漏。3：實體與關鍵屬性（含型別線索）清楚可萃取。

**2. Relationship & State 關係與狀態**
- 0：完全未提關聯或狀態。1：隱約暗示。2：主要關聯可推，狀態流轉部分缺。3：關聯與生命週期清楚。

**3. API Boundary 行為與邊界**
- 0：看不出任何可數的動作。1：有動作但邊界糊、無輸入輸出。2：多數動作可切 command/query，部分輸入輸出缺。3：每個動作邊界清楚、輸入輸出明確。

**4. Business Rule Completeness 規則完整性**
- 0：無任何規則。1：只有 happy path。2：有規則但 unhappy / edge case 不全。3：規則窮盡含例外與邊界。

**5. Validation & Acceptance 驗證與驗收**
- 0：無驗證、無驗收判準。1：零星提到。2：部分欄位驗證 / 部分行為有成功失敗判準。3：驗證與每個行為的驗收判準齊備。

**6. Scope & Integration 範圍與整合點**
- 0：範圍不明、未提外部依賴。1：範圍模糊。2：要做的清楚、不做的 / 整合點部分缺。3：in/out 範圍與外部依賴 / side effects 明確。

**7. Terminology Consistency 術語一致性**
- 0：同概念多名且互相矛盾。1：明顯不一致。2：少數不一致。3：術語前後一致、無矛盾。
