# athena-dev-plugin

Athena 開發團隊專用 Claude Code Plugin — 提供 point → spec → plan → build → review → ship 全流程骨架。

Plugin 定義流水線的**流程契約**（每個 stage 的輸入/輸出規格），各團隊在自己的專案中提供 stage 的實際 skill 實作。
流程會根據 point 評分自動分流為三種 weight class（Minimal / Lightweight / Full），避免小任務走過重的儀式。

## 架構

```
athena-dev-plugin（本 repo）              團隊專案
┌──────────────────────────────┐    ┌──────────────────────────────┐
│ athena-flow   （編排器）       │    │ .athena/skills/              │
│ athena-point  （評分閘門）     │    │   ├── my-team-spec/SKILL.md  │
│ athena-core   （共用參考）     │    │   ├── my-team-plan/SKILL.md  │
│                              │    │   ├── my-team-build/SKILL.md │
│ athena-pre-build  （Git 分支） │    │   ├── my-team-verify/SKILL.md│
│ athena-post-build （Git 提交） │    │   ├── my-team-review/SKILL.md│
│ git-conventions （Git 規範）   │    │   └── my-team-ship/SKILL.md  │
│                              │    │                              │
│ Stage Contracts              │    │   # 可選：替換 plugin 預設     │
│ Skill Templates              │    │   ├── my-team-pre-build/     │
│                              │    │   └── my-team-post-build/    │
└──────────────────────────────┘    └──────────────────────────────┘
      流程骨架 + 契約                        團隊上繳的 skill
```

## Plugin 包含的 Skills

| Skill | 類型 | 可替換？ | 說明 |
|-------|------|---------|------|
| **athena-flow** | 編排器 | 否 | 單一入口流程編排器，串接所有階段 |
| **athena-point** | 閘門 | 否 | 需求評分與分流（決定是否需要走 spec） |
| **athena-core** | 參考庫 | — | 共用參考庫（Reconciler Contract、Skill 模板等） |
| **athena-pre-build** | flow-inline | 是（有預設） | Build 前自動建立 Git 分支 |
| **athena-post-build** | flow-inline | 是（有預設） | Build/Verify 通過後自動 Git commit |
| **git-conventions** | 參考庫 | — | Git 分支命名與 commit message 規範 |

## Stage 分類

### Standard Stage（團隊必須提供）

| Stage | 職責 | 執行方式 |
|-------|------|----------|
| **spec** | 需求分析，產出結構化規格 | Fresh agent |
| **plan** | 將規格轉換為可執行工程計畫 | Fresh agent |
| **build** | 根據計畫執行實作 | Fresh agent |
| **verify** | 驗證 build 產出的正確性 | Fresh agent |
| **review** | 程式碼審查、品質把關 | Fresh agent |
| **ship** | 部署、發布、收尾 | Fresh agent |

### Flow-Inline Stage（Plugin 提供預設，團隊可選擇性替換）

| Stage | 職責 | 執行方式 |
|-------|------|----------|
| **pre-build** | Build 前建立 Git 分支 | Flow agent 內聯 |
| **post-build** | Gate PASS 後自動 Git commit | Flow agent 內聯 |

| | Standard Stage | Flow-Inline Stage |
|---|---|---|
| 缺少 skill 時 | 停止流程 + 引導 | 使用 plugin 預設 |
| 執行方式 | Fresh agent | Flow agent 內聯 |
| 交接方式 | Handoff artifact | Flow context |
| 團隊是否必須提供 | 是 | 否（可選替換） |

所有 stage 的契約定義見 `skills/athena-flow/references/stage-contracts.md`。

## 安裝

### 方式 A：本地載入（單次 session）

啟動 Claude Code 時指定 plugin 目錄：

```bash
claude --plugin-dir /path/to/athena-dev-plugin
```

### 方式 B：永久安裝（透過 marketplace）

```bash
# 1. 將本 repo 註冊為 marketplace
claude plugin marketplace add https://github.com/Athena-Git-Group/athena-dev-plugin.git

# 2. 安裝 plugin
claude plugin install athena-dev-plugin

# 3. 確認安裝
claude plugin list
```

## 團隊如何上繳 Skill

### 1. 建立目錄

在專案根目錄建立 `.athena/skills/<skill-name>/` 目錄。

### 2. 撰寫 SKILL.md

複製模板（`skills/athena-core/assets/skill-template/SKILL.md`），填入 frontmatter：

```yaml
---
name: my-team-build
description: 我們團隊的 build skill
stage: build
---
```

`stage` 欄位告訴 flow 這個 skill 對應哪個 pipeline stage。

### 3. 遵守 Stage 契約

每個 stage 有定義好的輸入/輸出契約（見 `skills/athena-flow/references/stage-contracts.md`）。Skill 必須：

- 讀取前一個 stage 的 handoff artifact
- 產出該 stage 要求的 artifact
- 寫入 handoff artifact 到 `handoffs/` 目錄

### 4. 同一 Stage 多流程？

如果一個 stage 有多種流程，建立一個 **index skill** 作為路由：

```
.athena/skills/
├── my-team-build-index/SKILL.md    ← stage: build（路由器）
├── my-team-build-backend/SKILL.md  ← 無 stage（子 skill）
└── my-team-build-frontend/SKILL.md ← 無 stage（子 skill）
```

