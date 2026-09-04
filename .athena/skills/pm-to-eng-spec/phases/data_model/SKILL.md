---
name: data_model
description: >
  PM → 工程化流水線的階段 2（後端 track，概念/邏輯實體層，**實體集合的唯一真相**）。讀取已釐清的需求
  （specify/spec.md），用萃取決策樹把散文收斂成一組實體：判定 entity / attribute / enum / junction、
  區分 stored vs derived、合併同義實體、分類 master vs transactional、補出 class diagram 看不到的
  data-only 實體（junction / history / i18n），並以覆蓋帳本證明沒漏掉任何需求名詞。
  下游 class_diagram（物件設計）與 db_table（持久化）都對齊它、互不依賴。
  由 pm-to-eng-flow 在 target = backend / fullstack 時以全新 agent 觸發，也可獨立使用。前提：specify 已 READY。
---

# data_model · 概念/邏輯實體模型（階段 2 / 後端 track · 實體集合真相）

> 流水線位置：score(gate) → clarify(gate) → specify(gate) → **data_model**(概念/邏輯實體) →（class_diagram 物件設計 ∥ db_table 持久化）→ api → gherkin。
> 本階段是「從需求萃取 entity」的唯一現場：把 spec.md 的散文收斂成一組實體與關係。
> class_diagram 與 db_table 是本階段的**消費者**（彼此是兄弟、互不依賴）；實體集合衝突時以本檔產出為準。

## 定位（為什麼獨立成一個 stage）

class_diagram 的鏡頭是三層職責（行為），它**看不到沒有行為的純資料實體**（junction / history / i18n）。
若讓 class_diagram 當實體來源，這些會被漏掉。故把「實體集合」抽成獨立的概念/邏輯層：

- **本檔（概念/邏輯）**：有哪些實體、彼此關係、每個屬性的語意 —— 與技術無關。
- **class_diagram（物件設計）**：怎麼拆 Controller / Service / DAO + Entity / DTO —— 程式結構。
- **db_table（物理）**：DBML、型別、索引、約束、持久化機制。

## 複雜度比例原則

- **簡單**（少數實體、單純 CRUD）→ 實體目錄 + 屬性 + 關係即可，覆蓋帳本可精簡。
- **複雜**（多實體 / N:M / 有狀態 / 需歷史 / 多語）→ 完整跑萃取決策樹、data-only 實體、生命週期與覆蓋帳本。

## 輸入

- `specs/<slug>/specify/spec.md`（**唯一資料來源**；首行 STATUS 必須為 READY）——
  其「資料維度與範例資料」段（身分 / 基數 / optionality / 值域 / 狀態 / 保存 / PII / 量級 /
  存取樣式 / 範例資料）即本階段素材；「關鍵實體」與「全域需求」段補業務語意。
- `specs/<slug>/score/score-report.md`（選讀，當複雜度線索）。

## 輸出

- `specs/<slug>/data_model/data-model.md`，含下列節（依複雜度伸縮）：
  1. **實體目錄**：實體 | 分類（master/reference vs transactional）| 業務識別（自然鍵 / 代理鍵）| 是否 data-only（junction / history / i18n）| 來源
  2. **屬性**（每實體一表）：屬性 | stored / derived（derived 註明計算來源）| 必填? | 值種類 / 值域（enum 列出封閉集合）| PII?
  3. **關係**：關係 | 基數（1:1 / 1:N / N:M）| 存在性 | 刪除行為（業務語言）
  4. **生命週期**（有狀態實體）：狀態集合 + 合法轉移 + 是否留歷史
  5. **關係圖**：Mermaid `erDiagram`
  6. **覆蓋帳本**：spec.md 每個名詞片語 → 歸類（entity / attribute / enum / derived / junction / ignore）+ 去向
  7. **通用語言詞彙表**（複雜時）：核心業務術語 | 定義 | 別名 / 同義詞 | 對應實體或屬性 —— 統一團隊術語，與覆蓋帳本一致。簡單需求可省略。
- `specs/<slug>/handoffs/data_model.md`（依 handoff-contract）

## 萃取決策樹（名詞 → 什麼）

逐一掃 spec.md 的名詞片語，依序判定（每個結果都記進覆蓋帳本）：

