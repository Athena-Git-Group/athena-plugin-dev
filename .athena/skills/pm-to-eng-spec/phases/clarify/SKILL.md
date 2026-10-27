---
name: clarify
description: >
  PM → 工程化流水線的需求釐清（硬性 gate，上游為 score 評分）。讀取原始 PM 需求文件，以「拷問式訪談」
  （grill-with-docs：一次一題、附建議答案、磨利術語、用情境壓測邊界）逐一釐清模糊、
  缺漏、矛盾之處，直到需求「足以開始工程化轉換」為止，才把 STATUS 標記為 RESOLVED；
  否則標記 BLOCKED 並列出缺口。由 pm-to-eng-flow 編排器以全新 agent 觸發，也可獨立使用。
---

# clarify · 需求釐清（gate）

> 流水線位置：score(gate) → **clarify(gate)** → specify(gate) → 結構層 → 契約層 → 規格層。
> 這是第二道 gate（score 評分通過後）。在本階段判定 RESOLVED 之前，下游結構層 / 契約層 /
> 規格層一律不得啟動。釐清需求是後續一切轉換的前提。
> **本階段前後端共用（target 無關）**；target 只影響上游 score 的 rubric 與下游走哪條 track。

## 引擎 vs gate 的分工（重要）

- **grill 引擎**（`rules/grill-with-docs.md`）負責「怎麼問」：一次一題、附建議答案、能查 codebase
  就查、磨利模糊術語、用具體情境壓測邊界；專案若有既有 codebase / CONTEXT.md，再啟用 glossary
  挑戰與程式碼交叉比對。
- **clarify（本檔）**負責「輸入/輸出 artifact 與 gate 判定」：吃 `source/requirement.md`、
  吐 `clarified.md` + `STATUS`。grill 的 CONTEXT.md / ADR 只是**選用增益**，不取代 `clarified.md`。

## `clarified.md` 的定位

`clarified.md` 是 `specify` phase 的**輸入**，由它收斂成 `specs/<slug>/specify/spec.md`。
**結構層以後的 phase**（data_model / class_diagram / db_table / screens / api / ui_contract / gherkin）
一律以 `specify/spec.md` 為需求真源，**不直接讀本檔**。本階段的**輸出格式與完成判準不變**
——變的只是「誰讀它」；下方「範例資料」與「邊界」兩段仍要寫成可直接落地的形態，
因為 `specify` 有義務把它們**逐筆無損搬進** `spec.md` 餵給 gherkin。

## 輸入

- **`target`**（由編排器傳入：`backend` / `frontend` / `fullstack`）——決定是否套用完成判準的「資料維度」段（`backend` / `fullstack` 才檢）。獨立執行而未取得時，預設 `backend`。
- `specs/<slug>/source/requirement.md`（原始 PM 需求，不可變）
- `specs/<slug>/score/score-report.md`（上游 score 階段產出）——其**缺口清單**
  （所有 `<3` 維度）即本階段的**提問議程**：缺口已一次列清，照單澄清即可。

## 輸出

- `specs/<slug>/clarify/clarified.md`
  - **第一行必為** `STATUS: RESOLVED` 或 `STATUS: BLOCKED`
  - 其後為釐清後的結構化需求（業務目標、角色、行為、規則、邊界、驗收條件…）
  - **「範例資料」與「邊界」兩段是下游 gherkin 的直接素材**（Spec by Example + 邊界優先），務必寫成可直接落地的形態：
    - **範例資料**：每個核心實體 ≥3 筆真實具體資料（見完成判準「範例資料」）。
    - **邊界**：每條規則把界線寫成**帶具體觸發值**的條目（如「退款金額上限 = 訂單金額；1001 應拒」），而非抽象敘述——讓 gherkin 能直接寫 `例子` 列、不必再猜。
- `specs/<slug>/clarify/questions.md`（**只在有高影響缺口時**）——追寫（append）給使用者的
  待澄清問題；題號與標記契約依 pack 根 `rules/questions-共用契約.md` 追寫。無高影響缺口時不建立本檔。
- `specs/<slug>/handoffs/clarify.md`（依 `phases/common/rules/handoff-contract.md`）

## SOP

### Phase 1 -- 跑澄清迴圈

