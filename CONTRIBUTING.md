# Contributing — Plugin 自身工程

本檔給想要修改 athena-dev-plugin 本體的開發者。一般使用者請看 [README](README.md)。

## Claude 設定分層

Plugin repo 的 `.claude/` 下有兩份 settings，職責分開：

| 檔案 | 是否 commit | 內容 |
|------|-----------|------|
| `.claude/settings.json` | ✅ tracked，共享 baseline | 具體 git verb allowlist（status/diff/log/add/commit/checkout/branch/fetch/push/…）+ deny destructive ops（`push --force`、`reset --hard`、`config`、`filter-branch` 等） |
| `.claude/settings.local.json` | ❌ gitignored | 個別 contributor 的 Read 白名單與個人偏好；harness 自動往這裡加新規則時不會污染共享 baseline |

避免把 `Bash(git *)` 這類過寬規則放進 baseline——deny list 才是收斂危險動作的正路。

## Runtime artifacts 不進 git

Plugin 自己會 dogfood `/athena-flow`，所以 `points/`、`handoffs/`、`requirement-feedback/`、`plans/` 在 disk 上會出現，但全部在 `.gitignore` 內、**不應該 commit**。若有特定 report 想當示範，搬到 `examples/` 並明確標註。

> 例外：require-point.sh hook 仍然會看磁碟上的 `points/*.md` 來決定要不要放行；untrack 不影響 hook 偵測。

## 本地 lint

```bash
bash scripts/lint-plugin.sh
```

檢查項目：

- JSON manifest 合法（`plugin.json` / `marketplace.json` / `hooks/hooks.json` / `.claude/settings.json`）
- `plugin.json` 宣告的 `skills` / `commands` / `agents` / `hooks` 路徑都實際存在
- 所有 `SKILL.md` / `commands/*.md` / `agents/*.md` 帶合法 frontmatter
- SKILL.md `name` 欄位與資料夾同名
- `stage` 值在允許清單內
- `hooks/*.sh` 與 `scripts/*.sh` 通過 `bash -n` 與 executable bit

完全靜態，不打 Anthropic API，不 spawn subagent。

## CI

`.github/workflows/lint.yml` 在每個 PR 跑上面的 lint。Semantic / L4 eval **不在 CI 跑**——需要 spawn subagent + API key，目前留給手動或 nightly。

## Eval cases（dogfood）

`.athena/evals/` 是 plugin 自己的 eval case 目錄，**不會**被 plugin 安裝程序拷貝到 consumer 專案——consumer 自己的 `.athena/evals/` 是另一份。目前提供一個 reference case：

```
.athena/evals/point-cases/example-trivial.md
```

包含 4 條 `[mechanical]` 條件 + 1 條 `[semantic]` 條件（mechanical 條件適合放進未來的 CI eval runner；semantic 條件保留給手動執行）。

執行（手動）：

```bash
/athena-dev-plugin:athena-skill-eval athena-point example-trivial
```

## 提交流程

修改 plugin 本體時請遵守 [README 的「Hooks 機制」](README.md#hooks-機制) 提到的 point gate：
任何 `Edit` / `Write` / `MultiEdit` / `NotebookEdit` 前都要先有 `points/<slug>.md`。
docs-only 改動（純 README / 註解 / 設定格式）可走 CLAUDE.md 例外條款 #2，
但建議仍寫一份 Trivial point report 留下審計軌跡。

Commit message 遵循 [`skills/git-conventions/SKILL.md`](skills/git-conventions/SKILL.md) 規範。

---

← 回 [README](README.md)
