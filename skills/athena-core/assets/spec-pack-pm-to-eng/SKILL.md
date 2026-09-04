---
name: pm-to-eng-spec
description: >
  Spec stage 的多 phase 編排 skill：把 PM 需求文件轉成工程化規格——
  score（可譯性 gate）→ clarify（釐清 gate）→ specify（需求結構化 gate，
  產出 spec.md＝結構層以後的唯一需求真源）→ 結構層（data_model /
  class_diagram / db_table 或 screens）→ 契約層（api / ui_contract）→
  ui_prototype（前端 / fullstack 的靜態雛形）→ gherkin 規格層。
  改編自 athena-skills 的 pm-to-eng-flow，已適配
  athena-flow spec stage 契約：單一 spec agent 內順序執行 phases、
  產出落在 specs/<slug>/、gate verdict 映射為 PASS / FAIL 格式。
stage: spec
---

# PM → Engineering Spec（spec stage 編排）

你是 spec stage 的**phase 編排者**，在**單一 agent 內順序執行** `phases/` 下的
子 skill。原版 pm-to-eng-flow「每 phase 開新 agent」的模型在 spec stage shell 內
**不可用**（shell 無 Agent 工具）——以「artifact 落盤 + 逐 phase 讀檔」替代
agent 隔離：每個 phase 只讀自己需要的檔案，不把整份 artifact 重複帶著走。

## 先讀哪些檔（progressive disclosure）

- `points/<slug>.md` — point-report，取需求敘述、slug、verdict
- `specs/arguments.yml`（若存在）— 取 `spec_pack.target` 與 `spec_pack.frontend_verify`
- **不要**預先讀所有 phase 的 SKILL.md——輪到哪個 phase 才 Read `phases/<name>/SKILL.md`

## 設定解析

| 設定 | 來源 | 缺值時 |
|------|------|--------|
| `target`（backend / frontend / fullstack） | `specs/arguments.yml` 的 `spec_pack.target` | 從需求文字推斷：出現畫面 / UI / 頁面 / 表單 / 操作流程等字樣 → `fullstack`；否則 `backend`。**推斷結果與依據必須寫進最終 handoff 的 Risks** |
| `frontend_verify`（mcp / playwright / agent-browser / vitest-testing-library） | `spec_pack.frontend_verify` | 視為未指定；gherkin 仍產 runner-agnostic `.feature`，在 handoff 標注建議機制 |

Spec stage 是 headless 執行——**不得**以互動詢問取得設定；缺值一律走上表的
推斷 + 記錄假設。

## Workspace（對照原版 eng-output/，vendored 檔已改寫）

所有產出落在 `specs/<slug>/`（`<slug>` 沿用 point-report 的 slug）：

```text
specs/<slug>/
  ├─ source/requirement.md      # 需求原文（自 point-report 抄錄，不可變）
  ├─ score/score-report.md      # Phase 0，開頭含 VERDICT
  ├─ clarify/clarified.md       # Phase 1，開頭含 STATUS（**specify 的輸入**）
  ├─ clarify/questions.md       # 待澄清問題（headless 協議；clarify / specify /
  │                             #   ui_prototype **三支共用**，見下方共用契約）
  ├─ clarify/answers.md         # 使用者的回答（由 flow 主對話寫入）
  ├─ specify/spec.md            # Phase 2，開頭含 STATUS；**結構層以後的唯一需求真源**
  ├─ specify/requirements-checklist.md      # Phase 2 規格品質自檢
  ├─ design/                    # 【輸入】設計師視覺稿，選用，pack 不寫入
  ├─ data_model/ class_diagram/ db_table/   # 結構層（backend）
  ├─ screens/                               # 結構層（frontend）
  ├─ api/ ui_contract/                      # 契約層
  ├─ ui_prototype/              # 【輸出】前端 / fullstack 專屬：ui-plan.md + index.html + <screen>.html
  ├─ gherkin/                   # 規格層（fullstack 分 backend/ frontend/）
  └─ handoffs/<stage>.md        # 各 phase 的內部交接便條
```

