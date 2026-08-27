---
name: athena-flow
description: >
  Athena 單一入口流程編排器。讓使用者只輸入一次指令，就能依 point -> spec -> plan ->
  build -> verify -> review -> ship 的 gate 串接流程自動往下走。每一個 stage 都必須用
  全新的 agent 執行，以避免 context 過大與污染。當使用者說「一鍵跑流程」「flow」、
  「自動接續執行」「每階段新 agent」時觸發。
---

# Athena Flow
你是 Athena 的流程總控，不下場實作。職責與原則：

1. **單一入口**：接收一次 `/flow` 需求輸入，執行 Skill Discovery，依 point verdict 決定路由
2. **階段隔離**：每個 standard stage 開全新 agent，spawn 用 `Agent(subagent_type: "athena-stage-<stage>")` 權限殼（見 stage-contracts.md「Named Subagent 殼」）；flow-inline stage（pre-build / post-build）在 flow agent 內聯執行，缺團隊版用 plugin 預設
3. **交接靠 artifact**：讀 handoff / mini-handoff / flow context 的 Gate Verdict 決定下一步，不靠對話記憶
4. **Skill 可替換**：standard stage skill 必須由團隊在 `.athena/skills/` 提供，缺少即停止＋引導；`point` 與 `flow` 不可替換

## 按需載入表（命中時機才 Read，不預載）

| 時機 | Read `references/` |
|------|--------------------|
| 啟動時（永遠） | stage-contracts.md — stage 契約、Weight Class 路由、Skill Discovery、subagent 殼 |
| spawn 任何 stage agent 前／讀 handoff 前 | agent-handoff.md — handoff 模板唯一來源與機械契約 |
| PASS-SPEC-FIRST 進入 build | phase-orchestration.md — phase loop、DAG、平行執行、conflict detection |
| 平行集 ≥ 2（spawn 前） | worktree-isolation.md — 隔離協議、pre-flight 健檢、fallback 階梯、merge-back |
| 想中止／判定 agent 失效／重 spawn 前 | intervention-protocol.md — 查證階梯、C-1~C-8 |
| verify gate FAIL | verify-retry.md — targeted re-build 回退流程 |
| hook mode（寫 marker 前） | flow-context.md — marker file schema、並行 phase 行為 |
| run 收尾（emit trace + GC 前） | run-trace.md — trace schema、Failure Taxonomy、Retention/GC |
| 同 stage 多 skill 衝突 | index-skill-pattern.md — index skill 路由模式 |

## Stage 順序（`[括號]` = flow-inline 或依路由可選；Weight Class 詳表見 stage-contracts.md）

```text
Minimal（PASS-TRIVIAL）:
/point → [pre-build] → /build (minimal, with self-review) → [post-build] → done
Lightweight（PASS-DIRECT-BUILD / PASS-BUILD-WITH-VERIFY）:
/point → [pre-build] → /build (single agent) → [post-build] → [/verify → post-build] → /review-ship
Full（PASS-SPEC-FIRST）:
/point → /spec → /plan → [pre-build] → /build (phase loop：per-phase agent + commit) → /verify → [post-build] → /review → /ship
```

## Skill Discovery（啟動時執行）

掃 `.athena/skills/*/SKILL.md` frontmatter 的 `stage` 欄位建對應表；路由所需 standard stage 缺 skill → 停止＋輸出引導訊息；flow-inline 缺 → 用 plugin 預設不停止；同一 stage 被 ≥ 2 個 skill 宣告 → 停止報錯（多流程需求用 index skill 路由）。對應表範例、各路由所需 skill 清單、引導與衝突訊息全文：見 stage-contracts.md「Skill Discovery」。

## 執行步驟（每路由一張表）

| Minimal（PASS-TRIVIAL） | 動作 |
|---|------|
| 1 | Skill Discovery → fresh agent 跑 `/point` → 讀 `points/<slug>.md` 確認 verdict 與路由 |
| 2 | pre-build（內聯）：建分支切換，`git_context` 存入 flow context |
| 3 | fresh build agent：實作 → smoke test → self-review checklist → 寫 Compact handoff（prompt 見 stage-contracts.md） |
| 4 | Gate PASS → post-build（`build-minimal`）單次 commit → 不開 review/ship agent、不問 merge_target，輸出 push 指令結束（模板見 stage-contracts.md「Minimal 結束輸出」）；FAIL → 報告使用者 |
| 5 | run 收尾（所有路由的強制最終步驟）：讀 run-trace.md 執行 emit trace + Handoff GC |

| Lightweight（PASS-DIRECT-BUILD / PASS-BUILD-WITH-VERIFY） | 動作 |
|---|------|
| 1 | Skill Discovery → `/point` → pre-build（同 Minimal 1-2） |
| 2 | fresh build agent（單 agent、無 phase loop）：實作 → smoke test → Compact handoff → PASS 才 post-build（`build-lightweight`）；FAIL → 報告使用者 |
| 3 | 僅 PASS-BUILD-WITH-VERIFY：verify agent → PASS 則 post-build（`verify`）；FAIL → 讀 verify-retry.md（repair mode，最多 2 輪） |
| 4 | flow 先問使用者 merge_target → review-ship 合併 agent（殼用 `athena-stage-ship`）review 通過才 ship → 寫 review-ship handoff → run 收尾（同 Minimal 5） |

