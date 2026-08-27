---
name: plugin-contract-spec
description: >
  plugin 自身 prompt 契約改動的 spec skill（skills / agents / commands /
  hooks / scripts）。這類需求沒有資料模型、資料表、畫面或 endpoint，
  產出改成：契約面盤點（grep 實據）→ 逐項改動規格 → 既有規則衝突檢查 →
  驗收條件。由 team-spec-index DELEGATE，不自行宣告 stage。
---

# Plugin Contract Spec

你在寫的規格，標的是**LLM 讀的行為契約**：`skills/**/SKILL.md`、`skills/**/references/*.md`、`agents/*.md`、`commands/*.md`，以及支撐它們的 `hooks/*.sh` 與 `scripts/*.py`。
這類改動沒有實體、資料表、畫面或 endpoint——**不要**產出 data_model 等 pm-to-eng-spec 的產物（見非協商規則 1）。

> **Agent 隔離**：你在全新的 agent 中執行（由 `team-spec-index` 同一 agent 內 DELEGATE），一切從檔案讀取。
> **Headless**：spec stage 不得互動詢問，缺資訊走下方 clarify 協議。

## 這類改動的失敗形狀

契約改動不會「跑不起來」，它的失敗形狀是**一半生效**，且**所有 gate 都顯示 PASS**：
enum 加進 `run-trace.md` 但 `hill-climb.md` 逐 tag 表沒加；規則寫進 `phase-orchestration.md`
但 phase agent 實際讀的 `agents/athena-stage-build.md` 沒鏡射；flow-context 欄位改了語意
但 `hooks/auto-commit.sh` 的 `jq` 消費點沒改（靜默壞、不報錯）。
所以這份規格的主要工作不是描述想要什麼，而是**窮舉誰在消費這個契約**。

## 工具邊界（spec stage shell 契約）

- Write **只能**寫 `specs/` 與 `handoffs/<slug>-spec.md`
- Bash 唯讀（`grep` / `git` 查詢）；**不得**改檔、commit / push、跑會寫入的 script
- **不寫實作程式碼**、**不做 phase 拆解**——那是 plan stage 的工作
- 需要範圍外工具時：在 handoff 回報並停止，不繞道

## 先讀哪些檔

| 檔案 | 用途 |
|------|------|
| `points/<slug>.md` | 需求原文、scorecard、**Risks 段**、point 已查證的消費者清單（是起點不是終點——必須自己再 grep 一次） |
| `specs/<slug>/route.md` | index 寫的路由判定與改動標的清單 |
| `specs/<slug>/clarify/answers.md`（若存在） | 使用者先前的回答 |
| 每個改動標的檔案本身 | **必讀原文**——規格要引用現況，不能憑印象描述 |
| `references/output-templates.md`（本 skill） | 五份產出物 + handoff 的完整模板，動筆前先讀 |

## 產出物（全落在 `specs/<slug>/`；模板見 references/output-templates.md）

```text
specs/<slug>/
  ├─ source/requirement.md      # 需求原文（自 point-report 抄錄，不可變）
  ├─ route.md                   # index 已寫
  ├─ contract-surface.md        # 契約面盤點（核心產出，每列都要 grep 實據）
  ├─ changes/<ID>.md            # 逐項改動規格，一項一檔（目標行為寫行為、不寫文案）
  ├─ conflicts.md               # 既有規則衝突檢查（不可省）
  ├─ acceptance.md              # 驗收條件（機械 + 通讀兩類都要）
  └─ clarify/questions.md       # 僅在有未解問題時
```

## 消費者判定規則（contract-surface 的核心邏輯）

- **逐項列舉式引用 → 必須同步。** 對方把 enum / 欄位 / 規則逐個列出來的，漏一項就是漏一項。
- **指標式引用 → 不需同步。** 對方只寫「詳見 X」的，改 X 就夠。
- **跨語言消費者（bash / python）→ 一律標「壞掉時會不會報錯」**——不報錯的是最高風險，必須在 `acceptance.md` 有對應的機械驗收。
- **「agent 實際會讀哪一份」優先於「文件寫在哪一份」**——reference 寫了但 agent 殼（`agents/*.md`）沒鏡射等於沒寫，兩邊都要列。

## Clarify 協議（headless）

能從 requirement + 標的檔案原文客觀回答的，就地解決。**不可腦補。** 仍有未解問題 →
寫 `specs/<slug>/clarify/questions.md`（逐題編號、附預設選項與影響說明），最終 handoff 發
`FAIL — 待使用者澄清，見 specs/<slug>/clarify/questions.md #spec-gap` 後停止。使用者回答由主對話寫入 `clarify/answers.md` 後重跑 spec stage；重跑先讀 answers.md，已答的不重問。

## Handoff（`handoffs/<slug>-spec.md`；標題級骨架，全文模板見 references/output-templates.md §6）

`# Spec Handoff — <slug>` → `## Stage` → `## Inputs Used` → `## Artifacts Produced` →
`## 契約面摘要`（改動項／錨點／必須同步的消費者／跨語言）→ `## Gate Verdict` → `## Risks` → `## Next Recommended Stage`（plan）

### Gate 條件

`PASS` 需要全部成立：每個改動項都有 `changes/<ID>.md` 且含現況原文引用（帶檔案:行號）；
`contract-surface.md` 每個改動項都有**真實 grep 輸出**；`conflicts.md` 每個改動項都有結論且
有衝突的都有解法；`acceptance.md` 機械與通讀兩類都有；沒有未解的 clarify 問題。任一不成立 → `FAIL` 帶 tag：

| 情況 | Verdict |
|------|---------|
| 有未解澄清問題 | `FAIL — 待澄清 #spec-gap` |
| 契約面盤點缺 grep 實據 | `FAIL — 盤點無實據 #spec-gap` |
| 規則衝突無解法 | `FAIL — 規則衝突未解 #rule-conflict`（原因文字需列出互斥兩條規則的來源，見 run-trace.md Failure Taxonomy 段） |
| 需求本身矛盾或無法工程化 | `FAIL — 需求不可譯 #spec-gap` |

## 非協商規則

1. **不產出 data_model / class_diagram / db_table / screens / api / ui_contract**——那是 `pm-to-eng-spec` 的產物
2. **不做 phase 拆解**——那是 plan stage 的工作
3. **不寫實作程式碼**
4. **契約面盤點必須附真實 grep 輸出**——不得憑印象列消費者，不得虛構輸出
5. **現況必須原文引用並帶檔案:行號**——不得憑記憶描述現況
6. **逐項列舉式引用必須同步**；指標式引用不必——判定寫進盤點表
7. **跨語言消費者必須標「壞掉時會不會報錯」**——不報錯的要有對應機械驗收
8. **`conflicts.md` 不可省**，每個改動項都要有結論
9. **涉及 ≥ 2 檔同一契約面 → `acceptance.md` 必須有通讀驗收項**
10. **不腦補**——答不出來就寫 questions.md 走 FAIL 協議
11. **不使用 taxonomy enum 裡不存在的 tag**
12. **`source/requirement.md` 不可變**——不改寫、不摘要
