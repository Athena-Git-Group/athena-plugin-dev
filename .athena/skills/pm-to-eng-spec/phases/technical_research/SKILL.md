---
name: technical_research
description: >
  PM → 工程化流水線的**條件式**階段（上游為 specify）。由 specs/arguments.yml 的
  spec_pack.technical_research 控制：`run` 才執行，**缺鍵或 skip 一律略過**（不產 artifact、不 FAIL）。
  執行時把 spec.md 的 NFR、全域需求與限制收斂成一組技術決策，產出 decision-driven 的
  research.md（研究問題 → 選項 → 判準 → 決策 → 風險）與高層總覽型的 techstack.md
  （前端框架 / 型別策略 / 後端分層 / 持久化 / 測試機制）。techstack.md 存在時即為下游
  結構層 / 契約層的技術棧真源；不存在時下游一律沿用預設棧（Nuxt 4 + TypeScript strict）。
  不觸外部網路：素材只限 spec.md、專案既有檔案與既有知識。
  本 phase 為本 repo 原創（非 vendored），判準借鑑自 CH3-SDD-workflow 的 technical-research
  skill（另含 GitHub Spec Kit 概念），授權標註見 pack 根目錄的 VENDORED.md。
---

# technical_research · 技術研究與棧收斂（條件式 / 無 gate）

> 流水線位置：score(gate) → clarify(gate) → specify(gate) → **technical_research（條件式）**
> → 結構層 → 契約層 → 規格層。
> **本階段不是 gate**：它不擋任何下游。`run` 時 artifact 缺失才會由編排器判 FAIL；
> `skip`（含缺鍵的預設）時本階段**視為已完成**，下游照常執行。
> **本階段前後端共用（target 無關）**——後端 track 也可能有持久化 / 分層決策要拍板。

## 定位（為什麼是條件式、為什麼預設不跑）

本 pack 的預設棧是**已定案**的（Nuxt 4 + TypeScript strict，見
`../pm-to-eng-flow/references/frontend-stack-conventions.md`）。棧已定案的專案跑技術研究
只會產出一份重述既有慣例的文件，毫無資訊量。

因此本階段的預設是**不跑**：

| `spec_pack.technical_research` | 行為 |
|-------------------------------|------|
| **缺鍵（預設）** | **略過**：不建 `specs/<slug>/technical_research/` 目錄、不產 artifact、**不 FAIL**；編排器在最終 handoff 的 Risks 記「未做技術研究，沿用預設棧」 |
| `skip` | 同上（顯式宣告） |
| `run` | 執行本階段；兩份 artifact 任一缺失或為空 → 編排器判 `FAIL — technical_research 產出缺失 #skill-defect` |

> 缺鍵預設 `skip` 是**既有專案行為完全不變**的唯一保證：沒有動過
> `specs/arguments.yml` 的專案，跑起來與本階段不存在時逐字相同。
> **不得**把預設改成 `run`，也不得「推斷需不需要研究」——設定缺值就是 `skip`，
> 不推斷、不互動詢問。

## 先讀（references/）

- `references/research-artifact.md` — `research.md` 的最小必要資訊判準（決策骨架、
  聚焦度、替代方案品質、未驗證假設的揭露方式）。產 `research.md` 前必讀。
- `references/techstack-artifact.md` — `techstack.md` 的最小必要資訊判準（高層分類、
  固定欄位、來源回指、「本次不引入」清單）。產 `techstack.md` 前必讀。
- （選讀增益）`.agents/constitution/` 若存在（`CONSTITUTION.md`、`shared.md`、
  `skills/technical-research/*.md`），把其中規則視為額外約束套用。
  **缺這個目錄是常態，缺檔照常執行本 phase，不得因此停止、不得回報缺失。**

## 輸入

- `specs/<slug>/specify/spec.md`（**唯一需求真源**；首行 STATUS 必須為 `READY`）——
  特別是其「全域需求」（NFR）、「邊界情況」、「資料維度與範例資料」（量級 / 保存 / PII）
  與「假設」段：技術研究問題一律從這些段落推導，**不自行發明研究題目**。
- `specs/<slug>/score/score-report.md`（選讀，取複雜度線索）。
- `../pm-to-eng-flow/references/frontend-stack-conventions.md`（必讀對照）——
  本 pack 的**預設棧**。研究結論與它一致時直接沿用並註明；不一致時必須在
  `research.md` 寫明「為什麼本專案要偏離預設棧」，不得無理由改棧。
