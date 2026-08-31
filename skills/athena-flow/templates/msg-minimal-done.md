# Minimal 結束輸出

Minimal build gate PASS + post-build commit 完成後，flow **不開任何 review/ship agent**、
不問 merge_target、不寫 review-ship handoff，直接逐字輸出下列訊息（代入實際值；
commit hash 此時已存在，如實引用）。**輸出本訊息之後**才執行 run 收尾
（emit trace + Handoff GC，見 `references/run-trace.md`）。

```
✅ Done — build + self-review passed.

Committed: <commit_hash> on <branch_name>

When ready to push:
  git push -u origin <branch_name>
```
