# 最終 Handoff 範例（`handoffs/refund-partial-spec.md`）

以下是骨架填完後的樣子——前三行維持機械契約：第 1 行逐字 `# Handoff: spec`、第 2 行空行、
第 3 行是一句摘要（`hooks/auto-commit.sh` 取此行為 commit 描述）。

```markdown
# Handoff: spec

把「訂單部分退款」需求轉成工程規格：完成 score / clarify / specify 三道 gate，並產出 backend track 的資料模型、類別圖、DB 表與 API 契約，最後補上 Gherkin 規格。

## Stage
spec（pm-to-eng-spec，target: backend）

## Inputs Used
- points/refund-partial.md
- specs/arguments.yml

## Artifacts Produced
- specs/refund-partial/source/requirement.md
- specs/refund-partial/score/score-report.md
- specs/refund-partial/clarify/clarified.md
- specs/refund-partial/clarify/questions.md
- specs/refund-partial/specify/spec.md
- specs/refund-partial/specify/requirements-checklist.md
- specs/refund-partial/data_model/data-model.md
- specs/refund-partial/class_diagram/class-diagram.mmd
- specs/refund-partial/db_table/schema.dbml
- specs/refund-partial/api/refund.intent.yaml
- specs/refund-partial/api/openapi.yaml
- specs/refund-partial/gherkin/refund.feature

## Gate Verdict
PASS

## Risks / Unresolved Issues
- score PASS-WITH-GAPS：需求未說明退款是否需要主管複核，已於 clarify 依現行流程文件補齊，若流程有變需回頭修 spec.md
- frontend_verify 未指定：gherkin 產出的是 runner-agnostic .feature，建議於 plan 階段決定驗證機制
- openapi.yaml 未經 validator 驗證（openapi-spec-validator 與 npx @redocly/cli 皆不可用，依契約跳過驗證、不觸網安裝）
- gherkin 待釐清：退款金額超過原訂單金額時的預期行為未定義（見 gherkin/refund.feature 的 @待釐清）；本 run 不回退階段，缺口經使用者回答 → clarify/answers.md → 下一輪 spec stage

## Next Recommended Stage
plan
```
