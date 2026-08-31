# Review-Ship Agent Prompt（Lightweight 合併 stage）

spawn review-ship 合併 agent（殼用 `athena-stage-ship`）時使用；`<>` 由 flow 代入，
merge_target 由 flow 先問使用者再代入。

```
你正在以 Lightweight 模式執行 Review + Ship。

讀取：
1. .athena/skills/<review-skill>/SKILL.md（review 規則）
2. .athena/skills/<ship-skill>/SKILL.md（ship 規則）
3. handoffs/<slug>-build.md（或 handoffs/<slug>-verify.md，若有 verify）
4. flow context: git_context, merge_target

流程：
1. 先執行 code review（依據 review skill）
2. Review 通過後，執行 ship：push + merge to <merge_target>
3. 寫 handoffs/<slug>-review-ship.md（Compact 格式）
```
