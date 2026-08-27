# Point Gate Rules

`/point` 是 Athena harness 的進場閘門，不是純建議。

## Point Report Contract

每次新的需求評分，都要產生：

- `points/<request-slug>.md`

這份檔案是後續 `/spec`、`/build` 判斷能否進場的依據。

## Required Fields

- Request summary
- Scorecard
- Total score
- Knowledge base needed
- Knowledge sources checked
- Route
- Gate verdict
- Allowed next commands
- Risks

## Gate Verdict Meanings（權威定義）

| Verdict | Weight | 允許 | 要求 |
|---------|--------|------|------|
| `PASS-TRIVIAL` | Minimal | `/build` | build agent 結束前執行 self-review checklist；不進 review-ship，由 flow 直接提示 push 指令 |
| `PASS-DIRECT-BUILD` | Lightweight | `/build` | build 完成後進 `/review-ship`（Lightweight 合併 stage） |
| `PASS-BUILD-WITH-VERIFY` | Lightweight | `/build` | 完成後必須進 `/verify` → `/review-ship`（Lightweight 合併 stage） |
| `PASS-SPEC-FIRST` | Full Weight | `/spec` | spec 完成後再考慮 `/plan`；完整流程：spec → plan → build(phase loop) → verify → review → ship |

## Hard Stops

命中條件 → 目標 verdict 的完整映射見 `athena-point/SKILL.md`「硬性 Gate」表（單一來源）。
核心約束：命中任一硬性 Gate 時不得產生 `PASS-DIRECT-BUILD`。

## Missing Report Behavior

若沒有 point-report：

- `/build` 不得開始
- `/spec` 應優先要求先補 `/point`，除非是明確的長期新專案啟動