1. READ 讀原始需求 + score-report 的缺口清單，拆成 可確認 / 待釐清 / 缺失 三類
   （score 已標出的 `<3` 維度先進「待釐清」）。`target ∈ backend / fullstack` 時，另以下方
   「完成判準 · 資料維度」逐條對照需求，未決或未明的項目（身分 / 基數 / optionality / 值域 /
   狀態 / 保存 / PII / 量級 / 存取樣式 / 範例資料）一律先進「待釐清」議程；簡單 CRUD 依比例原則
   只放 ★ 四條。
2. READ 先讀 `rules/grill-with-docs.md`（本階段的訪談引擎），再依其紀律跑澄清迴圈：一次一題、
   每題附你建議的答案，等回饋再問下一題；能靠探索專案 / codebase 回答的，先去查（專案裝了
   graphify，優先用 `graphify query / path / explain`，省 token 且關係更全面），查完了之後，將整理
   好的資訊跟使用者確認狀況；對模糊或一詞多義的字眼，提出精確的標準術語；**用具體情境壓測概念
   邊界，逼出精確界線（shift-left）**：對每條規則的可量化維度（值域上下限、字串長度、optionality、
   enum 封閉集合、狀態機合法 / 非法轉移、唯一性、不存在 / 空集合）主動問「界線在哪、越界要怎樣」，
   把答案寫成帶觸發值的邊界條目。這批邊界越早釘死，下游 gherkin 越不必回退補問。
   > 下游回饋（本 pack 的現行流程，與上游原版不同）：`gherkin` 階段若仍掃出**此處未定義的邊界**，
   > 只會把場景標 `@待釐清` 並寫進 `handoffs/gherkin.md` 的「回饋訊號」段，由編排器收斂進最終 spec
   > handoff 的 Risks 回報使用者。**不存在**「回頭改寫本檔重跑」或「回退本階段」的路徑——結構層
   > 之後的需求真源是 `specify/spec.md`，下游不得回讀本檔（依 pack 根 `SKILL.md` 非協商規則
   > 「依 target 走 track，結構層之後一律以 `specify/spec.md` 為需求真源」）。使用者的補答一律經
   > `clarify/answers.md` 進入**下一輪** spec stage（重跑 clarify → specify）。本階段把邊界問得越
   > 完整，該回饋越少。
3. THINK （選用增益）若專案已有 CONTEXT.md / 程式碼：依 `rules/grill-with-docs.md` 的「用詞彙表
   挑戰」與「與程式碼交叉比對」兩段，用 glossary 挑戰衝突術語、與程式碼交叉比對矛盾；術語釐清的
   當下就更新 CONTEXT.md（格式依 `templates/CONTEXT-FORMAT.md`）；符合三條件才提議 ADR（格式依
   `templates/ADR-FORMAT.md`）。

### Phase 2 -- 收斂並判定 STATUS

1. THINK 把澄清結果回寫成結構化需求（業務目標、角色、行為、規則、邊界、驗收條件…），其中
   「範例資料」與「邊界」兩段務必寫成下游 gherkin 可直接取用的具體形態（見上方「輸出」）。
2. READ 對照下方「完成判準」逐條檢查，決定首行要寫 `RESOLVED` 還是 `BLOCKED`。某項 PM 當場無法
   決定時：列為缺口（BLOCKED），或標「延後決策 @負責人 / 截止日」才視為該項過關——**一律不得由
   clarify 自行填值**（見非協商規則「絕不腦補」）。
3. WRITE 若仍有未解的高影響缺口（會改變業務目標、角色、主要流程、規則界線或驗收條件的缺口）：
   先讀 `specs/<slug>/clarify/answers.md`（若存在）——已被回答的題目不重複追寫，在該題標題行末
   追加「（已回答）」，不刪題、不改號；再把高影響缺口排序，每輪只取最高影響的 1–3 題，以
   PM-friendly 措辭追寫（append）到 `specs/<slug>/clarify/questions.md`，標題行標 `[clarify]`
   來源，附建議選項與影響說明；題號與標記的完整共用契約依 pack 根 `rules/questions-共用契約.md`
   追寫。低影響缺口（次要文案、可安全延後的細節）在 `clarified.md` 就地標「假設：…」或
   「待釐清」，不升級。