詳見 `skills/athena-flow/references/index-skill-pattern.md`。

### 5. 替換 Flow-Inline 預設（可選）

團隊可替換 plugin 預設的 pre-build / post-build 行為。在 `.athena/skills/` 中建立對應 skill：

```yaml
---
name: my-team-pre-build
description: 我們團隊的 pre-build skill（使用 Jira ticket 整合）
stage: pre-build
---
```

若未提供，flow 會自動使用 plugin 的 `athena-pre-build` / `athena-post-build` 預設。

## 團隊知識庫

athena-point 在評分時會自動掃描 `.athena/knowledge/` 目錄，讀取團隊的業務規則、產品規格等知識文件來輔助判斷。

```
.athena/knowledge/
├── domain-rules/        # 業務規則、政策、SOP
├── product-specs/       # 產品規格、PRD、功能定義
├── api-contracts/       # API 規格、schema 定義
└── ...                  # 自由組織
```

目錄結構由團隊自行組織，沒有強制規範。若目錄不存在，不影響評分流程。

## Weight Class（三層分流）

Flow 根據 point 評分自動決定流程重量，避免小任務走過重的儀式：

| Verdict | Weight | 分數 | Agent 數 | 路線 |
|---------|--------|------|---------|------|
| `PASS-TRIVIAL` | **Minimal** | 0-4 | 2 | point → build(+self-review) → commit → done |
| `PASS-DIRECT-BUILD` | **Lightweight** | 5-7 | 3 | point → build → review-ship |
| `PASS-BUILD-WITH-VERIFY` | **Lightweight** | 8-14 | 4 | point → build → verify → review-ship |
| `PASS-SPEC-FIRST` | **Full** | 15-30 | 7+N | point → spec → plan → build(phases) → verify → review → ship |

- **Minimal**：build agent 結束前自帶 self-review checklist，不開 review/ship agent，由使用者自行 push
- **Lightweight**：review + ship 合併為一個 agent
- **Full**：完整流程，build 內部依 plan.md 拆分 phase loop

## 流程概覽

```
/flow
  │
  ├─ Skill Discovery：掃描 .athena/skills/，建立 stage → skill 對應表
  │    Standard stage：團隊必須提供，缺少則停止
  │    Flow-inline stage：團隊有就用，沒有就用 plugin 預設
  │
  ├─ /point（plugin 內建）
  │     ↓
  │  (scoring gate)
  │     ↓
  │  PASS-TRIVIAL ──────────────────→ [pre-build] → build(minimal) → [post-build] → done
  │  PASS-DIRECT-BUILD ─────────────→ [pre-build] → build → [post-build] → review-ship
  │  PASS-BUILD-WITH-VERIFY ────────→ [pre-build] → build → [post-build] → verify → [post-build] → review-ship
  │  PASS-SPEC-FIRST → spec → plan → [pre-build] → build(phases) → [post-build] → verify → [post-build] → review → ship
  │
  │  [括號] = flow-inline stage（flow agent 內聯執行）
  │  其餘 = standard stage（fresh agent 執行）
  │
  └─ Git Lifecycle:
       [pre-build]  — 建立分支，遵循 git-conventions 命名規範
       [post-build] — gate PASS 後自動 commit，遵循 git-conventions 格式
```

## 強制規則

安裝本 plugin 後，**任何程式碼變更都必須先跑 `/athena-dev-plugin:athena-point`**。
Agent 不得自行判斷複雜度而跳過 point 評分。唯一例外：使用者明確說「不要跑 point」或純文件改動。

## 參考文件

> 以下路徑皆相對於 plugin 的 `skills/` 目錄。

| 文件 | 位置 | 說明 |
|------|------|------|
| Stage 編排 | `athena-flow/references/stage-orchestration.md` | Weight Class 路由與 stage 順序定義 |
| Stage 契約 | `athena-flow/references/stage-contracts.md` | 每個 stage 的輸入/輸出規格 |
| Skill 元資料規格 | `athena-core/references/skill-metadata-spec.md` | SKILL.md frontmatter 欄位定義 |
| Index Skill 模式 | `athena-flow/references/index-skill-pattern.md` | 同 stage 多 skill 的路由規範 |
| Agent Handoff 契約 | `athena-flow/references/agent-handoff.md` | stage 間的交接格式 |
| Git Lifecycle Hooks | `athena-flow/references/git-lifecycle-hooks.md` | Git 操作的觸發時機定義 |
| Git 規範 | `git-conventions/SKILL.md` | 分支命名與 commit message 規範 |
| Skill 模板 | `athena-core/assets/skill-template/SKILL.md` | 一般 skill 起手模板 |
| Index Skill 模板 | `athena-core/assets/index-skill-template/SKILL.md` | Index skill 起手模板 |

## 內建參考 Skills

本 repo 也包含以下 skills 作為**參考實作範例**。這些不會被 flow 自動使用——團隊應將它們作為建立自己 stage skill 的參考：

| Skill | 對應 Stage | 說明 |
|-------|-----------|------|
| **athena-discovery** | spec | 需求分析（7 步流程，產出 Activity + Feature Rules） |
| **athena-specformula** | plan | 工程計畫產生器（產出 plan.md + Phase 卡片） |
| **athena-carry-on-engineering-plan** | build | 計畫執行器（human-in-the-loop 逐 Phase 推進） |
