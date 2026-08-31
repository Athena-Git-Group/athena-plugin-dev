# Stage Contracts

## 概述

每個可替換的 stage 都有一份契約，定義該 stage 的**輸入**（從前一個 stage 的 handoff 讀取什麼）和**輸出**（必須產出什麼 artifact 給下一個 stage）。下游團隊上繳到 `.athena/skills/` 的 skill 必須遵守對應契約，才能被 `athena-flow` 正確編排。

**不可替換的 stage**：`point`（`athena-point`，流程閘門）與 `flow`（`athena-flow`，編排器本身）由 plugin 自身控制，不開放替換。其餘 stage 分兩類：**Standard Stage**（fresh agent 執行）與 **Flow-Inline Stage**（flow agent 內聯執行）。

## Weight Class 路由

Flow 根據 point verdict 決定流程重量等級，影響 Build 模式、Handoff 格式與 agent 數量（stage 順序圖見 SKILL.md「Stage 順序」）：

| Verdict | Weight | Build 模式 | Handoff 模式 | Agent 數量 |
|---------|--------|-----------|-------------|-----------|
| `PASS-TRIVIAL` | Minimal | 單 agent + self-review | Compact | 2（point + build）— 無 verify / review / ship agent |
| `PASS-DIRECT-BUILD` | Lightweight | 單 agent，無 phase loop | Compact | 3（point + build + review-ship 合併 agent） |
| `PASS-BUILD-WITH-VERIFY` | Lightweight | 單 agent，無 phase loop | Compact | 4（point + build + verify + review-ship 合併 agent） |
| `PASS-SPEC-FIRST` | Full | Phase loop（依賴 plan.md） | Standard | 7+N（完整流程；review 與 ship 各自獨立 agent） |

### Skill Resolution

- **Standard stage**：依 Skill Discovery 對應表找 `.athena/skills/<skill-dir>/SKILL.md`。找到 → 開 fresh agent 載入執行；找不到 → 停止流程，輸出引導訊息。
- **Flow-inline stage**（pre-build / post-build）：先掃 `.athena/skills/`，找不到就用 plugin 預設（`athena-pre-build` / `athena-post-build`），**不停止流程、不引導補齊**。Git 命名規範由 `git-conventions` skill 提供。

### Named Subagent 殼

Plugin 在 `agents/` 提供 per-stage subagent 殼（`athena-point`、`athena-stage-spec`、`athena-stage-plan`、`athena-stage-build`、`athena-stage-verify`、`athena-stage-review`、`athena-stage-ship`），每個都帶階段化的 tool scope。Flow 啟動 standard stage 時應呼叫 `Agent(subagent_type: "athena-stage-<stage>")` 取代 generic Agent，讓 harness 強制工具邊界；團隊 skill 仍是邏輯來源，subagent 只是權限殼。**review-ship 合併 stage 用 `athena-stage-ship` 殼**——不存在 `athena-stage-review-ship` 殼，複用工具最寬的 ship 殼（其 Read/Grep/Bash 足以做 review、Bash(push/merge) 做 ship），prompt 中同時傳入 team review skill 與 ship skill。若 subagent 因 tool scope 擋掉合理操作，回報給使用者並擴充殼的 `tools` 欄位，不要繞道。

## Skill Discovery（flow 啟動時執行）

1. 掃描 `.athena/skills/` 下所有子目錄，讀取每個 `SKILL.md` frontmatter 的 `stage` 欄位，建立 stage → skill 對應表
2. 檢查**路由需要經過的** standard stage 是否都有對應 skill（缺少 → 停止＋引導，訊息見下）
3. 檢查 flow-inline stage 是否有團隊版本（有則用團隊的，無則用 plugin 預設；不停止、不引導補齊）
4. 兩個以上 skill 宣告相同 `stage` → 停止報錯（訊息見下）

各路由所需 standard skill（只檢查路由會經過的 stage）：

