# Skill Metadata Specification

## 概述

所有 skill 的 `SKILL.md` 使用 YAML frontmatter 宣告元資料。本文件定義完整的欄位規格，包含下游團隊上繳 skill 所需的欄位。

## Frontmatter 欄位

```yaml
---
name: <string>          # 必填。Skill 識別名稱，英文小寫 + 連字號（如 my-team-build）
description: <string>   # 必填。說明此 skill 做什麼、何時觸發
stage: <string>         # 條件必填。對應 pipeline stage（見下方列表）
user-invocable: <bool>  # 選填。是否可被使用者直接呼叫，**預設 true**
                        # （2026-08-04 實測 v2.1.221：未宣告此欄位的 skill 可被斜線呼叫；
                        #   明設 false 者呼叫時靜默不解析，且不會回 "Unknown command"。
                        #   要禁止使用者直接呼叫必須顯式寫 false）
---
```

## `stage` 欄位

### 用途

讓 `athena-flow` 在掃描 `.athena/skills/` 時，知道這個 skill 應該被綁定到哪個 pipeline stage。

### 允許值

| stage 值 | 類型 | 說明 |
|----------|------|------|
| `pre-build` | flow-inline | Build 前的準備操作（如建立 Git 分支） |
| `spec` | standard-with-plugin-default | 需求分析階段（**團隊未提供時 flow 退回 plugin 預設 `athena-spec-default`，不停止**） |
| `plan` | standard | 工程計畫產生階段 |
| `build` | standard | 實作階段 |
| `post-build` | flow-inline | Build/Verify 後的收尾操作（如自動 commit） |
| `verify` | standard | 驗證階段 |
| `review` | standard | 審查階段 |
| `ship` | standard | 部署階段 |

> `point` 和 `flow` 由 plugin 控制，不允許下游團隊宣告。

### Stage 分類

stage 分**三類**（此三行是 `athena-skill-audit` L1 靜態檢查合法值分類的逐字來源）：

- Standard（團隊必須提供，缺少 → flow 停止＋引導）：`plan` / `build` / `verify` / `review` / `ship`
- Standard-with-plugin-default（團隊優先，缺少 → 退回 plugin 預設、不停止）：`spec`
- Flow-inline（團隊優先，缺少 → 用 plugin 預設、不停止）：`pre-build` / `post-build`

#### Standard Stage

- 由 **fresh agent** 執行（每個 stage 獨立 agent）
- **團隊必須提供**，缺少時 flow 停止並引導
- 產出 handoff artifact 到 `handoffs/` 目錄
- 完整的 agent 隔離，不共享對話上下文

#### Standard Stage with Plugin Default（目前只有 `spec`）

- 執行模型與 Standard Stage **完全相同**：fresh agent、產出 handoff artifact、完整 agent 隔離
- **團隊優先**：`.athena/skills/` 有宣告 `stage: spec` 的 skill → 用它，plugin 預設**完全不被載入**
- **團隊未提供時退回 plugin 預設** `athena-spec-default`，**不停止流程、不引導補齊**
- 「有 plugin 預設」只改 resolution，不改執行方式、輸入輸出或 gate 契約

#### Flow-Inline Stage

- 在 **flow agent 中內聯執行**（不開 fresh agent）
- **Plugin 提供預設實作**，團隊可在 `.athena/skills/` 中替換
- 透過 **flow context** 傳遞資訊（不產出 handoff artifact）
- 適用於輕量級的跨 stage 輔助操作

### 有 Plugin 預設的 stage 的 Discovery 規則

`spec`（standard-with-plugin-default）與 flow-inline stage 的 discovery 都是「團隊優先、缺則預設」，
與其餘 standard stage 不同：

```
1. 掃描 .athena/skills/ 尋找對應 stage 的 skill
   （plugin 預設本身永遠不進 flow 的 stage → skill 對應表）
2. 若找到 → 使用團隊的 skill（團隊替換了預設），plugin 預設完全不被載入
3. 若未找到 → 使用 plugin 預設
   （spec → athena-spec-default；pre-build / post-build → athena-pre-build / athena-post-build）
4. 不會停止流程，也不會引導團隊補齊（因為有預設）
5. 因為 plugin 預設不在對應表內，「團隊有 + plugin 有」不會被判為重複 stage 綁定
```

**三類的關鍵差異**：

| | Standard Stage | Standard with Plugin Default（`spec`） | Flow-Inline Stage |
|---|---|---|---|
| 適用 stage | `plan` / `build` / `verify` / `review` / `ship` | `spec` | `pre-build` / `post-build` |
| 缺少 skill 時 | 停止流程 + 引導 | 使用 plugin 預設（不停止、不引導） | 使用 plugin 預設 |
| 執行方式 | Fresh agent | Fresh agent | Flow agent 內聯 |
| 交接方式 | Handoff artifact | Handoff artifact | Flow context |
| 團隊是否必須提供 | 是 | 否（可選替換） | 否（可選替換） |

### 何時需要

- 放在 `.athena/skills/` 下、要被 flow 編排的 skill → **必填**
- Plugin 內建的 skill（如 athena-core） → 不需要
- Index skill（路由多個子 skill） → **必填**，且子 skill 不宣告 `stage`

## `name` 命名規範

- 使用英文小寫 + 連字號
- 建議前綴團隊名稱，避免跨團隊衝突（如 `payments-build`、`logistics-spec`）
- Index skill 建議命名為 `<team>-<stage>-index`（如 `payments-build-index`）
- Flow-inline skill 替換預設時，建議命名為 `<team>-<stage>`（如 `payments-pre-build`）

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

### Flow-Inline Skill（替換預設）

```yaml
---
name: payments-pre-build
description: >
  Payments 團隊的 pre-build skill。替換 plugin 預設的分支建立邏輯，
  使用團隊自訂的分支命名規範與 Jira ticket 整合。
stage: pre-build
---
```
