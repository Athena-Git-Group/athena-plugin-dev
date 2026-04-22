# Stage Orchestration

## Goal

讓使用者只下單一指令，Athena 自己完成整條流程編排。
每個 stage 的實際執行 skill 由團隊在 `.athena/skills/` 提供。

## Default Sequence

1. Point（plugin 內建）
2. Spec if needed（團隊 skill）
3. Plan if needed（團隊 skill）
4. Build（團隊 skill）
5. Verify（團隊 skill）
6. Review（團隊 skill）
7. Ship（團隊 skill）

## Skill Resolution

每個 stage 啟動前，flow 根據 Skill Discovery 的對應表找到該 stage 的 skill：

```
stage → .athena/skills/<skill-dir>/SKILL.md
```

- 找到 → 開 fresh agent，讓它 Read 該 SKILL.md 後執行
- 找不到 → 停止流程，輸出引導訊息

詳見 `stage-contracts.md` 和 `index-skill-pattern.md`。

## Agent Isolation Rule

每個 stage 都必須是 fresh agent：

- Point agent（plugin 內建 athena-point）
- Spec agent（載入團隊 spec skill）
- Plan agent（載入團隊 plan skill）
- Build agent（載入團隊 build skill）
- Verify agent（載入團隊 verify skill）
- Review agent（載入團隊 review skill）
- Ship agent（載入團隊 ship skill）

不要重用。

## Why

- 避免 context 累積太大
- 避免前一階段的推理污染後一階段
- 讓每個 stage 只看它該看的 artifact
- 讓不同團隊可以替換任意 stage 的實作

## Handoff

每個 stage 結束時都要留下：

- stage summary
- produced artifacts
- gate result
- recommended next stage

Handoff 格式詳見 `stage-contracts.md`。
