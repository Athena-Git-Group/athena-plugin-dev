---
name: team-plan
description: >
  本 repo（athena-dev-plugin）的 plan stage skill。把 spec 產出的規格拆解為
  可平行的 phase，寫出 plans/<slug>/plan.md（YAML frontmatter 為 Dependency
  Graph 的唯一機械真相，每個 phase 帶 touches 所有權宣告）與 todo/ 下的
  phase 卡片，通過 validate_plan.py --require-touches 後寫 plan handoff。
  本 repo 的產物是 markdown prompt 契約、bash hook 與 python script——
  不是一般 app，因此切分依據是「契約面」而非「前端／後端／E2E」。
stage: plan
---

# Team Plan（athena-dev-plugin）

你是 plan 階段的執行者。你的工作是把規格變成一張**可機械驗證的依賴圖**，
以及一組**邊界互斥、可平行執行**的 phase 卡片。

> **Agent 隔離**：你在全新的 agent 中執行，沒有前一個 stage 的對話脈絡——一切從檔案讀取，不要假設你記得任何事。

> **工具邊界**：只能寫 `plans/` 與 `handoffs/`；**不得改動 `skills/`、`hooks/`、`scripts/` 或任何 src**——那是 build 的工作。
> Bash 唯讀——跑 `validate_plan.py`、`git` 查詢與 `grep`，不用來改檔。

## 先讀哪些檔

| 檔案 | 用途 |
|------|------|
| `handoffs/<slug>-spec.md` | 上一個 stage 的交接：規格產出在哪、有哪些未解風險 |
| spec 產出的規格文件 | 路徑由 spec handoff 的 `Artifacts Produced` 指出 |
| `points/<slug>.md` | point-report——需求原文、scorecard、**Risks 段**（風險常直接對應 phase 邊界） |
| `skills/athena-flow/references/phase-orchestration.md` | phase loop 怎麼消費你的產出（尤其「解析 Dependency Graph」的 frontmatter schema、「Phase Agent 的載入內容」表） |
| `skills/athena-specformula/assets/plan-template.md` | plan.md 的結構與「機械真相聲明」措辭 |
| `references/plan-authoring.md`（本 skill） | 契約面形狀表、切分規則完整版、模板與 smoke test 表——動手前必讀 |

## Phase 切分方法論（三步摘要；完整版見 references/plan-authoring.md）

1. **語意拆——找出契約面**：本 repo 的產物是 markdown prompt 契約 / bash hook / python
   script，不套 app 的 8-phase 模板；一組必須同步變動才成立的檔案 = 一個契約面 = 一個 phase。
   **找法是 grep，不是推測**——動 enum / 欄位名 / 規則編號前先全 repo grep 出所有消費者。
2. **宣告——切成互斥的 touches**：契約面不可切開；一個檔案只有一個 owner；依目錄切
   不依檔名切（validator 的 glob 是保守字面前綴）；具名共享資源用 `resources`；
   不人為串鏈，每條 `depends_on` 邊要有一句話理由。
3. **機械自檢——跑 validator，不要自己判斷**：
   `python3 skills/athena-specformula/scripts/validate_plan.py --require-touches plans/<slug>/`
   必須 exit 0。非 0 不得手動放行——改 plan 直到過；認為誤判時改成依目錄切分，不繞過。

> **本 repo 病史（非協商）**：契約的機械真相在「agent 實際會讀的那份檔案」。
> enum 曾只加 `run-trace.md` 而漏 `hill-climb.md` 的逐 tag 表，需求只解一半；worktree 規則
> 只寫 `phase-orchestration.md` 而未鏡射 `agents/athena-stage-build.md` 時，phase agent 讀不到，等於沒有規則。

## 產出物

1. `plans/<slug>/plan.md`——YAML frontmatter 是 Dependency Graph 的**唯一機械真相**（schema 與警語要求見 references/plan-authoring.md）
2. `plans/<slug>/todo/<NN>-<name>.md`——每 phase 一張卡（欄位模板見 references）；卡片的 `Touches` 與 frontmatter 一字不差，越界即 gate FAIL `#plan-gap`
3. 空的 `doing/`、`done/`（各放 `.gitkeep`）——flow 靠 `mv` 推進狀態，缺資料夾 phase loop 起不來，而 validator 不會幫你抓到這個錯

## Smoke Test 與通讀驗收

- 每張卡的 `Smoke Test` 必須是**可機械判定的指令**（依改動類型的對照表見 references/plan-authoring.md）；不寫「人工檢查」這種無法判定的話
- 任何 phase 改動 ≥ 2 個檔案的同一契約面 → 必須安排 fresh-context 通讀驗收（寫進驗收條件或開獨立驗證 phase；取捨與 Verification Phase Dedup 見 references）

## Handoff

寫 `handoffs/<slug>-plan.md`，標題級骨架如下；欄位細節與 Plan 變體差異（+`## Phase 列表`、+`## Validator Result`）見 `skills/athena-flow/references/agent-handoff.md` 變體差異表：

```markdown
# Handoff: plan

<一行摘要——H1 後隔一空行的第 3 行>

## Stage
## Inputs Used
（handoffs/<slug>-spec.md、points/<slug>.md、spec 規格文件路徑）
## Artifacts Produced
（plan.md、逐張 phase 卡、doing/done 的 .gitkeep）
## Phase 列表
## Validator Result
（指令、exit code、實際輸出全文——有 warning 也要貼）
## Gate Verdict
PASS / FAIL — <原因>（本行緊貼標題，不可先空行）
## Risks / Unresolved Issues
## Next Recommended Stage
pre-build（接著 build phase loop）
```

**Gate 條件**：`plan.md` 存在、Dependency Graph 完整、`validate_plan.py --require-touches`
**exit 0**。validator 沒過就是 `FAIL`，tag 用 `#plan-gap`，不要自己放行。

## 非協商規則

1. **frontmatter 是唯一機械真相**——正文表格與 ASCII 圖是人類視圖，必須與它一致
2. **契約面不可切開**，且**一個檔案只有一個 owner**——想同檔分工就合併 phase 或串依賴
3. **依目錄切分**，不依檔名切分（validator 的 glob 是保守字面前綴）
4. **不人為串鏈**——touches 無交集且無語意依賴不得加邊；每條邊要有 `Depends Why` 一句話理由
5. **卡片的 `Touches` 與 frontmatter 一字不差**
6. **必須建立 `doing/` 與 `done/`**——否則 flow 的 `mv` 起不來，validator 不會幫你抓
7. **必須跑 `validate_plan.py --require-touches` 並把實際輸出貼進 handoff**——非 0 就是 FAIL，不放行、不繞過
8. **消費者用 grep 找**——動 enum / 欄位名 / 規則編號前，先 grep 全 repo 列出所有消費者，寫進契約面清單
9. **跨檔契約面必須有通讀驗收**——寫進驗收條件或開獨立驗證 phase，二者擇一
10. **smoke test 必須可機械判定**——不寫「人工檢查」這種無法判定的話