| 路由 | 需要的 standard skill |
|------|----------------------|
| Minimal（PASS-TRIVIAL） | build（不需要 review、ship） |
| Lightweight / PASS-DIRECT-BUILD | build + review + ship（review-ship 合併執行） |
| Lightweight / PASS-BUILD-WITH-VERIFY | build + verify + review + ship（review-ship 合併執行） |
| Full（PASS-SPEC-FIRST） | spec + plan + build + verify + review + ship |

### 對應表範例

```
# Standard stages（團隊提供）
spec   → .athena/skills/my-team-spec/SKILL.md
plan   → .athena/skills/my-team-plan/SKILL.md
build  → .athena/skills/my-team-build-index/SKILL.md
verify → .athena/skills/my-team-verify/SKILL.md
review → .athena/skills/my-team-review/SKILL.md
ship   → .athena/skills/my-team-ship/SKILL.md

# Flow-inline stages（團隊替換或 plugin 預設）
pre-build  → .athena/skills/my-team-pre-build/SKILL.md  # 團隊有提供
post-build → athena-post-build/SKILL.md                  # 使用 plugin 預設
```

### 缺少 Standard Skill 時的引導訊息

停止流程，逐字輸出 `templates/msg-missing-skill.md` 的訊息全文（輸出那一刻才讀該檔）。

### 重複 Stage 綁定的報錯訊息

停止流程，逐字輸出 `templates/msg-stage-conflict.md` 的訊息全文（輸出那一刻才讀該檔）。

---

### pre-build（Flow-Inline）

| 項目 | 說明 |
|------|------|
| **職責** | Build 前的準備操作（建立 Git 分支並切換） |
| **執行方式** | Flow agent 內聯執行（不開 fresh agent） |
| **Plugin 預設** | `athena-pre-build`（團隊可替換） |
| **輸入** | `points/<slug>.md` 中的 slug、verdict、任務性質 |
| **必要輸出** | flow context 的 `git_context`（branch_created、branch_name、base_branch、ticket） |
| **交接方式** | Flow context（不產出 handoff artifact） |
| **Gate 條件** | 無 gate — 分支建立成功即繼續 |
| **失敗處理** | 分支已存在 → 切換到該分支而非重建；有未提交變更 → 先 stash |

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
| **必要輸出** | `plans/<slug>/plan.md`（含 Dependency Graph，frontmatter 每個 phase 含 `touches` 所有權宣告：`files` glob + `resources`）+ Phase 卡片 |
| **Handoff** | `handoffs/<slug>-plan.md`，包含計畫路徑、phase 列表 |
| **Gate 條件** | plan.md 存在且 Dependency Graph 完整，並已通過 `validate_plan.py --require-touches`（可平行 pair 的 touches 互斥） |

### build（Minimal / Lightweight — 單一 agent）

兩種 Weight 的 Build 都是**單一 fresh agent、不跑 phase loop**，無需 plan.md、phase card、mini-handoff。

| 項目 | 共通說明 |
|------|---------|
| **職責** | 根據 point-report 完成所有實作 |
| **輸入** | `points/<slug>.md`（point-report）+ 實際程式碼 |
| **必要輸出** | `handoffs/<slug>-build.md`（Compact 格式，agent 直接寫，非合成） |
| **Smoke Test** | Agent 自行執行（從 point-report 推斷合理的驗證指令） |
| **Commit** | 單次 post-build commit |

| 差異 | Minimal（PASS-TRIVIAL） | Lightweight（PASS-DIRECT-BUILD / PASS-BUILD-WITH-VERIFY） |
|------|------------------------|------------------------------------------------------|
| **Self-Review** | 寫 handoff 前執行 checklist（見 prompt），任一項不過 → Gate FAIL，flow 停下來報告使用者 | 無 |
| **`triggering_stage`** | `build-minimal` | `build-lightweight` |
| **Gate 條件** | Smoke test 通過 + self-review 全部通過 | Smoke test 通過 |
| **Handoff 變體** | `agent-handoff.md` 差異表 **Minimal build** 列 | 差異表 **Compact build** 列 |
| **後續** | commit 後 flow 輸出 push 指令直接結束——不開 review-ship agent，由使用者自行 push（見下方「Minimal 結束輸出」） | verify（僅 PASS-BUILD-WITH-VERIFY）→ review-ship |

