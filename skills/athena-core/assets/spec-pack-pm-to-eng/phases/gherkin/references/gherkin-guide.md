# 中文 Gherkin 撰寫指南 · 細則

> 配合 `SKILL.md` 的執行步驟與完成判準。本檔定義「怎麼把已釐清的需求寫成可執行的中文 .feature」。
> 三個姊妹檔：Scenario Outline / Data Table 用 `scenario-outline-guide.md`；邊界覆蓋用 `boundary-checklist.md`；完整成品看 `example.feature`。

本版 .feature 的三個設計理念（與一般 BDD 的差異）：

1. **Spec by Example** — 每個場景用 **`specify/spec.md`「資料維度與範例資料」段的真實範例資料**寫具體值，不寫抽象斷言（見 §4）。
2. **邊界優先（QA shift-left）** — 邊界 / 錯誤情境是第一級公民，**排在 happy path 之前**（見 §5）。
3. **善用 Scenario Outline** — 同一規則的多個案例（正常 + 邊界 + 錯誤）收進 Examples 表（見 `scenario-outline-guide.md`）。

---

## 1. 語言設定（必要）

下游 runner（Cucumber：Java / Python）要靠檔頭才認得中文關鍵字。**每支 .feature 第一行必為**：

```gherkin
# language: zh-TW
```

zh-TW 關鍵字對照（只用這些，混用英文中文會 parse 失敗）：

| 概念 | 英文 | 中文關鍵字（本版採用） |
|---|---|---|
| Feature | Feature | `功能` |
| Rule | Rule | `Rule`（⚠️ zh-TW 無中文 Rule 字，保留英文 `Rule:`） |
| Background | Background | `背景` |
| Scenario | Scenario | `場景` |
| Scenario Outline | Scenario Outline | `場景大綱` |
| Examples | Examples | `例子` |
| Given | Given | `假設` |
| When | When | `當` |
| Then | Then | `那麼` |
| And | And | `而且` |
| But | But | `但是` |

> `Rule:` 在 zh-TW 沒有對應中文關鍵字。若團隊 Gherkin 版本不支援 `Rule`（Gherkin 6 前），改用「一個 Feature 對一條規則」或 `@rule-xxx` 標籤替代，並於 handoff 標明。

---

## 2. Feature / Rule / Scenario 切分

| 層級 | 對應 | 一句話 |
|---|---|---|
| `功能` Feature | 一個業務能力（通常對齊一個 endpoint 群 / 一個畫面流程） | 「使用者能做的一件事」 |
| `Rule` | 該能力下的一條業務規則 | spec.md 的一條 FR / 全域需求 / 邊界情況 |
| `場景` Scenario | 規則的一個具體案例 | 一筆真實資料走一遍 |

切分準則：
- **一條 spec.md 的 FR / 全域需求 → 一個 `Rule` 區塊**；規則底下放它的正常 / 邊界 / 錯誤場景。
- 規則有多個資料案例 → 收進 `場景大綱` + `例子`（見 `scenario-outline-guide.md`），不要複製貼上多個 `場景`。
- Feature 開頭寫一段 `角色 + 目標 + 效益`（As / I want / So that）的中文敘述，對齊 spec.md 的使用者故事與成功標準。

---

## 3. Scenario 三段式品質

| 段 | 規則 |
|---|---|
| `假設` Given | 只描述**前置狀態**（資料已存在、處於某狀態），不放動作。 |
| `當` When | **單一**觸發動作（一個 endpoint 呼叫 / 一個畫面操作）。一個場景只有一個 When。 |
| `那麼` Then | **可驗證**的結果：狀態碼 / 回應欄位值 / 實體狀態變化 / 畫面變化。一個結果一行，用 `而且` 串。 |

- 措辭用**使用者行為 / 業務語言**，不寫死 runner API（runner-agnostic，見 SKILL「.feature 是 runner-agnostic」）。
  - ✅ 後端：`當 我以金額 1000 對訂單 ORD-001 申請退款`
  - ❌ 後端：`當 我 POST /orders/ORD-001/apply-refund {"amount":1000}`（綁死 HTTP 細節）
  - ✅ 前端：`當 我在訂單詳情頁點「申請退款」並輸入 1000`
- Then 對齊上游契約：後端對 openapi.yaml 的回應 + erm.dbml 的實體狀態；前端對 screen-map 的畫面 / 導航。
- 狀態碼 / 錯誤碼語意以 `../../api/references/api-conventions.md` §2、§3 為準（400 語法 / 422 業務驗證 / 409 衝突 / 404 不存在）。

