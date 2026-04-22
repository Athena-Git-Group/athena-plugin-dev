# athena-dev-plugin

Athena 開發團隊專用 Claude Code Plugin — 提供 spec → plan → build → review → ship 全流程工作流。

## 包含的 Skills

| Skill | 說明 |
|-------|------|
| **athena-flow** | 單一入口流程編排器，串接所有階段 |
| **athena-point** | 需求評分與分流（決定是否需要走 spec） |
| **athena-discovery** | 需求分析（Phase 01）— 產出 Activity、Feature Rules |
| **athena-specformula** | 工程計畫產生器 — 產出 plan.md + Phase 卡片 |
| **athena-carry-on-engineering-plan** | 計畫執行器 — human-in-the-loop 逐 Phase 推進 |
| **athena-core** | 共用參考庫（Reconciler Contract 等） |

## 安裝

在 Claude Code 中安裝此 plugin：

```bash
claude plugin add https://github.com/Athena-Git-Group/athena-dev-plugin.git
```

## 流程概覽

```
/flow → /point → /discovery → /specformula → /carry-on-engineering-plan
         ↓
   (scoring gate)
         ↓
  PASS-DIRECT-BUILD → 直接 build
  PASS-SPEC-FIRST   → discovery → specformula → carry-on
```

## 注意事項

此 plugin 包含核心流程鏈。部分下游 skills（如 form-entity-spec、form-bdd-analysis、auto-red/green/refactor 等）未包含在內，需另行安裝或搭配 athena-workflow-plugin 使用。
