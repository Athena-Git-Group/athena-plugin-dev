---
plan: add-rule-conflict-tag
phases:
  - id: "01"
    name: taxonomy-enum
    depends_on: []
    touches:
      files: ["skills/hxde-flow/references/**", "skills/hxde-hill-climb/references/**"]
      resources: ["trace-schema"]
  - id: "02"
    name: emit-trace-script
    depends_on: ["01"]
    touches:
      files: ["scripts/**"]
      resources: ["trace-schema"]
status_source: folders
---

# 工程計畫：新增 rule-conflict failure tag

> **需求摘要**: 在 failure taxonomy 新增 `#rule-conflict` tag，並讓 emit-trace 能彙整它。

## Dependency Graph

> **機械真相聲明**：本檔頂部的 YAML frontmatter 是 Dependency Graph 的**唯一機械真相**
> （由 `scripts/validate_plan.py` 解析與驗證）。下方的 markdown 表格與 ASCII 圖只是
> **人類視圖**，必須與 frontmatter 一致，否則 validator 會報 error。
> `status_source: folders` 表示 phase 狀態的唯一真相是卡片所在的 `todo/` / `doing/` /
> `done/` 資料夾；表格中的「狀態」欄僅供人類瀏覽。
>
> **防過度串鏈**：兩個 phase 若 touches 無交集且無語意依賴，**不得**加 `depends_on`
> 邊——邊只表達真正的依賴，人為串鏈會抹掉可平行性。
>
> （以上兩段警語照抄自 `skills/hxde-specformula/assets/plan-template.md`，以該檔為準。）

| Phase | Name | Depends On | 狀態 |
|-------|------|------------|------|
| 01 | taxonomy-enum | — | todo |
| 02 | emit-trace-script | 01 | todo |

```
01 → 02
```
