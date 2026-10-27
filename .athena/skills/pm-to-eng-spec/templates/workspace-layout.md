# Workspace 目錄配置（`specs/<slug>/`）

所有產出落在 `specs/{{SLUG}}/`（`{{SLUG}}` 沿用 point-report 的 slug）：

```text
specs/{{SLUG}}/
  ├─ source/requirement.md      # 需求原文（自 point-report 抄錄，不可變）
  ├─ score/score-report.md      # score phase，開頭含 VERDICT
  ├─ clarify/clarified.md       # clarify phase，開頭含 STATUS（**specify 的輸入**）
  ├─ clarify/questions.md       # 待澄清問題（headless 協議；clarify / specify /
  │                             #   ui_prototype **三支共用**，見 rules/questions-共用契約.md）
  ├─ clarify/answers.md         # 使用者的回答（由 flow 主對話寫入）
  ├─ specify/spec.md            # specify phase，開頭含 STATUS；**結構層以後的唯一需求真源**
  ├─ specify/requirements-checklist.md      # specify 規格品質自檢
  ├─ design/                    # 【輸入】設計師視覺稿，選用，pack 不寫入
  ├─ data_model/ class_diagram/ db_table/   # 結構層（backend）
  ├─ screens/                               # 結構層（frontend）
  ├─ api/ ui_contract/                      # 契約層
  ├─ ui_prototype/              # 【輸出】前端 / fullstack 專屬：ui-plan.md + index.html + <screen>.html
  ├─ gherkin/                   # 規格層（fullstack 分 backend/ frontend/）
  └─ handoffs/<stage>.md        # 各 phase 的內部交接便條
```

最終 stage handoff 寫 `handoffs/{{SLUG}}-spec.md`（repo 根目錄，flow 契約位置）。

## `design/` 是輸入，pack 的任何 phase 都不得寫入

`specs/{{SLUG}}/design/` 是**輸入**（設計師視覺稿，由人提供、可能不存在）——
**pack 的任何 phase 都不得寫入它**。可點擊的雛形一律落在
`specs/{{SLUG}}/ui_prototype/`（`ui_prototype` phase 的輸出）；兩者不得互換、不得互覆。
與稿不一致處標 `待釐清` / `待補設計`，不擅自選邊。
