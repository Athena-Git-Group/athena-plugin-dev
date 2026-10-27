# Rule 1 - 判準依序檢查，第一個命中就決定

- Level: `MUST`
- 分流判準依下表**由上而下**檢查，第一個命中的條件決定路由，不再往下看。
- 標的清單從 point-report（`points/<slug>.md`）讀；清單不足時用 Grep 自己查證，不得用猜的補。

| # | 條件 | 路由 |
|---|------|------|
| 1 | 改動標的**只**落在 plugin 自身表面：`skills/`、`agents/`、`commands/`、`hooks/`、`scripts/`、`.claude-plugin/`、`.athena/skills/`、`tests/fixtures/`、`docs/` | `plugin-contract-spec` |
| 2 | 需求引入或修改**產品**的實體 / 資料表 / 畫面 / API endpoint（標的含 `src/`、`specs/<其他 slug>/` 的產品規格） | `pm-to-eng-spec` |
| 3 | 兩邊都有（例：plugin 改動同時要動產品 `src/`） | **先** `plugin-contract-spec`，**再** `pm-to-eng-spec`；兩份產出都要，最終 handoff 合成一份 |
| 4 | 判不出來 | **不猜**。走 clarify 協議（見 `.athena/skills/team-common/rules/clarify-protocol.md`） |

- Why：`pm-to-eng-spec` 的 phase 是為產品功能寫死的（data_model → class_diagram → db_table → api → gherkin，或 screens → ui_contract），而 plugin 自身改動沒有實體、資料表、畫面或 endpoint——硬套產品流程只會腦補不存在的資料模型，或撞上「artifact 為空即 FAIL」而空轉。

## Good Example

- 這個例子是好的，因為它依序檢查、在第一個命中處停下，並留下查證依據。

```md
標的清單：skills/athena-flow/SKILL.md、hooks/auto-commit.sh。
檢查條件 1：兩個標的都在 plugin 自身表面 → 命中，路由 plugin-contract-spec。
不再檢查條件 2-4。
```

## Bad Example

- 這個例子是壞的，因為它跳過順序、憑整體印象挑路由。

```md
這需求讀起來像產品功能，直接走 pm-to-eng-spec，不用逐條對路徑。
```

# Rule 2 - 判準看路徑，不看語氣

- Level: `MUST`
- 判準看的是**改動標的落在哪些路徑**，不是需求講得像什麼。
- 需求用產品語言描述（講畫面、講使用者）但標的全在 `skills/` 等 plugin 表面 → 仍走條件 1。

## Good Example

- 這個例子是好的，因為它以標的路徑為準，不被敘述語氣帶走。

```md
需求寫「讓使用者在報告畫面看到白話摘要」，但改動標的只有
skills/athena-flow/references/*.md → 條件 1，plugin-contract-spec。
```

## Bad Example

- 這個例子是壞的，因為它用需求的敘述語氣決定路由。

```md
需求提到「畫面」跟「使用者」，應該是產品功能，走 pm-to-eng-spec。
（實際標的全在 skills/，根本沒有畫面檔案）
```

# Rule 3 - 不自己寫規格，verdict 沿用子 skill

- Level: `MUST`
- 本 index 只做路由與（條件 3 時的）handoff 合成，**不自己寫規格**。
- Gate Verdict 沿用子 skill 的判定，不自行改寫。
- 唯一由本 index 自己產生的 FAIL 有兩種：
  - 路由判不出來：`FAIL — spec 路由無法判定，見 specs/<slug>/clarify/questions.md #spec-gap`
  - 子 skill 沒寫出 `handoffs/<slug>-spec.md`：`FAIL — <子 skill> 未產出 spec handoff #contract-violation`

## Good Example

- 這個例子是好的，因為 index 只轉述子 skill 的 verdict，不加工。

```md
plugin-contract-spec 的 handoff Gate Verdict 為
「FAIL — 待使用者澄清，見 specs/add-tag/clarify/questions.md #spec-gap」
→ 最終 handoff 沿用此 verdict，index 不改寫、不補規格。
```

## Bad Example

- 這個例子是壞的，因為 index 越權替子 skill 翻案並自己補寫規格。

```md
子 skill 發了 FAIL，但我看問題不大，自己補兩段規格，verdict 改成 PASS。
```

# Rule 4 - 最終只有一份 handoff；兩者依序時照合成規則合併

- Level: `MUST`
- 不論路由結果為何，最終**只有一份** `handoffs/<slug>-spec.md`。
- 條件 3（兩者依序）時，兩個子 skill 都跑完後，由 index 合成一份：
  - `Artifacts Produced`：兩邊都列。
  - `Gate Verdict`：取較嚴的——任一 FAIL 即 FAIL。
  - `Risks / Unresolved Issues`：兩邊合併。

## Good Example

- 這個例子是好的，因為兩份產出合成一份、verdict 取較嚴。

```md
plugin-contract-spec：PASS；pm-to-eng-spec：FAIL — 缺畫面清單 #spec-gap。
合成一份 handoffs/add-view-spec.md：Artifacts 兩邊都列，
Gate Verdict = FAIL — 缺畫面清單 #spec-gap，Risks 合併兩邊。
```

## Bad Example

- 這個例子是壞的，因為它留下兩份 handoff 檔案。

```md
兩個子 skill 各自寫了 handoffs/add-view-spec.md 與
handoffs/add-view-spec-2.md，都留著讓 flow 自己挑。
```

# Rule 5 - 只有本 index 宣告 `stage: spec`

- Level: `MUST`
- 本 repo 的 spec stage 綁定只能由本 index 的 frontmatter 宣告 `stage: spec`。
- 兩個子 skill（`plugin-contract-spec`、`pm-to-eng-spec`）都**不得**宣告 `stage`，否則 flow 會偵測到重複 stage 綁定並停止。

## Good Example

- 這個例子是好的，因為 stage 綁定只有一處。

```md
team-spec-index frontmatter：stage: spec
plugin-contract-spec frontmatter：（無 stage 欄位）
```

## Bad Example

- 這個例子是壞的，因為子 skill 也宣告了 stage，造成重複綁定。

```md
team-spec-index frontmatter：stage: spec
plugin-contract-spec frontmatter：stage: spec
```