- 專案既有檔案（選讀）：`package.json`、既有 `src/` 佈局、既有 `.athena/` 慣例等，
  用來確認「這個專案實際上長什麼樣」。**唯讀**，不得修改。

## 輸出

- `specs/<slug>/technical_research/research.md` — decision-driven 的研究紀錄。
  每個決策一個區塊，必含：**研究問題 → 選項 → 判準 → 決策 → 風險**，
  並標「**已定 / 待定**」與**依據來源**（`spec.md#<FR/NFR 編號>`、既有檔案路徑、
  或 `frontend-stack-conventions.md`）。判準見 `references/research-artifact.md`。
- `specs/<slug>/technical_research/techstack.md` — 收斂後的技術棧宣告，分五類：
  **前端框架 / 型別策略 / 後端分層 / 持久化 / 測試機制**，每項標
  `來源：research.md#<決策>`。判準見 `references/techstack-artifact.md`。
- `specs/<slug>/handoffs/technical_research.md`（依 handoff-contract）——
  含「已定 / 待定」決策數、偏離預設棧的項目、需後續 spike 驗證的項目。
- 有高影響缺口時**追寫**（append）`specs/<slug>/clarify/questions.md`——見「缺口升級協議」。

## 執行步驟

1. [ ] 確認 `spec_pack.technical_research` = `run`。缺鍵或 `skip` → **不執行本階段、不建目錄、
       不寫任何檔**，直接回報「已略過（設定未開啟）」。
2. [ ] 確認 `specs/<slug>/specify/spec.md` 存在、非空、首行為 `STATUS: READY`；否則回報並中止。
3. [ ] 從 `spec.md` 的全域需求 / NFR / 邊界 / 量級 / 保存 / PII 逐條掃出**會改變技術選擇的**
       問題，列成研究問題清單。與技術選擇無關的需求不列（判準見
       `references/research-artifact.md` 判準 2）。
4. [ ] 讀 `frontend-stack-conventions.md` 與專案既有檔案，先把「已由預設棧或既有專案決定」的
       問題**標為已定**並註明依據——這一步通常會消掉大半清單。
5. [ ] 對剩下的問題逐一收斂：列 2–3 個**真有 trade-off 差異**的選項、寫出判準
       （對回 `spec.md` 的哪條需求 / NFR）、下決策、記風險與未驗證假設。
       資訊不足而不阻塞主結論者標「**待定**」並寫清楚待定什麼，**不腦補、不編數值**。
6. [ ] 寫 `research.md`，逐區塊自檢 `references/research-artifact.md` 的**五條判準**
       （判準 5 = 偏離預設棧必須寫理由，MUST，本 pack 特有——不得略過）。
7. [ ] 從 `research.md` 抽出最終採用結果，寫 `techstack.md`（五類 + 來源回指 +
       「本次不引入的技術」），逐項自檢 `references/techstack-artifact.md` 的**五條判準**。
       **不把研究理由整段搬進 `techstack.md`**。
8. [ ] 高影響缺口（會改變決策集合 / 比較維度 / 採納方向者）走「缺口升級協議」。
9. [ ] 寫 `handoffs/technical_research.md`。

## 缺口升級協議（headless；本 pack 無互動訪談、無 slash 委派）

本 pack 在 spec stage shell 內執行，**不能**互動提問，也**不能**呼叫其他 skill 的
slash 指令。所有缺口一律走既有的檔案協議，**不另立第二套協議、不另開新檔**：

1. **只升級會改變決策集合、比較維度或採納方向的缺口**才算高影響。
2. 局部不確定性（未量測的容量 / 效能、尚未驗證的相容性）**不升級**——寫在對應決策的
   「風險」欄並標「待定」即可。
3. 高影響缺口每輪只取最高影響的 **1–3 題**，以 PM-friendly 措辭**追寫（append）**到既有的
   `specs/<slug>/clarify/questions.md`
   （**四支共用此檔**：clarify / specify / technical_research / ui_prototype；題號 `Q<n>` 全檔連號、標題行標 `[<phase>]` 來源——**題號與標記契約見 pack 根 `SKILL.md`「`clarify/questions.md` 共用契約」**），
   附建議選項與影響說明。
