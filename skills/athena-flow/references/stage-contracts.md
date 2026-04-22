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

### build

| 項目 | 說明 |
|------|------|
| **職責** | 根據計畫執行實作（後端/前端/全端） |
| **輸入** | `handoffs/<slug>-plan.md` + `plans/<slug>/` 下的 phase 卡片 |
| **必要輸出** | 可編譯/可執行的程式碼變更 |
| **Handoff** | `handoffs/<slug>-build.md`，包含變更檔案列表、建置狀態 |
| **Gate 條件** | 建置成功（exit code 0） |

---

### post-build（Flow-Inline）

| 項目 | 說明 |
|------|------|
| **職責** | Stage gate 通過後自動提交 Git commit |
| **執行方式** | Flow agent 內聯執行（不開 fresh agent） |
| **Plugin 預設** | `athena-post-build`（團隊可替換） |
| **觸發時機** | build gate PASS 後 + verify gate PASS 後（各觸發一次） |
| **輸入** | flow context 的 `git_context` + 對應的 handoff artifact + `triggering_stage` 參數 |
| **必要輸出** | flow context 的 `git_context.commits` 陣列追加新 commit |
| **交接方式** | Flow context（不產出 handoff artifact） |
| **Gate 條件** | 無 gate — commit 成功或無變更皆繼續 |

#### 觸發參數

| 觸發點 | `triggering_stage` | 預設 commit type |
|--------|---------------------|------------------|
| build gate PASS 後 | `build` | `feat` / `fix` |
| verify gate PASS 後 | `verify` | `test` |

#### Flow Context 輸出格式

```yaml
git_context:
  commits:
    - hash: "abc1234"
      stage: "build"
      message: "[HAP-3621] feat(member): add member export API"
      files_committed: 12
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
| **職責** | 部署、發布、收尾 |
| **輸入** | `handoffs/<slug>-review.md` + 所有先前 artifacts + flow context 的 `git_context` |
| **必要輸出** | 部署確認（commit hash、PR URL、部署狀態等） |
| **Handoff** | `handoffs/<slug>-ship.md`，包含部署結果 |
| **Gate 條件** | 部署成功 |

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
6. **Standard stage 必須由全新的 agent 執行**——不得讓同一個 agent 處理多個 standard stage
7. **Flow-inline stage 在 flow agent 中執行**——不開 fresh agent
8. Skill 不得假設自己能存取前一個 stage 的對話脈絡——一切靠 artifact 或 flow context
