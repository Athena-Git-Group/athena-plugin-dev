# Git Lifecycle Hooks

## 概述

定義 athena-flow 在 stage 執行前後自動觸發的 Git 操作時機。
Git 操作以 **flow-inline stage** 的形式執行，由對應的 skill 提供操作程序：

- **pre-build** → `athena-pre-build` skill（plugin 預設，團隊可替換）
- **post-build** → `athena-post-build` skill（plugin 預設，團隊可替換）

命名規範由 `git-conventions` skill 提供。

## Hook 一覽

```
                    ┌─────────────────────────────────┐
                    │           athena-flow            │
                    └─────────────────────────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
               ◆ point        ◆ spec/plan     ◆ build
                    │              │              │
                    │              │     ┌────────┴────────┐
                    │              │     │  [pre-build]    │
                    │              │     │ athena-pre-build │
                    │              │     └────────┬────────┘
                    │              │              │
                    │              │         build agent
                    │              │              │
                    │              │     ┌────────┴────────┐
                    │              │     │  [post-build]   │
                    │              │     │ trigger: build   │
                    │              │     └────────┬────────┘
                    │              │              │
                    │              │         ◆ verify
                    │              │              │
                    │              │     ┌────────┴────────┐
                    │              │     │  [post-build]   │
                    │              │     │ trigger: verify  │
                    │              │     └────────┬────────┘
                    │              │              │
                    │              │      ◆ review → ◆ ship
                    └──────────────┴──────────────┘
```

> `[括號]` 表示 flow-inline stage。

## Hook 定義

### pre-build（athena-pre-build skill）

| 項目 | 說明 |
|------|------|
| **時機** | build stage agent 啟動**之前** |
| **Skill** | `athena-pre-build`（plugin 預設）或團隊在 `.athena/skills/` 中的 `stage: pre-build` skill |
| **操作** | 建立 Git 分支並切換 |
| **輸入** | point-report 中的 slug、verdict、任務性質 |
| **輸出** | flow context 的 `git_context`（branch_name、base_branch、ticket） |
| **失敗處理** | 若分支已存在，切換到該分支而非重建；若有未提交變更，先 stash |

### post-build（athena-post-build skill）

此 skill 在兩個時間點被呼叫，透過 `triggering_stage` 參數區分：

#### 觸發點 1：build gate PASS 後

| 項目 | 說明 |
|------|------|
| **時機** | build stage agent 完成且 gate = PASS **之後** |
| **Skill** | `athena-post-build`（plugin 預設）或團隊的 `stage: post-build` skill |
| **操作** | 自動 commit build 產出的變更 |
| **輸入** | flow context 的 `git_context` + build handoff artifact + `triggering_stage: build` |
| **輸出** | flow context 的 `git_context.commits` 追加新 commit |
| **失敗處理** | 若無變更可 commit，記錄 `no_changes` 並繼續 |

#### 觸發點 2：verify gate PASS 後

| 項目 | 說明 |
|------|------|
| **時機** | verify stage agent 完成且 gate = PASS **之後** |
| **Skill** | 同上（同一個 post-build skill） |
| **操作** | 自動 commit verify 產出的測試相關變更 |
| **輸入** | flow context 的 `git_context` + verify handoff artifact + `triggering_stage: verify` |
| **輸出** | flow context 的 `git_context.commits` 追加新 commit |
| **失敗處理** | 若無新變更（verify 沒改程式碼），跳過並繼續 |

## Flow Context 傳遞

Git lifecycle hooks 產生的資訊存入 **flow context**（flow orchestrator 的內部狀態），供後續 hooks 與 stages 使用：

```yaml
git_context:
  branch_created: true
  branch_name: "feature/main_hap3621_member_export"
  base_branch: "main"
  ticket: "3621"
  commits:
    - hash: "abc1234"
      stage: "build"
      message: "[HAP-3621] feat(member): add member export API"
      files_committed: 12
    - hash: "def5678"
      stage: "verify"
      message: "[HAP-3621] test(member): add member export unit tests"
      files_committed: 3
```

此 context 可傳遞給 review / ship stage 的 handoff artifact，讓下游 skill 知道有哪些 commits。

## 執行規則

1. **Flow-inline 執行** — 在 flow agent 中內聯執行，不開新 agent
2. **Plugin 預設 + 團隊可替換** — 團隊可在 `.athena/skills/` 上繳替代 skill
3. **只在 gate PASS 後才 commit** — FAIL 不觸發任何 git 操作
4. **Hook 失敗不阻斷流程** — git 操作失敗時記錄警告，但 stage 流程繼續（除非使用者設定為 strict mode）
5. **不 push** — 所有操作僅限 local，push 由 ship stage 決定
6. **冪等** — 分支已存在就切換，commit 無變更就跳過
