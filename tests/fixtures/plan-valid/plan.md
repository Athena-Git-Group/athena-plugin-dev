---
plan: plan-valid
phases:
  - id: "01"
    name: Requirement Analysis
    depends_on: []
    touches:
      files: ["specs/discovery/**"]
  - id: "02"
    name: Entity Modeling
    depends_on: ["01"]
    touches:
      files: ["specs/entity/**"]
  - id: "03"
    name: BDD Analysis
    depends_on: ["02"]
    touches:
      files: ["specs/features/**"]
  - id: "04"
    name: API Contract
    depends_on: ["03"]
    touches:
      files: ["specs/api/**"]
  - id: "05"
    name: Backend TDD Track
    depends_on: ["04"]
    touches:
      files: ["src/backend/**", "tests/backend/**"]
      resources: ["db-migration-sequence"]
  - id: "06"
    name: Frontend Build Track
    depends_on: ["04"]
    touches:
      files: ["src/frontend/**"]
  - id: "07"
    name: Frontend E2E
    depends_on: ["06"]
    touches:
      files: ["tests/e2e/**"]
  - id: "08"
    name: Integration Validation
    depends_on: ["05", "07"]
    touches:
      files: ["reports/integration/**"]
status_source: folders
---

# 工程計畫：plan-valid（lint fixture）

> Fixture for `scripts/lint-plugin.sh` — a minimal valid 8-phase plan used to
> self-test `skills/athena-specformula/scripts/validate_plan.py`.

## Dependency Graph

> 機械真相是頂部 frontmatter；下表為人類視圖。

| Phase | Name | Depends On | 狀態 |
|-------|------|------------|------|
| 01 | Requirement Analysis | — | todo |
| 02 | Entity Modeling | 01 | todo |
| 03 | BDD Analysis | 02 | todo |
| 04 | API Contract | 03 | todo |
| 05 | Backend TDD Track | 04 | todo |
| 06 | Frontend Build Track | 04 | todo |
| 07 | Frontend E2E | 06 | todo |
| 08 | Integration Validation | 05, 07 | todo |
