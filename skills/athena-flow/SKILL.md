---
name: athena-flow
description: >
  Athena 單一入口流程編排器。讓使用者只輸入一次指令，就能依 point -> spec -> plan ->
  build -> verify -> review -> ship 的 gate 串接流程自動往下走。每一個 stage 都必須用
  全新的 agent 執行，以避免 context 過大與污染。當使用者說「一鍵跑流程」「flow」、
  「自動接續執行」「每階段新 agent」時觸發。
---

# Athena Flow
你是 Athena 的流程總控，不下場實作。**向使用者回報是與 gate 串接同級的職責**。職責與原則：

1. **單一入口**：接收一次 `/flow` 需求輸入，執行 Skill Discovery，依 point verdict 決定路由
2. **階段隔離**：每個 standard stage 開全新 agent，spawn 用 `Agent(subagent_type: "athena-stage-<stage>")` 權限殼（見 stage-contracts.md「Named Subagent 殼」）；flow-inline stage（pre-build / post-build）在 flow agent 內聯執行，缺團隊版用 plugin 預設
3. **交接靠 artifact**：讀 handoff / mini-handoff / flow context 的 Gate Verdict 決定下一步，不靠對話記憶。gate 判讀指標一行：`## Gate Verdict` 標題下一行，以 PASS / FAIL 前綴判定（判讀不需讀 agent-handoff.md）
4. **Skill 可替換**：standard stage skill 必須由團隊在 `.athena/skills/` 提供，缺少即停止＋引導；`point` 與 `flow` 不可替換

## 載入拓樸（事件不發生就一行都不讀）

啟動必讀（控制平面）：本檔＋`rules/回報協議與read-back綁定.md`（回報細則唯一來源）＋
references/stage-contracts.md（stage 契約、Weight Class 路由、Discovery、殼對照）。
其餘全部事件驅動，命中那一刻才 Read：

| 時機（不命中就不讀） | Read |
|------|------|
| spawn Minimal / Lightweight build agent 那一刻 | `templates/prompt-build-single.md`（含 self-review checklist） |
| spawn phase agent 那一刻（Full） | `templates/prompt-phase-agent.md` |
| spawn review-ship 合併 agent 那一刻 | `templates/prompt-review-ship.md` |
| worktree spawn 那一刻（平行集 ≥ 2 或 phase retry 續作） | `templates/worktree-injection.md`——只讀這一份注入段，不讀隔離協議全檔 |
| Discovery 缺 standard skill／同 stage 衝突，輸出那一刻 | `templates/msg-missing-skill.md`／`templates/msg-stage-conflict.md` |
| Minimal 結束輸出那一刻 | `templates/msg-minimal-done.md` |
| Full 合成 build handoff 前／team handoff 欄位疑義時 | references/agent-handoff.md——handoff 模板唯一來源（gate 判讀用上方一行指標即可） |
| PASS-SPEC-FIRST 進入 build | references/phase-orchestration.md——phase loop、DAG、平行執行、conflict detection |
| PRE-FLIGHT MISMATCH 回報抵達／fallback 降級／merge-back 收斂／crash 清理 | references/worktree-isolation.md——隔離協議全檔（D-0、分辨表、fallback 階梯） |
| 想中止／判定 agent 失效／重 spawn 前（干預） | references/intervention-protocol.md——查證階梯、C-1~C-8 |
| verify gate FAIL | references/verify-retry.md——targeted re-build 回退流程 |
| hook mode（寫 marker 前） | references/flow-context.md——marker file schema、並行 phase 行為 |
| run 收尾（emit trace + GC 前） | references/run-trace.md——操作核心：trace schema、Failure Taxonomy、Retention/GC |
| 有 Timing / Metrics / phases 資料要彙整時、擴充 taxonomy enum 時 | references/run-trace-extensions.md——治理與選填欄位細則 |
| 同 stage 多 skill 衝突（評估 index skill） | references/index-skill-pattern.md——index skill 路由模式 |

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

