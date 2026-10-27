---
name: specify
description: >
  PM → 工程化流水線的需求結構化 gate（上游為 clarify）。把 clarify 釐清後的
  clarified.md 收斂成結構化規格 spec.md：依商業價值切分使用者故事、把 FR / NFR 歸戶到
  故事或全域需求、補齊邊界情況與成功標準，並**無損承載** clarified.md 的資料維度與範例資料。
  產出 spec.md 是結構層與其後所有 phase 的**唯一需求真源**；另產 requirements-checklist.md
  做規格品質自檢。缺口以 headless 檔案協議追寫回 clarify/questions.md，不互動訪談。
  本 phase 為本 repo 原創（非 vendored），判準借鑑自 CH3-SDD-workflow 的 specify skill，
  授權標註見 pack 根目錄的 VENDORED.md。
---

# specify · 需求結構化（gate）

> 流水線位置：score(gate) → clarify(gate) → **specify(gate)** → 結構層 → 契約層 → 規格層。
> 這是第三道 gate。本階段判定 `STATUS: READY` 之前，結構層 / 契約層 / 規格層一律不得啟動。
> **本階段前後端共用（target 無關）**；target 只影響下游走哪條 track。

## 定位（為什麼獨立成一個 phase）

`clarified.md` 是**訪談的產物**：它證明「需求已經問清楚了」，但排版仍貼著訪談議程，
沒有故事切分、沒有需求歸戶、沒有可量測的成功標準。結構層（data_model / screens）
需要的是**已收斂的規格**，不是訪談紀錄。

因此本 phase 做一次、且只做一次的轉換：

- **`clarify/clarified.md`** — 訪談結論。**本 phase 是它唯一的機械消費者**，
  結構層以後的 phase 不再直接讀它。
- **`specify/spec.md`** — 結構化規格。**結構層與其後所有 phase 的唯一需求真源**。

> **無損承載是本 phase 的核心義務**：`clarified.md` 餵給下游的每一種素材
> （資料維度、範例資料、帶觸發值的邊界、規則）都必須在 `spec.md` 內被承載。
> 只寫敘述層 = 下游 `data_model` / `gherkin` 當場失去素材，且不會有任何 gate 報錯。

## 輸入

- `specs/<slug>/clarify/clarified.md`（**唯一上游**；STATUS 必須為 `RESOLVED`）——
  其「資料維度」「範例資料」「邊界」「規則」各段是本階段必須逐項承載的素材。
- `specs/<slug>/score/score-report.md`（選讀，當複雜度線索與缺口議程）。
- `specs/<slug>/source/requirement.md`（選讀，回查原始措辭與 PM 用語）。
- `specs/<slug>/clarify/answers.md`（若存在，選讀）——使用者對前一輪 `questions.md` 的回答。

## 輸出

- `specs/<slug>/specify/spec.md`
  - **第一行必為** `STATUS: READY` 或 `STATUS: NEEDS-CLARIFICATION`（編排器只認這一行）
  - 其後為結構化規格，必含節見 `templates/spec-structure.md`：
    使用者故事（含驗收情境 + 故事專屬 FR / NFR）、邊界情況、全域需求、關鍵實體、
    **資料維度與範例資料**、成功標準（SC-nnn）、假設、**承載覆蓋對照表**
  - 承載覆蓋對照表是一張完整性對照表：`clarified.md` 的每個標題段、每條規則、
    每筆範例資料各佔一列，記錄它在 `spec.md` 裡的對應位置，用來證明轉換過程中
    沒有任何內容掉落。
  - 缺任一節即未完成；**承載覆蓋對照表不得有「未處理」**
- `specs/<slug>/specify/requirements-checklist.md` — 規格品質自檢清單（見
  `rules/quality-checklist.md`）。全項勾選、或明確標「不適用 + 理由」，
  才可把 `spec.md` 首行寫成 `STATUS: READY`。
- `specs/<slug>/handoffs/specify.md`（依 `phases/common/rules/handoff-contract.md`）
- 有高影響缺口時**追寫**（append）`specs/<slug>/clarify/questions.md`——見「缺口升級協議」。