#### Minimal 結束輸出

Build gate PASS + post-build commit 完成後，逐字輸出 `templates/msg-minimal-done.md`
的訊息全文（輸出那一刻才讀該檔）——訊息**先輸出**，run 收尾（emit trace + GC）在其之後執行。

#### Build Agent Prompt（單一 agent 模式，Minimal / Lightweight 共用）

prompt 全文見 `templates/prompt-build-single.md`（spawn 那一刻才讀該檔；
含 Minimal self-review checklist 四項）。

### build（Phase Loop — Full Weight）

Build 不再是單一 agent 執行的 opaque stage。Flow 讀取 `plan.md` 的 Dependency Graph，將 implementation phases 拆解為 phase loop。詳見 `phase-orchestration.md`。

| 項目 | 說明 |
|------|------|
| **職責** | 根據計畫執行實作（後端/前端/全端），以 phase 為單位 |
| **輸入** | `handoffs/<slug>-plan.md` + `plans/<slug>/plan.md`（YAML frontmatter = Dependency Graph 機械真相）+ `plans/<slug>/todo/` 的 phase 卡（執行時 flow mv 至 `doing/`，gate PASS 後 mv 至 `done/`） |
| **執行方式** | Flow 驅動的 phase loop — 每個 phase 由 fresh agent 執行 |
| **Phase 輸出** | 每個 phase 寫 `handoffs/<slug>-build-phase-<NN>.md`（mini-handoff） |
| **Phase Gate** | 每個 phase agent 執行 smoke test，結果寫入 mini-handoff |
| **Phase Commit** | 每個 phase gate PASS 後，flow 執行 post-build commit（per-phase，不合併多個 phase 的變更） |
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

Dependency Graph 中無相互依賴的 phase 可同時啟動；平行 phase 完成後進行 conflict detection。詳見 `phase-orchestration.md`。

### post-build（Flow-Inline）

| 項目 | 說明 |
|------|------|
| **職責** | Stage gate 通過後自動提交 Git commit |
| **執行方式** | Flow agent 內聯執行（不開 fresh agent） |
| **Plugin 預設** | `athena-post-build`（團隊可替換） |
| **輸入** | flow context 的 `git_context` + 對應的 mini-handoff 或 handoff artifact + `triggering_stage` 參數（Full per-phase 觸發另附 `phase_number`、`phase_name`） |
| **必要輸出** | flow context 的 `git_context.commits` 陣列追加新 commit |
| **交接方式** | Flow context（不產出 handoff artifact） |
| **Gate 條件** | 無 gate — commit 成功或無變更（記錄 `no_changes`）皆繼續 |

#### 觸發參數

| 觸發點 | `triggering_stage` | 預設 commit type |
|--------|---------------------|------------------|
| Minimal build gate PASS 後 | `build-minimal` | `feat` / `fix` |
| Lightweight build gate PASS 後 | `build-lightweight` | `feat` / `fix` |
| 每個 build phase gate PASS 後（Full） | `build-phase-<NN>` | `feat` / `fix` |
| verify gate PASS 後（若 verify 無程式碼變更則跳過） | `verify` | `test` |
| Lightweight verify fix 完成後（PASS-BUILD-WITH-VERIFY） | `verify-fix-lightweight` | `fix` |
| Full verify fix（targeted re-build）完成後 | `verify-fix-phase-<NN>` | `fix` |

#### Flow Context 輸出格式

```yaml
git_context:
  commits:
    - hash: "abc1234"
      stage: "build-phase-05"
      message: "[HAP-3621] feat(member): add member export API (phase-05)"
      files_committed: 5
```

此 context 可傳遞給 review / ship stage 的 handoff，讓下游 skill 知道有哪些 commits。

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

**FAIL（request-changes）處理**（Full 路由）：Gate Verdict 的機器值為 FAIL、tag = `#review-finding`（格式見 `agent-handoff.md`）；flow 讀到 FAIL → **停止流程**，報告 review 意見給使用者，**不自動 retry**。PASS → flow 詢問使用者 merge_target 後才開 ship agent。

### ship

