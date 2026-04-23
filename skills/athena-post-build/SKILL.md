---
name: athena-post-build
description: >
  Build/Verify 通過後自動提交 Git commit。從分支名稱推斷 ticket，
  根據 triggering_stage 決定 commit type，遵循 git-conventions 格式。
  Plugin 提供預設實作，團隊可在 .athena/skills/ 中替換。
  Flow-inline 執行（不開 fresh agent）。
stage: post-build
user-invocable: false
---

# Athena Post-Build

你在 flow agent 中被內聯執行。你的職責是在 stage gate 通過後自動提交 Git commit。

你會在以下時間點被呼叫：
1. **Lightweight build gate 通過後** — `triggering_stage: build-lightweight`
2. **每個 build phase gate 通過後（Full Weight）** — `triggering_stage: build-phase-<NN>`
3. **verify stage 通過後** — `triggering_stage: verify`
4. **verify fix 完成後（Lightweight）** — `triggering_stage: verify-fix-lightweight`
5. **verify fix 完成後（Full Weight）** — `triggering_stage: verify-fix-phase-<NN>`

## 先讀哪些檔

- Read `../git-conventions/SKILL.md` 取得 commit message 規範
- Read `../git-conventions/references/output-language.md` 取得語言偏好
- 讀取對應的 handoff artifact：
  - `triggering_stage: build-lightweight` → `handoffs/<slug>-build.md`（Compact build handoff）
  - `triggering_stage: build-phase-<NN>` → `handoffs/<slug>-build-phase-<NN>.md`（mini-handoff）
  - `triggering_stage: verify` → `handoffs/<slug>-verify.md`
  - `triggering_stage: verify-fix-lightweight` → `handoffs/<slug>-build.md`（更新的 Compact build handoff）
  - `triggering_stage: verify-fix-phase-<NN>` → `handoffs/<slug>-build-phase-<NN>.md`（更新的 mini-handoff）

## 輸入

| 來源 | 欄位 | 說明 |
|------|------|------|
| flow context | `branch_name` | pre-build 建立的分支名稱 |
| flow context | `ticket` | 從分支名稱推斷的 HAP ticket |
| flow 傳入 | `triggering_stage` | 觸發來源（見下方觸發表），決定 commit type |
| flow 傳入 | `phase_number` | Phase 編號（僅 build-phase 觸發時） |
| flow 傳入 | `phase_name` | Phase 名稱（僅 build-phase 觸發時） |
| handoff artifact | `gate_verdict` | 必須是 PASS |
| handoff artifact | `files_changed` | 變更的檔案清單 |

## Commit Type 決定

根據 `triggering_stage` 與變更性質推斷：

| triggering_stage | 預設 Commit Type | 說明 |
|------------------|-------------------|------|
| `build-lightweight` | `feat` / `fix` | Lightweight 模式，整個 build 一次 commit |
| `build-phase-<NN>` | `feat` / `fix` | Full 模式，視 point-report 的任務性質 |
| `verify` | `test` | 測試相關變更 |
| `verify-fix-lightweight` | `fix` | Lightweight verify 修復 |
| `verify-fix-phase-<NN>` | `fix` | Full verify 修復 |

### Build Phase 的 Type 細分

| 條件 | Commit Type |
|------|-------------|
| 新功能（預設） | `feat` |
| point-report 含 bug / fix 語意 | `fix` |
| 重構性質 | `refactor` |
| 文件變更 | `docs` |
| 雜項 | `chore` |

## 執行步驟

```
1. 前提檢查
   - 確認 gate_verdict = PASS（否則跳過）
   - 確認有未提交的變更：git status --porcelain
   → 若為空，回報 no_changes 並結束

2. 從 flow context 取得 ticket
   TICKET="${git_context.ticket}"
   → 若為空，commit message 不加 [HAP-XXXX] prefix

3. 決定 commit type
   根據 triggering_stage + 變更性質推斷

4. 決定 scope
   根據變更的檔案路徑推斷主要模組
   例如：src/member/** → scope = member

5. 讀取語言偏好
   從 git-conventions/references/output-language.md 取得
   description 部分可依偏好使用對應語言

6. 組合 commit message（遵循 git-conventions）
   若有 ticket:  [HAP-${TICKET}] <type>(<scope>): <description> (<phase-tag>)
   若無 ticket:  <type>(<scope>): <description> (<phase-tag>)

   phase-tag 格式：
   - build-lightweight: 無 phase-tag（整個 build 一次 commit）
   - build phase: (phase-05)
   - verify-fix-lightweight: (verify-fix)
   - verify fix:  (verify-fix-phase-06)
   - verify:      (verify)

   Lightweight 範例（無 phase-tag）：
   [HAP-3621] feat(member): add member export API

7. Stage & Commit
   git add <relevant-files>
   git commit -m "<formatted-message>"

8. 將結果追加到 flow context
```

## 輸出

追加到 flow context 的 `git_context.commits` 陣列（不產出 handoff artifact）：

```yaml
git_context:
  commits:
    - hash: "abc1234"
      stage: "build-phase-05"
      message: "[HAP-3621] feat(approval): add approval API and schema (phase-05)"
      files_committed: 5
    - hash: "bcd2345"
      stage: "build-phase-06"
      message: "[HAP-3621] feat(approval): add approval frontend page (phase-06)"
      files_committed: 4
    - hash: "cde3456"
      stage: "build-phase-07"
      message: "[HAP-3621] test(approval): integration validation (phase-07)"
      files_committed: 3
    - hash: "def4567"
      stage: "verify"
      message: "[HAP-3621] test(approval): add unit tests (verify)"
      files_committed: 2
```

## 失敗處理

| 狀況 | 處理方式 |
|------|----------|
| gate_verdict != PASS | 跳過，不觸發 commit |
| 無未提交的變更 | 回報 `no_changes`，繼續流程 |
| commit 失敗 | 記錄警告，繼續流程（不阻斷） |
| 無法推斷 scope | 使用空 scope：`<type>: <description>` |

## 非協商規則

1. **Gate 沒過不 commit** — 只有 PASS 才觸發
2. **沒有變更不硬 commit** — `git status` 為空就跳過
3. **Commit message 必須遵循 git-conventions** — 不得自行發明格式
4. **不 push** — 只做 local commit，push 留給 ship stage
5. **不改歷史** — 不做 rebase、amend、force push
6. **Ticket 從 flow context 取得** — 不另外詢問使用者
7. **一個 triggering_stage 一個 commit** — 不合併多個 phase 的變更，每個 phase 獨立 commit（Full Weight）
8. **Lightweight 模式整個 build 一次 commit** — `triggering_stage: build-lightweight` 時，commit message 不帶 phase-tag
