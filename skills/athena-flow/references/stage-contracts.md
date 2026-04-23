# Stage Contracts

## 概述

每個可替換的 stage 都有一份契約，定義該 stage 的**輸入**（從前一個 stage 的 handoff 讀取什麼）和**輸出**（必須產出什麼 artifact 給下一個 stage）。

下游團隊上繳的 skill 必須遵守對應 stage 的契約，才能被 `athena-flow` 正確編排。

## 不可替換的 Stage

以下 stage 由 plugin 自身控制，不開放替換：

| Stage | Skill | 原因 |
|-------|-------|------|
| **point** | `athena-point` | 流程閘門，決定路由邏輯 |
| **flow** | `athena-flow` | 流程編排器本身 |

## 可替換的 Stage

Stage 分為兩類：**Standard Stage**（fresh agent 執行）和 **Flow-Inline Stage**（flow agent 內聯執行）。

---

### pre-build（Flow-Inline）

| 項目 | 說明 |
|------|------|
| **職責** | Build 前的準備操作（建立 Git 分支） |
| **執行方式** | Flow agent 內聯執行（不開 fresh agent） |
| **Plugin 預設** | `athena-pre-build`（團隊可替換） |
| **輸入** | `points/<slug>.md` 中的 slug、verdict、任務性質 |
| **必要輸出** | flow context 的 `git_context`（branch_name、base_branch、ticket） |
| **交接方式** | Flow context（不產出 handoff artifact） |
| **Gate 條件** | 無 gate — 分支建立成功即繼續 |

#### Flow Context 輸出格式

```yaml
git_context:
  branch_created: true
  branch_name: "feature/main_hap3621_member_export"
  base_branch: "main"
  ticket: "3621"
```

---

### spec

| 項目 | 說明 |
|------|------|
| **職責** | 需求分析，產出結構化規格 |
| **輸入** | `points/<slug>.md` 中的需求描述與 point verdict（point stage 輸出在 `points/` 而非 `handoffs/`） |
| **必要輸出** | 需求規格文件（Activity Diagrams、Feature Rules、Execution Plan 等） |
| **Handoff** | `handoffs/<slug>-spec.md`，包含 artifacts produced、gate verdict |
| **Gate 條件** | 規格文件產出且通過 Quality Gate |

### plan

| 項目 | 說明 |
|------|------|
| **職責** | 將規格轉換為可執行的工程計畫 |
| **輸入** | `handoffs/<slug>-spec.md` + spec 階段產出的規格文件 |
| **必要輸出** | `plans/<slug>/plan.md`（含 Dependency Graph）+ Phase 卡片 |
| **Handoff** | `handoffs/<slug>-plan.md`，包含計畫路徑、phase 列表 |
| **Gate 條件** | plan.md 存在且 Dependency Graph 完整 |

### build（Lightweight — 無 plan 時）

當路由為 `PASS-DIRECT-BUILD` 或 `PASS-BUILD-WITH-VERIFY`（Lightweight Weight Class）時，
Build 以 Lightweight 模式執行——單一 fresh agent，不跑 phase loop。

| 項目 | 說明 |
|------|------|
| **職責** | 根據 point-report 完成所有實作 |
| **執行方式** | 單一 fresh agent（不跑 phase loop） |
| **輸入** | `points/<slug>.md`（point-report）+ 實際程式碼 |
| **無需** | plan.md、phase card、mini-handoff |
| **必要輸出** | `handoffs/<slug>-build.md`（agent 直接寫，非合成） |
| **Smoke Test** | Agent 自行執行（從 point-report 推斷合理的驗證指令） |
| **Commit** | 單次 post-build commit（`triggering_stage: build-lightweight`） |
| **Gate 條件** | Smoke test 通過 |

#### Lightweight Build Agent Prompt

```
你正在以 Lightweight 模式執行 Build。
這是一個低複雜度的任務，不需要 phase loop。

讀取：
1. .athena/skills/<build-skill>/SKILL.md（你的 build skill）
2. points/<slug>.md（需求描述與評分）

完成後：
1. 執行 smoke test（根據變更性質選擇合理的驗證指令）
2. 寫 handoffs/<slug>-build.md（使用 Compact 格式，見 agent-handoff.md）
```