| 項目 | 說明 |
|------|------|
| **職責** | 推送分支、合併到目標環境 |
| **輸入** | `handoffs/<slug>-review.md` + flow context 的 `git_context` + **`merge_target`（flow 傳入）** |
| **必要輸出** | push 確認、merge 結果、目標分支狀態 |
| **Handoff** | `handoffs/<slug>-ship.md`（格式見 `agent-handoff.md` 差異表 **Ship** 列），包含 push/merge 結果 |
| **Gate 條件** | push 成功 + merge 成功 |

**merge_target 來源**：Ship agent **不詢問使用者**——為保持 ship agent 非互動且確定性，所有使用者決策由 flow 在啟動 agent 前取得。Flow 先問使用者「要合到哪個分支？（預設：`{git_context.base_branch}`）」，將答案作為 `merge_target` 傳入。

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

#### 失敗處理

| 狀況 | 處理 |
|------|------|
| push 失敗（remote rejected） | 報告錯誤，詢問使用者處理 |
| merge conflict | 報告衝突檔案，**不 force merge**，交給使用者 |
| 目標分支不存在 | 報告錯誤，列出可用的遠端分支 |

### review-ship（Lightweight 合併 Stage）

Lightweight 路由中，review 和 ship 由**同一個 fresh agent** 執行，產出合併的 handoff。

| 項目 | 說明 |
|------|------|
| **職責** | 程式碼審查 + 推送分支 + 合併到目標環境 |
| **執行方式** | 單一 fresh agent，先 review 再 ship |
| **輸入** | PASS-DIRECT-BUILD: `handoffs/<slug>-build.md`；PASS-BUILD-WITH-VERIFY: `handoffs/<slug>-build.md` + `handoffs/<slug>-verify.md`。加上 flow context `git_context` + `merge_target`（flow 傳入） |
| **必要輸出** | `handoffs/<slug>-review-ship.md`（Compact 格式，見 `agent-handoff.md` 差異表 **Review-ship** 列） |
| **Gate 條件** | Review 通過 + push 成功 + merge 成功 |

#### review-ship Agent Prompt

prompt 全文見 `templates/prompt-review-ship.md`（spawn 那一刻才讀該檔）。

**Review 不通過時**（`request-changes`）：Agent **停止 ship**，不執行 push/merge；寫 handoff 並標 Gate Verdict = FAIL、附 review 意見；flow 讀取 FAIL → 報告使用者，不自動 retry。

---

## Handoff 契約與隔離原則（通用）

- 無論哪個 standard stage，handoff artifact 都必須包含 Base 模板的六欄——模板全文、mini-handoff 模板與機械契約見 `agent-handoff.md`；**Flow-inline stage 不產出 handoff artifact**，改用 flow context 傳遞資訊
- **Standard stage 由全新 agent 執行，不共享上下文**：skill 在乾淨 agent 中被載入，沒有前一個 stage 的對話歷史，所有前置資訊必須從 handoff artifact 讀取（避免 context 過大、避免前階段推理污染、讓團隊可替換任意 stage 實作）；**Flow-inline stage 在 flow agent 中內聯執行，共享 flow context**——輕量操作不值得 fresh agent 的成本
- Skill 設計要求：Standard stage 在「先讀哪些檔」明確列出所有 artifact 路徑；Flow-inline stage 明確列出需要的 reference 與 flow context 欄位；所有判斷依據來自檔案或 flow context，不引用「上一步」的對話內容

## 規則

1. Skill 必須在 SKILL.md frontmatter 宣告 `stage` 欄位；輸出必須符合該 stage 契約的「必要輸出」（Standard stage 產出含通用六欄的 handoff 到 `handoffs/`，Flow-inline stage 更新 flow context）
2. 隔離與交接、gate PASS 才 commit、只有 Ship 可 push：依上方隔離原則與 flow `SKILL.md` 非協商規則 1、2、5、6（唯一合併例外：Lightweight 的 review-ship）
3. **Git hook 失敗不阻斷流程** — git 操作失敗時記錄警告，stage 流程繼續（除非使用者設定 strict mode）
4. **Git 操作冪等** — 分支已存在就切換，commit 無變更就跳過