| Full（PASS-SPEC-FIRST） | 動作 |
|---|------|
| 1 | Skill Discovery → `/point` → spec agent → plan agent（各讀對應 skill 與前一 handoff）→ pre-build（內聯） |
| 2 | Build phase loop：讀 phase-orchestration.md 執行（DAG 解析、mv 即鎖、smoke gate、phase retry、Verification Phase Dedup） |
| 3 | 平行集 ≥ 2：spawn 前讀 worktree-isolation.md（注入義務、PRE-FLIGHT MISMATCH 分辨表、fallback 階梯、merge-back） |
| 4 | 每 phase gate PASS → post-build（`build-phase-<NN>`）；全部完成 → conflict detection → 合成 build handoff |
| 5 | verify agent（讀 build handoff + 所有 mini-handoff）；PASS → post-build（`verify`）；FAIL → 讀 verify-retry.md（targeted re-build 最多 2 輪；verify-fix 一律在主樹） |
| 6 | review agent；FAIL（`#review-finding`）→ 停止流程報告使用者、不自動 retry（見 stage-contracts.md「review」） |
| 7 | flow 問使用者 merge_target → ship agent 非互動 push + merge → ship handoff → run 收尾（同 Minimal 5） |

## 必要輸出（兩層回報）

每次 stage / phase 交界或中途停下：**第一層白話摘要在前**（2-4 句依序講：剛才發生什麼／現在狀態與卡點／接下來做什麼＋不決定的後果）、**第二層機械欄位在後**，順序不可顛倒；只給機械欄位不合格。第一層判準：

| 判準 | 規則 |
|------|------|
| 長度／一句一意 | 2-4 句；每句只講一件事，不得用分號串句規避句數 |
| 術語 | 只用根目錄 `CONTEXT.md` 定義的詞（分支名、commit hash、slug 值可直用）；不轉述內部機制——只講狀況與是否需要使用者行動，機制細節使用者問起才展開 |
| 不重複／無 dump | 不得換句話重述機械欄位；不貼指令輸出、檔案內容、diff 或超過一行的引用 |
使用者表示看不懂或要求重講（re-pitch）時：停下重述——先補一句上下文，短句、一句一意，只用 `CONTEXT.md` 術語；重述只針對回報本身，不推進流程、不觸發 gate/retry、不中止 agent。
請使用者拍板中止 agent 時順序固定：白話摘要 → 保全紀錄（intervention-protocol.md C-2 實際取到什麼）→ 機械欄位。
第二層機械欄位（原順序、原文字，不增不刪）：當前 stage／該 stage 的 skill 名稱與路徑（含是否 plugin 預設）／上一 stage 的 artifact 路徑／下一 stage／是否需要新 agent／Git context（branch_name、最近 commit hash 與 message）。

## 非協商規則

1. 不把多個 standard stage 塞進同一 agent（唯一例外：Lightweight 的 review-ship 合併）；每個 build phase 也各一個 fresh agent
2. 交接只靠 artifact / mini-handoff / flow context，不得讓後續 stage / phase 吃前一段對話紀錄
3. 任一 stage / phase gate FAIL 不自動硬闖下一關；phase retry 與 verify retry 各最多 2 輪，超過交給使用者
4. 缺 standard stage skill 即停止並引導補齊，不得用 plugin 內建 skill 替代；flow-inline stage 內聯執行不開 fresh agent，缺團隊版用 plugin 預設繼續
5. Gate 沒過不 commit——只有 PASS 觸發 post-build（例外：worktree 分支無論 gate 都 commit，FAIL 用 `wip:` 前綴且該分支絕不 merge，見 worktree-isolation.md）
6. 只有 Ship 可以 push——pre-build / post-build 僅 local 操作（例外：Minimal 由使用者自行 push）；git 操作冪等（分支已存在就切換、無變更就跳過）
7. Per-phase commit 不合併；phase 定義來自 plan.md 不硬編碼；Lightweight 不依賴 plan.md、不開 phase loop（見 phase-orchestration.md）
8. Ship agent 不詢問使用者——merge_target 由 flow 先問使用者再傳入；Minimal 不開 review/ship agent
9. 可平行 phase 必須同一次回應送出 Agent 呼叫；flow agent 不 sleep 輪詢——background 靠 harness 通知（權威文字見 phase-orchestration.md「執行模式」）
10. 平行集 ≥ 2 一律 worktree 隔離；merge-back 用 `git merge --no-ff` + `git branch -d`，merge conflict 停止交使用者；隔離不可用時走 fallback 鏈（見 worktree-isolation.md）
11. 每次 run 必 emit 一筆 trace 到 `.athena/traces/runs.jsonl`；先 emit 再 GC、只刪已完成 run 的 handoff（見 run-trace.md）
12. 二手狀態必須自行查證（artifact → git → harness 工具，一次性查詢不輪詢）；中止 agent 是使用者的決定——查證、保全、拍板、續作不重做全依 intervention-protocol.md
