---
eval-case-version: 1
target-stage: point
description: |
  Reference eval case for athena-point. Sanity-checks that a clearly
  trivial request gets routed to PASS-TRIVIAL with total score ≤ 4
  and the point-report file lands at the expected path.
expected_max_steps: 10
---

# Case：athena-point — example-trivial

Reference dogfood case for the point skill. Intentionally mechanical-heavy
so it can run cheaply without burning API budget on semantic grading.

## Setup

本 case 無需預先建立 mock 檔案；point skill 的唯一輸入是下方 `## Task` 段的
需求文字，不依賴 repo 中已存在的 mock 檔。

## Task

對以下需求執行 athena-point 評分流程：「把 README 第一行的 typo
"athena-dev-pluign" 改成 "athena-dev-plugin"。」

## Expected

- [mechanical] 執行後，`points/*.md` 下恰好新增一個檔案，其路徑含有由需求
  推導出的 slug（例如包含 "typo" 或 "readme"）
- [mechanical] 寫出的 point-report 含一行符合
  `^- Gate verdict: .*PASS-TRIVIAL`（允許反引號包裹的 `` `PASS-TRIVIAL` `` 形式）
- [mechanical] 寫出的 point-report 含一行 Total，數值 ≤ 4，符合
  pattern `^- Total: [0-4]/30`
- [mechanical] 寫出的 point-report 含 `Knowledge base needed: no`（typo fix
  不需要知識依賴）
- [semantic] judge sub-agent 讀 Why / Risks 段後，確認推理過程與「這是一個
  單純 typo fix」的定性一致（optional，deferred：CI 跳過，僅手動執行時評分）

## Anti-patterns

- [mechanical] point 不得在 `points/` 以外建立或修改任何檔案（point 的職責
  就是只寫 `points/<slug>.md`；若它動了 src/ 或其他檔，是 Expected 段
  完全沒檢查的獨立退化訊號）

## Notes

- Run via `/athena-dev-plugin:athena-skill-eval athena-point example-trivial`.
- CI runs static lint only (see `.github/workflows/lint.yml`); the
  `[semantic]` criterion above is for local / nightly use.
