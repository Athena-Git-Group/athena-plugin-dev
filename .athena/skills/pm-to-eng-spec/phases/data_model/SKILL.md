---
name: data_model
description: >
  PM → 工程化流水線的後端 track 概念/邏輯實體層，是**實體集合的唯一真相**。
  它讀取已經釐清的需求（specify/spec.md），用萃取決策樹把散文收斂成一組實體。
  具體要做的事有五件：判定每個名詞是 entity、attribute、enum，還是 junction
  （多對多關係的中間關聯實體，例如學生與課程之間的「選課」）；
  區分哪些值要實際存起來（stored）、哪些可以由其他資料算出來所以不存（derived，
  例如訂單總額可由明細加總算出）；把同義的實體合併成一個；
  把實體分成 master 與 transactional 兩類；補出 class diagram 看不到的純資料實體
  （junction / history / i18n）。最後用一張覆蓋對照表證明沒有漏掉任何需求名詞。
  下游的 class_diagram（物件設計）與 db_table（持久化）都對齊本 phase 的產出，彼此互不依賴。
  由 pm-to-eng-flow 在 target = backend / fullstack 時以全新 agent 觸發，也可獨立使用。前提：specify 已 READY。
---

# data_model · 概念/邏輯實體模型（後端 track · 實體集合真相）

> 流水線位置：score(gate) → clarify(gate) → specify(gate) → **data_model**(概念/邏輯實體) →（class_diagram 物件設計 ∥ db_table 持久化）→ api → gherkin。
> 本 phase 是整條流水線上唯一做「從需求萃取 entity」的地方：把 spec.md 的散文收斂成一組實體與關係。
> class_diagram 與 db_table 都是本 phase 的**消費者**，兩者是平行的兄弟關係、互不依賴；
> 實體集合有衝突時，一律以本檔的產出為準。

## 定位（為什麼獨立成一個 phase）

class_diagram 看事情的角度是三層職責，也就是行為，所以它**看不到那些沒有行為的純資料實體**
（junction 多對多中間關聯表 / history 歷史紀錄表 / i18n 多語翻譯表）。如果讓 class_diagram 當成實體的來源，這些實體就會被漏掉。
因此把「有哪些實體」這件事抽出來，獨立成一個概念/邏輯層：

- **本檔（概念/邏輯層）**：有哪些實體、實體之間是什麼關係、每個屬性代表什麼意思 —— 與技術無關。
- **class_diagram（物件設計）**：程式結構怎麼拆，包括 Controller / Service / DAO 與 Entity / DTO。
- **db_table（物理層）**：DBML、欄位型別、索引、約束，以及實際怎麼持久化。

## 複雜度比例原則

- **簡單**（實體數量少、只有單純的 CRUD）→ 做到實體目錄、屬性、關係三節即可，覆蓋對照表可以寫得精簡。
- **複雜**（實體多 / 有 N:M 關係 / 實體有狀態 / 需要保留歷史 / 需要多語）→ 完整跑一遍萃取決策樹，並補齊純資料實體、生命週期與覆蓋對照表。

## 萃取決策樹：判斷每個名詞該歸成什麼

> **覆蓋對照表**是一張完整性對照表：spec.md 掃出來的每一個名詞各佔一列，記錄它被歸成了什麼
> （entity / attribute / enum / derived / junction / 忽略），以及它對應到產出文件的哪一節。
> 它的用途是證明沒有任何需求名詞在轉換過程中被漏掉。

逐一掃過 spec.md 裡的每個名詞片語，依下列順序判定，每判定完一個就把結果記進覆蓋對照表：

1. 純粹是敘述上的雜訊、UI 用語、沒有資料意義的字眼 → **忽略**（在對照表標 ignore）。
2. 是一組封閉且固定的值集合（狀態種類、類別、角色名）→ 判成 **enum**；
   若這組值需要被多處引用、需要在地化、或值本身帶有自己的屬性 → 升格成 **reference table**。
   這兩者的分界難判時，先讀 `rules/extraction-cases.md` 的「enum 與 reference table 的分界」一條。
3. 看起來像一個欄位、但其實可以從其他資料算出來（總額、年齡、餘額、「是否逾期」）→ 判成 **derived**，
   不實際存成一個欄位，只記錄它的計算來源；只有在明確需要保留歷史快照、或讀取效能有要求時，
   才實際存成一個欄位，並且標上 `denormalized` 與一致性維護方式。
