# Handoff: verify (lightweight)

{{ONE_LINE_SUMMARY}}

## Stage
verify

## Inputs Used
- points/{{SLUG}}.md
- handoffs/{{SLUG}}-build.md
- git diff {{BASE}}...HEAD

## Artifacts Produced
- handoffs/{{SLUG}}-verify.md（本檔；verify 只回報，不產出程式碼）

## Gate Verdict
{{VERDICT_LINE}}

## Checks Performed
- {{ACCEPTANCE_ITEM}}: {{CHECK_RESULT}}
- {{SMOKE_RERUN_COMMAND}}: {{CHECK_RESULT}}
- {{RISK_CHECK_COMMAND}}: {{CHECK_RESULT}}

## Issues Found
1. {{FILE_PATH}}:{{LINE_NO}} — {{ISSUE_DESCRIPTION}} #{{TAXONOMY_TAG}}

## Risks / Unresolved Issues
{{RISKS_OR_NONE}}

## Next Recommended Stage
{{NEXT_STAGE}}

## Timing
- Started At: {{STARTED_AT_UTC}}
- Ended At: {{ENDED_AT_UTC}}

<!-- 前三行（H1 → 空行 → 一行摘要）與「Gate Verdict 緊貼標題」依
     skills/athena-flow/references/agent-handoff.md 的機械契約，不可變動。
     Lightweight 模式：Inputs Used 不含 mini-handoff、issue 不加 [Phase NN]
     前綴、無 Affected Phases 段。Issues Found 若無 issue 則填 None。
     複製後刪除本註解。 -->
