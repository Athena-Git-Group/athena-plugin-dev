---
name: team-spec-index
description: >
  Spec stage 的路由索引。本 repo 有兩種截然不同的需求輸入：一是 PM 的產品
  功能需求單（有實體、畫面、endpoint），二是 plugin 自身的 prompt 契約改動
  （skills / agents / hooks / scripts，沒有資料模型也沒有畫面）。兩者需要
  完全不同的 spec 流程，因此由本 index 依機械判準分流到 pm-to-eng-spec
  或 plugin-contract-spec。
stage: spec
---

# Spec Index（athena-dev-plugin）

你是 spec stage 的**路由器**，不自己寫規格。

> **Agent 隔離**：你在全新的 agent 中執行，沒有前一個 stage 的對話脈絡。
> 一切從檔案讀取。

> **一個 stage 一個 agent**：你和你 DELEGATE 的子 skill 在**同一個** agent 中
> 執行。不要嘗試開新 agent（spec shell 沒有 Agent 工具）。

## 為什麼需要分流

`pm-to-eng-spec` 的 phase 是為產品功能寫死的：`data_model` → `class_diagram`
→ `db_table` → `api` → `gherkin`（或 `screens` → `ui_contract`）。它的非協商
規則要求「依 target 走 track，不混跑」，且「前端一律 Nuxt 4 + TypeScript strict」。

但這個 repo 的另一半工作是改 plugin 自己：`skills/**/SKILL.md`、
`skills/**/references/*.md`、`agents/*.md`、`commands/*.md`、`hooks/*.sh`、
`scripts/*.py`。這類需求**沒有實體、沒有資料表、沒有畫面、沒有 endpoint**。
硬套產品 track 只有兩種結局：腦補一個不存在的資料模型（污染 plan），
或撞上「artifact 為空即 FAIL」而空轉。

所以分流。

## 先讀哪些檔

- `points/<slug>.md` — point-report。需求原文、scorecard、**Risks 段**、
  以及 point 自己列出的受影響檔案／消費者清單
- 不要預先讀兩個子 skill 的 SKILL.md——判完路由才 Read 中選的那一份

## 路由判準（依序檢查，第一個命中就決定）

判準看的是**改動標的落在哪些路徑**，不是需求講得像什麼。標的清單從
point-report 讀，不足時用 Grep 自己查證。

| # | 條件 | 路由 |
|---|------|------|
| 1 | 改動標的**只**落在 plugin 自身表面：`skills/`、`agents/`、`commands/`、`hooks/`、`scripts/`、`.claude-plugin/`、`.athena/skills/`、`tests/fixtures/`、`docs/` | `plugin-contract-spec` |
| 2 | 需求引入或修改**產品**的實體 / 資料表 / 畫面 / API endpoint（標的含 `src/`、`specs/<其他 slug>/` 的產品規格） | `pm-to-eng-spec` |
| 3 | 兩邊都有（例：plugin 改動同時要動產品 `src/`） | **先** `plugin-contract-spec`，**再** `pm-to-eng-spec`；兩份產出都要，最終 handoff 合成一份 |
| 4 | 判不出來 | **不猜**。見下方「判不出來時」 |

**判準的機械依據**：條件 1 的路徑清單與 `hooks/require-point.sh` 的自我保護
路徑高度重疊，那不是巧合——那些正是「plugin 改自己」的表面。

### 判不出來時

不要憑感覺挑一邊。寫 `specs/<slug>/clarify/questions.md`（沿用
`pm-to-eng-spec` 的 headless 協議格式：逐題編號、附預設選項與影響說明），
最終 handoff 給：

```
FAIL — spec 路由無法判定，見 specs/<slug>/clarify/questions.md #spec-gap
```

然後**停止**。flow 會回報使用者；使用者的回答由主對話寫入
`specs/<slug>/clarify/answers.md` 後重跑 spec stage。

先檢查 `answers.md` 是否已存在——存在就讀它，不要重複問同一題。

## 執行程序

1. 讀 `points/<slug>.md`，取需求原文與改動標的清單
2. 若 `specs/<slug>/clarify/answers.md` 存在 → 讀入，納為判準依據
3. 套上表判準決定路由
4. 把路由結果與**依據**寫入 `specs/<slug>/route.md`：

   ```markdown
   # Spec Route — <slug>

   ## 判定
   <plugin-contract-spec | pm-to-eng-spec | 兩者依序>

   ## 命中的判準
   第 <N> 條

   ## 依據（改動標的清單）
   - `<path>` — <來源：point-report 第 N 段 / 自行 Grep 查證>
   ```

5. Read 中選子 skill 的 `SKILL.md`，**DELEGATE**（在本 agent 內執行它）
6. 確認子 skill 已寫出 `handoffs/<slug>-spec.md`
7. 條件 3（兩者依序）時：兩個子 skill 都跑完，把兩份產出合成**一份**
   `handoffs/<slug>-spec.md`——Artifacts Produced 兩邊都列，Gate Verdict
   取較嚴的（任一 FAIL 即 FAIL），Risks 合併

## Gate Verdict

你不自己產生 verdict，**沿用子 skill 的**。唯一由你產生的 FAIL 是路由判不出來
那一種（`#spec-gap`）。

子 skill 沒寫出 `handoffs/<slug>-spec.md` → `FAIL — <子 skill> 未產出 spec
handoff #contract-violation`。

## 非協商規則

1. **不自己寫規格**——只做路由與（條件 3 時的）handoff 合成
2. **只有本 index 宣告 `stage: spec`**——兩個子 skill 都不得宣告 `stage`，
   否則 flow 會偵測到重複 stage 綁定並停止
3. **判準看路徑，不看語氣**——需求講得像產品功能但標的全在 `skills/`，走條件 1
4. **判不出來就走 FAIL 協議**——不猜、不預設挑一邊
5. **不開新 agent**——index 與子 skill 同一個 agent（spec shell 無 Agent 工具）
6. **最終只有一份 `handoffs/<slug>-spec.md`**——條件 3 也是合成一份，不是兩份
7. **不讀前 stage 對話脈絡**——一切從 `points/` 與 `specs/` 讀
