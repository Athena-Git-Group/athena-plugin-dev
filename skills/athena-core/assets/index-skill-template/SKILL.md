---
name: <team>-<stage>-index
description: >
  <team> 團隊 <stage> stage 的路由索引。
  根據需求特徵分派到不同的子 skill。
stage: <pre-build | spec | plan | build | post-build | verify | review | ship>
---

# <Stage> Index

你是 <stage> stage 的路由器，不直接執行工作。

## 先讀哪些檔

- 讀取前一個 stage 的 handoff artifact：`handoffs/<slug>-<prev-stage>.md`

## 路由邏輯

1. 讀取 handoff artifact，分析需求特徵
2. 根據條件決定路由：
   - <條件 A> → DELEGATE `<team>-<stage>-a`
   - <條件 B> → DELEGATE `<team>-<stage>-b`
   - <同時需要兩者> → 依序 DELEGATE A → B
3. 確認子 skill 的 handoff artifact 已產出

## 子 Skill 清單

| Skill | 條件 | 說明 |
|-------|------|------|
| `<team>-<stage>-a` | <觸發條件> | <說明> |
| `<team>-<stage>-b` | <觸發條件> | <說明> |

## 非協商規則

1. **一個 stage 一個 agent**——本 skill 在全新的 agent 中執行，不得與其他 stage 共用 agent
2. **不讀對話脈絡**——所有前置資訊都從 handoff artifact 取得，不得假設 agent 記得前一個 stage 的任何內容
3. 不自己執行實作，只做路由
4. 確保最終 handoff artifact 符合 <stage> stage 契約
5. 所有子 skill 完成後才寫入最終 handoff
6. **不跨 stage 執行**——只做本 stage 契約定義的工作，不越界幫下一個 stage 做事
