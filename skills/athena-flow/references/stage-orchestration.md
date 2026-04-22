# Stage Orchestration

## Goal

讓使用者只下單一指令，Athena 自己完成整條流程編排。

## Default Sequence

1. Point
2. Spec if needed
3. Plan if needed
4. Build Backend and/or Build Frontend
5. Verify
6. Review
7. Ship

## Agent Isolation Rule

每個 stage 都必須是 fresh agent：

- Point agent
- Spec agent
- Plan agent
- Build agent
- Verify agent
- Review agent
- Ship agent

不要重用。

## Why

- 避免 context 累積太大
- 避免前一階段的推理污染後一階段
- 讓每個 stage 只看它該看的 artifact

## Handoff

每個 stage 結束時都要留下：

- stage summary
- produced artifacts
- gate result
- recommended next stage
