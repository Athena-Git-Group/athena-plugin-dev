# L2 Contract Checks

依 stage 對照 `skills/athena-flow/references/stage-contracts.md` 的「必要輸入 / 必要輸出」。
採 keyword heuristic：在 SKILL.md 全文中搜尋特定字串。

> **重要**：因為是 grep 比對，誤判為 false negative（規則沒命中但 skill 其實有寫）的情況不算 ❌，
> 一律用 🟡 並標示為「heuristic 建議」。

## 通用規則：handoff 契約

所有 standard stage skill 必須在 SKILL.md 中明確提及如何取得前置輸入（handoff 或 point-report）並寫入本 stage 的 handoff：

| 檢查項 | 搜尋 keyword | 失敗 tier |
|--------|------------|----------|
| 取得前置輸入 | `handoffs/` 或 `points/`（依該 stage 契約） | 🟡 |
| 寫入本 stage handoff | `handoffs/` AND（本 stage 名稱 OR `<stage>`） | 🟡 |
| Handoff 通用欄位 | `Gate Verdict` AND `Inputs Used` AND `Artifacts Produced` | 💡（建議套用通用模板） |

> 注意：build stage 的前置輸入依 weight class 而異 — Minimal/Lightweight 從 `points/<slug>.md` 讀，Full 才從 `handoffs/<slug>-plan.md` 讀。詳見下方「Build 視 Weight Class 而定」段。

## 各 stage keyword 對照表

| stage | 必要輸入 keyword（任一） | 必要輸出 keyword（任一） |
|-------|----------------------|----------------------|
| `spec` | `points/` 或 `point-report` | `handoffs/` AND `spec` |
| `plan` | `handoffs/` AND `spec` | `plans/` AND `plan.md` |
| `build` | (`points/` OR `point-report`) OR (`handoffs/` AND `plan`) | `handoffs/` AND `build` |
| `verify` | `handoffs/` AND `build` | `handoffs/` AND `verify` |
| `review` | `handoffs/` AND（`verify` OR `build`） | `handoffs/` AND `review` |
| `ship` | `handoffs/` AND `review` | `handoffs/` AND `ship` |

### Build 視 Weight Class 而定

`build` 的「必要輸入」依 `point-report` 的 verdict 而異：

| Weight Class | 必要輸入 | 對應 verdict |
|---|---|---|
| Minimal | `points/<slug>.md` | `PASS-TRIVIAL` |
| Lightweight | `points/<slug>.md` | `PASS-DIRECT-BUILD`、`PASS-BUILD-WITH-VERIFY` |
| Full | `handoffs/<slug>-plan.md` + `plans/<slug>/plan.md` | `PASS-SPEC-FIRST` |

任一寫法命中即視為已說明前置依賴。Minimal/Lightweight build skill 寫 `points/<slug>.md`、Full build skill 寫 `handoffs/<slug>-plan.md` 都合規。

### Spec 必要輸出的補強檢查

`spec` 除了寫 handoff，還必須產出 spec 規格文件本身（Activity Diagrams、Feature Rules 等）。
若 SKILL.md 提到 `handoffs/<slug>-spec.md` 但完全沒提及 `規格` / `Activity` / `Feature Rules` / `Scenario` 任一字眼 → 💡 建議補述產出哪些 spec artifact。

## Flow-inline stage 額外規則

| stage | 必須提及 |
|-------|---------|
| `pre-build` | `git_context` AND（`branch_name` OR `分支`） |
| `post-build` | `git_context` AND（`commits` OR `commit`） AND `triggering_stage` |

> Flow-inline stage 不寫 `handoffs/`，改用 flow context。
> 如果 SKILL.md 提到 `handoffs/<stage>.md` 反而是錯誤訊號（🟡 提示）。

## Agent 隔離宣告（建議）

Standard stage skill 建議在 SKILL.md 中明確說明 agent 隔離原則。
搜尋 keyword：

- `agent 隔離` / `agent isolation` / `fresh agent` / `不共享上下文` / `隔離 context`

未命中 → 💡（建議加入該段，幫助讀 SKILL.md 的人理解）。

## 非協商規則的對照

對 `skills/athena-core/assets/skill-template/SKILL.md` 中列出的 4 條「非協商規則」做對照：

1. 一個 stage 一個 agent
2. 不讀對話脈絡
3. 必須寫 handoff
4. 不跨 stage 執行

如果該 skill 完全沒提到上述任何一條 → 💡（建議加入「非協商規則」段）。

## Index skill 額外規則

如果是 index skill（name 以 `-index` 結尾）：

- 必須提到「依任務性質路由到子 skill」之類的字眼
- 必須列出可能路由到的子 skill
- 不需檢查讀寫 handoffs（由子 skill 負責）

詳見 `skills/athena-flow/references/index-skill-pattern.md`。

## 輸出對應

未通過的契約檢查：

- 一律 🟡（不用 ❌）
- 附上對應 stage-contracts.md 的章節連結
- 附上「期望片段範例」（從 skill-template 摘）

範例輸出片段：

```
🟡 沒看到讀取 handoffs/<slug>-plan.md
   契約：skills/athena-flow/references/stage-contracts.md#build
   建議在「先讀哪些檔」段加入：
     - 讀取前一個 stage 的 handoff：handoffs/<slug>-plan.md
   （若你的寫法不同但等義，請忽略此提醒）
```