4. 有獨立身分、有自己的生命週期、而且帶多個屬性 → 判成 **entity**。
5. 只依附在某個 entity 上、沒有獨立身分 → 判成該 entity 的 **attribute**。
6. 描述的是兩個 entity 之間的多對多關係或一次事件（選課、訂單明細、標籤關聯）→ 判成 **associative entity（junction）**。
7. 是同一個真實事物的不同稱呼（會員 / 用戶 / 客戶）→ **合併成一個 entity**，其餘稱呼當成別名，寫進實體目錄表的「來源」欄位。
8. 同一個字在不同情境指的是不同事物 → **拆成不同的 entity**，各自命名。

## 輸入

- `specs/<slug>/specify/spec.md`，它是本階段的**唯一資料來源**，而且首行的 STATUS 必須是 READY。
  其中「資料維度與範例資料」段是本階段的主要素材，內容涵蓋身分、基數、optionality、值域、
  狀態、保存政策、PII、資料量級、存取樣式與範例資料；「關鍵實體」與「全域需求」兩段則補充業務語意。
- `specs/<slug>/score/score-report.md`，選讀，用來判斷這次需求的複雜度。

## 輸出

- `specs/<slug>/data_model/data-model.md`，含下列節（依複雜度伸縮）：
  1. **實體目錄**：實體 | 分類（master/reference 或 transactional）| 業務識別（自然鍵 / 代理鍵）| 是否為純資料實體（junction / history / i18n）| 來源（這個實體是從需求的哪句話來的，同義別名也記在這一欄）
  2. **屬性**（每個實體各一張表）：屬性 | 是 stored 還是 derived（derived 要註明計算來源）| 是否必填 | 值的種類與值域（enum 要把封閉集合逐一列出）| 是否為 PII
  3. **關係**：關係 | 基數（1:1 / 1:N / N:M）| 存在性（兩端是否可以不存在）| 刪除行為（用業務語言描述，例如「刪除會員時，他的訂單要保留」）
  4. **生命週期**（只有狀態型實體需要）：狀態集合 + 哪些狀態轉移是合法的 + 是否需要保留歷史
  5. **關係圖**：Mermaid `erDiagram`
  6. **覆蓋對照表**：spec.md 的每個名詞片語各一列，記錄它被歸成什麼（entity / attribute / enum / derived / junction / ignore），以及它對應到本文件的哪一節
  7. **通用語言詞彙表**（需求複雜時才需要）：核心業務術語 | 定義 | 別名 / 同義詞 | 對應到哪個實體或屬性。這一節的用途是統一團隊的用詞，內容要與覆蓋對照表一致。需求簡單時可以省略。
- `specs/<slug>/handoffs/data_model.md`（依 `phases/common/rules/handoff-contract.md` 的格式）。

## SOP

### Phase 1 -- 萃取與去重

1. READ 讀取 `specs/<slug>/specify/spec.md` 的「資料維度與範例資料」「關鍵實體」「全域需求」段，確認首行為 `STATUS: READY`；選讀 `specs/<slug>/score/score-report.md` 當複雜度線索。
2. THINK 依上方的萃取決策樹逐一判定每個名詞片語該歸成什麼（entity / attribute / enum / derived / junction / ignore）。遇到難判的邊界情境時，先讀取 `rules/extraction-cases.md` 裡對應的那一條，再收斂判定：enum 與 reference table 分不清時讀「enum 與 reference table 的分界」；不確定一個值要不要存起來時讀「衍生值預設不存成欄位」；1:1 不知道該合併還是拆開時讀「1:1 關係預設合併進主實體」；碰到地址、金額這類值物件時讀「值物件預設嵌入主實體」；懷疑有同義詞或一詞多義時讀「同義詞要合併、一詞多義要拆分」。
3. WRITE 產出初版的實體 / 屬性 / enum 清單；每判定完一個名詞，就同步把結果記進覆蓋對照表。
4. THINK 檢查實體之間是否有同義重複、或同一個名稱被用在兩種意思上；難判時讀取 `rules/extraction-cases.md` 的「同義詞要合併、一詞多義要拆分」一條，再把同義的實體合併、把一詞多義的實體拆開。

