# Git Lifecycle Hooks

## 概述

定義 athena-flow 在 stage 執行前後自動觸發的 Git 操作時機。
Git 操作以 **flow-inline stage** 的形式執行，由對應的 skill 提供操作程序：

- **pre-build** → `athena-pre-build` skill（plugin 預設，團隊可替換）
- **post-build** → `athena-post-build` skill（plugin 預設，團隊可替換）

命名規範由 `git-conventions` skill 提供。

## Hook 一覽

### Minimal Flow

```
    ┌───────────────────────────────────────┐
    │              athena-flow               │
    └───────────────────────────────────────┘
                      │
                 ◆ point
                      │
            ┌─────────┴─────────┐
            │   [pre-build]     │
            └─────────┬─────────┘
                      │
                ◆ build (minimal, with self-review)
                      │
            ┌─────────┴─────────┐
            │   [post-build]    │
            │  trigger:         │
            │  build-minimal    │
            └─────────┬─────────┘
                      │
                    done
            (flow prints push cmd)
```

### Lightweight Flow

```
    ┌───────────────────────────────────────┐
    │              athena-flow               │
    └───────────────────────────────────────┘
                      │
                 ◆ point
                      │
            ┌─────────┴─────────┐
            │   [pre-build]     │
            └─────────┬─────────┘
                      │
                ◆ build (single agent)
                      │
            ┌─────────┴─────────┐
            │   [post-build]    │
            │  trigger:         │
            │  build-lightweight│
            └─────────┬─────────┘
                      │
              [◆ verify]  ← 僅 PASS-BUILD-WITH-VERIFY
                      │
            [post-build: verify]
                      │
              ◆ review-ship
```

### Full Flow

