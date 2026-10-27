# Worktree 注入段（spawn 時附加到 agent prompt 末尾）

只要 agent 被送進 worktree（首次或續作 spawn），flow 就把下列段落逐字附加到
Agent Prompt（`templates/prompt-phase-agent.md`）末尾；`<>` 由 flow 代入。
適用判準（D-0）、健檢處置與收尾協議見 `references/worktree-isolation.md`。

```
主樹絕對路徑：<main-repo-root>
Main Tree Branch: <flow 自己的 branch_name>
Expected Branch: <僅在 flow 自己指定分支名時注入：手動 worktree 協議用 -b 新建的分支名，
                 或 phase retry 續作掛回的既有分支名。原生 worktree 模式下分支名由 harness
                 決定、flow 不知道，此行省略>

開工第二步（Pre-Flight 三項健檢，在 Edit 任何程式碼之前先做完並自報實測值）：
1. 跑 `git branch --show-current`：輸出必須**非空**，且 ≠ 上面的 Main Tree Branch；
   上面有 Expected Branch 時，必須**等於**它。空輸出（detached HEAD）算不通過
2. 跑 `pwd`：輸出必須 ≠ 上面的主樹絕對路徑（確認你不在主樹）
3. Read 兩類路徑各一項：(a) 主樹 artifact——`<main-repo-root>/plans/<slug>/doing/<NN>-<name>.md`
   （上列任務卡片，加主樹絕對路徑前綴，見下方雙路徑規則）可讀；(b) worktree code——
   上列 touches.files 中已存在於基線的任一檔案（你 cwd 的相對路徑）可讀。
   本 phase 全為新建檔案時，此項記 `n/a (all-new)` 即算通過

三項都通過 → 在 mini-handoff 加一行（選填自報，不列入 gate 判定），然後照上面開工：
Pre-Flight: OK (branch=<實測>, cwd=<實測>, targets=<ok|n/a (all-new)>)

任一項不通過 → **立即停止**：不 Edit、不 Write、不 commit、**不寫 mini-handoff**，
以 final response 回下列固定格式（多項不符每項一行）後結束：
PRE-FLIGHT MISMATCH — <branch|cwd|target-file>: expected <X>, actual <Y>
不要自己修復（不要 `git checkout`、不要換目錄）——修復是 flow 的決策，你只回報。

你在獨立的 git worktree 中工作，雙路徑規則：
- code 讀寫 → 用你 cwd（worktree）的相對路徑
- artifact 讀寫 → 上列任務卡片、handoff、spec、mini-handoff 一律改用
  <main-repo-root>/ 前綴的主樹絕對路徑
收尾時無論 gate 結果都 commit 到你的 worktree 分支
（PASS 用 git-conventions 正常格式；FAIL 用 `wip:` 前綴），
並在 mini-handoff（寫到 <main-repo-root>/handoffs/…）回報
`Worktree Branch:`（值 = `git branch --show-current` 實測）。
```
