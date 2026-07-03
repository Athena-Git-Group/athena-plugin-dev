---
name: athena-flow
description: >
  Athena 單一入口流程編排器。讓使用者只輸入一次指令，就能依 point -> spec -> plan ->
  build -> verify -> review -> ship 的 gate 串接流程自動往下走。每一個 stage 都必須用
  全新的 agent 執行，以避免 context 過大與污染。當使用者說「一鍵跑流程」「flow」、
  「自動接續執行」「每階段新 agent」時觸發。
---

# Athena Flow

你是 Athena 的流程總控，不直接承接整條任務的實作細節。你的責任是：

1. 接收單一需求輸入
2. **發現 skill**：掃描 `.athena/skills/` 找出團隊上繳的 skill
3. 判斷從哪個 stage 開始
4. 為每個 standard stage 啟動全新的 agent，載入對應的團隊 skill
5. 在 flow agent 中內聯執行 flow-inline stage
6. 等待 stage 完成後讀取 handoff artifact
7. 根據 gate 決定下一個 stage

## 先讀哪些檔

- Read `references/stage-orchestration.md`
- Read `references/agent-handoff.md`
- Read `references/stage-contracts.md`
- Read `references/index-skill-pattern.md`
- Read `references/git-lifecycle-hooks.md` — Git 操作的觸發時機
- Read `references/phase-orchestration.md` — Build 內部的 phase loop 編排
- Read `references/verify-retry.md` — Verify 失敗的回退流程
- Read `references/flow-context.md` — Hook 模式的 marker file schema
- Read `references/run-trace.md` — Run Trace schema + Failure Taxonomy + Handoff GC（強制收尾步驟）

## 核心原則

### 單一入口

使用者只需要輸入一次 `/flow` 指令。

### 階段隔離

每個 standard stage 必須由全新的 agent 執行，不沿用上一個 stage 的 agent。

> **Named subagent**: Plugin 在 `agents/` 提供 per-stage subagent 殼
> （`athena-point`、`athena-stage-spec`、`athena-stage-plan`、`athena-stage-build`、
> `athena-stage-verify`、`athena-stage-review`、`athena-stage-ship`），每個都帶
> 階段化的 tool scope。Flow 啟動 standard stage 時應呼叫
> `Agent(subagent_type: "athena-stage-<stage>")` 取代 generic Agent，讓 harness
> 替你強制工具邊界。團隊 skill 仍是邏輯來源，subagent 只是權限殼。
> 若 subagent 因 tool scope 擋掉合理操作，回報給使用者並擴充殼的 `tools`
> 欄位，不要繞道。

### Flow-Inline Stage

flow-inline stage（pre-build、post-build）在 flow agent 中直接執行，不開 fresh agent。
適用於輕量級的跨 stage 輔助操作。

### 交接靠 artifact，不靠記憶

上一個 stage 的輸出必須寫成可讀的 artifact 或 handoff note，下一個 stage 再讀它。
不得假設 agent 會記得前一階段的對話脈絡。
Flow-inline stage 透過 flow context 傳遞資訊。

### Skill 可替換

除了 `point` 和 `flow` 之外，所有 stage 的執行 skill 由團隊在 `.athena/skills/` 中提供。

- **Standard stage**（spec、plan、build、verify、review、ship）：團隊必須提供，缺少時停止流程
- **Flow-inline stage**（pre-build、post-build）：Plugin 提供預設，團隊可選擇性替換

## Stage 順序

Flow 根據 point verdict 決定兩種路線（詳見 `stage-orchestration.md` Weight Class）：

```text
Minimal（PASS-TRIVIAL）:
/point → [pre-build] → /build (minimal, with self-review) → [post-build] → done

Lightweight（PASS-DIRECT-BUILD / PASS-BUILD-WITH-VERIFY）:
/point → [pre-build] → /build (single agent) → [post-build] → [/verify → post-build] → /review-ship

Full（PASS-SPEC-FIRST）:
/point → /spec → /plan → [pre-build] → /build (phase loop) → /verify → [post-build] → /review → /ship
                                              │
                                              ├── phase-05 agent → [post-build] commit
                                              ├── phase-06 agent → [post-build] commit
                                              └── phase-07 agent → [post-build] commit
```

> `[括號]` 表示 flow-inline stage 或依路由可選的 stage。
> Build 內部的 phase loop 僅在 Full 路線使用。詳見 `phase-orchestration.md`。

## Skill Discovery（啟動時執行）

