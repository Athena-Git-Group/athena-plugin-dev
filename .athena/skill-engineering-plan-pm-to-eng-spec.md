# Skill 工程編排提案

## 任務資訊

- 處理路徑: `optimize`
- 改動範圍: `chain rewrite`（根編排器 skill rewrite + 12 支 phase 子 skill 結構重排 + vendored 制度廢除）
- 目標 Skills: `pm-to-eng-spec`（真源：`skills/athena-core/assets/spec-pack-pm-to-eng/`；dogfood：`.athena/skills/pm-to-eng-spec/`）
- 前提決策（已於根因閘門確認）: 本 pack 定調為正式 fork，上游 `athena-skills` 不再是真源；A/B 組 vendored 約束解除。

## 控制平面重建

### 根 SKILL.md（256 行 → 目標約 80 行）

- 以 Phase 分段重寫「執行程序」，step 一律 READ / THINK / WRITE 動詞開頭（本 pack 在 spec shell 內無 Agent 工具，不會有 DELEGATE step）：
  - Phase 0 -- 斷點續跑與準備（READ 續跑判準 rule → 逐 phase 判定 → WRITE source/requirement.md）
  - Phase 1 -- 三道 gate（score → clarify → specify；gate 流程留 inline，verdict 字串與映射細節委派 rule）
  - Phase 2 -- 依 target 走 track（track 順序表留 inline——它是純控制流；逐 phase「Read phases/<name>/SKILL.md → 執行 → 驗 artifact 非空」）
  - Phase 3 -- 收尾與最終 handoff（READ handoff template → WRITE handoffs/<slug>-spec.md）
- keep-inline 的控制資訊：先讀哪些檔、設定解析表（target / frontend_verify 推斷）、track 順序表、工具邊界。
- 外移後原地只留「讀取時機 + 處理對象 + 預期產出」一行，不重述內容（單一溯源）。
- 「非協商規則」9 條解散：各條併入對應 rule 檔；SOP 相應 step 留回掛。
- 設計 rationale（gherkin 例外的理由、auto-commit 取第 3 行的理由）隨規則搬進 rule 檔的說明段。

### phases/ 子 skill（12 支）

- 每支 SKILL.md 的「執行步驟」改寫為 READ / THINK / WRITE 動詞 step；高判斷工作（評分裁量、缺口判讀、設計取捨）留在 SOP，穩定判準 / 骨架 / 自動化外移。
- 統一五段骨架：輸入 / 輸出 / SOP（Phase+step）/ 完成判準 / 非協商規則。`score` 的「閘門語意」改名「完成判準」。
- 刪除「先讀」vs「references/」雙清單——只留 step 級回掛（弱回掛的 `class_diagram` / `data_model` / `score` 補到 step 級、指明檔名）。
- 刪除標題中沿用上游的「階段 N」舊編號（fork 後無保留理由），順序語彙一律以根檔 track 表為準；根檔 `:151-152` 的救火註記隨之刪除。
- 跨檔回指不再用「非協商規則 #N」序號，改用規則名稱或 rule 檔名回指（解除脆弱序號耦合；上游「編號不得位移」義務已隨 fork 失效）。

### 共用層

- `phases/pm-to-eng-flow/`（references-only、無 SKILL.md）收編為 `phases/common/`：
  - `common/rules/handoff-contract.md`（9 支 SKILL.md 指涉它但無一給路徑——全部補成帶路徑的 READ 回掛）
  - `common/rules/frontend-stack-conventions.md`（維持跨前端階段單一真源地位；fork 後「該檔不得修改」約束解除，但內容本次不動）

## 來源能力保留策略

