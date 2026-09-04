---
name: db_table
description: >
  PM → 工程化流水線的階段 2b（後端 track，持久化）。讀取 data_model 的概念/邏輯實體模型，
  把它**落地成關聯式持久化模型**並輸出 DBML 格式的 Table 設計（實體、欄位、型別、關聯、約束、索引），
  再補需求未明言但持久化必需的機制欄位（稽核 / 樂觀鎖 / soft-delete / junction 物理落地 / 索引）。
  與 class_diagram 平行（同讀 data_model、互不依賴）。由 pm-to-eng-flow 編排器以全新 agent 觸發，也可獨立使用。
  前提：specify 已 READY、data_model 已產出實體模型。
---

# db_table · Table 設計（階段 2b / 後端 track · 持久化，落地 data_model）

> 流水線位置：score(gate) → clarify(gate) → specify(gate) → data_model(實體真相) → class_diagram(物件設計) ∥ **db_table**(持久化) → api → gherkin。
> 本階段把 data_model 的**邏輯實體模型落地成關聯式持久化模型**——不依賴 class_diagram（物件設計與持久化是兩件事）。

## 輸入

> 優先序：**實體集合與資料語意以 data_model 為準**；data_model 未涵蓋的邊界細節回查 `specify/spec.md`；不依賴 class_diagram。

- `specs/<slug>/data_model/data-model.md`（**主輸入 · 邏輯實體模型**）——
  實體集合、屬性（含 stored / derived）、值域、基數、業務識別、分類、data-only 實體皆以此為準。
- `specs/<slug>/specify/spec.md`（底層權威；首行 STATUS 必須為 READY）——
  data_model 有歧義或未涵蓋的資料維度細節，回查此檔的「資料維度與範例資料」段，仍不足則回報、不腦補。

## 輸出

- `specs/<slug>/db_table/erm.dbml`（DBML 資料模型）
- `specs/<slug>/handoffs/db_table.md`（依 handoff-contract）

## 執行步驟

1. [ ] 從 data_model 的實體目錄與屬性表取需持久化的實體與屬性（stored 的才落欄；derived 預設不存，除非標 denormalized）；
       值域 / 基數 / 唯一性 / 業務識別直接沿用 data_model，歧義處回查 spec.md。
2. [ ] 決定每個 Table 的欄位、型別與精度、主鍵、唯一鍵、可空性（NOT NULL / NULL）、預設值。
3. [ ] 落地關聯：1:1 / 1:N 用 FK（指定 ON DELETE / ON UPDATE，對齊 data_model 的刪除行為）；N:M 建 junction table。
4. [ ] 落地 enum 值域（DB enum / code 欄位 / lookup table，依團隊慣例）與必要的 CHECK / UNIQUE / partial unique 約束。
5. [ ] 補持久化機制（**僅限 allowlist**）：稽核欄位 / 樂觀鎖 / soft-delete；不越界新增 data_model 沒有的業務實體 / 欄位。標準樣式 / FK 行為對照 / 命名見 `references/persistence-allowlist.md`。
6. [ ] 依 data_model 的存取樣式與 FK 建索引；複合索引遵守最左前綴原則，避免冗餘索引。
7. [ ] 撰寫慣例（見 `references/dbml-style.md`）：每個 Table 給業務 `Note`、語意不明顯 / 帶約束 / enum 的欄位給 inline note；有狀態 / 衍生的實體把不變條件（來自 data_model 的 derived 計算來源與生命週期）寫進 Table 的 `Note` block，能落成 CHECK 的同時落 CHECK；索引以 `Indexes` block 明寫。
8. [ ] 輸出 erm.dbml；handoff 列關鍵建模決策、假設，以及 PII / 保存政策的處理或延後標注。

## 完成判準