1. 純敘述噪音、UI 字眼、無資料意義 → **忽略**（標 ignore）。
2. 封閉且固定的值集合（狀態種類、類別、角色名）→ **enum**；
   若需被多處引用 / 在地化 / 自帶屬性 → 升格為 **reference table**。
3. 看似欄位、但可由其他資料算出（總額、年齡、餘額、「逾期」）→ **derived**，不存、記計算來源；
   僅在明確需要快照或效能時才落欄，並標 `denormalized` + 一致性維護方式。
4. 有獨立身分 + 生命週期 + 多個屬性 → **entity**。
5. 只依附某 entity、無獨立身分 → 該 entity 的 **attribute**。
6. 描述兩個 entity 間的多對多關係或事件（選課、訂單明細、標籤關聯）→ **associative entity（junction）**。
7. 同一真實事物的不同稱呼（會員 / 用戶 / 客戶）→ **合併為一個 entity**，別名記在來源欄。
8. 同一個字在不同情境指不同事物 → **拆成不同 entity**，各自命名。

> 難判的邊界（enum vs reference、stored vs derived、1:1 拆併、值物件、多型、歷史）見 `references/extraction-cases.md`。

## 執行步驟

1. [ ] 跑萃取決策樹，產出初版實體 / 屬性 / enum 清單；同步記覆蓋帳本。
2. [ ] 實體去重：合併同義、拆解一詞多義。
3. [ ] 分類每個實體：master/reference vs transactional。
4. [ ] 補 data-only 實體：N:M → junction；「要看歷史 / 某時點」→ history / 快照；「名稱 / 描述要多語」→ i18n 翻譯表。
5. [ ] 標每個屬性 stored / derived（derived 寫來源）、必填、值域、PII。
6. [ ] 連關係：基數、存在性、刪除行為（業務語言）。
7. [ ] 有狀態實體畫狀態集合 + 合法轉移，標是否留歷史。
8. [ ] 彙整通用語言詞彙表（複雜時）：把合併的同義詞、核心術語定義收斂成詞彙表，術語對齊覆蓋帳本。
9. [ ] 產出 data-model.md（依複雜度伸縮）+ Mermaid `erDiagram`；handoff 列關鍵萃取決策與假設。
10. [ ] 覆蓋驗收：確認 spec.md 每個名詞都在帳本裡有歸類與去向。

## 完成判準

- [ ] spec.md 每個名詞片語都在覆蓋帳本中被歸類、有去向（無「未處理」）。
- [ ] 每個實體都有業務識別與分類；無同義重複、無一詞多義殘留。
- [ ] 每個屬性都標了 stored / derived；derived 都有計算來源。
- [ ] 每個關係都有基數、存在性、刪除行為。
- [ ] data-only 實體（junction / history / i18n）依需求補齊，不多不少。
- [ ] 未決資訊不腦補：spec.md 沒給的，標 `待釐清` 並回報，不自行編。
- [ ] （複雜時）通用語言詞彙表涵蓋所有核心術語，別名 / 同義詞已標注，與覆蓋帳本一致。

## references/

- `references/extraction-cases.md` — 萃取決策樹的邊界案例集（enum vs reference、stored vs derived、1:1 拆併、值物件、N:M、階層、多型、歷史）+ 概念層命名慣例。難判時參考。

> 不另附 Mermaid `erDiagram` 語法速查——agent 已內建語法。

## 非協商規則

1. **只依 spec.md 萃取** —— data-only 實體（junction / history / i18n）屬持久化/結構必需、不算擴張，但仍須由需求觸發。
2. **絕不腦補** —— 資料語意缺漏標 `待釐清` 回報，不自填值域 / 基數 / 身分。
3. **本檔是實體集合真相** —— class_diagram 與 db_table 對齊本檔；衝突時它們回報，不在下游悄悄改實體集合。
4. `specify/spec.md` 的 STATUS 非 READY 時，回報並中止。
5. 探索既有 codebase 時優先用 graphify；探索結果回頭跟使用者確認，不擅自當定論。
6. `specs/<slug>/specify/spec.md` **缺失、為空、或首行非 `STATUS: READY`** 時，**回報並中止**——
   **不得**改讀 `clarify/` 的訪談產出、**不得**回頭讀 `source/requirement.md` 自行腦補、
   **不得**產出空 artifact 後宣告完成。
