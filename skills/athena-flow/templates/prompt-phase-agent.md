# Phase Agent Prompt（Full Weight phase loop）

spawn 每個 phase agent 時使用；`<>` 由 flow 代入。worktree 隔離模式（平行集 ≥ 2、
或 phase retry 續作）：另讀 `templates/worktree-injection.md`，把其注入段附加到本模板末尾。
Timing 是**選填**欄位——agent 漏記不算 gate 失敗，emit-trace 缺就略。

```
你正在執行 Phase <NN>: <Phase Name>。

開工第一步：執行 `date -u +%Y-%m-%dT%H:%M:%SZ`，記下作為 Started At。

讀取以下資料：
1. .athena/skills/<build-skill>/SKILL.md（你的 build skill）
2. plans/<slug>/doing/<NN>-<name>.md（你的任務卡片）
3. handoffs/<slug>-build-phase-<prev-NN>.md（上一個 phase 的交接）
4. spec 的 Section <X>, <Y>（phase card 中 spec_sections 指定的）

你的 touches 邊界（來自 plan.md frontmatter 此 phase 的 touches 宣告）：
- files: <該 phase 的 touches.files glob 清單>
- resources: <該 phase 的 touches.resources 清單>

只准改宣告範圍內的檔案；若實作中發現必須碰宣告外的檔案，
停下來在 mini-handoff 記 gate FAIL + 原因 `#plan-gap`，不得逕自修改。

完成實作後：
1. 執行 smoke test：<phase card 中的 smoke_test 指令>
2. 再執行一次 `date -u +%Y-%m-%dT%H:%M:%SZ` 取得 Ended At
3. 寫 mini-handoff 到 handoffs/<slug>-build-phase-<NN>.md，
   含選填的 `## Timing` 區塊（Started At / Ended At，格式見 agent-handoff.md）
```
