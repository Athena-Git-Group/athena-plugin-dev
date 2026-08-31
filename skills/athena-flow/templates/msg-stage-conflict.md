# 重複 Stage 綁定的報錯訊息

Skill Discovery 發現同一 stage 被 ≥ 2 個 skill 宣告時，停止流程並逐字輸出
（代入實際 stage 名與 skill 路徑）：

```
⚠️ Stage 衝突：build 被多個 skill 宣告

- .athena/skills/team-build-api/SKILL.md → stage: build
- .athena/skills/team-build-web/SKILL.md → stage: build

同一個 stage 只能有一個 skill。如果需要多個流程，請建立 index skill 作為路由。
詳見：athena-dev-plugin/skills/athena-flow/references/index-skill-pattern.md
```