最終 stage handoff 寫 `handoffs/<slug>-spec.md`（repo 根目錄，flow 契約位置）。

## `clarify/questions.md` 共用契約（三個寫入者）

這份檔是本 pack **唯一由 phase 主動追寫**的「問使用者」通道，有 **3 個寫入者**：
`clarify`、`specify`、`ui_prototype`。三者一律**追寫（append）**，
**不得**重寫全檔、**不得**重編既有題號；**不另立第二套協議、不另開新檔**。

- **題號**：全檔連號 `Q<n>`。新題取「檔內現有最大題號 + 1」；檔案不存在時自 `Q1` 起。
- **來源標記**：每題標題行必須標出提問的 phase——
  `### Q<n> · [<phase>] <一句話問題>`，`<phase>` ∈ `clarify` / `specify` /
  `ui_prototype`。使用者要能一眼看出某題是哪一階段問的。
- **內容**：PM-friendly 措辭，附建議選項與「答案會改變什麼」的影響說明。
- **已回答標示**：使用者的回答由 flow 主對話寫入 `clarify/answers.md`。
  後續輪次讀到 `answers.md` 已涵蓋的題目時，在該題標題行末追加 `（已回答）`——
  **不刪題、不改號**，歷史必須可追。
- **每輪題數**：每支 phase 每輪 ≤ 3 題（各 phase 自己的「缺口升級協議」）。
- **編排器責任**：本檔負責在最終 handoff 收斂——gate 型寫入者（`clarify` / `specify`）
  走 FAIL 停止；非 gate 型寫入者（`ui_prototype`）不改 verdict，
  但**必須**進 Risks（見 Gate Verdict 映射表對應列）。
- **`gherkin` 的待釐清缺口不走本檔**（唯一的例外，明文釘死以免出現第二套題號）：
  `gherkin` 在 `.feature` 上標 `@待釐清`、並在 `handoffs/gherkin.md` 的「回饋訊號」段列出缺口，
  **不追寫 `questions.md`、不編 `Q<n>` 題號**。編排器把那些缺口**逐題轉錄**進最終 handoff
  的 Risks；答案同樣經使用者 → `clarify/answers.md` → 下一輪 spec stage 回來。
  本 run 內**不回退階段**。理由：`gherkin` 是最末階段，缺口已具體綁在某條 `Scenario` 上，
  溯源靠 `.feature` 的 `@待釐清` 標記即足；把它塞進 `questions.md` 會讓「gate 型 / 非 gate 型
  寫入者」的二分法多出第三類。

## 執行程序

0. **斷點續跑檢查**——逐 phase 檢查 artifact 是否已存在且非空、gate 是否已過
   （score 看 `score-report.md` 首行 VERDICT、clarify 看 `clarified.md` 首行 STATUS、
   **specify 看 `specify/spec.md` 首行 `STATUS: READY`**）；已完成的 phase **跳過不重跑**。
   **gate 未過不算「已完成」**：`clarified.md` 首行為 `STATUS: BLOCKED`、或 `spec.md`
   首行為 `STATUS: NEEDS-CLARIFICATION` 時，該 phase **一律重跑**（重跑前先納入可能已更新的
   `clarify/answers.md`），**不得**當成已完成跳過、**不得**沿用該 artifact 往下走。
   這讓 clarify FAIL → 使用者補答 → flow 重跑 spec stage 的迴圈成本最小化。
   選用 phase `ui_prototype` 的判定另有規則：**`target` = `backend` 時視為不適用
   （等同「已完成（略過）」）**，不因缺檔重跑、不因缺檔 FAIL——backend track 本來就不執行它
   （見第 5 步順序表）；`target` = `frontend` / `fullstack` 時看 `ui_prototype/ui-plan.md`
   非空、且該目錄下至少一個 `.html` 非空。
