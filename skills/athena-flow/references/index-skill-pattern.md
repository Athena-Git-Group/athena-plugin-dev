# Index Skill Pattern

## 問題

同一個 stage 可能有多種流程。例如 build stage 可能需要區分：
- 後端 API 的 build 流程
- 前端 SPA 的 build 流程
- 批次任務的 build 流程

## 解法：Index Skill

當同一個 stage 存在多個 skill 時，團隊必須建立一個 **index skill** 作為該 stage 的入口。Index skill 負責根據需求特徵，路由到正確的子 skill。

## 結構

```
.athena/skills/
├── my-team-build-index/       # Index skill — 宣告 stage: build
│   └── SKILL.md
├── my-team-build-backend/     # 子 skill — 不宣告 stage
│   └── SKILL.md
├── my-team-build-frontend/    # 子 skill — 不宣告 stage
│   └── SKILL.md
```

### 規則

1. **只有 index skill 宣告 `stage` 欄位**，子 skill 不宣告
2. `athena-flow` 只會找到 index skill 並呼叫它
3. Index skill 負責讀取 handoff artifact，判斷路由條件，再 DELEGATE 到子 skill
4. 子 skill 的最終輸出仍然必須符合該 stage 的契約（寫 handoff artifact）
5. **一個 stage 一個 agent**——index skill 和其子 skill 都在同一個 fresh agent 中執行，但不得與其他 stage 共用 agent
6. **不讀前 stage 對話脈絡**——一切從 handoff artifact 讀取

## Index Skill 的 SKILL.md 範例

```yaml
---
name: my-team-build-index
description: >
  Build stage 路由索引。根據需求的技術類型分派到對應的 build skill。
stage: build
---
```

```markdown
# Build Index

你是 build stage 的路由器，不直接執行 build。

## 路由邏輯

1. 讀取 `handoffs/<slug>-plan.md`
2. 判斷技術類型：
   - 涉及後端 API → DELEGATE `my-team-build-backend`
   - 涉及前端頁面 → DELEGATE `my-team-build-frontend`
   - 全端 → 依序 DELEGATE 後端 → 前端
3. 確認子 skill 的 handoff artifact 已產出

## 非協商規則

1. 不自己寫程式碼，只做路由
2. 確保最終 handoff artifact 符合 build stage 契約
```

## 子 Skill 的 SKILL.md 範例

```yaml
---
name: my-team-build-backend
description: >
  後端 API 的 build skill。使用 Java + Spring Boot，TDD 流程。
---
```

> 注意：子 skill **不宣告 `stage`**，因為它不直接被 flow 發現，而是由 index skill DELEGATE。

## 何時需要 Index Skill

| 情境 | 需要 Index Skill？ |
|------|-------------------|
| 一個 stage 只有一個 skill | 不需要，直接宣告 `stage` |
| 一個 stage 有多個 skill，根據條件選擇 | 需要 |
| 一個 stage 有多個 skill，需要依序全部執行 | 需要（index skill 負責排序） |
