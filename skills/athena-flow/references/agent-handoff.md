# Agent Handoff Contract

## Principle

agent 之間不共享上下文，靠檔案交接。

## Handoff Artifact

建議每個 stage 在 `handoffs/` 下留下：

- `handoffs/<request-slug>-point.md`
- `handoffs/<request-slug>-spec.md`
- `handoffs/<request-slug>-plan.md`
- `handoffs/<request-slug>-build.md`
- `handoffs/<request-slug>-verify.md`
- `handoffs/<request-slug>-review.md`
- `handoffs/<request-slug>-ship.md`

## Minimum Contents

- Stage name
- Inputs used
- Artifacts produced
- Gate verdict
- Risks / unresolved issues
- Next recommended stage

## Rule

下一個 agent 先讀 handoff artifact，再開始工作。