1. **準備**——解析設定；把需求原文寫入 `specs/<slug>/source/requirement.md`。
2. **Phase 0 · score**——Read `phases/score/SKILL.md`，傳入 target 執行。
   讀 `score/score-report.md` 首行 VERDICT（**該 phase 只產這三個值，逐值行為如下**）：
   - `BLOCKED` → 寫最終 handoff：`FAIL — 需求可譯性不足（score BLOCKED），退回 PM 補件 #spec-gap`，附缺口清單，**停止**
   - `PASS-WITH-GAPS` → 繼續，缺口記入最終 handoff 的 Risks
   - `PASS-CLEAN` → 繼續，**無缺口需記入 Risks**（不必為 score 補任何 Risks 行）
3. **Phase 1 · clarify（headless 協議，本 skill 最大改編處）**——原版的拷問式
   互動訪談在此**不可用**。改為：
   a. Read `phases/clarify/SKILL.md`，以 score 缺口清單為議程
   b. 先檢查 `clarify/answers.md` 是否存在——存在則把它當使用者回答納入
   c. 能從需求文件 + answers 客觀回答的問題就地解決；**不可腦補**無依據的答案
   d. 全部可解 → 產出 `clarified.md`（STATUS: RESOLVED），續跑
   e. 仍有未解問題 → 依「`clarify/questions.md` 共用契約」追寫 `clarify/questions.md`
      （標 `[clarify]`），最終 handoff：`FAIL — clarify 待使用者澄清，見
      specs/<slug>/clarify/questions.md #spec-gap`，**停止**。flow 會回報使用者；
      使用者的回答由主對話寫入 `clarify/answers.md` 後重跑 spec stage
   f. `clarified.md` 首行為 `STATUS: BLOCKED`（clarify 自判完成判準未達成）→
      **與 e 同一道 gate**：**不得進 specify**（非協商規則 1）。把 `clarified.md`
      內文列出的缺口依共用契約追寫進 `clarify/questions.md`（該檔已有等義題目就不重複追寫），
      最終 handoff 用**與 e 相同**的字串
      `FAIL — clarify 待使用者澄清，見 specs/<slug>/clarify/questions.md #spec-gap`，**停止**；
      Risks 另記一行「clarify STATUS: BLOCKED」以區分成因。
      下一輪重跑時 BLOCKED **不算已完成**（見第 0 步）
4. **Phase 2 · specify（需求結構化 gate）**——Read `phases/specify/SKILL.md`，
   把 `clarify/clarified.md` 收斂成 `specs/<slug>/specify/spec.md`。
   讀 `spec.md` 首行 STATUS：
   - `NEEDS-CLARIFICATION` → 缺口已由本 phase 依共用契約**追寫**到 `clarify/questions.md`
     （標 `[specify]`）；最終 handoff：`FAIL — specify 待澄清（spec.md STATUS:
     NEEDS-CLARIFICATION），見 specs/<slug>/clarify/questions.md #spec-gap`，**停止**
   - `READY` → 繼續。**自此之後的所有 phase 一律以 `specify/spec.md` 為需求真源**
5. **結構層 → 契約層 → 規格層 · 依 target 走 track**——順序照下表（原版可並行的 phase 在此
   **依序執行**）。每個 phase：Read `phases/<name>/SKILL.md` → 執行 → 確認
   artifact 存在且非空 → 確認內部 handoff 已寫。

   | target | 順序 |
   |--------|------|
   | backend | specify → data_model → class_diagram → db_table → api → gherkin |
   | frontend | specify → screens → ui_contract → ui_prototype → gherkin |
   | fullstack | specify → data_model → class_diagram → db_table → screens → api → ui_contract → ui_prototype → gherkin(backend) → gherkin(frontend) |

   > `ui_prototype` **只在 frontend / fullstack track** 執行（backend 完全不觸發），
   > 它也**不是 gate**，但 artifact 缺失時依下方映射表判 FAIL。
   > `ui_prototype` 追寫 `clarify/questions.md` 時的裁決（編排器責任）：
   > **不改變 verdict、不停止**，但編排器**必須**在 Risks 記
   > 「ui_prototype 追寫 N 題待澄清，見 specs/<slug>/clarify/questions.md（已知落差記於 ui-plan.md）」，
   > 並把該檔列入 `## Artifacts Produced`（非協商規則 9）。

   > 各 phase 自己的 `SKILL.md` 標題裡的「階段 N」字樣沿用上游 vendored 的舊編號
   > （尚未計入 `specify`），**與本檔的 Phase 編號不對應**。順序與 gate 一律**以本檔為準**。

