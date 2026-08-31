# 缺少 Standard Skill 的引導訊息

Skill Discovery 發現路由所需 standard stage 缺 skill 時，停止流程並逐字輸出下列訊息
（缺哪些 stage 就列哪些行）：

```
⚠️ 缺少 stage 對應的 skill

以下 stage 尚未找到團隊上繳的 skill：
- [ ] build — 在 .athena/skills/ 下建立一個 SKILL.md，frontmatter 包含 stage: build
- [ ] verify — 在 .athena/skills/ 下建立一個 SKILL.md，frontmatter 包含 stage: verify

請參考：
- Stage 契約：athena-dev-plugin/skills/athena-flow/references/stage-contracts.md
- Skill 元資料規格：athena-dev-plugin/skills/athena-core/references/skill-metadata-spec.md
- Skill 模板：athena-dev-plugin/skills/athena-core/assets/skill-template/

建立完成後重新執行 /flow。
```