進入流程前，先掃描團隊上繳的 skill：

1. 掃描 `.athena/skills/` 下所有子目錄
2. 讀取每個子目錄的 `SKILL.md` frontmatter
3. 提取 `stage` 欄位，建立 stage → skill 的對應表
4. 檢查 **standard stage** 是否都有對應 skill（缺少則停止 + 引導）
5. 檢查 **flow-inline stage** 是否有團隊版本（有則用團隊的，無則用 plugin 預設）

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

### Flow-Inline Stage Discovery 規則

```
1. 掃描 .athena/skills/ 尋找 stage: pre-build 或 stage: post-build
2. 若找到 → 使用團隊的 skill
3. 若未找到 → 使用 plugin 預設（skills/athena-pre-build/ 或 skills/athena-post-build/）
4. 不停止流程，不引導團隊補齊
```

### 缺少 Standard Skill 時的引導

如果某個 standard stage 沒有找到對應的 skill，**停止流程**並輸出引導訊息：

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

只有當路由需要經過的 standard stage 都有 skill 時，才繼續往下走。
例如 `PASS-DIRECT-BUILD` 需要 build + review + ship，不需要 spec、plan、verify。

### 重複 Stage 綁定

如果兩個以上的 skill 宣告了相同的 `stage`，**停止流程**並報錯：

```
⚠️ Stage 衝突：build 被多個 skill 宣告

- .athena/skills/team-build-api/SKILL.md → stage: build
- .athena/skills/team-build-web/SKILL.md → stage: build

同一個 stage 只能有一個 skill。如果需要多個流程，請建立 index skill 作為路由。
詳見：athena-dev-plugin/skills/athena-flow/references/index-skill-pattern.md
```

## 執行方式

1. 執行 **Skill Discovery**，建立 stage → skill 對應表（含 flow-inline fallback）
2. 用 fresh agent 執行 `/point`（plugin 內建）
3. 讀取 point-report
4. 根據 verdict 決定路由與 **Weight Class**（詳見 `stage-orchestration.md`）：

   **Minimal 路由：**
   - `PASS-TRIVIAL` → pre-build → build(minimal, with self-review) → post-build → done

   **Lightweight 路由：**
   - `PASS-DIRECT-BUILD` → pre-build → build(lightweight) → post-build → review-ship
   - `PASS-BUILD-WITH-VERIFY` → pre-build → build(lightweight) → verify → post-build → review-ship

   **Full 路由：**
   - `PASS-SPEC-FIRST` → spec → plan → pre-build → build(phase loop) → verify → post-build → review → ship

5. 檢查路由上所有 standard stage 都有對應 skill，缺少則引導
   - Minimal（PASS-TRIVIAL）需要：build（不需要 review、ship）
   - Lightweight / PASS-DIRECT-BUILD 需要：build + review + ship（review-ship 合併執行）
   - Lightweight / PASS-BUILD-WITH-VERIFY 需要：build + verify + review + ship（review-ship 合併執行）
   - Full（PASS-SPEC-FIRST）需要：spec + plan + build + verify + review + ship
6. **執行 pre-build**（flow-inline）：
   a. 讀取 pre-build skill（團隊版或 plugin 預設）
   b. 在 flow agent 中內聯執行
   c. 從 point-report 取得 slug、verdict 推斷 branch type
   d. 建立分支並切換
   e. 將 `git_context` 存入 flow context
7. 對 **spec、plan** 等非 build 的 standard stage：
   a. 開新 agent
   b. 讓 agent 讀取對應 skill 的 `SKILL.md`
   c. 讓 agent 讀取前一個 stage 的 handoff artifact
   d. 執行 skill
   e. 確認 handoff artifact 已寫入