| 高指導面積來源 | 保留位置 | 保留粒度 |
|---|---|---|
| score 三份 rubric（41–42 行 × 3） | `phases/score/rules/` | 逐字搬移，僅改路徑回掛；評分維度與門檻不濃縮 |
| `grill-with-docs.md`（126 行拷問流程引擎） | `phases/clarify/rules/` | 逐字搬移；其引用的 CONTEXT-FORMAT / ADR-FORMAT 一併搬 templates/ 並保持內部連結 |
| `quality-checklist.md`、`boundary-checklist.md`、`persistence-allowlist.md` 等掃描清單 | 各 phase `rules/` | 逐字搬移，清單子項一項不刪 |
| api 雙格式錨點（dsl / haapi anchor） | `phases/api/rules/` | 逐字搬移——格式錨點是 transpiler 正確性的前提 |
| 根檔 `questions.md` 共用契約（25 行 + gherkin 例外） | 根 `rules/` | 完整搬移含 rationale；三支 phase 的「複述+回指」刪複述、留純回指 |
| 根檔 Gate Verdict 映射表 + FAIL 字串 | 根 `rules/` | 逐字搬移——FAIL 字串是 flow 的機械契約，一字不改 |
| 最終 handoff 格式（含機械契約紅線） | 根 `templates/` + `.example` | 骨架照搬；「前三行機械契約」警語隨模板走 |
| 各 example 檔（.feature / openapi / screen-map / ui-contract） | 各 phase `templates/*.example.*` | 原樣保留 |

- 本次重構以「搬移 + 改回掛」為主，**不做內容濃縮**——語意密度風險僅存在於根 SKILL.md 的 SOP 重寫段，該段只壓縮控制流敘述，所有判準與字串契約都外移保留。
- 可安全刪除（無能力承載）：雙清單重複段、三處契約複述、舊編號註記、VENDORED A/B 重放機制文字。

## 步驟決策（根 SKILL.md，按現有段落）

| 現有段落 | 決策 |
|---|---|
| frontmatter description | rewrite（刪「改編自 / vendored」敘事，保留路由語意） |
| 先讀哪些檔 | keep-inline |
| 設定解析表 | keep-inline（headless 推斷是啟動必備控制資訊，10 行） |
| Workspace 目錄樹 | derive-template → `templates/workspace-layout.md` |
| questions.md 共用契約 | derive-rule → `rules/questions-共用契約.md` |
| 執行程序 0（斷點續跑） | derive-rule → `rules/斷點續跑判準.md`；SOP 留一個 READ step |
| 執行程序 1–4（三道 gate） | rewrite 成 Phase 1 的動詞 step；clarify a–f 分支收斂為 gate 控制流 + rule 回掛 |
| 執行程序 5（track 表） | keep-inline（純控制流） |
| 執行程序 6（api 環境前置檢查） | rewrite 併入 Phase 2 對應 step；FAIL 字串隨映射表進 rule |
| 執行程序 7（收尾） | rewrite 成 Phase 3 |
| Gate Verdict 映射表 | derive-rule → `rules/gate-verdict-映射.md` |
| 最終 Handoff 格式 | derive-template → `templates/final-handoff.md` + `.example.md` |
| 工具邊界 | keep-inline |
| 非協商規則 9 條 | delete（解散併入各 rule；gate 三連鎖入 gate rule、棧規則入 common rule、design/ 輸入規則入 workspace 相關 rule、規則 9 入 questions 契約 rule） |

## 步驟決策（phases/，references/ → rules/ / templates/ / scripts/ 重排）

| phase | rules/ | templates/ | scripts/ |
|---|---|---|---|
| score | rubric.md、rubric-backend.md、rubric-frontend.md | — | — |
| clarify | grill-with-docs.md | CONTEXT-FORMAT.md、ADR-FORMAT.md | — |
| specify | quality-checklist.md、story-splitting.md | spec-structure.md | — |
| data_model | extraction-cases.md | — | — |
| class_diagram | layering-heuristics.md | — | — |
| db_table | persistence-allowlist.md、dbml-style.md | — | — |
| api | api-conventions.md、dsl-format-anchor.md、haapi-format-anchor.md | example.intent.yaml、example.dbml、example.openapi.yaml | transpiler/openapi.py → scripts/openapi.py |
| screens | screen-breakdown.md | sitemap-guide.md、example-screen-map.md | — |
| ui_contract | view-model-binding-guide.md、api-layer-guide.md | example-ui-contract.md | — |
| ui_prototype | prototype-boundary.md、page-splitting.md | prototype-skeleton.md | — |
| gherkin | gherkin-guide.md、boundary-checklist.md、scenario-outline-guide.md | example.feature | — |
| pm-to-eng-flow → common | handoff-contract.md、frontend-stack-conventions.md | — | — |

- 所有搬移後，各 SKILL.md 與跨檔引用的路徑同步更新；`persistence-allowlist.md:3`、`sitemap-guide.md:70`、`api-conventions.md:119` 等序號回指改為規則名稱回指。
- 根檔 `:222` 工具邊界與 `:154-161` 前置檢查中的 transpiler 路徑改為 `phases/api/scripts/openapi.py`。

