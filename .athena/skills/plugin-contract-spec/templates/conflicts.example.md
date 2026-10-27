# 規則衝突檢查 — add-timing-field

## 改動項 A
搜尋過的規則來源：
- `skills/athena-flow/SKILL.md`「非協商規則」段
- `.athena/skills/*/SKILL.md`「非協商規則」段
- `.athena/skills/team-common/rules/fail-reporting.md`

結果：有衝突

### 衝突（若有）
- **衝突對象**：`skills/athena-flow/references/agent-handoff.md:11` — 「mini-handoff 的 H1 是 `# Phase Handoff:`，勿順手統一」
- **衝突內容**：新增 Timing 區塊時若連帶調整 H1 字樣，會破壞 auto-commit.sh 的 awk 匹配——新欄位與既有機械契約不能同時任意變動
- **解法**：在新規則明文寫出例外與適用層級——只新增 `## Timing` 區塊，H1 與既有欄位一字不動；已查證無跨檔引用編號需要重排
