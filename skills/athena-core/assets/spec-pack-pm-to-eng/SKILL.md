---
name: pm-to-eng-spec
description: >
  Spec stage 的多 phase 編排 skill：把 PM 需求文件轉成工程化規格——
  score（可譯性 gate）→ clarify（釐清 gate）→ specify（需求結構化 gate，
  產出 spec.md＝結構層以後的唯一需求真源）→ 結構層（data_model /
  class_diagram / db_table 或 screens）→ 契約層（api / ui_contract）→
  ui_prototype（前端 / fullstack 的靜態雛形）→ gherkin 規格層。
  在單一 spec agent 內順序執行 phases、產出落在 specs/<slug>/、
  gate verdict 映射為 PASS / FAIL 格式。
stage: spec
---

# PM → Engineering Spec（spec stage 編排）

你是 spec stage 的**phase 編排者**，在**單一 agent 內順序執行** `phases/` 下的子 skill。
spec stage shell 沒有 Agent 工具，因此以「artifact 落盤 + 逐 phase 讀檔」替代 agent 隔離：
每個 phase 只讀自己需要的檔案，不把整份 artifact 重複帶著走。

## 先讀哪些檔（progressive disclosure）

- `points/<slug>.md` — point-report，取需求敘述、slug、verdict
- `specs/arguments.yml`（若存在）— 取 `spec_pack.target` 與 `spec_pack.frontend_verify`
- **不要**預先讀所有 phase 的 SKILL.md——輪到哪個 phase 才 Read `phases/<name>/SKILL.md`

## 設定解析

| 設定 | 來源 | 缺值時 |
|------|------|--------|
| `target`（backend / frontend / fullstack） | `specs/arguments.yml` 的 `spec_pack.target` | 從需求文字推斷：出現畫面 / UI / 頁面 / 表單 / 操作流程等字樣 → `fullstack`；否則 `backend`。**推斷結果與依據必須寫進最終 handoff 的 Risks** |
| `frontend_verify`（mcp / playwright / agent-browser / vitest-testing-library） | `spec_pack.frontend_verify` | 視為未指定；gherkin 仍產 runner-agnostic `.feature`，在 handoff 標注建議機制 |

Spec stage 是 headless 執行——**不得**以互動詢問取得設定；缺值一律走上表的推斷 + 記錄假設。

## Track 順序

依 target 走下表的 track，不混跑；可並行的 phase 在此一律**依序執行**：

| target | 順序 |
|--------|------|
| backend | specify → data_model → class_diagram → db_table → api → gherkin |
| frontend | specify → screens → ui_contract → ui_prototype → gherkin |
| fullstack | specify → data_model → class_diagram → db_table → screens → api → ui_contract → ui_prototype → gherkin(backend) → gherkin(frontend) |

- backend 結構層 data_model 先於 class_diagram / db_table；fullstack 的 ui_contract 必須在 api 之後；`ui_prototype` 必須在 `ui_contract` 之後、`gherkin` 之前，且 backend track 不執行它。
- **結構層與其後的 phase 一律以 `specify/spec.md` 為需求真源，不得回讀 `clarify/clarified.md`**。
- 本 pack 不寫實作程式碼、不越界做 plan 的工作（phase 拆解是下一個 stage 的事）。

## 工具邊界（遵守 spec stage shell 契約）

- Write **只能**寫 `specs/` 與 `handoffs/<slug>-spec.md`
- Bash **只能**跑文件工具（api transpiler `python3 phases/api/scripts/openapi.py` 屬此類）與唯讀 git；不得改 `src/`、不得 commit / push
- 需要範圍外工具時：在最終 handoff 回報並停止，不繞道

# SOP

## Phase 1 -- 斷點續跑判定與準備

1. READ 讀取 `points/<slug>.md` 取得需求敘述、slug 與 verdict；`specs/arguments.yml` 存在時一併讀取，依上方設定解析表補足缺值並記下推斷依據。
2. READ 讀取 `rules/斷點續跑判準.md`，對照 `specs/<slug>/` 下既有 artifact 與 gate 狀態，逐 phase 判定哪些跳過、哪些必須重跑。
3. READ 需要確認產出路徑或 `design/` 的寫入禁令時，讀取 `templates/workspace-layout.md`，據此決定本次要建立的目錄。
4. WRITE 把需求原文抄錄到 `specs/<slug>/source/requirement.md`。