#### Lightweight Build Handoff 格式

使用 Compact 格式（詳見 `agent-handoff.md`「Compact Build Handoff」段落）：

```markdown
# Handoff: build (lightweight)

## Gate Verdict
PASS / FAIL + 原因

## Files Changed
- <file list with new/modified annotation>

## Smoke Test Result
- <command>: <result>

## Risks / Unresolved Issues
<若無則 None>
```

---

### build（Phase Loop — Full Weight）

Build 不再是單一 agent 執行的 opaque stage。
Flow 讀取 `plan.md` 的 Dependency Graph，將 implementation phases 拆解為 phase loop。
詳見 `phase-orchestration.md`。

| 項目 | 說明 |
|------|------|
| **職責** | 根據計畫執行實作（後端/前端/全端），以 phase 為單位 |
| **輸入** | `handoffs/<slug>-plan.md` + `plans/<slug>/plan.md`（Dependency Graph）+ `plans/<slug>/phase-cards/` |
| **執行方式** | Flow 驅動的 phase loop — 每個 phase 由 fresh agent 執行 |
| **Phase 輸出** | 每個 phase 寫 `handoffs/<slug>-build-phase-<NN>.md`（mini-handoff） |
| **Phase Gate** | 每個 phase agent 執行 smoke test，結果寫入 mini-handoff |
| **Phase Commit** | 每個 phase gate PASS 後，flow 執行 post-build commit（per-phase） |
| **最終 Handoff** | 所有 phase 完成後，flow 合成 `handoffs/<slug>-build.md`（彙整所有 mini-handoff） |
| **Gate 條件** | 所有 phase gate PASS |

#### Phase Loop 流程

```
for each phase in dependency order:
  1. fresh agent → build skill + phase card + mini-handoff(prev) + spec sections
  2. agent 實作 → smoke test → 寫 mini-handoff
  3. flow 讀 Gate Verdict
     - PASS → post-build commit → 繼續
     - FAIL → phase retry（最多 2 輪）→ 仍失敗則停止
→ 所有 phase 完成 → 合成 handoffs/<slug>-build.md
```

#### 平行 Phase

Dependency Graph 中無相互依賴的 phase 可同時啟動。
平行 phase 完成後進行 conflict detection。詳見 `phase-orchestration.md`。

---

### post-build（Flow-Inline）

| 項目 | 說明 |
|------|------|
| **職責** | Stage gate 通過後自動提交 Git commit |
| **執行方式** | Flow agent 內聯執行（不開 fresh agent） |
| **Plugin 預設** | `athena-post-build`（團隊可替換） |
| **觸發時機** | Lightweight build gate PASS 後 + 每個 build phase gate PASS 後（Full）+ verify gate PASS 後 + verify fix 完成後 |
| **輸入** | flow context 的 `git_context` + 對應的 mini-handoff 或 handoff artifact + `triggering_stage` 參數 |
| **必要輸出** | flow context 的 `git_context.commits` 陣列追加新 commit |
| **交接方式** | Flow context（不產出 handoff artifact） |
| **Gate 條件** | 無 gate — commit 成功或無變更皆繼續 |

#### 觸發參數

| 觸發點 | `triggering_stage` | 預設 commit type |
|--------|---------------------|------------------|
| Lightweight build gate PASS 後 | `build-lightweight` | `feat` / `fix` |
| 每個 build phase gate PASS 後（Full） | `build-phase-<NN>` | `feat` / `fix` |
| verify gate PASS 後 | `verify` | `test` |
| Lightweight verify fix 完成後 | `verify-fix-lightweight` | `fix` |
| Full verify fix 完成後 | `verify-fix-phase-<NN>` | `fix` |

#### Flow Context 輸出格式

