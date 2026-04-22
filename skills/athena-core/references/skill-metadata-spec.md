# Skill Metadata Specification

## 概述

所有 skill 的 `SKILL.md` 使用 YAML frontmatter 宣告元資料。本文件定義完整的欄位規格，包含下游團隊上繳 skill 所需的欄位。

## Frontmatter 欄位

```yaml
---
name: <string>          # 必填。Skill 識別名稱，英文小寫 + 連字號（如 my-team-build）
description: <string>   # 必填。說明此 skill 做什麼、何時觸發
stage: <string>         # 條件必填。對應 pipeline stage（見下方列表）
user-invocable: <bool>  # 選填。是否可被使用者直接呼叫，預設 false
---
```

## `stage` 欄位

### 用途

讓 `athena-flow` 在掃描 `.athena/skills/` 時，知道這個 skill 應該被綁定到哪個 pipeline stage。

### 允許值

| stage 值 | 說明 |
|----------|------|
| `spec` | 需求分析階段 |
| `plan` | 工程計畫產生階段 |
| `build` | 實作階段 |
| `verify` | 驗證階段 |
| `review` | 審查階段 |
| `ship` | 部署階段 |

> `point` 和 `flow` 由 plugin 控制，不允許下游團隊宣告。

### 何時需要

- 放在 `.athena/skills/` 下、要被 flow 編排的 skill → **必填**
- Plugin 內建的 skill（如 athena-core） → 不需要
- Index skill（路由多個子 skill） → **必填**，且子 skill 不宣告 `stage`

## `name` 命名規範

- 使用英文小寫 + 連字號
- 建議前綴團隊名稱，避免跨團隊衝突（如 `payments-build`、`logistics-spec`）
- Index skill 建議命名為 `<team>-<stage>-index`（如 `payments-build-index`）

## 範例

### 一般 Skill

```yaml
---
name: payments-build
description: >
  Payments 團隊的 build skill。使用 Java + Spring Boot，
  遵循團隊的 TDD 流程與 CI pipeline。
stage: build
---
```

### Index Skill（同一 stage 多流程）

```yaml
---
name: payments-build-index
description: >
  Payments 團隊 build stage 的路由索引。
  根據需求類型分派到不同的 build skill。
stage: build
---
```

### 不屬於任何 stage 的輔助 Skill

```yaml
---
name: payments-utils
description: >
  Payments 團隊共用的 reference 庫，不直接參與 pipeline。
---
```
