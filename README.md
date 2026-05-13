# athena-dev-plugin

Athena 開發團隊專用 Claude Code Plugin — 提供 point → spec → plan → build → review → ship 全流程骨架。

Plugin 定義流水線的**流程契約**（每個 stage 的輸入/輸出規格），各團隊在自己的專案中提供 stage 的實際 skill 實作。
流程會根據 point 評分自動分流為三種 weight class（Minimal / Lightweight / Full），避免小任務走過重的儀式。

## 架構

```
athena-dev-plugin（本 repo）                   consumer 專案
┌────────────────────────────────────┐     ┌──────────────────────────────┐
│ skills/   流程 skill                │     │ .athena/skills/              │
│   flow / point / core / pre-build  │     │   ├── my-team-spec/SKILL.md  │
│   post-build / git-conventions /…  │     │   ├── my-team-plan/SKILL.md  │
│                                    │     │   ├── my-team-build/SKILL.md │
│ commands/  Slash command 入口        │     │   ├── my-team-verify/…       │
│   /athena-flow /athena-point …     │     │   ├── my-team-review/…       │
│                                    │     │   └── my-team-ship/…         │
│ agents/    Per-stage subagent 殼    │     │                              │
│   stage-spec / build / verify / …  │     │   # 可選：替換 flow-inline     │
│   每個附 tool scope                 │     │   ├── my-team-pre-build/     │
│                                    │     │   └── my-team-post-build/    │
│ hooks/     PreToolUse + SubagentStop│     │                              │
│   require-point.sh  (gate)         │     │ .athena/knowledge/   (可選)   │
│   auto-commit.sh    (opt-in)       │     │ .athena/evals/       (可選)   │
│                                    │     │                              │
│ scripts/   lint-plugin.sh          │     │ points/    /flow runtime      │
│ .github/workflows/  CI lint         │     │ handoffs/  /flow runtime      │
│ .athena/evals/  dogfood eval cases │     │ requirement-feedback/ (可選)  │
└────────────────────────────────────┘     └──────────────────────────────┘
        流程骨架 + 契約 + harness 強制                  團隊上繳的 skill + 工作檔
```

## Plugin 結構

Plugin 透過 Claude Code 的四個 manifest 入口（`skills` / `commands` / `agents` / `hooks`）發布功能。

### Skills（流程邏輯）

| Skill | 類型 | 可替換？ | 說明 |
|-------|------|---------|------|
| **athena-flow** | 編排器 | 否 | 單一入口流程編排器，串接所有階段 |
| **athena-point** | 閘門 | 否 | 需求評分與分流（決定是否需要走 spec） |
| **athena-core** | 參考庫 | — | 共用參考庫（Reconciler Contract、Skill 模板等） |
| **athena-pre-build** | flow-inline | 是（有預設） | Build 前自動建立 Git 分支 |
| **athena-post-build** | flow-inline | 是（有預設） | Build/Verify 通過後自動 Git commit |
| **athena-skill-audit** | 輔導工具 | — | 團隊主動觸發的 skill 品質健檢（L1+L2 靜態，獨立於 flow） |
| **athena-skill-eval** | 輔導工具 | — | L4 動態 eval runner — 對 skill 跑 case，捕捉真實行為（獨立於 flow） |
| **athena-audit-requirement-backend** | 輔導工具 | — | PM 需求文件「後端視角」可譯性審計（獨立於 flow，PM/TL 主動觸發） |
| **athena-audit-requirement-frontend** | 輔導工具 | — | PM 需求文件「前端視角」可譯性審計（獨立於 flow，PM/TL 主動觸發） |
| **git-conventions** | 參考庫 | — | Git 分支命名與 commit message 規範 |

### Slash Commands（使用者入口）

| Command | 對應 Skill | 用途 |
|---------|-----------|------|
| `/athena-flow <request>` | `athena-flow` | 單一入口流程編排器 |
| `/athena-point <request>` | `athena-point` | 需求評分與分流 |
| `/athena-skill-audit [skill]` | `athena-skill-audit` | Skill 靜態品質健檢 |
| `/athena-skill-eval <skill> <case>` | `athena-skill-eval` | Skill 動態行為評估 |

