# Agent Handoff Contract

## Principle

agent 之間不共享上下文，靠檔案交接。

## Handoff Artifact

每個 stage 在 `handoffs/` 下留下對應的 artifact：

- `handoffs/<slug>-spec.md`
- `handoffs/<slug>-plan.md`
- `handoffs/<slug>-build.md`
- `handoffs/<slug>-verify.md`
- `handoffs/<slug>-review.md`
- `handoffs/<slug>-ship.md`

> **例外**：point stage 的輸出在 `points/<slug>.md`（由 plugin 內建的 athena-point 控制）。

## Minimum Contents

- Stage name
- Inputs used
- Artifacts produced
- Gate verdict
- Risks / unresolved issues
- Next recommended stage

## 非協商規則

1. **每個 stage 必須由全新的 agent 執行**——不得讓同一個 agent 處理多個 stage，避免 context window 過大與推理污染
2. 下一個 agent 先讀 handoff artifact，再開始工作
3. 不得從對話脈絡取得前一 stage 的資訊——一切靠 artifact 檔案
4. 每個 stage 結束時必須寫入完整的 handoff artifact，不可省略
