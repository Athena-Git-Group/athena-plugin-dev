# CONTEXT.md 格式

## 結構

```md
# {Context 名稱}

{一到兩句話，描述這個 context 是什麼、為什麼存在。}

## 語言（Language）

**Order**：
{這個術語的一到兩句描述}
_避免_：Purchase, transaction

**Invoice**：
交貨後寄給客戶的付款請求。
_避免_：Bill, payment request

**Customer**：
下訂單的個人或組織。
_避免_：Client, buyer, account
```

## 規則

- **要有主見。** 當同一個概念有多個用詞時，挑最好的那個，其餘的列在 `_避免_` 底下。
- **定義要精簡。** 最多一到兩句。定義它「是什麼」，而非它「做什麼」。
- **只收錄這個專案 context 專屬的術語。** 一般性的程式設計概念（timeout、錯誤型別、工具模式）
  不屬於這裡，即使專案大量使用它們也一樣。加入一個術語前先問：這是這個 context 獨有的概念，
  還是一般性的程式設計概念？只有前者該收。
- **當自然形成群集時，用子標題把術語分組。** 如果所有術語都屬於單一內聚的領域，平鋪一列就好。

## 單一 vs 多 context 的 repo

**單一 context（多數 repo）：** repo 根目錄放一份 `CONTEXT.md`。

**多個 context：** repo 根目錄放一份 `CONTEXT-MAP.md`，列出有哪些 context、各自在哪、
彼此如何關聯：

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — 接收並追蹤客戶訂單
- [Billing](./src/billing/CONTEXT.md) — 產生發票並處理付款
- [Fulfillment](./src/fulfillment/CONTEXT.md) — 管理倉庫揀貨與出貨

## Relationships

- **Ordering → Fulfillment**：Ordering 發出 `OrderPlaced` 事件；Fulfillment 消費它們以開始揀貨
- **Fulfillment → Billing**：Fulfillment 發出 `ShipmentDispatched` 事件；Billing 消費它們以產生發票
- **Ordering ↔ Billing**：共用 `CustomerId` 與 `Money` 型別
```

這個 skill 會推斷適用哪種結構：

- 若存在 `CONTEXT-MAP.md`，讀它以找出有哪些 context
- 若只存在根目錄的 `CONTEXT.md`，就是單一 context
- 若兩者都不存在，在第一個術語被釐清時，惰性建立一份根目錄 `CONTEXT.md`

當存在多個 context 時，推斷目前的主題關聯到哪一個。若不清楚，就問。