短形式由 harness 路由到對應 skill；若有衝突可用 fully-qualified `/athena-dev-plugin:athena-flow`。Commands 是 thin wrapper，邏輯在 `skills/<name>/SKILL.md`。

### Agents（per-stage tool-scope shells）

Flow agent 啟動 standard stage 時，會以 `Agent(subagent_type: "athena-stage-<stage>")` 包裝 fresh agent，讓 harness 替每個 stage 強制工具邊界——團隊 skill 仍是邏輯來源，subagent 只負責限縮工具範圍。

| Subagent | Stage | 工具範圍 |
|----------|-------|---------|
| `athena-point` | point | Read / Grep / Glob / Write(`points/`) |
| `athena-stage-spec` | spec | Read / Grep / Glob / Bash(唯讀 git, diagram CLI) / Write(`specs/` + `handoffs/`) |
| `athena-stage-plan` | plan | 同 spec，Write 改為 `plans/` + `handoffs/` |
| `athena-stage-build` | build | 完整 Read / Edit / Write / MultiEdit / Bash / Grep / Glob（commit/push 仍禁） |
| `athena-stage-verify` | verify | Read / Grep / Glob / Bash(測試) / Write(`handoffs/`)；**禁 Edit** |
| `athena-stage-review` | review | Read / Grep / Glob / Bash(靜態分析) / Write(`handoffs/`)；**禁 Edit** |
| `athena-stage-ship` | ship | Read / Grep / Glob / Bash(`git push` / `gh`) / Write(`handoffs/`)；唯一可 push 的 stage |

Subagent description 標註「only via athena-flow」以避免 main agent 繞過 flow 直接觸發。

### Hooks（harness 強制行為）

| Hook 事件 | 檔案 | 行為 |
|----------|------|------|
| `PreToolUse` (Edit / Write / MultiEdit / NotebookEdit) | `hooks/require-point.sh` | 沒有 `points/*.md` 就 block 編輯——強制執行「先跑 /athena-point」 |
| `SubagentStop` | `hooks/auto-commit.sh` | 看 `.athena/.flow-context.json`；`mode: hook` 才接管 commit，否則由 flow-inline post-build skill 處理 |

詳細觸發範圍、自我保護路徑與 escape hatch 見下方「Hooks 機制」段。

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
claude plugin marketplace add https://github.com/Athena-Git-Group/athena-plugin-dev.git

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

## 輔導工具（獨立於 flow，團隊主動觸發）

Plugin 內建三個與 `/flow` 完全解耦的輔導工具，**都不寫機器 verdict、不阻擋任何流程**。每個工具的完整說明在獨立檔案：

| 工具 | 看什麼 | 觸發者 | 完整文件 |
|------|--------|--------|----------|
| `/athena-skill-audit` | SKILL.md 靜態結構（L1+L2） | RD | [docs/tools/skill-audit.md](docs/tools/skill-audit.md) |
| `/athena-skill-eval` | Skill 真實執行行為（L4） | RD | [docs/tools/skill-eval.md](docs/tools/skill-eval.md) |
| `/athena-audit-requirement-{backend,frontend}` | PM 需求單可譯性 | PM / TL | [docs/tools/audit-requirement.md](docs/tools/audit-requirement.md) |

三者全部走 ✅ / 🟡 / 💡 三段式建議格式，**不使用 PASS / FAIL**，避免被誤用為 CI gate。

> **與 `athena-point` 的劃線**：point 是 flow 閘門（決定要不要走 spec），輔導工具不影響 flow。其中 audit-requirement 與 point 的 Requirement Clarity 看似重疊，但 point 服務 RD 工程分流（低分 → 走 spec 重寫），audit-requirement 服務 PM 需求驗收（低分 → 退回 PM 補資訊，可重跑）。同一需求週期可同時用兩個工具。

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

## Hooks 機制

Plugin 透過兩條 harness hook 把流程契約落到 runtime 強制：一條檢查事前（point gate），一條接管事後（auto-commit）。兩者都列在 `hooks/hooks.json`。

