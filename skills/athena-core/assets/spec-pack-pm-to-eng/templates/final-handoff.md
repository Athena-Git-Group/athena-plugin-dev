# 最終 Handoff 骨架（`handoffs/<slug>-spec.md`）

依 athena-flow 的 `agent-handoff.md` 契約，必含 Minimum Contents 六欄。

**前三行是機械契約**（見 `agent-handoff.md` 的「機械契約紅線」）：第 1 行逐字 `# Handoff: spec`、
第 2 行空行、第 3 行是**這次 spec 做了什麼**的一句摘要。`hooks/auto-commit.sh` 取第 3 行為
commit 描述——H1 改字樣、或第 3 行寫成 `- **Stage**: ...` 這種欄位標籤，commit 訊息會**靜默**缺描述。

```markdown
# Handoff: spec

{{ONE_LINE_SUMMARY}}

## Stage
spec（pm-to-eng-spec，target: {{TARGET}}）

## Inputs Used
- points/{{SLUG}}.md
- {{ARGUMENTS_YML_STATUS}}

## Artifacts Produced
{{ARTIFACT_PATH_LIST}}

## Gate Verdict
{{GATE_VERDICT}}

## Risks / Unresolved Issues
{{RISK_LIST}}

## Next Recommended Stage
plan
```

填位符號說明：

- `{{ONE_LINE_SUMMARY}}` — 一行摘要，這次 spec 做了什麼；H1 後隔一空行的第 3 行，auto-commit.sh 取此行為 commit desc
- `{{TARGET}}` — `backend` / `frontend` / `fullstack`
- `{{SLUG}}` — 沿用 point-report 的 slug
- `{{ARGUMENTS_YML_STATUS}}` — `specs/arguments.yml`（或「缺，target 由需求推斷」）
- `{{ARTIFACT_PATH_LIST}}` — 逐一列出 `specs/<slug>/` 下實際產出的檔案路徑；含 `specify/spec.md` 與 `specify/requirements-checklist.md`；frontend / fullstack 另含 `ui_prototype/ui-plan.md` 與各張 `.html`
- `{{GATE_VERDICT}}` — `PASS`，或 `FAIL — 原因 #tag`（逐字照 `rules/gate-verdict-映射.md` 的映射表）
- `{{RISK_LIST}}` — 至少涵蓋下列幾類（無該類時該行省略）：
  - score `PASS-WITH-GAPS` 的缺口（`PASS-CLEAN` 時本行省略）
  - `target` / `frontend_verify` 的推斷假設
  - `ui_prototype` 追寫 `clarify/questions.md` 時記「ui_prototype 追寫 N 題待澄清」——非 gate，不改 verdict，但不得省略
  - 各 phase handoff 標注的範圍外待辦與假設——含 `gherkin` handoff 的「回饋訊號（待釐清缺口）」逐題轉錄：本 run 不回退階段，缺口一律經使用者回答 → `clarify/answers.md` → 下一輪 spec stage