6. **api phase 的環境前置檢查**——執行前先驗 `command -v python3` 與
   `python3 -c "import yaml"`：
   - 缺 → 保留已產出的 `*.intent.yaml`，最終 handoff：`FAIL — api phase 需
     python3 + pyyaml，環境缺失 #env`，明說 openapi.yaml 未產出，**停止**
   - 過 → 依 `phases/api/SKILL.md` 跑 transpiler 產 `openapi.yaml`
   - phases/api 建議的 spec 驗證工具（`openapi-spec-validator` / `npx @redocly/cli`）
     屬**選用**：兩者皆不可用時**跳過驗證、不 FAIL、不觸網安裝**，
     在最終 handoff 的 Risks 記「openapi.yaml 未經 validator 驗證」
7. **收尾**——寫最終 handoff `handoffs/<slug>-spec.md`（格式見下），
   Gate Verdict: `PASS`。

## Gate Verdict 映射（原版語彙 → flow 契約）

| 情況 | 最終 handoff Gate Verdict |
|------|--------------------------|
| score VERDICT = `BLOCKED` | `FAIL — 需求可譯性不足（score BLOCKED），退回 PM 補件 #spec-gap` |
| score VERDICT = `PASS-WITH-GAPS` | **不影響 verdict**（續跑）；缺口記入 Risks |
| score VERDICT = `PASS-CLEAN` | **不影響 verdict**（無缺口，不必為 score 補 Risks 行） |
| clarify gate 未過（仍有未解問題，**或** `clarified.md` 首行 `STATUS: BLOCKED`） | `FAIL — clarify 待使用者澄清，見 specs/<slug>/clarify/questions.md #spec-gap`（BLOCKED 時 Risks 另記成因） |
| specify `STATUS: NEEDS-CLARIFICATION` | `FAIL — specify 待澄清（spec.md STATUS: NEEDS-CLARIFICATION），見 specs/<slug>/clarify/questions.md #spec-gap` |
| `spec.md` 缺失 / 為空 / 首行非 `STATUS: READY` 而下游被觸發 | `FAIL — specify 產出缺失 #skill-defect` |
| frontend / fullstack track 的 `ui_prototype` 產出缺失或為空 | `FAIL — ui_prototype 產出缺失 #skill-defect` |
| `ui_prototype`（**非 gate**）追寫 `clarify/questions.md` | **不影響 verdict**（不 FAIL、不停止）；Risks **必須**記「`ui_prototype` 追寫 N 題待澄清，見 `specs/<slug>/clarify/questions.md`」，且該檔列入 Artifacts Produced。**不得靜默吞掉** |
| 任一 phase artifact 缺失或為空 | `FAIL — <phase> 產出缺失 #skill-defect` |
| api transpiler 環境缺失 | `FAIL — 需 python3 + pyyaml #env` |
| 全部 phase 完成 | `PASS` |

## 最終 Handoff 格式（`handoffs/<slug>-spec.md`）

依 athena-flow 的 `agent-handoff.md` 契約，必含。
**前三行是機械契約**（見 `agent-handoff.md` 的「機械契約紅線」）：第 1 行逐字 `# Handoff: spec`、
第 2 行空行、第 3 行是**這次 spec 做了什麼**的一句摘要。`hooks/auto-commit.sh` 取第 3 行為
commit 描述——H1 改字樣、或第 3 行寫成 `- **Stage**: ...` 這種欄位標籤，commit 訊息會**靜默**缺描述。