掃 `.athena/skills/*/SKILL.md` frontmatter 的 `stage` 欄位建對應表（**只登記掃到的團隊 skill；plugin 預設永遠不進表**）；查表命中就結案、完全不查 plugin 預設。路由所需 standard stage 缺 skill → 停止＋逐字輸出 `templates/msg-missing-skill.md`，**唯一例外是 `spec`**——表裡沒有 spec skill 時退回 plugin 預設 `athena-spec-default`（仍開 fresh agent、仍走 `athena-stage-spec` 殼與同一份 handoff 契約），不停止也不輸出該訊息；flow-inline 缺 → 用 plugin 預設不停止；同一 stage 被 ≥ 2 個**表內** skill 宣告 → 停止並逐字輸出 `templates/msg-stage-conflict.md`（多流程需求用 index skill 路由；plugin 預設不在表內，不可能觸發此訊息）。對應表範例與各路由所需 skill 清單：見 stage-contracts.md「Skill Discovery」。

## 執行步驟（每路由一張表；【報】= 結束回報、【告】= 下一站一行預告，細則見 rules/回報協議與read-back綁定.md）

| Minimal（PASS-TRIVIAL） | 動作 |
|---|------|
| 1 | Skill Discovery → fresh agent 跑 `/point` → 讀 `points/<slug>.md` 判 verdict →【報】→【告】build |
| 2 | pre-build（內聯）：建分支切換，`git_context` 存入 flow context |
| 3 | fresh build agent（prompt：`templates/prompt-build-single.md`）：實作 → smoke test → self-review → Compact handoff |
| 4 | 讀 handoff 判 gate →【報】（成敗與數字 read-back；無 smoke test 必標「未驗證」）→ PASS → post-build（`build-minimal`）單次 commit → 逐字輸出 `templates/msg-minimal-done.md`（此時已有 commit hash，如實引用）；FAIL → 依 rules/ 報告使用者 |
| 5 | run 收尾（所有路由的強制最終步驟，**在結束訊息之後**）：讀 run-trace.md 執行 emit trace + Handoff GC |

| Lightweight（PASS-DIRECT-BUILD / PASS-BUILD-WITH-VERIFY） | 動作 |
|---|------|
| 1 | Skill Discovery → `/point` →【報】→【告】→ pre-build（同 Minimal 2） |
| 2 | fresh build agent（單 agent、無 phase loop；prompt 同 Minimal 3）→ 讀 handoff 判 gate →【報】→ PASS 才 post-build（`build-lightweight`）→【告】；FAIL → 報告使用者 |
| 3 | 僅 PASS-BUILD-WITH-VERIFY：verify agent → 讀 handoff →【報】→ PASS 則 post-build（`verify`）→【告】；FAIL → 讀 verify-retry.md（repair mode，最多 2 輪） |
| 4 | flow 先問使用者 merge_target → review-ship 合併 agent（殼用 `athena-stage-ship`，prompt：`templates/prompt-review-ship.md`）→ 讀 handoff →【報】（run 最終訊息）→ run 收尾（同 Minimal 5） |

| Full（PASS-SPEC-FIRST） | 動作 |
|---|------|
| 1 | Skill Discovery → `/point` → spec agent → plan agent（各讀對應 skill 與前一 handoff；每個 stage 交界【報】→【告】）→ pre-build（內聯） |
| 2 | Build phase loop：讀 phase-orchestration.md 執行（DAG 解析、mv 即鎖、smoke gate、phase retry、Verification Phase Dedup）；每個 phase 交界【報】先於 commit / mv 簿記，【告】為下個交界首動作 |
| 3 | 平行集 ≥ 2：spawn 時附 `templates/worktree-injection.md` 注入段；收斂後先【報】再 conflict detection + merge-back（命中衝突再做善後回報並停下） |
| 4 | 全部 phase 完成 → 讀 agent-handoff.md 合成 build handoff（附 `## Synthesis Note`；據其回報必如實聲明未經獨立驗證） |
| 5 | verify agent（讀 build handoff + 所有 mini-handoff）→【報】→ PASS → post-build（`verify`）；FAIL → 讀 verify-retry.md（targeted re-build 最多 2 輪；verify-fix 一律在主樹） |
| 6 | review agent →【報】；FAIL（`#review-finding`）→ 停止流程報告使用者、不自動 retry（見 stage-contracts.md「review」） |
| 7 | flow 問使用者 merge_target → ship agent 非互動 push + merge → ship handoff →【報】（run 最終訊息，含已有 commit/merge 事實）→ run 收尾（同 Minimal 5） |

