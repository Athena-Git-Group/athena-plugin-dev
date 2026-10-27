# 後端視角 Scoring Rubric

PM 需求文件「後端可譯性」評分維度。對應 specformula Phase 02-04
（Entity / BDD Analysis / API Contract）的反向推導 — 後端 RD 看完 PM 文件
能否機械推出資料模型、API 邊界、業務規則、驗證條件、外部依賴。

## 評分尺度

每維度 0-3 分：

| 分數 | 含義 |
|------|------|
| **0** | 完全沒提，後端 RD 必須回頭問 PM 才能繼續 |
| **1** | 略有提及但不夠用，仍需大量補問 |
| **2** | 大致可推但有局部缺口，補 1-2 個問題即可 |
| **3** | 充分，後端 RD 可直接機械萃取，無需追問 |

總分 0-18。**對話中以自然語言陳述「N 個維度給得足、M 個維度需補」，不輸出 yaml score 欄位。**

> 不設「合格分數線」 — 本工具不是 gate，分數只是讓 PM 看見哪幾條缺。

---

## 維度 1：Entity Identifiability（實體可辨識性）

**對應 specformula Phase**：02 (Entity Modeling — erm.dbml 推導)

**追問點**：
- 文件中是否提到主要的「資料對象」（例如使用者、訂單、商品、收藏紀錄）？
- 每個對象有哪些屬性（欄位）被明示或可從情境推出？
- 對象之間的關聯（誰屬於誰、一對多 / 多對多）能否從文件推出？

**評分判準**：
- 0：完全沒提資料對象（例如只有「使用者覺得好用」這種感受陳述）
- 1：點名了主要對象但沒列屬性
- 2：主要對象 + 屬性都有，但關聯不明
- 3：對象、屬性、關聯都齊備

---

## 維度 2：State Transition Clarity（狀態流轉清晰度）

**對應 specformula Phase**：03 (BDD Analysis — Examples 中的狀態前後條件)

**追問點**：
- 資料對象有沒有「狀態」概念（草稿 / 已送出 / 已審核 / 已取消 / 已過期）？
- 狀態之間的轉換規則是否說明？（誰能轉、什麼條件下轉、轉完做什麼）
- 是否說明「終止狀態」（不可再變更）？

**評分判準**：
- 0：完全沒提狀態
- 1：提到狀態名稱但沒說轉換規則
- 2：主要狀態轉換有，但 unhappy path 與終止狀態不明
- 3：狀態圖能完整還原（含 happy / unhappy / 終止）

> 若需求本身是無狀態查詢類（純讀取），可在報告中標註「N/A，本需求無狀態流轉概念」並給 3 分。

---

## 維度 3：API Boundary Definition（API 邊界定義）

**對應 specformula Phase**：04 (API Contract — api.yml 推導)

**追問點**：
- 每個使用者「動作」能否切到一個獨立的後端動作（command/query 邊界）？
- 同一個畫面上的多個動作是否被混為一談（例如「儲存」實際是 create + update + 寄 email 三件事）？
- 動作的觸發者（使用者 / 系統定時 / 外部 webhook）是否明確？

**評分判準**：
- 0：只有「使用者用這個功能」這種大顆粒陳述
- 1：列出主要動作但邊界模糊
- 2：動作邊界清楚但觸發者不明
- 3：每個動作邊界 + 觸發者 + command/query 性質都明確

---

## 維度 4：Business Rule Completeness（業務規則完整度）

**對應 specformula Phase**：03 (BDD Analysis — happy / unhappy / edge case Examples)

**追問點**：
- 規則是否窮盡 happy path（一切順利時）？
- 是否說明 unhappy path（使用者輸入不合法、額度不足、權限不夠）？
- 是否說明 edge case（並發、超時、空集合、極大值）？
- 是否說明錯誤時的使用者可見訊息？

**評分判準**：
- 0：只描述 happy path 一句話
- 1：happy 詳細但 unhappy 完全沒提
- 2：happy + unhappy 有，但 edge case 不全
- 3：happy / unhappy / edge case 與錯誤訊息都齊

---

## 維度 5：Data Validation Rules（資料驗證規則）

**對應 specformula Phase**：02 (erm.dbml 約束) + 03 (Examples 中的邊界值)

**追問點**：
- 每個輸入欄位是否說明：必填 / 選填、格式（email / 電話 / 日期）、長度範圍、數值上下限？
- 是否說明唯一性約束（例如 email 不能重複）？
- 是否說明格式錯誤時的回饋訊息？

**評分判準**：
- 0：完全沒提驗證
- 1：提到必填但沒提格式 / 範圍
- 2：主要欄位有驗證規則，但唯一性 / 訊息不明
- 3：必填、格式、範圍、唯一性、錯誤訊息都齊

---

## 維度 6：Integration Points（整合點 / 外部依賴）

**對應 specformula Phase**：08 (Integration Validation — 外部系統與 side effects)

**追問點**：
- 是否依賴外部系統（金流 / 簡訊 / email / 第三方 API / 內部其他服務）？
- 是否會產生 side effect（寄信、扣款、寄通知、寫 audit log、觸發排程）？
- 外部系統失敗時的處理策略（重試？回滾？人工補單？）是否說明？

**評分判準**：
- 0：完全沒提外部系統與 side effects
- 1：提到外部系統名稱但沒說怎麼用
- 2：外部系統 + 用法清楚，但失敗處理不明
- 3：外部系統、用法、失敗策略都齊

> 若需求本身完全自足（純內部 CRUD 無 side effect），標註「N/A」並給 3 分。

---

## 整體陳述範例（對話用）

```
6 個維度中：
- ✅ 給得足：Entity Identifiability、API Boundary Definition、Integration Points
- 🟡 需補充：State Transition Clarity（缺 unhappy path）、Business Rule Completeness（無 edge case）、Data Validation Rules（欄位格式未說明）

整體看起來骨架清楚，主要是規則完整度 / 驗證細節需要 PM 再補一輪。
```

> 範例只是參考，實際輸出依需求文件而定。**不要寫成 yaml**，純自然語言。