4. 本階段**不是 gate**：升級缺口後仍把已收斂的部分寫完，`research.md` 對應決策標「待定」，
   本階段不自行中止流水線。**編排器的裁決已明定**（pack 根 `SKILL.md` 執行程序第 5 步、
   Gate Verdict 映射表對應列、非協商規則 9）：本階段追寫 `questions.md`
   **不改變 Gate Verdict、不停止**，但編排器**必須**把「追寫 N 題待澄清」記進最終 handoff 的 Risks，
   不得靜默吞掉。

## 完成判準

- [ ] `research.md` 每個決策區塊都有：研究問題、選項、判準、決策、風險，且標「已定 / 待定」。
- [ ] 每個決策都有**依據來源**（`spec.md#<編號>` / 既有檔案路徑 / `frontend-stack-conventions.md`），
      無「憑經驗」這類無來源敘述。
- [ ] 每個決策的選項至少 1 個是**有比較價值的真替代方案**（不是近義重述）。
- [ ] 未驗證的容量 / 效能 / 相容性假設已明示為風險或「待定」，**未寫成既定事實**。
- [ ] `techstack.md` 五類（前端框架 / 型別策略 / 後端分層 / 持久化 / 測試機制）皆表態，
      不適用者明標 `N/A + 原因`；每項有 `來源：research.md#<決策>`。
- [ ] `techstack.md` 有「本次不引入的技術」節。
- [ ] 偏離預設棧的項目在 `research.md` 有明寫理由；未偏離者明寫「沿用預設棧」
      （`references/research-artifact.md` **判準 5**，MUST）。
- [ ] 全程未觸外部網路、未安裝任何套件、未修改 `specs/<slug>/` 以外的檔案。

## 斷點續跑

`spec_pack.technical_research` = `run` 且 `research.md` 與 `techstack.md` **皆存在且非空**
→ 本 phase **跳過不重跑**（沿用 wrapper 執行程序第 0 步）。
`skip`（含缺鍵）→ **永遠視為「已完成（略過）」**，不因缺檔重跑、不因缺檔 FAIL。

## references/

- `references/research-artifact.md` — `research.md` 的最小必要資訊判準（**判準 1–5** + good / bad 對照；
  判準 5「偏離預設棧必須寫理由」是本 pack 特有的 MUST）。
- `references/techstack-artifact.md` — `techstack.md` 的最小必要資訊判準（**判準 1–5** + good / bad 對照）。

## 非協商規則

1. **缺鍵 = `skip`** —— `spec_pack.technical_research` 缺值時**略過本階段**，不推斷、
   不互動詢問、不產半套 artifact。既有專案的行為必須與本階段不存在時逐字相同。
2. **`techstack.md` 是棧真源，但只在它存在時** —— 本階段略過時，下游一律沿用
   `../pm-to-eng-flow/references/frontend-stack-conventions.md` 的 Nuxt 4 + TypeScript strict
   （見 pack 根 `SKILL.md` 非協商規則 5）。**不得**產出一份只寫「沿用預設」的空殼檔來假裝跑過。
3. **不觸外部網路** —— 不查網頁、不裝套件、不跑 `npm install` / `pip install`。素材只限
   `spec.md`、專案既有檔案與既有知識；資訊不足就標「待定」。
4. **絕不腦補** —— 未量測的容量 / 效能 / 相容性結論標為風險或「待定」，不寫成既定事實；
   不自填版本號、門檻值與 SLA。
5. **每個決策必有來源** —— 回指 `spec.md` 的 FR / NFR 編號、既有檔案路徑或預設棧慣例；
   研究問題不得脫離 `spec.md`（不寫成通用技術教學）。
6. **兩份 artifact 分工不得混** —— 詳細取捨與替代方案留在 `research.md`；
   `techstack.md` 只寫最終採用結果、用途與來源回指。
7. **不越界** —— 不寫實作程式碼、不改 `src/`、不做 plan stage 的工作（任務拆解、
   類別圖、系統分析都不是本階段的事）；不修改 `../pm-to-eng-flow/references/` 下的任何檔案。
8. `specs/<slug>/specify/spec.md` **缺失、為空、或首行非 `STATUS: READY`** 時，**回報並中止**——
   **不得**改讀 `clarify/` 的訪談產出、**不得**回頭讀 `source/requirement.md` 自行腦補、
   **不得**產出空 artifact 後宣告完成。
9. `.agents/constitution/` 是**選讀增益**：存在則套用，**缺檔照常執行**，不得因缺它停止或 FAIL。
