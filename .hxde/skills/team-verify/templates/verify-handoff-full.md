# Handoff: verify

{{ONE_LINE_SUMMARY}}

## Stage
verify

## Inputs Used
- points/{{SLUG}}.md
- handoffs/{{SLUG}}-build.md（flow 合成的最終 build handoff）
- handoffs/{{SLUG}}-build-phase-{{NN}}.md（所有 mini-handoff，逐一列出）
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
1. **[Phase {{NN}}]** {{FILE_PATH}}:{{LINE_NO}} — {{ISSUE_DESCRIPTION}} #{{TAXONOMY_TAG}}

## Affected Phases
- Phase {{NN}}: {{ISSUE_COUNT}}

## Risks / Unresolved Issues
{{RISKS_OR_NONE}}

## Next Recommended Stage
{{NEXT_STAGE}}

## Timing
- Started At: {{STARTED_AT_UTC}}
- Ended At: {{ENDED_AT_UTC}}

<!-- 前三行（H1 → 空行 → 一行摘要）與「Gate Verdict 緊貼標題」依
     skills/hxde-flow/references/agent-handoff.md 的機械契約，不可變動。
     Issues Found / Affected Phases 若無 issue 則填 None。複製後刪除本註解。 -->
