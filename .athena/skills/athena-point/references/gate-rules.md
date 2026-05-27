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

## Gate Verdict Meanings

### `PASS-TRIVIAL`（Minimal）

允許：
- `/build`

要求：
- build agent 結束前執行 self-review checklist
- 不進 review-ship，由 flow 直接提示 push 指令

### `PASS-DIRECT-BUILD`（Lightweight）

允許：
- `/build`

要求：
- build 完成後進 `/review-ship`（Lightweight 合併 stage）

### `PASS-BUILD-WITH-VERIFY`（Lightweight）

允許：
- `/build`

要求：
- 完成後必須進 `/verify` → `/review-ship`（Lightweight 合併 stage）

### `PASS-SPEC-FIRST`（Full Weight）

允許：
- `/spec`

要求：
- spec 完成後再考慮 `/plan`
- 完整流程：spec → plan → build(phase loop) → verify → review → ship

## Hard Stops

以下情況下不得產生 `PASS-DIRECT-BUILD`：

- 未查證但明顯依賴知識庫
- 有 schema / entity 變更
- 有 API contract 變更
- 需求存在關鍵歧義
- 牽涉高風險 domain rule

## Missing Report Behavior

若沒有 point-report：

- `/build` 不得開始
- `/spec` 應優先要求先補 `/point`，除非是明確的長期新專案啟動