4. WRITE 把判定結果寫進 `specs/<slug>/clarify/clarified.md`：第一行為 `STATUS: RESOLVED` 或
   `STATUS: BLOCKED`，`BLOCKED` 時在內文列出尚缺的資訊交由編排器停止回報。
5. WRITE 依 `phases/common/rules/handoff-contract.md` 寫 `specs/<slug>/handoffs/clarify.md`。

## 完成判準（RESOLVED 的條件）

### 通用（所有 target 必檢）
- [ ] 每個行為都有可驗證的輸入 / 輸出 / 規則。
- [ ] 關鍵術語已收斂為單一精確定義，無一詞多義。
- [ ] 無阻斷性的缺漏或互相矛盾。

### 資料維度（target ∈ backend / fullstack 必檢）
> 比例原則：簡單 CRUD 只需 ★ 標記的四條；多實體 / 跨流程 / 有狀態的複雜需求才全套。

**身分與唯一性**
- [ ] ★ 每個被持久化的實體都有明確的業務識別：哪個欄位（或欄位組合）能唯一辨識一筆。若無自然鍵、預期用代理鍵，也明說。
- [ ] 所有「同一筆不可重複」的業務規則都寫成明確的唯一性條件，含條件式唯一（例：同一 user 僅一筆 active）。

**關係與基數**
- [ ] 實體間關係都標了基數（1:1 / 1:N / N:M）與方向。
- [ ] 每個關係標了存在性與刪除行為（上層必須存在嗎？可否為空？刪上層時下層保留 / 連帶 / 禁止？）——用業務語言，不要求講 FK 機制。

**欄位語意**
- [ ] ★ 每個業務欄位都有：是否必填、資料種類（文字 / 數字 / 日期 / 金額 / 布林 / 列舉），及對精度敏感者的精度需求（金額小數位、時間是否含時區）。
- [ ] ★ 每個列舉型欄位都列出**完整且封閉的值集合**（status / type / 類別…），含預設值與是否可擴充。

**生命週期**
- [ ] 有狀態的實體都有明確的狀態集合與合法轉移（誰能從哪個狀態到哪個狀態）。
- [ ] 是否需要保留歷史 / 變更軌跡（只覆蓋現值 vs 留歷史）有明確答案。

**非功能 / 合規 / 規模**
- [ ] 個資 / 敏感欄位已標記（哪些是 PII，是否需遮罩 / 加密 / 存取限制）。
- [ ] 資料保存與清除政策有交代（保存多久、能否硬刪、法遵要求）。
- [ ] 預期資料量級與成長（至少數量級）已知——影響後續分區 / 索引 / 封存。
- [ ] 多租戶與隔離邊界有明確答案（若適用）。

**存取樣式**
- [ ] 主要查詢 / 讀取樣式已捕捉（用什麼條件查、是否排序 / 分頁、高頻查詢欄位）——作為索引與反正規化依據。

**範例資料（高槓桿）**
- [ ] ★ 每個核心實體至少有 3 筆真實範例資料（PM 提供或共同建構），用以交叉驗證型別、optionality、值域、格式與唯一性。

> **不屬本 gate 職責、缺席不得 BLOCKED**（由 db_table 依團隊慣例補）：
> 代理鍵策略、稽核欄位（created_at / updated_at / created_by / version）、
> soft-delete 機制、索引細節、FK 的 CASCADE / RESTRICT / SET NULL 語法、join table 機制。

> 任一條（通用 + 適用的資料維度）未達成 → 寫 `STATUS: BLOCKED` 並在內文列出尚缺的資訊，交由編排器停止回報。

## 非協商規則

1. **絕不腦補** — 使用者沒給的，標記為缺失，不替他編。
2. **一次只問一題**，等回饋再問下一題（grill 引擎核心紀律）。
3. **探索 ≠ 定論** — codebase / graphify 探索得到的結論，一律先自行整理，再回頭跟使用者
   確認「是不是這樣」，不得擅自當成已確認事實推進。
4. 未達完成判準就不得寫 `RESOLVED`。
5. `clarified.md` 第一行必為 `STATUS:` 標記，編排器只認這一行。
