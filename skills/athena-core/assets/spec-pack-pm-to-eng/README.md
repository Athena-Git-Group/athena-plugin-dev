# Spec Pack: PM → Engineering（starter pack）

把 PM 需求文件轉成工程化規格的 **spec stage 實作**。它同時是 **plugin 的 spec 預設**：
專案的 `.athena/skills/` 下沒有任何宣告 `stage: spec` 的 skill 時，`/athena-flow` 的
`PASS-SPEC-FIRST`（Full 路由）spec 階段就由本 pack 執行——**不必安裝**。
把它裝到自己專案的 `.athena/skills/` 是為了**改它**（見下方「安裝」）。

## 它做什麼

把 PM 需求文件依序推過 score → clarify → specify → 結構層 → 契約層 →
〔ui_prototype〕→ gherkin 等 phase；完整 phase 順序與分支條件見 `SKILL.md`。

產出全部落在 `specs/<slug>/`，最終 handoff 寫 `handoffs/<slug>-spec.md`。

`specify/spec.md` 的「結構層以後唯一需求真源」地位與 gate 細節見 `SKILL.md`。

## 安裝（選用——**不裝也會用到**）

**不裝也會生效**：`.athena/skills/` 下找不到 `stage: spec` 的 skill 時，flow 退回
plugin 預設 skill `athena-spec-default`，由它載入本 pack 執行。flow **不會**停下來
要你補齊 spec skill，也**不會**因此報錯。

**裝到 `.athena/skills/` 只有一個理由：你要改它**（增刪 phase、換技術棧、加團隊判準）。
在你的專案根目錄：

```bash
cp -R <plugin-root>/skills/athena-core/assets/spec-pack-pm-to-eng \
      .athena/skills/pm-to-eng-spec
```

裝完 `/athena-flow` 的 Skill Discovery 會掃到它並綁到 `stage: spec`，你的副本從此
**取代** plugin 預設（預設完全不會被載入——plugin 預設永遠不進 discovery 對應表，
所以「團隊有 + plugin 有」不會被判為 duplicate-stage）。
注意：**同一 stage 只能有一個 skill**——若你的專案 `.athena/skills/` 下已有**另一個**
宣告 `stage: spec` 的 skill（例如自己的 spec index），flow 會報 duplicate-stage 錯，請先擇一。

## 設定（選用，在專案的 `specs/arguments.yml` 追加）

```yaml
spec_pack:
  target: fullstack        # backend（預設推斷）/ frontend / fullstack
  frontend_verify: mcp     # mcp / playwright / agent-browser / vitest-testing-library
```

缺設定時 target 由需求文字推斷（假設會記入 handoff Risks），不會互動詢問。

## 環境需求

- **api phase**：`python3` + `pyyaml`（transpiler `phases/api/scripts/openapi.py`
  把 intent DSL 編譯成 openapi.yaml）。缺環境時 phase 會 FAIL 並保留
  intent.yaml，不會產出半套 openapi。
- **前端 track**：前端棧依 `phases/common/rules/frontend-stack-conventions.md`
  （單一事實來源）固定為 Nuxt 4 + TypeScript strict。本 pack **不提供**專案級
  的棧覆寫設定；棧不同的團隊請把本 pack 裝到 `.athena/skills/` 後 fork 該
  conventions 檔自行調整。

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
- **血緣與同步紀律**：本 pack 已於 2026-10-27 正式 fork，`athena-skills` 不再
  是真源，詳見 `VENDORED.md`。真源（本目錄）→ dogfood 安裝
  （`.athena/skills/pm-to-eng-spec/`）仍維持單向同步，只改真源側，用
  `scripts/sync-spec-pack.sh` 同步、由 `scripts/lint-plugin.sh` 把關 drift。
- **授權與概念來源**：`specify` / `ui_prototype` 等 plugin 原創 phase 的判準
  借鑑自 CH3-SDD-workflow（Apache-2.0）與 GitHub Spec Kit（MIT）；完整標註見
  `VENDORED.md` 的「概念來源與授權標註」節。