8. **Build stage**（分三種模式）：

   **8-M. Minimal Build**（PASS-TRIVIAL）：
   a. 開一個 fresh agent，載入 build skill
   b. 讓 agent 讀取 `points/<slug>.md`（point-report）
   c. Agent 完成實作 → 執行 smoke test → 執行 **self-review checklist** → 寫 `handoffs/<slug>-build.md`（Compact 格式，含 self-review 結果）
   d. Flow 讀取 build handoff 的 Gate Verdict
   e. PASS → 執行 **post-build**（flow-inline，`triggering_stage: build-minimal`）→ 單次 commit → **跳到步驟 11（Minimal 結束）**
   f. FAIL → 報告使用者

   **8-L. Lightweight Build**（PASS-DIRECT-BUILD / PASS-BUILD-WITH-VERIFY）：
   a. 開一個 fresh agent，載入 build skill
   b. 讓 agent 讀取 `points/<slug>.md`（point-report）
   c. Agent 完成所有實作 → 執行 smoke test → 寫 `handoffs/<slug>-build.md`（Compact 格式）
   d. Flow 讀取 build handoff 的 Gate Verdict
   e. PASS → 執行 **post-build**（flow-inline，`triggering_stage: build-lightweight`）→ 單次 commit
   f. FAIL → 報告使用者

   **8-F. Full Build — Phase Loop**（PASS-SPEC-FIRST，詳見 `phase-orchestration.md`）：
   a. 讀取 `plans/<slug>/plan.md` 的 Dependency Graph
   b. 識別狀態為 `todo` 的 implementation phases
      > **Dedup**: 若最後一個 phase 是純驗證且 verify stage 在路由中，跳過該 phase（見 `phase-orchestration.md` Verification Phase Dedup）
   c. 按依賴順序（或平行）對每個 phase：
      i. 開 fresh agent
      ii. 載入 build skill + phase card + 前一個 phase 的 mini-handoff + 指定的 spec sections
      iii. Agent 執行實作 → smoke test → 寫 mini-handoff
      iv. Flow 讀 mini-handoff 的 Gate Verdict
      v. PASS → 執行 **post-build**（flow-inline，`triggering_stage: build-phase-<NN>`）→ commit
      vi. FAIL → phase retry（最多 2 輪，詳見 `phase-orchestration.md`）
   d. **可平行的 phase 必須在同一次回應內全部送出 Agent 呼叫**：
      - ≤ 2 個可平行 phase 用 foreground 平行（多個 `Agent` tool calls 在同一回應）
      - ≥ 3 個或時間落差大用 background 平行（`Agent(run_in_background: true)` + harness 完成通知）
      - **平行集 ≥ 2 一律帶 `isolation: "worktree"`**（每個 phase agent 獨立 git worktree）。
        prompt 必須注入主樹絕對路徑——雙路徑規則：code 走 worktree cwd、artifact
        （phase 卡 / spec / mini-handoff）一律走主樹絕對路徑。phase agent 無論 gate 結果
        都 commit 到 worktree 分支（PASS 正常格式、FAIL 用 `wip:` 前綴）並在 mini-handoff
        回報 `Worktree Branch:`；選項不可用時走 fallback 鏈（手動 worktree 協議 →
        shared-tree），序列 phase 不用 worktree——詳見 `phase-orchestration.md`「Worktree 隔離」
      - 啟動前用 `TaskCreate` 為每個 phase 建立 task 作為 UX 投影，完成通知到達時 `TaskUpdate`
      - 不在 flow agent 內 `sleep` 輪詢，背景模式靠 harness 通知
   e. 所有可平行 phase 完成後再做 conflict detection（兩層）；衝突就停。
      - **worktree 模式**：通過後 flow 在主樹按拓撲序對各 `Worktree Branch:` 執行
        `git merge --no-ff`（**只 merge latest gate = PASS 的分支**），成功後 `git branch -d`；
        merge conflict 是第三層安全網，停止交使用者，不自動解；下游 phase 一律等上游
        平行集全部 merge-back 完成後才 spawn，不提早觸發（詳見 `phase-orchestration.md`）
      - **shared-tree 模式**：無衝突才依序 commit（原行為）
   f. 所有 phase 完成 → 合成 `handoffs/<slug>-build.md`
9. **Verify stage**（跳過 `PASS-DIRECT-BUILD`，該路由無 verify）：
   a. 開新 agent 執行 verify skill
   b. Agent 讀取 `handoffs/<slug>-build.md` + 實際程式碼（Full Weight 另讀所有 mini-handoff）
   c. 若 PASS → 執行 post-build commit（`triggering_stage: verify`）→ 繼續
   d. 若 FAIL：
      - **Full Weight** → **Verify Retry**（詳見 `verify-retry.md`）：
        i. 解析 issues 的 affected_phase
        ii. 對每個 broken phase 開 fresh agent 修復
        iii. 修復後 commit（`triggering_stage: verify-fix-phase-<NN>`）
        iv. 重新合成 build handoff → 完整 re-verify
        v. 最多 2 輪，超過交給使用者
      - **Lightweight** → 開 fresh build agent（repair mode），修復所有 issues → post-build commit（`triggering_stage: verify-fix-lightweight`）→ re-verify，最多 2 輪