```
    ┌───────────────────────────────────────┐
    │              athena-flow               │
    └───────────────────────────────────────┘
                      │
        ◆ point → ◆ spec → ◆ plan
                      │
            ┌─────────┴─────────┐
            │   [pre-build]     │
            └─────────┬─────────┘
                      │
            ┌─────────┴─────────┐
            │   Phase Loop      │
            │                   │
            │  phase-05 agent   │
            │       ↓           │
            │  [post-build]     │
            │  trigger:phase-05 │
            │       ↓           │
            │  phase-06 agent   │
            │       ↓           │
            │  [post-build]     │
            │  trigger:phase-06 │
            │       ↓           │
            │  phase-07 agent   │
            │       ↓           │
            │  [post-build]     │
            │  trigger:phase-07 │
            └─────────┬─────────┘
                      │
                 ◆ verify
                      │
            ┌─────────┴─────────┐
            │   [post-build]    │
            │  trigger: verify  │
            └─────────┬─────────┘
                      │
             ◆ review → ◆ ship
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

此 skill 在多個時間點被呼叫，透過 `triggering_stage` 參數區分：

#### 觸發點 M：Minimal build gate PASS 後

| 項目 | 說明 |
|------|------|
| **時機** | Minimal build agent 完成且 handoff Gate Verdict = PASS **之後** |
| **Skill** | `athena-post-build`（plugin 預設）或團隊的 `stage: post-build` skill |
| **操作** | 自動 commit 整個 build 的變更（單次 commit，無 phase-tag） |
| **輸入** | flow context 的 `git_context` + `handoffs/<slug>-build.md` + `triggering_stage: build-minimal` |
| **輸出** | flow context 的 `git_context.commits` 追加新 commit |
| **適用路由** | `PASS-TRIVIAL` |
| **後續** | Flow 直接結束，不進 review-ship |

#### 觸發點 0：Lightweight build gate PASS 後

| 項目 | 說明 |
|------|------|
| **時機** | Lightweight build agent 完成且 handoff Gate Verdict = PASS **之後** |
| **Skill** | `athena-post-build`（plugin 預設）或團隊的 `stage: post-build` skill |
| **操作** | 自動 commit 整個 build 的變更（單次 commit，無 phase-tag） |
| **輸入** | flow context 的 `git_context` + `handoffs/<slug>-build.md` + `triggering_stage: build-lightweight` |
| **輸出** | flow context 的 `git_context.commits` 追加新 commit |
| **適用路由** | `PASS-DIRECT-BUILD`、`PASS-BUILD-WITH-VERIFY` |

#### 觸發點 1：每個 build phase gate PASS 後（Full Weight only）

| 項目 | 說明 |
|------|------|
| **時機** | 每個 phase agent 完成且 mini-handoff Gate Verdict = PASS **之後** |
| **Skill** | `athena-post-build`（plugin 預設）或團隊的 `stage: post-build` skill |
| **操作** | 自動 commit 該 phase 產出的變更 |
| **輸入** | flow context 的 `git_context` + mini-handoff + `triggering_stage: build-phase-<NN>` + `phase_number` + `phase_name` |
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

#### 觸發點 3：verify fix 完成後（Full Weight）

| 項目 | 說明 |
|------|------|
| **時機** | Full Weight verify fail 的 targeted re-build agent 完成且 gate = PASS **之後** |
| **Skill** | 同上 |
| **操作** | 自動 commit 修復的變更 |
| **輸入** | flow context 的 `git_context` + 更新的 mini-handoff + `triggering_stage: verify-fix-phase-<NN>` |
| **輸出** | flow context 的 `git_context.commits` 追加新 commit |
| **失敗處理** | 同上 |

#### 觸發點 4：verify fix 完成後（Lightweight）

| 項目 | 說明 |
|------|------|
| **時機** | Lightweight verify fail 的 repair build agent 完成且 gate = PASS **之後** |
| **Skill** | 同上 |
| **操作** | 自動 commit 修復的變更 |
| **輸入** | flow context 的 `git_context` + 更新的 build handoff + `triggering_stage: verify-fix-lightweight` |
| **輸出** | flow context 的 `git_context.commits` 追加新 commit |
| **適用路由** | `PASS-BUILD-WITH-VERIFY` |
| **失敗處理** | 同上 |

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
      stage: "build-phase-05"
      message: "[HAP-3621] feat(member): add member export API (phase-05)"
      files_committed: 5
    - hash: "bcd2345"
      stage: "build-phase-06"
      message: "[HAP-3621] feat(member): add member export page (phase-06)"
      files_committed: 4
    - hash: "cde3456"
      stage: "build-phase-07"
      message: "[HAP-3621] test(member): integration validation (phase-07)"
      files_committed: 3
    - hash: "def4567"
      stage: "verify"
      message: "[HAP-3621] test(member): add unit tests (verify)"
      files_committed: 2
```

此 context 可傳遞給 review / ship stage 的 handoff artifact，讓下游 skill 知道有哪些 commits。

## 執行規則

1. **Flow-inline 執行** — 在 flow agent 中內聯執行，不開新 agent
2. **Plugin 預設 + 團隊可替換** — 團隊可在 `.athena/skills/` 上繳替代 skill
3. **只在 gate PASS 後才 commit** — FAIL 不觸發任何 git 操作
4. **Hook 失敗不阻斷流程** — git 操作失敗時記錄警告，但 stage 流程繼續（除非使用者設定為 strict mode）
5. **只有 Ship 可以 push** — pre-build 和 post-build 僅做 local 操作，push 和 merge 到目標環境由 ship stage 執行
6. **冪等** — 分支已存在就切換，commit 無變更就跳過
7. **Per-phase commit（Full Weight）** — 每個 build phase 獨立 commit，不合併多個 phase 的變更
8. **Single commit（Lightweight）** — 整個 build 一次 commit，`triggering_stage: build-lightweight`，commit message 不帶 phase-tag
9. **Single commit（Minimal）** — 整個 build 一次 commit，`triggering_stage: build-minimal`，commit 後 flow 直接結束（不進 review-ship）
10. **Minimal 路由無 push** — commit 完成後 flow 輸出 push 指令提示，由使用者自行 push