## 制度檔與工具鏈

- `VENDORED.md` 改寫為 fork 聲明（兩份同步改）：記來源（athena-skills pm-to-eng-flow）、fork 日期（2026-10-27）、fork 理由、「上游不再是真源、不再 re-vendor」；刪除 A/B/C 分組、22 檔重放清單、「不得改」清單。
- `scripts/sync-spec-pack.sh`：刪除 step 0（上游 re-vendor）、`UPSTREAM_PHASE_DIRS` / `PLUGIN_OWN_PHASE_DIRS` 機制與上游參數；同步範圍從「只有 phases/」擴成「整個 pack，唯 root SKILL.md 除外」（讓新增的根層 rules/ templates/ 也被同步與 drift 檢查涵蓋）。
- `scripts/lint-plugin.sh` 第 7 步 drift check：比對範圍同步擴大（diff 整包、排除 root SKILL.md），錯誤訊息更新。
- `README.md`：與根 SKILL.md 重疊的三塊（phase 流程圖、spec.md 真源宣告、Nuxt 真源敘述）改為一句話 + 回指，安裝/環境/已知限制等「對人」內容保留。

## 檔案動作

### 新增 / 更新（真源側 `skills/athena-core/assets/spec-pack-pm-to-eng/`，再 sync 到 dogfood）

- Update 根 `SKILL.md`（重寫，兩份各自維護其 stage 宣告差異）
- Create 根 `rules/`：`questions-共用契約.md`、`gate-verdict-映射.md`、`斷點續跑判準.md`
- Create 根 `templates/`：`workspace-layout.md`、`final-handoff.md`、`final-handoff.example.md`
- Update 12 支 `phases/*/SKILL.md`（SOP 動詞化、五段骨架、回掛改路徑式）
- Move ~30 個 `references/` 檔至各 phase `rules/` / `templates/` / `scripts/`（見上表，逐字搬移）
- Rename `phases/pm-to-eng-flow/` → `phases/common/`
- Rewrite `VENDORED.md`（fork 聲明）；Update `README.md`、`scripts/sync-spec-pack.sh`、`scripts/lint-plugin.sh`

### 刪除

- `phases/pm-to-eng-flow/references/arguments.sample.yml`（孤兒，零引用）
- 各 phase 的「先讀」vs「references/」雙清單重複段
- `clarify` / `specify` / `ui_prototype` SKILL.md 中對 questions.md 契約的複述段（留純回指）
- `specify` / `ui_prototype` 中與根檔重複的斷點續跑敘述
- 各 phase 標題「階段 N」舊編號與根檔救火註記
- VENDORED.md 的 A/B 組重放清單與「不得改」清單（隨 fork 聲明重寫消失）
- sync-spec-pack.sh 的 step 0 與雙清單機制

## 驗證方式

1. **機械盤點**：`uv run skills/skill-engineering/scripts/analyze_skill_references.py --skill <pack 根> --skill phases/<各 phase>`——phase/step 可被解析（不再 0/0）、無 missing refs、無孤兒。
2. **drift 閘**：跑 `scripts/sync-spec-pack.sh` 後 `scripts/lint-plugin.sh` 全綠。
3. **fresh-context read-back**：派未參與實作的 agent 對照本 plan 逐項驗收（檔案存在、回掛成立、刪除項已清、FAIL 字串逐字未變、繁中為主）。
4. **能力重演**（語意密度）：派 fresh agent 僅憑新結構重演兩個抽查點——(a) score phase 能從 rule 回掛找到並套用對應 rubric 的完整維度；(b) gherkin phase 能從 boundary-checklist 掃出邊界情境清單。重演失敗則回修回掛或粒度。
5. **flow 契約回歸**：檢查 `athena-spec-default`、`athena-stage-spec` shell 與 `hooks/auto-commit.sh` 對本 pack 的依賴點（入口路徑、handoff 前三行機械契約）未被破壞。

## 實作閘門

- `/skill-form-sop`、`/skill-derive-*` 不在本 session 可用清單——落地時由 general-purpose subagent 讀取 `skills/skill-form-sop/`、`skills/skill-derive-rule|template|script/` 的 SKILL.md 作為規範執行，等效走 deriver 生態系。
- 使用者確認本 plan 後才進入 Phase 4 落地；只要求提案則停在此處。
