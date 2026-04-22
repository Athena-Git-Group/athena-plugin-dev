---
name: athena-pre-build
description: >
  Build 前自動建立 Git 分支。從 point-report 推斷 branch type 與名稱，
  遵循 git-conventions 命名規範。Plugin 提供預設實作，團隊可在 .athena/skills/ 中替換。
  Flow-inline 執行（不開 fresh agent）。
stage: pre-build
user-invocable: false
---

# Athena Pre-Build

你在 flow agent 中被內聯執行。你的職責是在 build stage 開始前建立 Git 分支。

## 先讀哪些檔

- Read `../git-conventions/SKILL.md` 取得分支命名規範
- Read `../git-conventions/references/output-language.md` 取得語言偏好
- 讀取 `points/<slug>.md`（point-report）取得 slug、verdict、任務性質

## 輸入

| 來源 | 欄位 | 說明 |
|------|------|------|
| point-report | `slug` | 需求的 slug，用於分支描述 |
| point-report | `verdict` | 路由結果，用於判斷 branch type |
| flow context | `base_branch` | 當前主分支（main / develop / master） |
| 使用者（可選） | `ticket` | HAP ticket 號碼 |

## 判斷 Branch Type

根據 point-report 的 verdict 與任務性質推斷：

| 條件 | Branch Type |
|------|-------------|
| 新功能（預設） | `feature/` |
| point-report 含 bug / fix 語意 | `bugfix/` |
| point-report 含 urgent / critical 語意 | `hotfix/` |
| point-report 含 refactor 語意 | `refactor/` |
| 雜項（docs、CI/CD、config） | `chore/` |

## 執行步驟

```
1. 偵測 base branch
   BASE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
   → 通常是 main、develop 或 master

2. 同步遠端
   git fetch origin ${BASE_BRANCH}

3. 組合分支名稱（遵循 git-conventions）
   若有 ticket:  <type>/<base>_hap<ticket>_<slug>
   若無 ticket:  <type>/<base>_<slug>

4. 檢查分支是否已存在
   若已存在 → git checkout <branch-name>（切換，不重建）
   若有未提交變更 → git stash → checkout → git stash pop

5. 建立並切換分支（分支不存在時）
   git checkout -b <branch-name> origin/${BASE_BRANCH}

6. 將結果寫入 flow context
```

## 輸出

回傳給 flow context（不產出 handoff artifact）：

```yaml
git_context:
  branch_created: true          # false 若切換到已存在的分支
  branch_name: "feature/main_hap3621_member_export"
  base_branch: "main"
  ticket: "3621"                # 空字串若無 ticket
```

## 失敗處理

| 狀況 | 處理方式 |
|------|----------|
| 分支已存在 | 切換到該分支，`branch_created: false` |
| 有未提交變更 | 先 `git stash`，切換後 `git stash pop` |
| 遠端不可達 | 記錄警告，從 local base branch 切出 |
| 分支名稱組合失敗 | 停止並回報錯誤，不進入 build |

## 非協商規則

1. **分支命名必須遵循 git-conventions** — 不得自行發明格式
2. **冪等** — 分支已存在就切換，不重建
3. **不 push** — 只做 local 操作
4. **不改歷史** — 不做 rebase、amend、force push
5. **必須產出 flow context** — 後續 post-build 依賴 branch_name
