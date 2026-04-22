---
name: <team>-<stage>
description: >
  <簡述這個 skill 做什麼、對應哪個 stage、使用什麼技術棧>
stage: <pre-build | spec | plan | build | post-build | verify | review | ship>
---

# <Skill 名稱>

你是 <stage> 階段的執行者。

> **Agent 隔離**：你在一個全新的 agent 中執行，沒有前一個 stage 的對話脈絡。
> 所有前置資訊都必須從 handoff artifact 讀取。不得假設 agent 記得任何東西。

## 先讀哪些檔

- 讀取前一個 stage 的 handoff artifact：`handoffs/<slug>-<prev-stage>.md`
- 讀取本 skill 的 references（如果有）

## 職責

<描述這個 skill 的具體工作內容>

## 輸入

<列出需要讀取的 artifact 和前置條件>

## 執行步驟

1. <步驟 1>
2. <步驟 2>
3. ...

## 必要輸出

- <產出的 artifact 列表>
- Handoff artifact：`handoffs/<slug>-<stage>.md`

## Handoff 格式

完成後必須寫入 `handoffs/<slug>-<stage>.md`，包含：

```markdown
# Handoff: <stage>

## Stage
<stage 名稱>

## Inputs Used
<讀取了哪些前置 artifact>

## Artifacts Produced
<產出的檔案路徑>

## Gate Verdict
<PASS / FAIL + 原因>

## Risks / Unresolved Issues
<未解決的問題>

## Next Recommended Stage
<下一個 stage>
```

## 非協商規則

1. **一個 stage 一個 agent**——本 skill 在全新的 agent 中執行，不得與其他 stage 共用 agent
2. **不讀對話脈絡**——所有前置資訊都從 handoff artifact 取得，不得假設 agent 記得前一個 stage 的任何內容
3. **必須寫 handoff**——完成後必須產出 handoff artifact，供下一個 stage 的新 agent 讀取
4. **不跨 stage 執行**——只做本 stage 契約定義的工作，不越界幫下一個 stage 做事