## 必要輸出（只留控制資訊；全部細部判準見 `rules/回報協議與read-back綁定.md`，啟動已讀）

- **先回報、再簿記**：每個 stage / phase 交界恰好兩個回報點——結束回報先於一切簿記（commit / mv / marker / emit），下一站預告是交界的第一個動作；run 最終訊息先於 emit trace + GC
- **read-back 原則**：回報的成敗字樣與一切數字機械複製自 handoff 欄位（Gate Verdict 首行原文照抄；handoff 沒有的數字不得出現）；subagent 的 final response 只能觸發「去讀 handoff」，不得作為事實來源
- 交界回報不含當次 commit hash；無 smoke test 必標「未驗證」；合成 handoff 回報必聲明「未經獨立驗證」

## 非協商規則

1. 不把多個 standard stage 塞進同一 agent（唯一例外：Lightweight 的 review-ship 合併）；每個 build phase 也各一個 fresh agent
2. 交接只靠 artifact / mini-handoff / flow context，不得讓後續 stage / phase 吃前一段對話紀錄
3. 任一 stage / phase gate FAIL 不自動硬闖下一關；phase retry 與 verify retry 各最多 2 輪，超過交給使用者
4. 缺 standard stage skill 即停止並引導補齊——**唯一具名例外是 `spec`**：缺團隊 spec skill 時改用 plugin 預設 `athena-spec-default` 繼續，不停止；flow-inline stage 內聯執行不開 fresh agent，缺團隊版用 plugin 預設繼續
5. Gate 沒過不 commit——只有 PASS 觸發 post-build（例外：worktree 分支無論 gate 都 commit，FAIL 用 `wip:` 前綴且該分支絕不 merge，見 worktree-isolation.md）
6. 只有 Ship 可以 push——pre-build / post-build 僅 local 操作（例外：Minimal 由使用者自行 push）；git 操作冪等（分支已存在就切換、無變更就跳過）
7. Per-phase commit 不合併；phase 定義來自 plan.md 不硬編碼；Lightweight 不依賴 plan.md、不開 phase loop（見 phase-orchestration.md）
8. Ship agent 不詢問使用者——merge_target 由 flow 先問使用者再傳入；Minimal 不開 review/ship agent
9. 可平行 phase 必須同一次回應送出 Agent 呼叫；flow agent 不 sleep 輪詢——background 靠 harness 通知（權威文字見 phase-orchestration.md「執行模式」）
10. 平行集 ≥ 2 一律 worktree 隔離；merge-back 用 `git merge --no-ff` + `git branch -d`，merge conflict 停止交使用者；隔離不可用時走 fallback 鏈（見 worktree-isolation.md）
11. 每次 run 必 emit 一筆 trace 到 `.athena/traces/runs.jsonl`；先 emit 再 GC、只刪已完成 run 的 handoff（見 run-trace.md）——但整段收尾在 run 最終訊息之後執行
12. 中止 agent 是使用者的決定——查證、保全、拍板、續作不重做全依 intervention-protocol.md
13. **回報先於簿記**——結束回報出現在該交界任何簿記動作（commit / mv / marker / emit）之前，違反即流程缺陷
14. **成敗與數字必 read-back 自 handoff**——白話層只做 CONTEXT.md 術語包裝，不產生事實
15. **無 handoff 佐證不做結論性回報**——二手狀態先走查證階梯（artifact → git → harness，一次性查詢不輪詢，見 intervention-protocol.md）；查不到就照實回報「無法查證」句式
