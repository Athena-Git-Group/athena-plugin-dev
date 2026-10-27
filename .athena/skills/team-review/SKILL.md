---
name: team-review
description: >
  本 repo（athena-dev-plugin）的 review stage skill。以品質視角 review
  markdown skill 文件、bash hooks、python script：正確性、一致性、
  與 repo 慣例對齊、文件內部引用完整。✅/🟡/💡 三段式輸出；只有
  正確性/一致性/引用完整的問題才 request-changes，品質建議不擋流程。
stage: review
---

# Team Review（athena-dev-plugin）

你是 review 階段的執行者。**你沒有 Edit 權限——指出問題，不修問題**
（規範見 `rules/review-output.md`）。

# SOP

## Phase 1 -- 讀取輸入

1. READ 讀取 `.athena/skills/team-common/rules/agent-isolation.md`，確認 fresh agent 的
   輸入來源與「判定依據自己查證」要求。
2. READ 讀取 `handoffs/<slug>-build.md` 與 `handoffs/<slug>-verify.md`（若有）。
3. READ 讀取實際 diff：`git diff <base>...HEAD` 或 `git show`。

## Phase 2 -- 逐視角審查

1. READ 讀取 `rules/review-rubric.md`，取得本 repo 產物型態的 review 視角
   與各視角的擋流程分級。
2. THINK 逐視角對 diff 審查；引用完整這類可機械查證的視角，實際逐一查證
   （例如 `ls` 被引用的檔案），不憑印象判定。
3. THINK 依已載入規則把每個發現分到 ✅ 通過項 / 🟡 建議修 / 💡 可選優化，
   並判定是否構成 request-changes。

## Phase 3 -- 輸出與 handoff

1. READ 讀取 `rules/review-output.md`，確認三段式輸出格式與 FAIL 判準。
2. READ 判定為 request-changes（FAIL）時，讀取
   `.athena/skills/team-common/rules/fail-reporting.md`，確認 Gate Verdict 的 FAIL 格式。
3. READ 讀取 `skills/athena-flow/references/agent-handoff.md` 的變體差異表
   「Review」列（Lightweight 合併模式改讀「Review-ship」列）。
4. WRITE 依該變體格式寫 handoff：獨立 review stage（Full 路由）寫
   `handoffs/<slug>-review.md`，review 結果以三段式寫入 `## Review Result` 段；
   Lightweight 合併模式依 flow prompt 指定併入 `handoffs/<slug>-review-ship.md`
   的 Review Verdict 段——request-changes 時 Gate Verdict = FAIL 並**停止 ship**。
5. READ 回頭檢查 handoff 是否符合本次已載入規則；若不符合，立即修正。
