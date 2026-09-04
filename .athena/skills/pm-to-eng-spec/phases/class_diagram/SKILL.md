---
name: class_diagram
description: >
  PM → 工程化流水線的階段 2a（後端 track，物件設計，對齊 data_model）。讀取 data_model 的實體模型與已釐清的需求，
  推導**物件設計模型**並輸出 Mermaid classDiagram。對齊團隊的三層式架構
  （Controller / Service / DAO + Entity / DTO），並把複雜需求的物件拆分畫清楚
  （遵循 SRP / OCP）。Entity / DTO 對齊 data_model 的實體；db_table 與本階段平行（同讀 data_model、互不依賴），api 對齊本階段的物件邊界。複雜度比例原則：簡單 CRUD 只畫
  標準三層骨架（或標 N/A 略過），複雜需求才畫出拆分。
  由 pm-to-eng-flow 在 target = backend / fullstack 時以全新 agent 觸發。前提：specify 已 READY、data_model 已產出實體模型。
---

# class_diagram · 物件設計模型（階段 2a / 後端 track · 物件設計）

> 流水線位置：score(gate) → clarify(gate) → specify(gate) → data_model(實體真相) → **class_diagram**(物件設計) ∥ db_table(持久化) → api → gherkin。
> 對齊 data_model：實體集合的真相在 data_model；本階段把那些實體**拆成三層物件與職責**，不自行增刪實體集合。db_table 與本階段平行、同讀 data_model。

## 架構：三層式（layered）

本團隊後端是三層式架構，class diagram 就照這個畫，**不套 DDD 充血領域**：

- 基本骨架：**Controller → Service → DAO** + **Entity / DTO**（資料 holder）。
- 業務邏輯放在 Service —— 這是三層式的常態，**不是貧血缺陷**。
- **複雜需求才拆**：一個 Service 過胖 → 依 SRP 拆成多個 Service / 抽出協作物件
  （Validator / Mapper / Strategy / 計算 helper）；需要擴充點 → 依 OCP 用介面 / 策略。

## 複雜度比例原則（重要）

- **簡單（CRUD / 單一 Service 就夠）** → 只畫標準三層骨架，或在 handoff 標
  `N/A — 標準三層，無額外拆分`，不硬擠一張低資訊量的圖。
- **複雜（多分支規則 / 跨實體流程 / 明顯該拆）** → 畫出 SRP/OCP 拆分：哪些 Service、為何拆、介面 / 策略在哪。
- 複雜度從 spec.md 判斷（實體數、行為數、規則分支）；可參考 `score/score-report.md` 的維度分數當線索。

> 何時拆 / 怎麼抽 / OCP 變化點怎麼認、over-design 反例見 `references/layering-heuristics.md`。

## 輸入

- `specs/<slug>/data_model/data-model.md`（**實體集合真相**；Entity / DTO 對齊其實體，不自行增刪實體集合）
- `specs/<slug>/specify/spec.md`（行為 / 規則細節；首行 STATUS 必須為 READY）——
  其故事專屬 FR / NFR、全域需求與邊界情況即行為與規則的真相
- `specs/<slug>/score/score-report.md`（選讀，當複雜度線索）

## 輸出

- `specs/<slug>/class_diagram/class-diagram.mmd`（Mermaid `classDiagram`）
  - 三層類別：Controller / Service / DAO + Entity / DTO
  - 複雜時：額外協作物件（Validator / Mapper / Strategy / helper）與其職責
  - 類別間關係（關聯 / 依賴 / 必要的介面實作）
- `specs/<slug>/handoffs/class_diagram.md`（依 handoff-contract；簡單時可標 N/A）

## 執行步驟

1. [ ] 判斷複雜度（簡單 → 標準三層骨架 / N/A；複雜 → 往下拆）。
2. [ ] 對應出 Controller / Service / DAO 與 Entity / DTO。
3. [ ] 複雜需求：找出該拆的職責，依 SRP 拆 Service / 抽協作物件；依 OCP 留擴充點。
4. [ ] 連類別關係（關聯 / 依賴 / 介面實作）。
5. [ ] 輸出 Mermaid classDiagram；handoff 列出拆分理由與關鍵設計決策（或標 N/A）。

## 完成判準

**三層式對齊（layered，不充血）**
- [ ] 需求每個行為都落到某 Controller / Service 方法；資料存取一律走 DAO。
- [ ] 業務邏輯放在 Service（三層常態），未為「充血」把邏輯硬塞進 Entity。
- [ ] Entity / DTO 與 data_model 的實體對齊（同名同義，無自行增刪實體集合）。

**比例原則（不過度設計）**
- [ ] 簡單 CRUD 只畫標準三層骨架，或於 handoff 標 `N/A — 標準三層，無額外拆分`；未硬擠低資訊量的拆分。
- [ ] 每一個額外協作物件（Validator / Mapper / Strategy / interface…）都有「需求觸發的理由」，不是投機抽象。

**SRP（單一職責）**
- [ ] Service 過胖才依 SRP 拆；每個拆出的類別職責單一、邊界說得清，handoff 寫明拆分理由。

**OCP（開放擴充）— 由需求的變化點觸發**
- [ ] 需求**明示或明確預示**多型 / 未來會增的變體時，抽出**介面 / 抽象**，各變體為 implement 該介面的類別，新增變體**不改既有類別**
      （例：付款現支援信用卡、未來要加其他 → `PaymentMethod` 介面 ← `CreditCardPayment` 實作；之後加 `LinePayPayment` 只新增類別）。
- [ ] 需求**沒有**變化點訊號時，**不**預先抽介面 / 策略（YAGNI）；保持單一實作。

**可交接**
- [ ] 類別關係（關聯 / 依賴 / 介面實作）標示清楚。
- [ ] handoff 列出關鍵設計決策與拆分理由（簡單時可標 N/A）。

## references/

- `references/layering-heuristics.md` — 三層式拆分準則（何時拆 Service、何時抽 Validator / Mapper / Strategy、OCP 變化點怎麼認、over-design 反例）+ 命名慣例。

> 不另附 Mermaid `classDiagram` 語法速查——agent 已內建語法。

## 非協商規則

1. 依 data_model（實體集合）與 spec.md（行為 / 規則）設計，不擴張需求未提及的物件、不自行增刪 data_model 的實體集合。
2. **遵循團隊三層式架構**（Controller / Service / DAO）；邏輯放 Service 是常態，不為「充血」硬把邏輯塞進 Entity。
3. **拆分服務於 SRP / OCP**，不為拆而拆；簡單需求不過度設計。
4. `specify/spec.md` 的 STATUS 非 READY 時，回報並中止。
5. 探索既有 codebase 時優先用 graphify；探索結果回頭跟使用者確認，不擅自當定論。
6. `specs/<slug>/specify/spec.md` **缺失、為空、或首行非 `STATUS: READY`** 時，**回報並中止**——
   **不得**改讀 `clarify/` 的訪談產出、**不得**回頭讀 `source/requirement.md` 自行腦補、
   **不得**產出空 artifact 後宣告完成。