```yaml
git_context:
  commits:
    - hash: "abc1234"
      stage: "build-phase-05"
      message: "[HAP-3621] feat(member): add member export API (phase-05)"
      files_committed: 5
```

---

### verify

| 項目 | 說明 |
|------|------|
| **職責** | 驗證 build 產出的正確性（測試、QA） |
| **輸入** | `handoffs/<slug>-build.md` + 實際程式碼變更 |
| **必要輸出** | 驗證報告（測試結果、覆蓋率、手動 QA 結果） |
| **Handoff** | `handoffs/<slug>-verify.md`，包含通過/失敗狀態、問題清單 |
| **Gate 條件** | 所有測試通過、無 blocking issue |

### review

| 項目 | 說明 |
|------|------|
| **職責** | 程式碼審查、品質把關 |
| **輸入** | `handoffs/<slug>-verify.md` + 實際程式碼變更 |
| **必要輸出** | 審查結果（approve / request-changes） |
| **Handoff** | `handoffs/<slug>-review.md`，包含審查意見、最終狀態 |
| **Gate 條件** | 審查通過（approved） |

### ship

| 項目 | 說明 |
|------|------|
| **職責** | 推送分支、合併到目標環境 |
| **輸入** | `handoffs/<slug>-review.md` + flow context 的 `git_context` + **`merge_target`（flow 傳入）** |
| **必要輸出** | push 確認、merge 結果、目標分支狀態 |
| **Handoff** | `handoffs/<slug>-ship.md`，包含 push/merge 結果 |
| **Gate 條件** | push 成功 + merge 成功 |

#### merge_target 來源

Ship agent **不詢問使用者**。`merge_target` 由 flow 在啟動 ship agent 前決定：

1. Flow 向使用者詢問：「要合到哪個分支？（預設：`{git_context.base_branch}`）」
2. 使用者回答後（或接受預設），flow 將結果作為 `merge_target` 傳入 ship agent
3. Ship agent 收到 `merge_target` 後非互動執行

> **為什麼不讓 ship agent 問？** 為保持 ship agent 非互動且確定性，所有使用者決策由 flow 在啟動 agent 前取得。

#### Ship 執行流程

```
1. 確認有未提交變更 → git add + git commit（若有）
2. git push -u origin <branch_name>
3. git checkout <merge_target>     # 切到使用者指定的目標分支
4. git pull origin <merge_target>  # 同步最新
5. git merge <branch_name>         # 合併（保留分支歷史）
6. git push origin <merge_target>  # 推送目標分支
7. git checkout <branch_name>      # 切回工作分支
8. 寫 handoffs/<slug>-ship.md
```

#### Ship Handoff 格式

```markdown
# Handoff: ship

## Stage
ship

## Inputs Used
- handoffs/<slug>-review.md
- git_context

## Push Result
- Branch: feature/main_hap3621_approval_workflow
- Remote: origin
- Status: success

## Merge Result
- Target: et
- Method: git merge（preserve history）
- Status: success
- Merge commit: <hash>

## Commits Shipped
| Hash | Stage | Message |
|------|-------|---------|
| abc1234 | build-phase-05 | [HAP-3621] feat(approval): add API (phase-05) |
| bcd2345 | build-phase-06 | [HAP-3621] feat(approval): add frontend (phase-06) |
| ... | ... | ... |

## Gate Verdict
PASS — pushed and merged to et

## Risks / Unresolved Issues
None

## Next Recommended Stage
(end of flow)
```

#### 失敗處理

| 狀況 | 處理 |
|------|------|
| push 失敗（remote rejected） | 報告錯誤，詢問使用者處理 |
| merge conflict | 報告衝突檔案，**不 force merge**，交給使用者 |
| 目標分支不存在 | 報告錯誤，列出可用的遠端分支 |

### review-ship（Lightweight 合併 Stage）

Lightweight 路由（`PASS-DIRECT-BUILD`、`PASS-BUILD-WITH-VERIFY`）中，
review 和 ship 由**同一個 fresh agent** 執行，產出合併的 handoff。