10. **Review + Ship stage**（分兩種模式）：

    **10-L. Lightweight Review-Ship**（PASS-DIRECT-BUILD / PASS-BUILD-WITH-VERIFY）：
    a. **Flow 先詢問使用者**：「要合到哪個分支？（預設：`{git_context.base_branch}`）」
    b. 使用者確認後，開一個 fresh agent 同時執行 review + ship。
       **殼用 `athena-stage-ship`**（不存在 `athena-stage-review-ship` 殼；review-ship 是合併
       stage，複用工具最寬的 ship 殼——其 Read/Grep/Bash 足以做 review、Bash(push/merge) 做 ship）。
       在 prompt 中同時傳入 team review skill 與 ship skill。
    c. Agent 先讀取 review skill 執行 code review
    d. Review 通過後，讀取 ship skill 執行 push + merge（使用 flow 傳入的 `merge_target`）
    e. 寫 `handoffs/<slug>-review-ship.md`（Compact 格式）

    **10-F. Full Review + Ship**（PASS-SPEC-FIRST）：
    a. 開新 agent 執行 review skill → 寫 `handoffs/<slug>-review.md`
    b. Flow 讀取 review Gate Verdict（格式見 `agent-handoff.md`；review 的機器值為 FAIL，tag=`#review-finding`）：
       - FAIL (request-changes) #review-finding → 停止流程，報告 review 意見給使用者，不自動 retry
       - PASS → 繼續
    c. **Flow 詢問使用者**：「要合到哪個分支？（預設：`{git_context.base_branch}`）」
    d. 使用者確認後，開新 agent 執行 ship skill，傳入 `merge_target`
    e. Ship agent 非互動執行 push + merge
    f. 寫 `handoffs/<slug>-ship.md`

11. **Minimal 結束**（僅 PASS-TRIVIAL）：

    Build gate PASS + post-build commit 完成後，flow **不開任何 review/ship agent**，直接輸出：

    ```
    ✅ Done — build + self-review passed.

    Committed: <commit_hash> on <branch_name>

    When ready to push:
      git push -u origin <branch_name>
    ```

    流程結束前仍執行步驟 12（emit trace + GC handoff）。不寫 review-ship handoff，不問 merge_target。

12. **Run 收尾 — Emit Trace + Handoff GC（所有路由的強制步驟，flow-inline）**：

    無論流程以 `shipped` / `done` / `stopped@<stage>` / `handed-to-human` 何種結局結束，
    flow 在最終回報使用者前，於 flow agent 內聯執行（不開 agent）：

    a. 蒐集本次 run 的 trace 欄位（trigger、point verdict/score/dimensions、weight、route、
       各 stage 的 gate/retries/agents、failures[]（含 taxonomy tag）、human_interventions、outcome）
    a2. **蒐集 stage metrics（選填、最低優先）**：對每個 stage 的 handoff 找 `## Metrics` JSON 區塊，
        填入該 stage 的 `stages[].metrics`（schema 見 `references/run-trace.md` Stage Metrics）。四種情況：
        - **有且合法**（合法 JSON 且 value 皆數字）→ 放進 `metrics`
        - **沒有** → 該 stage 不帶 `metrics`（合法）
        - **有但壞掉**（非法 JSON／含非數字 value）→ **安靜跳過**，該 stage 不帶 metrics
        - **Full Weight phase 彙整**：同名 metric 跨 phase 合併——`coverage` 取最後一個 phase（最終態），
          計數類（lint_*／tests_*）取**加總**
        > **非協商**：metrics 蒐集是 emit-trace 裡最低優先的附加動作；解析失敗只代表「少記一個數字」，
        > **絕不**影響 trace 寫入或 run 結局。metrics 不參與任何 gate 判定。
    a3. **蒐集時間與拓撲欄位（全部選填、同為最低優先）**：
        - run 層 `started_at`：讀 flow-context marker 的選填 `started_at`（見 `references/flow-context.md`）
        - `stages[].started_at` / `ended_at`：讀各 stage handoff 的選填 `## Timing` 區塊
          （`Started At:` / `Ended At:`，見 `references/agent-handoff.md`）
        - build stage 的 `phases[]` 與 `conflicts[]`（僅 Full Weight）：時間來自各 mini-handoff 的
          Timing 區塊；`mode` / `isolation`（`"worktree"` / `"shared"`，選填）/ `parallel_group`
          來自 flow 自己的 spawn 分組紀錄；`conflicts` 來自
          conflict detection 結果（彙整方式見 `references/phase-orchestration.md`「Phase 拓撲彙整」）
        - 計算三個選填 metrics（掛在 build stage 的 `metrics`，schema 見 `references/run-trace.md`）：
          `wall_seconds`（`ts` − `started_at`）、`agent_seconds`（phases 時長總和；缺 phases 時
          退回 stages 時長總和）、`max_parallel_width`（最大 `parallel_group` 大小）
        > **非協商**：所有時間與拓撲欄位皆選填、缺失即略；任何解析或計算失敗**安靜降級**
        > （該欄位不寫即可），**絕不**影響 trace 寫入或 run 結局。
    b. Append 一筆 JSON 到 `.athena/traces/runs.jsonl`（不存在則建立）
    c. 依 **Handoff Retention Policy** 做 GC（詳見 `references/run-trace.md`）：
       - outcome 為 `shipped` / `done` → 刪除該 slug 的所有 handoff（含 mini-handoff）
       - outcome 為 `stopped@<stage>` / `handed-to-human` → **保留** handoff（供 resume 與 Loop 3）
       - **先 emit trace 再 GC**；**只刪已寫入 trace 的當前 run；絕不刪 in-flight 或其他未解 run**

    此步驟對 Minimal / Lightweight / Full 三條路由都適用，是 flow 的最後一個動作。

