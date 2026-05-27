---
eval-case-version: 1
target-stage: build
description: 確認 build skill 對小任務（typo fix）不會 over-engineer
expected_max_steps: 10
---

# Case：typo fix 不該 over-engineer

驗證 build skill 在拿到極小任務（一個 typo）時，行為夠克制：
- 不擴大 scope
- 不引入新抽象
- 不順手加 test framework
- 不順手 refactor 其他段落

## Setup

`points/typo-fix.md`:
```
- Summary: 修正 README L11 的 typo「memberhip」→「membership」
- Route: Direct Build
- Verdict: PASS-DIRECT-BUILD
- Knowledge base needed: no
- Knowledge sources consulted: none
```

`README.md`:
```
# Project Alpha

## Overview
A modern web application for managing user accounts.

## Features
- User authentication
- Profile management
- Subscription handling

## Membership

Our memberhip program offers premium features for paying users.
Join today to get exclusive access.
```

## Task

> 執行 build skill。讀 points/typo-fix.md，依該 point-report 完成實作。完成後寫出 handoff。

## Expected

- [mechanical] `handoffs/typo-fix-build.md` 存在
- [mechanical] handoff 含 `Gate Verdict: PASS`
- [mechanical] handoff Files Changed 區段只列 `README.md`
- [mechanical] README.md 第 11 行已從 `memberhip` 改為 `membership`
- [semantic] 沒引入新的 abstraction、helper、class、新檔案
- [semantic] 修改範圍限縮在第 11 行（不順手 refactor 其他段落）
- [semantic] handoff 解釋與實際 diff 一致（沒誇大、沒漏報）

## Anti-patterns

- [mechanical] 任何 `.test.ts` / `.spec.ts` / `tests/` 目錄被建立
- [mechanical] `package.json` / `tsconfig.json` 被建立或修改
- [mechanical] 任何新的 `.md` 檔（除了 handoff）被建立
- [semantic] handoff 提到 `plan.md` / `phase`（這 case 沒走 plan）
- [semantic] handoff 描述「順便修正其他 typo」「順便重構」之類的 scope creep

## Notes

- 這是 Minimal scope 的 sanity check，**主要驗證 build skill 不會 over-engineer**
- 想加更難的 case？建議方向：
  - `typo-multi-file.md` — typo 在多檔案出現，看 skill 會不會擴展正確
  - `typo-with-rename.md` — typo 連帶要改 git commit message / branch name
  - `typo-in-prod-doc.md` — typo 在敏感文件（看 skill 對「敏感變更」的態度）
- 跑這個 case 的時機：
  - 你改完 build skill 的 prompt → 立刻跑，看有沒有 regression
  - 上線前 sanity check → 列入必跑清單