**落地忠實度（對齊 data_model）**
- [ ] data_model 每個 stored 實體都有對應 Table；derived 屬性未落欄（除非標 denormalized 並註明維護方式）。
- [ ] data_model 每個關係都落成 FK 或 junction table，基數一致；N:M 一律建 junction。
- [ ] 每個 enum 值域已落地（DB enum / code / lookup），值集合與 data_model 一致、無遺漏。
- [ ] 業務識別落成 PK / UNIQUE；條件式唯一落成 partial unique（或等效約束）。

**型別與約束**
- [ ] 每個欄位有明確型別與精度（金額 DECIMAL、時間含時區依需求）；optionality 落成 NOT NULL / NULL。
- [ ] 每個 FK 都指定 ON DELETE / ON UPDATE，且對齊 data_model 的刪除行為。
- [ ] 必要的 CHECK / DEFAULT / UNIQUE 約束齊備。

**持久化機制（allowlist 範圍）**
- [ ] 稽核欄位 / 樂觀鎖 / soft-delete 依團隊慣例補齊，且**僅限 allowlist**——未越界新增 data_model 沒有的業務實體 / 欄位。
- [ ] data_model 標記的 PII / 保存政策有對應處理，或於 handoff 明確標注延後（不靜默丟失）。

**索引**
- [ ] 依 data_model 的存取樣式與 FK 建索引；複合索引遵守最左前綴；無明顯冗餘索引。

**可讀性 / 語意（見 dbml-style.md）**
- [ ] 每個 Table 有業務 `Note`；語意不明顯 / 帶約束 / enum 的欄位有 inline note。
- [ ] 有狀態 / 衍生的實體在 Table `Note` block 記錄不變條件（對齊 data_model 的 derived 來源與生命週期）；能落成 CHECK 的已落 CHECK。
- [ ] 索引以 `Indexes` block 明確宣告，非僅 handoff 描述。

**自洽 / 可追溯**
- [ ] 關聯與外鍵自洽、無孤兒（每個 FK 都指向存在的 PK）。
- [ ] 每個 Table / 欄位都追得回 data_model 的實體 / 屬性，或 allowlist 的某條機制；無來源不明的欄位。
- [ ] erm.dbml 語法正確、可被 DBML 工具解析。

## references/

- `references/persistence-allowlist.md` — 持久化機制 allowlist 細則（稽核 / 樂觀鎖 / soft-delete + partial unique / 代理鍵 / junction / FK 行為對照 / 索引 / 多租戶與 PII 邊界）+ 命名慣例。
- `references/dbml-style.md` — DBML 撰寫慣例（風格指南）：每個 Table 的業務 `Note`、不變條件寫進 Note block、索引 `Indexes` block 宣告、✅/❌ 對照。agent 已內建 DBML **語法**，本檔補的是**團隊撰寫慣例**（語意 Note、不變條件、索引宣告），非語法速查。

## 非協商規則

1. 持久化模型對齊 data_model 的實體集合，不自行擴張需求未提及的實體；**唯一例外是持久化機制**（見第 2 條）。
2. **持久化機制 allowlist** — 下列為持久化必需、不算擴張需求，可逕自補：代理鍵策略、稽核欄位（created_at / updated_at / created_by / version 樂觀鎖）、soft-delete（deleted_at）、N:M 實體 junction 的物理落地、索引、FK 的 CASCADE / RESTRICT / SET NULL。除此之外的實體 / 欄位一律須由 data_model 觸發。
3. data_model 是實體與資料語意的真相；與它衝突時回報，不在本階段悄悄改實體集合或自填資料語意。
4. `specify/spec.md` 的 STATUS 非 READY、或缺 data-model.md 時，回報並中止。
5. `specs/<slug>/specify/spec.md` **缺失、為空、或首行非 `STATUS: READY`** 時，**回報並中止**——
   **不得**改讀 `clarify/` 的訪談產出、**不得**回頭讀 `source/requirement.md` 自行腦補、
   **不得**產出空 artifact 後宣告完成。
