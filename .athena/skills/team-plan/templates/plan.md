---
plan: {{PLAN_SLUG}}
phases:
  - id: "{{PHASE_ID}}"
    name: {{PHASE_NAME}}
    depends_on: [{{DEPENDS_ON_IDS}}]
    touches:
      files: [{{FILES_GLOBS}}]
      resources: [{{RESOURCES}}]
status_source: folders
---

# 工程計畫：{{PLAN_TITLE}}

> **需求摘要**: {{REQUIREMENT_SUMMARY}}

## Dependency Graph

{{MECHANICAL_TRUTH_WARNINGS}}
<!-- 上列填位：照抄 skills/athena-specformula/assets/plan-template.md 的「機械真相聲明」與「防過度串鏈」兩段警語，不自行改寫 -->

| Phase | Name | Depends On | 狀態 |
|-------|------|------------|------|
| {{PHASE_ID}} | {{PHASE_NAME}} | {{DEPENDS_ON_IDS}} | todo |

```
{{ASCII_GRAPH}}
```