| 項目 | 說明 |
|------|------|
| **職責** | 程式碼審查 + 推送分支 + 合併到目標環境 |
| **執行方式** | 單一 fresh agent，先 review 再 ship |
| **輸入** | PASS-DIRECT-BUILD: `handoffs/<slug>-build.md`；PASS-BUILD-WITH-VERIFY: `handoffs/<slug>-build.md` + `handoffs/<slug>-verify.md`。加上 flow context `git_context` + `merge_target`（flow 傳入） |
| **必要輸出** | `handoffs/<slug>-review-ship.md`（Compact 格式） |
| **Gate 條件** | Review 通過 + push 成功 + merge 成功 |

#### review-ship Agent Prompt

```
你正在以 Lightweight 模式執行 Review + Ship。

讀取：
1. .athena/skills/<review-skill>/SKILL.md（review 規則）
2. .athena/skills/<ship-skill>/SKILL.md（ship 規則）
3. handoffs/<slug>-build.md（或 handoffs/<slug>-verify.md，若有 verify）
4. flow context: git_context, merge_target

流程：
1. 先執行 code review（依據 review skill）
2. Review 通過後，執行 ship：push + merge to <merge_target>
3. 寫 handoffs/<slug>-review-ship.md（Compact 格式）
```

#### Review 不通過時

若 review 部分判定為 `request-changes`：
- Agent **停止 ship**，不執行 push/merge
- 寫 `handoffs/<slug>-review-ship.md`，Gate Verdict = FAIL，附上 review 意見
- Flow 讀取 FAIL → 報告使用者，不自動 retry

#### review-ship Handoff 格式

見 `agent-handoff.md`「Compact Review-Ship Handoff」段落。

---

## Handoff 契約（通用）

無論哪個 standard stage，handoff artifact 都必須包含以下欄位：

```markdown
# Handoff: <stage-name>

## Stage
<stage 名稱>

## Inputs Used
<列出讀取了哪些前置 artifact>

## Artifacts Produced
<列出產出的檔案路徑>

## Gate Verdict
<PASS / FAIL + 原因>

## Risks / Unresolved Issues
<未解決的風險或問題>

## Next Recommended Stage
<建議的下一個 stage>
```

> **Flow-inline stage 不產出 handoff artifact**，改用 flow context 傳遞資訊。

## Agent 隔離原則

**Standard stage：每個 stage 都由全新的 agent 執行，不共享上下文。**

- 你的 skill 會在一個乾淨的 agent 中被載入，沒有前一個 stage 的對話歷史
- 所有前置資訊都必須從 handoff artifact 讀取，不得假設 agent 記得任何東西
- 這是為了避免 context window 過大以及前一階段的推理污染

**Flow-inline stage：在 flow agent 中內聯執行，共享 flow context。**

- Flow-inline skill 被 flow agent 讀取後直接執行
- 可存取 flow context（git_context 等），不需要 handoff artifact
- 輕量級操作，不產生大量 context 污染

因此，skill 的設計必須：
1. Standard stage：在「先讀哪些檔」明確列出所有需要的 artifact 路徑
2. Flow-inline stage：明確列出需要讀取的 reference 與 flow context 欄位
3. 不引用任何「上一步」的對話內容
4. 所有判斷依據都來自檔案或 flow context，不來自記憶

## 規則

1. Skill 必須在 SKILL.md frontmatter 宣告 `stage` 欄位
2. Skill 的輸出必須符合該 stage 契約的「必要輸出」
3. Standard stage 必須產出 handoff artifact 到 `handoffs/` 目錄
4. Flow-inline stage 必須更新 flow context
5. Handoff artifact 必須包含上述通用欄位
6. **Standard stage 必須由全新的 agent 執行**——不得讓同一個 agent 處理多個 standard stage（**例外**：Lightweight 路由的 review-ship 可合併為一個 agent）
7. **Flow-inline stage 在 flow agent 中執行**——不開 fresh agent
8. Skill 不得假設自己能存取前一個 stage 的對話脈絡——一切靠 artifact 或 flow context
