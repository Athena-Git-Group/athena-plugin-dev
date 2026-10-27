<!-- 所有欄位皆必填——flow 的 phase agent 只讀這張卡，讀不到你的推理過程 -->
## Phase {{PHASE_ID}}: {{PHASE_NAME}}

- **Depends On:** {{DEPENDS_ON_IDS}}<!-- 無依賴寫「—」 -->
- **Depends Why:** {{DEPENDS_WHY}}<!-- 一句話講為什麼非得等這些 phase；無依賴寫「無前置」 -->
- **Spec Sections:** {{SPEC_SECTIONS}}<!-- 只列這個 phase 需要的 section 編號或標題 -->
- **Touches:** files: {{FILES_GLOBS}} / resources: {{RESOURCES}}<!-- 與 plan.md frontmatter 一字不差；resources 無則寫「—」 -->
- **Smoke Test:** {{SMOKE_TEST_COMMANDS}}<!-- 可機械判定的指令，依 .hxde/skills/team-common/rules/smoke-test.md Rule 1-2 選 -->

### 目標

{{PHASE_GOAL}}

### 契約面清單（本 phase 擁有、必須同步變動的檔案）

- `{{FILE_PATH}}` — {{WHY_THIS_FILE_BELONGS}}

### 驗收條件

- [ ] {{ACCEPTANCE_CRITERION}}
