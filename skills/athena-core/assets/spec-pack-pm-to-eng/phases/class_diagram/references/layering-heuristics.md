# 三層式拆分準則（何時拆、怎麼拆）

> 配合 `SKILL.md` 的完成判準（SRP / OCP）與比例原則。**預設不拆**——簡單 CRUD 走標準三層即可。
> 本檔給「出現什麼訊號才拆 / 才抽」的判斷線索，避免過度設計，也避免該拆不拆。

## 三層基線：各層該放 / 不該放什麼

| 層 | 該放 | 不該放 |
|---|---|---|
| Controller | 接請求、參數轉譯、呼叫 Service、組回應 | 業務邏輯、直接碰 DB |
| Service | **業務邏輯（三層常態）**、交易邊界、協調多 DAO | HTTP / 框架細節 |
| DAO | 資料存取、查詢組裝 | 業務規則 |
| Entity / DTO | 資料 holder（對齊 data_model） | 業務邏輯（不充血） |

## 何時拆 Service（SRP 訊號）

出現以下訊號才拆，否則一個 Service 是常態：

- 方法數 / 行數明顯過大，且內部分成幾群互不相干的職責。
- 一個 Service 同時扛多個不相干實體的核心邏輯。
- 有明顯**不同的變動原因**（兩塊邏輯會因不同需求各自改動）→ 拆開隔離變動。

拆完每個類別職責要能一句話講清；handoff 寫明拆分理由。

## 何時抽協作物件

- **Validator**：驗證邏輯複雜、有多條規則、或被多處複用。
- **Mapper**：Entity ↔ DTO 轉換繁瑣、欄位對應多。
- **計算 helper**：複雜計算（計費、折扣、排程）自成一塊。
- **Strategy / interface（OCP）**：見下。

## OCP 變化點怎麼認（關鍵）

**只有需求出現變化點訊號才抽介面**，否則保持單一實作（YAGNI）：

- 訊號：「目前支援 X、未來 / 也要支援 Y」「依類型不同、行為不同」「可插拔 / 可設定的策略」。
- 做法：抽出介面 / 抽象，各變體為 implement 該介面的類別，**新增變體不改既有類別**。

範例（直接套用）：

```
付款現支援信用卡、未來要加其他付款方式
  → interface PaymentMethod { pay(...) }
  → class CreditCardPayment implements PaymentMethod
  之後新增：class LinePayPayment implements PaymentMethod  ← 只新增類別，不動既有
```

## 反例（不要這樣 — over design）

- 為**單一且無變化點訊號**的實作預先抽介面（每個 Service 都配一個 interface）。
- 把邏輯硬塞進 Entity 做「充血領域模型」——本團隊是三層式，邏輯放 Service。
- 為了「看起來有設計」而拆出資訊量低的類別。

---

## 命名慣例（預設建議，團隊可覆寫）

- `XxxController` / `XxxService` / `XxxDao` / `XxxDTO`。
- 介面用能力 / 角色名（`PaymentMethod`），實作用具體變體名（`CreditCardPayment`）。