## SOP

### Phase 1 -- 確認輸入並建立承載對照表骨架

1. READ 確認 `clarify/clarified.md` 存在、非空、首行為 `STATUS: RESOLVED`；不符合就回報並中止，
   不得跳過 clarify 自行從 `source/requirement.md` 推導規格（見非協商規則「依序消費上游」）。
2. READ 通讀 `clarified.md`，列出它的**每一個標題段**，作為承載覆蓋對照表的左欄。
3. READ 先讀 `templates/spec-structure.md`，掌握 `spec.md` 的節結構與逐節填寫判準（含承載義務）；
   故事切分或 FR / NFR 歸戶難判時，另讀 `rules/story-splitting.md` 的判準與 good / bad 對照。
   （選讀增益）`.agents/constitution/` 若存在（`CONSTITUTION.md`、`shared.md`、
   `skills/specify/*.md`），把其中規則視為額外約束套用；**缺這個目錄是常態，缺檔照常執行本
   phase，不得因此停止、不得回報缺失**。

### Phase 2 -- 切故事、歸戶並無損搬運素材

1. THINK 依 `rules/story-splitting.md` 的判準切故事：把需求切成可獨立驗證的使用者故事，標
   Priority、寫「為何為此優先級」與「獨立驗證方式」，每個故事補至少一條驗收情境。
2. THINK 依 `rules/story-splitting.md` 歸戶 FR / NFR：能歸屬單一故事的直接掛在該故事底下；
   只有跨故事或無法合理歸戶的才留在「全域需求」。同一條需求只出現在一處，編號唯一。
3. WRITE 搬邊界：把 `clarified.md`「邊界」段逐條搬進「邊界情況」，**保留具體觸發值**
   （如「退款金額上限 = 訂單金額；1001 應拒」）。**不得**退化成抽象敘述。
4. WRITE **搬資料維度與範例資料（本 phase 最高風險的一步）**：把 `clarified.md` 的資料維度
   （身分 / 基數 / optionality / 值域 / 狀態 / 保存 / PII / 量級 / 存取樣式）與
   每個核心實體的範例資料**逐筆搬運**進「資料維度與範例資料」段（寫法依
   `templates/spec-structure.md` 第 6 節）。**不得摘要、不得改值、不得只寫「詳見
   clarified.md」。**範例資料每個核心實體 ≥ 3 筆；上游不足 3 筆時列為缺口，不自行編造。
5. WRITE 寫成功標準：可量測、技術中立，編號 `SC-nnn`。成功標準是**業務層成果**，
   不得寫成可直接生成場景的驗收步驟（`.feature` 的唯一來源是 FR / 邊界 / 範例資料）。
6. WRITE 寫假設：只記錄本 phase 自行補的推斷前提與範圍邊界，**不得偷渡新需求**。
7. WRITE 補承載覆蓋對照表：`clarified.md` 每個標題段 / 每條規則 / 每筆範例資料 → 在 `spec.md`
   的去向（哪個故事 / 全域需求 / 邊界情況 / 資料維度段）。**不得有「未處理」**。

### Phase 3 -- 自檢、判定 STATUS 並收尾

1. READ 先讀 `rules/quality-checklist.md`，依其骨架產出 `requirements-checklist.md` 並逐項
   自檢；不符即回頭修 `spec.md`，checklist 與 `spec.md` 同批更新。
2. THINK 判定首行 STATUS：全部達成 → `READY`；仍有高影響缺口 → `NEEDS-CLARIFICATION`，依下方
   「缺口升級協議」處理。
3. WRITE 把結果寫進 `spec.md`：首行 STATUS + 其後已收斂的全部內容，**不留空檔**。
4. WRITE 依 `phases/common/rules/handoff-contract.md` 寫 `specs/<slug>/handoffs/specify.md`。

## 缺口升級協議（headless；本 pack 無互動訪談、無 slash 委派）