## Phase 2 -- 通過 score、clarify、specify 三道 gate

1. READ 讀取 `phases/score/SKILL.md`，傳入 target 執行，處理 `specs/<slug>/source/requirement.md`，產出 `score/score-report.md`（首行含 VERDICT）。
2. READ 讀取 `rules/gate-verdict-映射.md`，取得三道 gate 的把關順序、各情況對應的 Gate Verdict 字串與 FAIL 停止義務。
3. THINK 依已載入規則判讀 score 首行 VERDICT：判 FAIL 時直接跳到 Phase 4 收尾並停止；續跑時把缺口整理成 clarify 的議程。
4. READ 讀取 `phases/clarify/SKILL.md`，以 score 缺口清單為議程執行；執行前先確認 `clarify/answers.md` 是否存在，存在則把它當使用者回答納入，產出 `clarify/clarified.md`（首行含 STATUS）。
5. THINK 依已載入規則判讀 clarify gate；需要把未解缺口升級給使用者時，讀取 `rules/questions-共用契約.md` 後追寫 `clarify/questions.md`（標 `[clarify]`），再跳到 Phase 4 收尾並停止。
6. READ 讀取 `phases/specify/SKILL.md`，把 `clarify/clarified.md` 收斂成 `specs/<slug>/specify/spec.md`（首行含 STATUS）與 `specify/requirements-checklist.md`。
7. THINK 依已載入規則判讀 specify gate：未達 `STATUS: READY` 時跳到 Phase 4 收尾並停止；`READY` 才進入 Phase 3。

## Phase 3 -- 依 target 走 track 完成結構層、契約層與規格層

1. READ 依上方 Track 順序表取出本次 target 的 phase 序列，逐個讀取 `phases/<name>/SKILL.md` 並執行，處理對象一律是 `specify/spec.md`，產出落在 `specs/<slug>/<phase>/`。
2. READ 走 frontend / fullstack track 的前端 phase（`screens` / `ui_contract` / 前端 `gherkin`）時，前端棧一律 **Nuxt 4 + TypeScript strict**，細節讀取 `phases/common/rules/frontend-stack-conventions.md`；`ui_prototype` 不適用棧規則，它產的是與框架無關的靜態 HTML/CSS，只在畫面命名與路由語彙上與 `screens` 的 Nuxt 路由保持一致。
3. READ 執行 `api` phase 前先驗 `command -v python3` 與 `python3 -c "import yaml"`，依已載入的 gate-verdict 映射規則處理環境缺失與選用 validator；通過則依 `phases/api/SKILL.md` 跑 `phases/api/scripts/openapi.py` 產 `openapi.yaml`。
4. THINK 每個 phase 執行完確認 artifact 存在且非空、內部 handoff 已寫；缺失時依已載入的 gate-verdict 映射規則判 FAIL，跳到 Phase 4 收尾並停止。
5. THINK `ui_prototype` 追寫 `clarify/questions.md` 時不改 verdict、不停止，但記下題數與檔案路徑，留給 Phase 4 寫進 Risks 與 Artifacts Produced。

## Phase 4 -- 收尾與最終 handoff

1. READ 讀取 `templates/final-handoff.md` 取得骨架與填位符號說明，需要對照填完後的樣子時再讀 `templates/final-handoff.example.md`。
2. THINK 依已載入的 gate-verdict 映射規則決定 Gate Verdict 字串，並逐項收斂 Risks：score 缺口、`target` / `frontend_verify` 的推斷假設、`ui_prototype` 追寫題數、各 phase handoff 的範圍外待辦，以及 `gherkin` handoff「回饋訊號」缺口的逐題轉錄。
3. WRITE 依骨架寫出 `handoffs/<slug>-spec.md`。
4. READ 回頭檢查 handoff 是否符合已載入規則與骨架：第 1 行逐字 `# Handoff: spec`、第 2 行空行、第 3 行是一句摘要，六欄齊備，FAIL 時帶 taxonomy tag；若不符合，立即修正。
