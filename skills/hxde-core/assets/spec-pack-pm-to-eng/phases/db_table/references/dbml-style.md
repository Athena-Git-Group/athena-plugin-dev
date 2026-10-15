# DBML 撰寫慣例 · 風格指南

> 配合 `SKILL.md`。DBML **語法**本身 agent 已內建——本檔只定義「團隊慣例」:
> 哪些東西一定要寫、怎麼寫,才讓 `erm.dbml` 可讀、可追溯、能承載業務語意。
> 命名慣例(snake_case / FK 命名 / 布林與時間欄位前後綴)見 `persistence-allowlist.md`,本檔不重複。

## 1. 每個 Table 都要有業務 Note

- **Table 層 `Note`**:寫這張表「是什麼」(業務定義),不是覆述欄位清單。
- **關鍵欄位 inline `note`**:語意不明顯、帶約束、或屬於 enum 的欄位都要寫。
- 純機制欄位(`created_at` / `version` / `deleted_at`)可省略 note。

## 2. 不變條件(invariants)寫進 Table 的 Note block

有狀態 / 有衍生 / 有跨欄一致性的實體,把**不變條件**寫進 Table 的 `Note` block。
來源是 data_model:**derived 屬性的計算來源**與**生命週期的合法轉移**,在這裡落成文字。

| 種類 | 範例 |
|---|---|
| 算術一致性 | `total = sum(order_item.subtotal)` |
| 狀態機 | `status 轉換須遵循 pending → confirmed → shipped → delivered（可 cancelled）` |
| 值域 | `total >= 0` |

> 不變條件是**文件化**,不等於 DB 約束。能落成 CHECK 的(如 `total >= 0`)同時落 CHECK;
> 跨表 / 狀態機這類 DB 難強制的,至少在 Note 留下,讓下游 build / api / gherkin 接得到。

## 3. 索引以 `Indexes` block 明確宣告

- 用 `Indexes { }` 寫出來,不要只靠口頭或 handoff 描述。
- 哪些要建、最左前綴、避免冗餘見 `persistence-allowlist.md` §7。

## 4. ✅ 好的做法

```dbml
Table order {
  order_id    varchar(36)   [pk, note: '訂單唯一識別碼']
  customer_id varchar(36)   [not null, ref: > customer.customer_id, note: '下單客戶']
  total       decimal(10,2) [not null, note: '訂單總金額,須 >= 0']
  status      varchar(20)   [not null, note: '訂單狀態: pending/confirmed/shipped/delivered/cancelled']
  created_at  timestamp     [not null]

  Indexes {
    customer_id
    status
    created_at
  }

  Note: '''
  訂單聚合根
  不變條件:
  - total = sum(order_item.subtotal)
  - status 轉換須遵循狀態機: pending → confirmed → shipped → delivered（可 cancelled）
  '''
}
```

## 5. ❌ 避免的做法

```dbml
Table order {
  id   int   [pk]   // 缺說明
  amt  float        // 縮寫 + 金額用 float(精度問題,應 decimal)
  stat int          // 用數字代替 enum,讀不出語意
  // 缺 Indexes block
  // 缺 Table Note 與不變條件
}
```

對照修正:

- 表名 / 欄位名照 `persistence-allowlist.md` 的 **snake_case**,不用縮寫。
- 金額用 `decimal(p,s)`,不用 `float`(浮點精度問題)。
- 列舉用語意字串(或 lookup table),不用裸數字。
- 每個 Table 有 `Note`;有狀態 / 衍生的補不變條件。
- 索引用 `Indexes` block 明寫。
