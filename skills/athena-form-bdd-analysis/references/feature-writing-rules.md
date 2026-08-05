# Feature File 撰寫規則

## 0. 語言：zh-TW 中文關鍵字

每支 `.feature` 第一行必為 `# language: zh-TW`。關鍵字只用 zh-TW 對照表：
`功能`（Feature）/ `背景`（Background）/ `場景`（Scenario）/ `場景大綱`（Scenario Outline）/
`例子`（Examples）/ `假設`（Given）/ `當`（When）/ `那麼`（Then）/ `而且`（And）/ `但是`（But）。
`Rule:` 在 zh-TW 無中文對應，保留英文 `Rule:`。混用英文中文關鍵字會 parse 失敗。

> 本檔後續條文以 Given / When / Then 指涉句型**類別**，`.feature` 內的實際步驟關鍵字一律用上表的中文。

## 1. 句型最少化，但剛好必要

句型數量 = 行為形狀數量，不是操作數量。一個句型覆蓋所有「形狀相同但資料不同」的操作。但當行為形狀 genuinely 不同時，給它專屬句型，不強行塞進同一個。

## 2. Data Table 承載結構化輸入與驗證

- When 的參數不寫進句型字串，放進 Data Table 欄位。
- Then 的多欄位驗證不用多行 And，用一張 Data Table。
- Data Table 欄位放橫向（欄位名為 header row，資料為 data row）。
- 欄位名與規格文件中的欄位名保持 1:1 對應。

## 3. Data Driven——守衛條件：前置狀態必須相容

同一個行為、不同的資料 → 同一個 Scenario Outline。差異全部在 Examples table 裡。

**但前提是：所有 Examples 行能共用同一組 Given（前置狀態）。** 若某些行需要額外的 Given 步驟，它們不能與不需要這些 Given 的行放在同一個 Scenario Outline 中——因為 Scenario Outline 的所有行共用同一個 scenario body（含 Given）。

## 4. Examples 覆蓋精準

每一行 Example 都有存在的理由——覆蓋一個等價類別或一個邊界條件。不窮舉所有可能值，選擇能代表該等價類的最小資料集。

- 每個 precondition 的拒絕路徑至少 1 行。
- 每個 postcondition 的驗證至少 1 行。
- 型別變異各 1 行。

## 5. Scenario 結構決策——Outline vs 獨立 Scenario

從句型.md 的 Examples 規劃表，經兩步分群決定每個 Scenario 的結構：

### 非 Flow 決策樹

```
Scenario 結構決策樹：

Step 0: 句型結構分群（前提）
┌─ 所有行的 When+Then 句型結構相同？
│  ├─ 否 → 按句型結構分群（如：成功路徑 vs 失敗路徑）
│  │       每群各自進入 Step 1
│  └─ 是 → 全部一起進入 Step 1

Step 1: 前置狀態分群
┌─ 群內所有行前置狀態相同？
│  ├─ 是 → Outline（若 ≥2 行）或 Scenario（若 1 行）
│  └─ 否 → 按前置狀態再分群
│       ├─ 「（無）」群 → Outline（若 ≥2 行）或 Scenario（若 1 行）
│       ├─ 群 A（相同前置狀態）→ Outline（若 ≥2 行）或 Scenario（若 1 行）
│       └─ 群 B（不同前置狀態）→ 各為獨立 Scenario，各自帶 Given
```

**關鍵：Scenario Outline 的所有行必須共用相同的 scenario body——包括 Given、When、Then 句型。** 句型結構不同的行（如成功路徑 vs 失敗路徑）絕不能合併為同一個 Outline，即使前置狀態相同。

**絕不在 Scenario Outline 中用註解標註「此行需額外 Given」。** 如果需要額外 Given，就必須拆為獨立 Scenario。

**1 行 Example 不用 Scenario Outline。** 若分群後某群只有 1 行，用普通 Scenario 而非 Outline。

## 6. Placeholder 邊界——只參數化資料值，不參數化句型

Scenario Outline 的 `<placeholder>` 只能出現在：
- Data Table 的值欄位（`| <from> | <to> |`）
- Then 斷言中的具體值（`violation_type 為 "<violation>"`）
- Examples table 的資料行

**不可用 placeholder 替換 Given/When/Then 的句型本身。**

## 7. Spec by Example——用具體資料，不用白話描述

Then 斷言必須是具體的值（`version 為 2`），不可是行為描述（`version 增加 1`）。Background 建立的初始狀態必須有明確的值，後續步驟的驗證值都基於這個已知的初始狀態推算。

## 8. Rule 標註前置/後置，前置在上

每個 Rule 必須標註 `前置` 或 `後置` 前綴：
- `Rule: 前置 - {描述}` — 測試 precondition 驗證（輸入不合法 → 操作被擋）
- `Rule: 後置 - {描述}` — 測試 postcondition 行為（操作成功後的狀態變化）

同一 Feature 內，所有「前置」Rule 排在「後置」Rule 上方。

## 9. Rule 底下單行案例用 `場景`，多行 data-driven 用 `場景大綱`

在 `Rule:` 區塊內，單行測試案例使用 `場景` 關鍵字（zh-TW 中 Scenario 與 Example
同為 `場景`，不存在英文 `Example:` 關鍵字）；多行 data-driven 案例用 `場景大綱` + `例子`。

```gherkin
Rule: 前置（參數）- 房間代碼必須為四位數字
  場景: 房間代碼格式不正確時操作失敗          # ← 單行案例用 場景
    ...

  場景大綱: 多種格式驗證                     # ← 多行 data-driven 用 場景大綱
    ...
    例子:
      | ... |
```

## 10. 變數參照用 `$entity.property` 風格

當 Data Table 或 Examples 中需要引用前置步驟建立的實體屬性時，一律使用 `$entity.property` 語法，不用中文白話描述。

- 引用 ID：`$使用者.id`、`$A.id`、`$lead.id`
- 引用其他屬性：`$學員.email`、`$journey.name`
- `entity` 為該實體在 Given 步驟中的名稱或 name 參數值
- 此風格同時適用於 When Data Table、Then Data Table、Examples table
