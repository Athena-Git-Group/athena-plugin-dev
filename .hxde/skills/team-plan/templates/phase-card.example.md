## Phase 01: taxonomy-enum

- **Depends On:** —
- **Depends Why:** 無前置
- **Spec Sections:** 2（tag 定義）、4（trace 彙整）
- **Touches:** files: skills/hxde-flow/references/**, skills/hxde-hill-climb/references/** / resources: trace-schema
- **Smoke Test:** `bash scripts/lint-plugin.sh && grep -q 'rule-conflict' skills/hxde-flow/references/run-trace.md && grep -q 'rule-conflict' skills/hxde-hill-climb/references/hill-climb.md`

### 目標

在 failure taxonomy 新增 `#rule-conflict` tag：run-trace.md 的 enum 表、
hill-climb.md 的「失敗模式 → 改進目標」逐 tag 表與 agent-handoff.md 的
tag 契約三處同步出現，語意一致。

### 契約面清單（本 phase 擁有、必須同步變動的檔案）

- `skills/hxde-flow/references/run-trace.md` — tag enum 的宣告處
- `skills/hxde-hill-climb/references/hill-climb.md` — 逐 tag 表的消費者（grep 實據）
- `skills/hxde-flow/references/agent-handoff.md` — handoff 的 tag 契約引用處

### 驗收條件

- [ ] 三個檔案都出現 `rule-conflict`（Smoke Test 的 grep 可判定）
- [ ] fresh-context reader 通讀本 phase 全部改動檔案，回報結構缺口（雞生蛋／缺失路徑／時序矛盾）
