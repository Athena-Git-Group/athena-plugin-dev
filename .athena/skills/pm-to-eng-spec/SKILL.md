---
name: pm-to-eng-spec
description: >
  Spec stage 的多 phase 編排 skill：把 PM 需求文件轉成工程化規格——
  score（可譯性 gate）→ clarify（釐清 gate）→ specify（需求結構化 gate，
  產出 spec.md＝結構層以後的唯一需求真源）→ 結構層（data_model /
  class_diagram / db_table 或 screens）→ 契約層（api / ui_contract）→
  gherkin 規格層。改編自 athena-skills 的 pm-to-eng-flow，已適配
  athena-flow spec stage 契約：單一 spec agent 內順序執行 phases、
  產出落在 specs/<slug>/、gate verdict 映射為 PASS / FAIL 格式。
  **子 skill——不宣告 stage**，由 team-spec-index 依路由判準 DELEGATE：
  處理「PM 產品功能需求」那一支；plugin 自身的 prompt 契約改動走
  plugin-contract-spec。
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
  ├─ clarify/questions.md       # 待澄清問題（headless 協議；clarify 與 specify 共用此檔）
  ├─ clarify/answers.md         # 使用者的回答（由 flow 主對話寫入）
  ├─ specify/spec.md            # Phase 2，開頭含 STATUS；**結構層以後的唯一需求真源**
  ├─ specify/requirements-checklist.md      # Phase 2 規格品質自檢
  ├─ design/                    # 【輸入】設計師視覺稿，選用，pack 不寫入
  ├─ data_model/ class_diagram/ db_table/   # 結構層（backend）
  ├─ screens/                               # 結構層（frontend）
  ├─ api/ ui_contract/                      # 契約層
  ├─ gherkin/                   # 規格層（fullstack 分 backend/ frontend/）
  └─ handoffs/<stage>.md        # 各 phase 的內部交接便條
```

最終 stage handoff 寫 `handoffs/<slug>-spec.md`（repo 根目錄，flow 契約位置）。

## 執行程序

0. **斷點續跑檢查**——逐 phase 檢查 artifact 是否已存在且非空、gate 是否已過
   （score 看 `score-report.md` 首行 VERDICT、clarify 看 `clarified.md` 首行 STATUS、
   **specify 看 `specify/spec.md` 首行 `STATUS: READY`**）；已完成的 phase **跳過不重跑**。
   這讓 clarify FAIL → 使用者補答 → flow 重跑 spec stage 的迴圈成本最小化。
1. **準備**——解析設定；把需求原文寫入 `specs/<slug>/source/requirement.md`。
2. **Phase 0 · score**——Read `phases/score/SKILL.md`，傳入 target 執行。
   讀 `score/score-report.md` 首行 VERDICT：
   - `BLOCKED` → 寫最終 handoff：`FAIL — 需求可譯性不足（score BLOCKED），退回 PM 補件 #spec-gap`，附缺口清單，**停止**
   - `PASS-WITH-GAPS` → 繼續，缺口記入最終 handoff 的 Risks
3. **Phase 1 · clarify（headless 協議，本 skill 最大改編處）**——原版的拷問式
   互動訪談在此**不可用**。改為：
   a. Read `phases/clarify/SKILL.md`，以 score 缺口清單為議程
   b. 先檢查 `clarify/answers.md` 是否存在——存在則把它當使用者回答納入
   c. 能從需求文件 + answers 客觀回答的問題就地解決；**不可腦補**無依據的答案
   d. 全部可解 → 產出 `clarified.md`（STATUS: RESOLVED），續跑
   e. 仍有未解問題 → 寫入 `clarify/questions.md`（PM-friendly、逐題編號、附
      預設選項與影響說明），最終 handoff：`FAIL — 待使用者澄清，見
      specs/<slug>/clarify/questions.md #spec-gap`，**停止**。flow 會回報使用者；
      使用者的回答由主對話寫入 `clarify/answers.md` 後重跑 spec stage
4. **Phase 2 · specify（需求結構化 gate）**——Read `phases/specify/SKILL.md`，
   把 `clarify/clarified.md` 收斂成 `specs/<slug>/specify/spec.md`。
   讀 `spec.md` 首行 STATUS：
   - `NEEDS-CLARIFICATION` → 缺口已由本 phase **追寫**到 `clarify/questions.md`；
     最終 handoff：`FAIL — 待澄清，見 specs/<slug>/clarify/questions.md #spec-gap`，**停止**
   - `READY` → 繼續。**自此之後的所有 phase 一律以 `specify/spec.md` 為需求真源**
5. **Phase 3–5 · 依 target 走 track**——順序照下表（原版可並行的 phase 在此
   **依序執行**）。每個 phase：Read `phases/<name>/SKILL.md` → 執行 → 確認
   artifact 存在且非空 → 確認內部 handoff 已寫。

   | target | 順序 |
   |--------|------|
   | backend | specify → data_model → class_diagram → db_table → api → gherkin |
   | frontend | specify → screens → ui_contract → gherkin |
   | fullstack | specify → data_model → class_diagram → db_table → screens → api → ui_contract → gherkin(backend) → gherkin(frontend) |

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
| clarify 有未解問題 | `FAIL — 待澄清，見 specs/<slug>/clarify/questions.md #spec-gap` |
| specify `STATUS: NEEDS-CLARIFICATION` | `FAIL — 待澄清，見 specs/<slug>/clarify/questions.md #spec-gap` |
| `spec.md` 缺失 / 為空 / 首行非 `STATUS: READY` 而下游被觸發 | `FAIL — specify 產出缺失 #skill-defect` |
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
specify/requirements-checklist.md>

## Gate Verdict
<PASS，或 FAIL — 原因 #tag（照上方映射表）>

## Risks / Unresolved Issues
- <score PASS-WITH-GAPS 的缺口>
- <target / frontend_verify 的推斷假設>
- <各 phase handoff 標注的範圍外待辦與假設>

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
   fullstack 的 ui_contract 必須在 api 之後。**結構層與其後的 phase 一律以
   `specify/spec.md` 為需求真源，不得回讀 `clarify/clarified.md`**
5. 前端一律 Nuxt 4 + TypeScript strict，依
   `phases/pm-to-eng-flow/references/frontend-stack-conventions.md`
6. 不寫實作程式碼、不越界做 plan 的工作（phase 拆解是下一個 stage 的事）
7. 最終 handoff 必含 Minimum Contents 六欄；FAIL 必帶 taxonomy tag