### 1. Point Gate（強制，always-on）

安裝本 plugin 後，**任何程式碼變更都必須先跑 `/athena-point`**。
這條規則由 `PreToolUse` hook `hooks/require-point.sh` 執行：
找不到 `points/*.md` 時，hook 會 block `Edit` / `Write` / `MultiEdit` / `NotebookEdit` tool。

**觸發範圍**：只在 cwd 是 Athena 專案（有 `.athena/` 或 `points/`）時生效，不會干擾未啟用 Athena 流程的其他專案。

**自我保護路徑（永遠放行，避免使用者在 hook 出狀況時被鎖死）**：

- `hooks/**`（gate 機制本身）
- `.claude-plugin/**`（plugin manifest）
- `commands/**`（slash command 入口）
- `.claude/**`（harness settings）
- `.athena/**`（團隊設定、escape marker、knowledge、evals）
- `points/**`、`handoffs/**`（評分與交接 artifact）

> v1 known gap：`agents/**` 與 `scripts/**` 尚未列入自我保護清單。修改這兩處時若沒 point report 仍會被 block，請走 escape hatch 暫時繞過。下個 minor revision 會補上。

**Escape Hatch**：

```bash
# 方式 A：env var（單一 session）
export ATHENA_SKIP_POINT_GATE=1

# 方式 B：marker file（持久於專案）
mkdir -p .athena && touch .athena/skip-point-gate
```

濫用 escape hatch 等於放棄 point gate；建議只在已明確判斷不需要分流時使用。

### 2. Auto-Commit（選用，opt-in via marker）

`SubagentStop` hook `hooks/auto-commit.sh` 是 `athena-post-build` skill 的替代路徑——對於想要「subagent 結束 → 自動 commit」嚴格綁定的團隊，可以改走 hook 模式。**預設不啟用**：flow agent 沒寫 marker，hook 就 no-op，由 flow-inline post-build skill 處理。

啟用方式：flow agent 在 spawn standard stage subagent **之前**寫入 `.athena/.flow-context.json`：

```json
{
  "mode": "hook",
  "triggering_stage": "build-phase-05",
  "slug": "<slug>",
  "branch_name": "feature/...",
  "ticket": "",
  "phase_number": "05",
  "expires_at": "2026-05-13T15:00:00Z"
}
```

Hook 行為：

1. 讀 marker → `mode != "hook"` 或 marker 不存在 → no-op
2. `expires_at` 過期 → 清除 marker，no-op
3. 找對應 handoff（`handoffs/<slug>-build.md` 等）
4. handoff 的 `## Gate Verdict` 不是 PASS → no-op
5. PASS → `git add -A && git commit`（不 push、不 amend、不 rebase）
6. 刪掉 marker（避免重複觸發）

Marker schema 與 mode 選擇建議詳見 `skills/athena-flow/references/flow-context.md`。

> v1 限制：平行 phase 共用單一 marker，無法區分。Full Weight 平行 phase 想用 hook 模式時建議拆 per-phase marker；目前的 reference impl 預設仍用 inline post-build skill。

## 給 Contributor

修改 plugin 本體的開發者請看 [CONTRIBUTING.md](CONTRIBUTING.md)，內含：Claude 設定分層（baseline vs local）、runtime artifacts gitignore 規則、`scripts/lint-plugin.sh` 本地 lint、CI workflow、dogfood eval cases，以及提交流程的注意事項。

## 參考文件

> 以下路徑皆相對於 plugin 的 `skills/` 目錄。

| 文件 | 位置 | 說明 |
|------|------|------|
| Stage 編排 | `athena-flow/references/stage-orchestration.md` | Weight Class 路由與 stage 順序定義 |
| Stage 契約 | `athena-flow/references/stage-contracts.md` | 每個 stage 的輸入/輸出規格 |
| Phase 編排 | `athena-flow/references/phase-orchestration.md` | Full Weight 內的 phase loop、平行模式、conflict detection |
| Flow Context | `athena-flow/references/flow-context.md` | Auto-commit hook 的 `.athena/.flow-context.json` schema 與 mode 選擇建議 |
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