---

## 4. Spec by Example — 具體值，不抽象（嚴格溯源）

每個場景用**真實的具體值**，不寫「某金額」「合法的 email」這種抽象詞。具體值的來源與嚴格度：

| 值的角色 | 來源 | 缺了怎麼辦 |
|---|---|---|
| **判定值**（決定通過 / 失敗：金額上限、enum 值、長度邊界、狀態） | spec.md 的範例資料 / FR；openapi.yaml 的 `minimum`/`maximum`/`enum`/`pattern`/`maxLength` | **不自編** → 標 `# 待釐清:<缺什麼>` 並寫進 handoff 回饋（見 §7、`boundary-checklist.md`） |
| **點綴值**（不影響判定：人名、訂單編號、時間戳） | 可用擬真代表值（`王小明`、`ORD-001`、`2026-06-17`） | 直接用擬真值即可 |

- `specify/spec.md` 的「資料維度與範例資料」段承載了每個核心實體至少 3 筆真實範例資料（承載義務見 `../../specify/references/spec-structure.md` §6）——**那批資料就是本階段 Examples 表的素材來源**。
- 判定值務必能在 handoff 的覆蓋矩陣裡回指到來源（`spec.md#FR-00X` 或 `openapi.yaml#Order.amount.maximum`）。
- ✅ `假設 訂單 ORD-001 的金額為 1000 元`
- ❌ `假設 有一張金額合理的訂單`（抽象、無法執行、AI 會各自腦補）

---

## 5. 場景排序（邊界優先 · QA shift-left）

**在每個 `Rule` 區塊內，場景的排列順序**：

```
1. 邊界值與錯誤路徑（最容易暴露需求漏洞的先寫、先排）
2. 等價類的代表正常案例
3. 完整 happy path
```

為什麼把邊界往前：
- 邊界是**最常暴露需求未定義**之處。先寫邊界，能在最早期逼出「PM 沒講清楚的規則」→ 立刻回饋（§7），而不是等實作到一半才發現。
- 下游 red/green 的 AI 一打開 .feature 就看到邊界，實作時**邊界條件先明確**，不會只做 happy path。
- 邊界清單由 `boundary-checklist.md` 逐類產生，對齊 openapi 驗證關鍵字與 spec.md 狀態機。

> Scenario Outline 的 `例子` 表內也照此精神：邊界列與錯誤列排在正常列之前，並用標籤分群（`@boundary` / `@error` / `@happy`），見 `scenario-outline-guide.md`。

---

## 6. 標籤慣例（讓下游可選擇性執行）

| 標籤 | 意義 |
|---|---|
| `@backend` / `@frontend` | target 變體（fullstack 分流時用） |
| `@happy` | 正常路徑 |
| `@boundary` | 邊界值案例 |
| `@error` | 錯誤 / 例外路徑 |
| `@待釐清` | 此場景依賴未定義的需求，**暫不可執行**，等 clarify 回饋（見 §7） |

---

## 7. 缺則回報 · 不腦補（與上游的迴圈）

寫場景時若發現**需求沒定義的邊界 / 規則 / 值**（例：「退款金額上限是多少？spec.md 沒寫」）：

1. **不要自己填一個數字**（違反「絕不腦補」）。
2. 把該場景標 `@待釐清`，步驟內用 `# 待釐清:<具體問題>` 註記。
3. 在 `handoffs/gherkin.md` 的「回饋訊號」段列出這些缺口（PM-friendly 問句），交由編排器決定：補進 `specify/spec.md` 後重跑本階段，或回退 clarify → specify。

> 這就是「邊界探索 shift-left」的迴圈：邊界優先 → 暴露缺口 → 回饋上游 → 釘死後落地。詳見 `boundary-checklist.md` §缺則回報。

---

## 8. ✅ / ❌ 快速對照

```gherkin
# ✅ 具體值、單一 When、可驗證 Then、邊界優先
場景: 退款金額超過訂單金額被拒（邊界 max+1）
  假設 訂單 ORD-001 的金額為 1000 元、狀態為「已付款」
  當 我對訂單 ORD-001 申請退款 1001 元
  那麼 退款應被拒絕
  而且 回應錯誤碼應為 REFUND_EXCEEDS_TOTAL（HTTP 422）
  而且 訂單 ORD-001 的狀態仍為「已付款」
```

```gherkin
# ❌ 抽象值、多個動作、無法驗證、綁死 runner
場景: 退款流程
  假設 有一張訂單
  當 使用者送出退款並且系統處理完成而且通知寄出
  那麼 一切正常
```