## 必要輸出

- 當前 stage
- 該 stage 使用的 skill 名稱與路徑（含是否為 plugin 預設）
- 上一個 stage 的 artifact 路徑
- 下一個 stage
- 是否需要新 agent
- Git context（branch_name、最近的 commit hash 與 message）

## 非協商規則

1. 不把多個 standard stage 塞進同一個 agent（**例外**：Lightweight 路由的 review-ship 可合併）
2. **不把多個 build phase 塞進同一個 agent** — 每個 phase 一個 fresh agent（僅 Full Weight）
3. 不讓後續 stage 或 phase 直接吃前一段聊天紀錄
4. 必須以 artifact、mini-handoff 或 flow context 作為 handoff 依據
5. 任一 stage 或 phase gate 失敗時，不自動硬闖下一關
6. 缺少 standard stage skill 時，不繼續執行，必須引導團隊補齊
7. 不使用 plugin 內建 skill 作為 standard stage 替代——standard stage skill 必須由團隊提供
8. Flow-inline stage 在 flow agent 中內聯執行，不開 fresh agent
9. Flow-inline stage 缺少團隊版本時，使用 plugin 預設繼續執行
10. Gate 沒過不 commit——只有 PASS 才觸發 post-build（例外：worktree 平行 phase 無論 gate 結果都在 worktree 分支 commit，FAIL 用 `wip:` 前綴且該分支絕不 merge，見 phase-orchestration.md）
11. **只有 Ship 可以 push** — pre-build 和 post-build 僅做 local 操作（**例外**：Minimal 路由由使用者自行 push）
12. 冪等——分支已存在就切換，commit 無變更就跳過
13. **Per-phase commit** — 每個 build phase 獨立 commit，不合併多個 phase（僅 Full Weight）
14. **Verify retry 最多 2 輪** — 超過交給使用者
15. **Phase 定義來自 plan.md** — flow 不硬編碼 phase 列表（僅 Full Weight）
16. **Lightweight 路由不依賴 plan.md** — 不開 phase loop，單 agent build
17. **Ship agent 不詢問使用者** — merge_target 由 flow 在啟動前取得並傳入
18. **Minimal 路由不開 review/ship agent** — build(minimal) 含 self-review，flow 結束後由使用者自行 push
19. **可平行 phase 必須同一次回應送出** — 不可序列化 Agent 呼叫，否則喪失平行（僅 Full Weight）
20. **flow agent 不 sleep 輪詢** — background 模式靠 harness 通知，foreground 模式靠 tool result 同步返回
21. **每次 run 必須 emit 一筆 trace** — 不論成敗，步驟 12 是強制收尾，append 到 `.athena/traces/runs.jsonl`
22. **GC 先 emit trace 後刪、且只刪已完成 run** — 絕不刪 in-flight 或未解 run 的 handoff（見 `references/run-trace.md`）
23. **平行集 ≥ 2 一律 worktree 隔離** — spawn 帶 `isolation: "worktree"`，merge-back 用 `git merge --no-ff` + `git branch -d`；merge conflict 停止交使用者；不可用時走 fallback 鏈（僅 Full Weight，詳見 `references/phase-orchestration.md`「Worktree 隔離」）
