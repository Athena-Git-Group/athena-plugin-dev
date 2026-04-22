# Stage Orchestration

## Goal

讓使用者只下單一指令，Athena 自己完成整條流程編排。
每個 stage 的實際執行 skill 由團隊在 `.athena/skills/` 提供。

## Default Sequence

```
1. Point（plugin 內建）
2. Spec if needed（standard stage，團隊 skill）
3. Plan if needed（standard stage，團隊 skill）
4. [pre-build]（flow-inline，athena-pre-build 或團隊替換）
5. Build（standard stage，團隊 skill）
6. [post-build: build]（flow-inline，athena-post-build 或團隊替換，triggering_stage=build）
7. Verify（standard stage，團隊 skill）
8. [post-build: verify]（flow-inline，athena-post-build 或團隊替換，triggering_stage=verify）
9. Review（standard stage，團隊 skill）
10. Ship（standard stage，團隊 skill）
```

> `[括號]` 表示 flow-inline stage，在 flow agent 中內聯執行。

## Skill Resolution

### Standard Stage

每個 standard stage 啟動前，flow 根據 Skill Discovery 的對應表找到該 stage 的 skill：

```
stage → .athena/skills/<skill-dir>/SKILL.md
```

- 找到 → 開 fresh agent，讓它 Read 該 SKILL.md 後執行
- 找不到 → 停止流程，輸出引導訊息

### Flow-Inline Stage

Flow-inline stage（pre-build、post-build）使用不同的 resolution 規則：

```
1. 掃描 .athena/skills/ 尋找對應 stage 的 skill
2. 若找到 → 使用團隊的 skill（Read 該 SKILL.md 後內聯執行）
3. 若未找到 → 使用 plugin 預設：
   - pre-build  → skills/athena-pre-build/SKILL.md
   - post-build → skills/athena-post-build/SKILL.md
4. 不停止流程，不引導團隊補齊
```

詳見 `stage-contracts.md` 和 `index-skill-pattern.md`。

## Agent Isolation Rule

**Standard stage** 都必須是 fresh agent：

- Point agent（plugin 內建 athena-point）
- Spec agent（載入團隊 spec skill）
- Plan agent（載入團隊 plan skill）
- Build agent（載入團隊 build skill）
- Verify agent（載入團隊 verify skill）
- Review agent（載入團隊 review skill）
- Ship agent（載入團隊 ship skill）

不要重用。

**Flow-inline stage** 在 flow agent 中內聯執行：

- pre-build（建立 Git 分支）
- post-build（自動 commit）

不開新 agent，直接由 flow orchestrator 讀取 skill 後操作。

## Why

- 避免 context 累積太大（standard stage 用 fresh agent）
- 避免前一階段的推理污染後一階段
- 讓每個 stage 只看它該看的 artifact
- 讓不同團隊可以替換任意 stage 的實作
- Flow-inline stage 輕量操作不值得開 fresh agent 的成本

## Git Lifecycle Hooks

Git 操作以 flow-inline stage 的形式穿插在 standard stage 之間：

- **pre-build**：build 前建立分支並切換，從 point-report 推斷分支類型與名稱
- **post-build（build 後）**：build gate PASS 後自動 commit 所有變更
- **post-build（verify 後）**：verify gate PASS 後自動 commit 測試相關變更（若有）

詳見 `git-lifecycle-hooks.md`。

## Handoff

每個 standard stage 結束時都要留下：

- stage summary
- produced artifacts
- gate result
- recommended next stage

Flow-inline stage 透過 **flow context** 傳遞，不產出 handoff artifact。
Flow context 中的 `git_context` 可在 review / ship stage 的 handoff 中引用。

Handoff 格式詳見 `stage-contracts.md`。