```markdown
# Handoff: spec

<一行摘要——這次 spec 做了什麼；H1 後隔一空行的第 3 行，auto-commit.sh 取此行為 commit desc>

## Stage
spec（pm-to-eng-spec，target: <target>）

## Inputs Used
- points/<slug>.md
- specs/arguments.yml（或「缺，target 由需求推斷」）

## Artifacts Produced
<逐一列出 specs/<slug>/ 下實際產出的檔案路徑；含 specify/spec.md 與
specify/requirements-checklist.md；frontend / fullstack 另含
ui_prototype/ui-plan.md 與各張 .html>

## Gate Verdict
<PASS，或 FAIL — 原因 #tag（照上方映射表）>

## Risks / Unresolved Issues
- <score PASS-WITH-GAPS 的缺口（PASS-CLEAN 時本行省略）>
- <target / frontend_verify 的推斷假設>
- <ui_prototype 追寫 clarify/questions.md 時記「ui_prototype 追寫 N 題待澄清」——非 gate，不改 verdict，但不得省略>
- <各 phase handoff 標注的範圍外待辦與假設——含 gherkin handoff 的「回饋訊號（待釐清缺口）」
  逐題轉錄：本 run 不回退階段，缺口一律經使用者回答 → clarify/answers.md → 下一輪 spec stage>

## Next Recommended Stage
plan
```

## 工具邊界（遵守 spec stage shell 契約）

- Write **只能**寫 `specs/` 與 `handoffs/<slug>-spec.md`
- Bash **只能**跑文件工具（api transpiler `python3 phases/api/transpiler/openapi.py`
  屬此類）與唯讀 git；不得改 `src/`、不得 commit / push
- 需要範圍外工具時：在最終 handoff 回報並停止，不繞道

## 非協商規則

1. **三道 gate**：score BLOCKED 不得進 clarify；clarify 未 RESOLVED 不得進 specify；
   **specify 未 READY 不得進結構層**
2. 任一 phase artifact 缺失或為空 → FAIL 停止，不硬闖下一 phase
3. clarify 不得腦補使用者未給的答案——不確定就寫進 questions.md 走 FAIL 協議
4. 依 target 走 track，不混跑；backend 結構層 data_model 先於 class_diagram / db_table；
   fullstack 的 ui_contract 必須在 api 之後；`ui_prototype` 必須在 `ui_contract`
   之後、`gherkin` 之前，且 backend track 不執行它。**結構層與其後的 phase 一律以
   `specify/spec.md` 為需求真源，不得回讀 `clarify/clarified.md`**
5. 前端棧一律 **Nuxt 4 + TypeScript strict**，依
   `phases/pm-to-eng-flow/references/frontend-stack-conventions.md`——該檔是跨前端
   階段（`screens` / `ui_contract` / `ui_prototype` / `gherkin` 前端）的**單一事實來源**。
   本 pack **不提供**專案級的棧覆寫通道；棧不同的團隊請 fork 該 conventions 檔後
   自行調整。該檔本身**不得修改**（vendored）。
6. 不寫實作程式碼、不越界做 plan 的工作（phase 拆解是下一個 stage 的事）
7. 最終 handoff 必含 Minimum Contents 六欄；FAIL 必帶 taxonomy tag
8. `specs/<slug>/design/` 是**輸入**（設計師視覺稿，由人提供、可能不存在）——
   **pack 的任何 phase 都不得寫入它**。可點擊的雛形一律落在
   `specs/<slug>/ui_prototype/`（`ui_prototype` phase 的輸出）；兩者不得互換、不得互覆。
   與稿不一致處標 `待釐清` / `待補設計`，不擅自選邊
9. **非 gate 的缺口升級不得靜默吞掉** —— `ui_prototype`
   追寫 `clarify/questions.md` 時**不改變 Gate Verdict、不停止**（它不是 gate），
   但編排器**必須**在最終 handoff 的 Risks 記「`ui_prototype` 追寫 N 題待澄清」
   並把 `questions.md` 列入 Artifacts Produced。收在 `PASS` 卻讓使用者不知道
   `questions.md` 有新題，即為流程缺陷。三個寫入者的題號與標記依
   「`clarify/questions.md` 共用契約」；`gherkin` 的待釐清缺口不走 `questions.md`，
   但**同樣**必須逐題轉錄進 Risks（見該契約段末條）。