本 pack 在 spec stage shell 內執行，**不能**互動提問，也**不能**呼叫其他 skill 的
slash 指令。所有缺口一律走既有的檔案協議，**不另立第二套協議、不另開新檔**：

1. **只升級會改變下游結構的缺口**——會改變故事切分、需求歸戶、主要流程、角色權限、
   範圍邊界或成功標準的，才算高影響。
2. 低影響缺口（局部 wording、次要互動、可安全延後的呈現選項）寫進 `spec.md` 的
   **「假設」段**或以 `[NEEDS CLARIFICATION: …]` 就地標記，**不升級**。
3. 高影響缺口先自行排序，**每輪只取最高影響的 1–3 題**，以 PM-friendly 措辭
   **追寫（append）**到既有的 `specs/<slug>/clarify/questions.md`，標題行標 `[specify]`
   來源，附建議選項與影響說明；題號與標記的完整共用契約依 pack 根
   `rules/questions-共用契約.md` 追寫。
4. `spec.md` 首行寫 `STATUS: NEEDS-CLARIFICATION`，其餘已收斂的內容照常寫完，**不留空檔**。
5. 交回編排器：wrapper 會發
   `FAIL — specify 待澄清（spec.md STATUS: NEEDS-CLARIFICATION），見 specs/<slug>/clarify/questions.md #spec-gap`
   並停止（與 clarify 那道 gate 的字串**刻意不同**，讓 flow 與使用者看得出是哪一道擋下來的）。
   使用者的回答由 flow 主對話寫入 `specs/<slug>/clarify/answers.md`，重跑 spec stage
   後本 phase 續跑。

## 完成判準（`STATUS: READY` 的條件）

- [ ] `templates/spec-structure.md` 列出的每一節都存在且非空殼。
- [ ] 每個使用者故事都有：敘述、Priority、優先級原因、獨立驗證方式、≥1 條驗收情境、
      專屬 FR（NFR 可省略但不得留空殼小節）。
- [ ] 可歸屬單一故事的 FR / NFR 已掛在故事底下；全域需求只剩跨故事或無法歸戶者；無重複編號。
- [ ] 邊界情況每條都帶**具體觸發值**，不是抽象敘述。
- [ ] **資料維度與範例資料**段完整承載 `clarified.md` 的對應內容；每個核心實體
      ≥ 3 筆範例資料，且**與上游逐筆一致（未摘要、未改值）**。
- [ ] 成功標準可量測、技術中立、編號 `SC-nnn`。
- [ ] 假設只表達前提與邊界，未偷渡新需求。
- [ ] **承載覆蓋對照表涵蓋 `clarified.md` 每個標題段 / 每條規則 / 每筆範例資料，無「未處理」。**
- [ ] `requirements-checklist.md` 全項勾選或標「不適用 + 理由」。
- [ ] 未決資訊不腦補：上游沒給的，標缺口或 `[NEEDS CLARIFICATION: …]`，不自行編值。

## 非協商規則

1. **無損承載** —— `clarified.md` 的資料維度、範例資料、帶觸發值的邊界一律逐筆搬進
   `spec.md`，**不得摘要、不得改值、不得以「詳見 clarified.md」代替**。下游只讀 `spec.md`。
2. **絕不腦補** —— 上游沒給的，標缺口或 `[NEEDS CLARIFICATION: …]`，不自填值域 / 門檻 / 規則。
3. **承載覆蓋對照表不得有「未處理」** —— 有未處理項就不是 `READY`。
4. **依序消費上游** —— `clarified.md` 的 STATUS 非 `RESOLVED` 時，回報並中止；不得跳過 clarify
   自行從 `source/requirement.md` 推導規格。
5. **無互動提問、無 slash 委派** —— 缺口一律**追寫**既有的 `clarify/questions.md`，
   每輪 ≤ 3 題；不另開新檔、不新增協議、不呼叫其他 skill 的斜線指令。
6. `spec.md` 第一行必為 `STATUS:` 標記，編排器只認這一行。
7. `.agents/constitution/` 是**選讀增益**：存在則套用，**缺檔照常執行**，不得因缺它停止或 FAIL。