### Phase 2 -- 分類與補齊 data-only 實體

5. THINK 判斷每個實體屬於 master/reference 還是 transactional 分類。
6. THINK 判斷是否需要補上沒有行為的純資料實體：有 N:M 關係就補 junction；需要查詢某個時間點的狀態或變更軌跡就補 history 表或快照表；名稱或描述需要多語就補 i18n 翻譯表。遇到難判情境時讀取 `rules/extraction-cases.md` 對應的那一條：關係本身帶屬性時讀「帶屬性的 N:M 關係要拆成 associative entity」；碰到階層或樹狀資料時讀「階層資料在本層只標注查詢需求，實作形式交給 db_table」；碰到多型或變體時讀「多型與變體在本層只用一個 type 欄位表示」；碰到歷史與時間維度需求時讀「歷史需求在本層只標注保留需求與讀取樣式」。
7. WRITE 為每個屬性標上四件事：它是 stored 還是 derived（derived 要寫明計算來源）、是否必填、值的種類與值域、是否為 PII。判斷一個值該不該實際存成欄位時，參考 `rules/extraction-cases.md` 的「衍生值預設不存成欄位」一條。
8. WRITE 把每一組關係連起來，各自寫明基數（1:1 / 1:N / N:M）、存在性、以及刪除行為（用業務語言描述）。
9. THINK 若某個實體有狀態，就列出它的狀態集合與哪些狀態轉移是合法的，並標示這個實體是否需要保留歷史。

### Phase 3 -- 彙整與產出

10. WRITE 需求複雜時，彙整通用語言詞彙表：把前面合併掉的同義詞與核心術語的定義收斂成一張詞彙表，用詞要與覆蓋對照表一致；需求簡單時可以省略這一節。
11. WRITE 產出 `data_model/data-model.md`，依需求複雜度伸縮前述七節，並附上 Mermaid `erDiagram`；接著依 `phases/common/rules/handoff-contract.md` 的格式寫 `handoffs/data_model.md`，在裡面列出關鍵的萃取決策與所做的假設。
12. READ 回頭檢查覆蓋對照表：確認 spec.md 的每個名詞片語都已經被歸類，而且都記了對應到本文件的哪一節；若發現有名詞沒被記到、或還留在「未處理」的狀態，立即補上。

## 完成判準

- [ ] spec.md 的每個名詞片語都在覆蓋對照表裡被歸類，而且都記了對應到哪一節；沒有任何名詞還留在「未處理」的狀態。
- [ ] 每個實體都有業務識別與分類；沒有同義重複的實體，也沒有一詞多義的實體殘留。
- [ ] 每個屬性都標了是 stored 還是 derived；每個 derived 都寫了計算來源。
- [ ] 每個關係都寫了基數、存在性與刪除行為。
- [ ] 純資料實體（junction / history / i18n）依需求補齊，不多也不少。
- [ ] 沒有把缺的資訊自己補出來：spec.md 沒給的，標 `待釐清` 並回報，不自行編造。
- [ ] 需求複雜時，通用語言詞彙表涵蓋所有核心術語，別名與同義詞都已標注，而且與覆蓋對照表一致。

## 非協商規則

1. **只依 spec.md 萃取** —— 純資料實體（junction / history / i18n）是結構上必要的補齊，不算擴張需求範圍，但它們仍然必須由需求本身觸發，不可以憑空加。
2. **絕不自己補缺的資訊** —— 資料語意有缺漏時標 `待釐清` 並回報，不要自行填入值域、基數或業務識別。
3. **本檔是實體集合的真相** —— class_diagram 與 db_table 都要對齊本檔；發現衝突時它們應該回報，不可以在下游悄悄改動實體集合。
4. `specify/spec.md` 的 STATUS 非 READY 時，回報並中止。
5. 探索既有 codebase 時優先用 graphify；探索結果回頭跟使用者確認，不擅自當定論。
6. `specs/<slug>/specify/spec.md` **缺失、為空、或首行非 `STATUS: READY`** 時，**回報並中止**——
   **不得**改讀 `clarify/` 的訪談產出、**不得**回頭讀 `source/requirement.md` 自行腦補、
   **不得**產出空 artifact 後宣告完成。
