# Spec Pack: PM → Engineering（starter pack）

把 PM 需求文件轉成工程化規格的 **spec stage 實作**，供團隊安裝到自己專案的
`.athena/skills/` 使用。這是 **opt-in** 的 starter pack——不安裝不影響任何
既有 flow 行為；安裝後 `PASS-SPEC-FIRST`（Full 路由）的 spec 階段由它執行。

## 它做什麼

```
PM 需求 → score（可譯性 gate）→ clarify（釐清 gate）
        → 結構層（data_model / class_diagram / db_table ∣ screens）
        → 契約層（api → openapi.yaml ∣ ui_contract）
        → gherkin（可執行 .feature 規格）
```

產出全部落在 `specs/<slug>/`，最終 handoff 寫 `handoffs/<slug>-spec.md`。

## 安裝（在你的專案根目錄）

```bash
cp -R <plugin-root>/skills/athena-core/assets/spec-pack-pm-to-eng \
      .athena/skills/pm-to-eng-spec
```

裝完 `/athena-flow` 的 Skill Discovery 會自動把它綁到 `stage: spec`。
注意：**同一 stage 只能有一個 skill**——若你的專案已有宣告 `stage: spec` 的
skill，flow 會報 duplicate-stage 錯，請先擇一。

## 設定（選用，在專案的 `specs/arguments.yml` 追加）

```yaml
spec_pack:
  target: fullstack        # backend（預設推斷）/ frontend / fullstack
  frontend_verify: mcp     # mcp / playwright / agent-browser / vitest-testing-library
```

缺設定時 target 由需求文字推斷（假設會記入 handoff Risks），不會互動詢問。

## 環境需求

- **api phase**：`python3` + `pyyaml`（transpiler 把 intent DSL 編譯成
  openapi.yaml）。缺環境時 phase 會 FAIL 並保留 intent.yaml，不會產出半套 openapi。
- **前端 track**：產出假設 Nuxt 4 + TypeScript strict 技術棧
  （見 `phases/pm-to-eng-flow/references/frontend-stack-conventions.md`）。
  棧不同的團隊請 fork 該 conventions 檔後自行調整。

## 與相鄰工具的分工（避免混淆）

| 工具 | 時機 | 問的問題 |
|------|------|---------|
| `/athena-point` | flow 入口 | 這任務要不要走 spec？（工程分流） |
| `athena-audit-requirement-*` | flow 之外、PM 交件時 | 這份 PRD 夠格進工程流程嗎？（需求驗收，退 PM 用） |
| **本 pack 的 score + clarify** | flow 內、spec stage 開頭 | 進了 spec 的需求撐不撐得起機械轉換？缺什麼就地釐清 |
| 本 repo 的 `athena-discovery` / `athena-form-*` | 獨立呼叫 | 另一套 BDD 導向 spec 工具，與本 pack 擇一使用即可 |

## 已知限制

- **clarify 是 headless 的**：spec stage 在 fresh agent 內執行，無法互動訪談。
  待澄清問題會寫進 `specs/<slug>/clarify/questions.md` 並以 FAIL 收場；
  使用者回答寫入 `clarify/answers.md` 後重跑 flow，spec stage 會斷點續跑。
- 原版可並行的 phase（class_diagram ∥ db_table、fullstack 雙 gherkin）在
  spec stage shell 內**依序執行**（shell 無 Agent 工具）。
- 來源與同步方式見 `VENDORED.md`。
