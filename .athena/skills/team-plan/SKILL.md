---
name: team-plan
description: >
  本 repo（athena-dev-plugin）的 plan stage skill。把 spec 產出的規格拆成一張可機械驗證的
  依賴圖（plans/<slug>/plan.md，Dependency Graph 以 YAML frontmatter 為準）
  與一組邊界互斥、可平行執行的 phase 卡片（todo/ 下，每張帶 touches 所有權
  宣告與 smoke test），通過 validate_plan.py --require-touches 後寫 plan handoff。
  本 repo 的產物是 markdown prompt 契約、bash hook 與 python script——不是
  一般 app，切分依據是「契約面」而非「前端／後端／E2E」。
stage: plan
---

# Team Plan（athena-dev-plugin）

你是 plan 階段的執行者：把規格變成可機械驗證的依賴圖與互斥的 phase 卡片。

# SOP

## Phase 1 -- 讀齊輸入

1. READ 讀取 `.athena/skills/team-common/rules/agent-isolation.md`，確認 fresh agent 的輸入紀律。
2. READ 讀取 `handoffs/<slug>-spec.md`，再依其 `Artifacts Produced` 讀取 spec 產出的規格文件。
3. READ 讀取 `points/<slug>.md`，特別是 Risks 段——風險常直接對應 phase 邊界。
4. READ 讀取 `skills/athena-flow/references/phase-orchestration.md` 的「解析 Dependency Graph」frontmatter schema 與「Phase Agent 的載入內容」表，確認下游怎麼消費你的產出。

## Phase 2 -- 切分 phase 並寫出 plan 與卡片

1. READ 讀取 `rules/phase-splitting.md`（本 skill），取得契約面切分判準。
2. THINK 依已載入規則找出規格涉及的契約面（消費者用 grep 找，不推測），切成互斥 touches 的 phase，並為每條依賴邊想好一句話理由。
3. READ 讀取 `templates/plan.md` 與 `templates/plan.example.md`（本 skill）；警語段的原文出處是 `skills/athena-specformula/assets/plan-template.md`。
4. WRITE 寫 `plans/<slug>/plan.md`——frontmatter 是 Dependency Graph 的機械依據，正文表格與 ASCII 圖必須與它一致。
5. READ 讀取 `templates/phase-card.md` 與 `templates/phase-card.example.md`（本 skill），以及 `.athena/skills/team-common/rules/smoke-test.md` 的 Rule 1、Rule 2（plan 時怎麼規劃 smoke test）。
6. WRITE 依樣板逐張寫 `plans/<slug>/todo/<NN>-<name>.md`，每張卡的 `Touches` 與 frontmatter 一字不差、`Smoke Test` 依已載入規則選定。
7. WRITE 建立空的 `plans/<slug>/doing/` 與 `plans/<slug>/done/`，各放一個 `.gitkeep`。

## Phase 3 -- 機械自檢與交接

1. READ 讀取 `rules/plan-quality.md`（本 skill），逐條檢查 plan 品質（含通讀驗收的安排）。
2. DELEGATE 執行 `python3 skills/athena-specformula/scripts/validate_plan.py --require-touches plans/<slug>/`；非 0 就依已載入規則改 plan 直到 exit 0。
3. READ 讀取 `skills/athena-flow/references/agent-handoff.md` 的 Plan 變體（+`## Phase 列表`、+`## Validator Result`）。
4. WRITE 照該變體寫 `handoffs/<slug>-plan.md`，`Validator Result` 貼指令、exit code 與實際輸出全文（有 warning 也要貼）。
5. READ Gate 為 FAIL 時（tag 用 `#plan-gap`），讀取 `.athena/skills/team-common/rules/fail-reporting.md` 並依其格式回報。
