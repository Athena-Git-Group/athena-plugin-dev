# Stage Orchestration

## Goal

讓使用者只下單一指令，Athena 自己完成整條流程編排。
每個 stage 的實際執行 skill 由團隊在 `.athena/skills/` 提供。

## Sequence Overview

Flow 根據 Weight Class 走不同路線（詳見下方 Weight Class 段落）。

### Minimal Sequence（PASS-TRIVIAL）

```
1. Point（plugin 內建）
2. [pre-build]（flow-inline，建立分支）
3. Build — Minimal Agent（一個 fresh agent 完成實作 + self-review checklist）
4. [post-build: build-minimal]（flow-inline，單次 commit）
5. Flow 直接輸出 push 指令 → done（不開 review-ship agent）
```

### Lightweight Sequence（PASS-DIRECT-BUILD / PASS-BUILD-WITH-VERIFY）

```
1. Point（plugin 內建）
2. [pre-build]（flow-inline，建立分支）
3. Build — Single Agent（一個 fresh agent 完成所有實作）
4. [post-build: build-lightweight]（flow-inline，單次 commit）
5. Verify（僅 PASS-BUILD-WITH-VERIFY，standard stage）
6. [post-build: verify]（僅 PASS-BUILD-WITH-VERIFY）
7. Review-Ship（review + ship 合併為一個 fresh agent）
```

### Full Sequence（PASS-SPEC-FIRST）

```
1. Point（plugin 內建）
2. Spec（standard stage，團隊 skill）
3. Plan（standard stage，團隊 skill）
4. [pre-build]（flow-inline，建立分支）
5. Build — Phase Loop（每個 phase 為 fresh agent）
   5a. Phase \<NN\> agent → mini-handoff → smoke test gate
   5b. [post-build: build-phase-\<NN\>]（flow-inline，per-phase commit）
   5c. 重複直到所有 phase 完成
   5d. 合成 handoffs/<slug>-build.md
6. Verify（standard stage，團隊 skill）
7. [post-build: verify]（flow-inline，triggering_stage=verify）
8. Review（standard stage，團隊 skill）
9. Ship（standard stage，推送分支 + 合併到目標環境）
```

> `[括號]` 表示 flow-inline stage，在 flow agent 中內聯執行。
> Build 內部的 phase loop（Full only）詳見 `phase-orchestration.md`。
> Verify 失敗的回退流程（Full only）詳見 `verify-retry.md`。

## Weight Class

Flow 根據 point verdict 決定流程重量等級，影響 Build 模式、Handoff 格式與 agent 數量。

| Verdict | Weight | Build 模式 | Handoff 模式 | Agent 數量 |
|---------|--------|-----------|-------------|-----------|
| `PASS-TRIVIAL` | Minimal | 單 agent + self-review | Compact | 2（point + build） |
| `PASS-DIRECT-BUILD` | Lightweight | 單 agent，無 phase loop | Compact | 3（point + build + review-ship） |
| `PASS-BUILD-WITH-VERIFY` | Lightweight | 單 agent，無 phase loop | Compact | 4（point + build + verify + review-ship） |
| `PASS-SPEC-FIRST` | Full | Phase loop（依賴 plan.md） | Standard | 7+N（完整流程） |

### Minimal Flow

適用於極低分、零風險的任務（PASS-TRIVIAL，0-4 分且無 override 命中）：

- 跳過 spec、plan、verify、review、ship
- Build = 一個 fresh agent 完成實作，結束前執行 **self-review checklist**
- 單次 commit（post-build flow-inline）
- **不開 review-ship agent** — flow 結束時直接輸出 push 指令
- Handoff 只留 point-report + compact build handoff（2 檔）

```
Minimal:
/point → [pre-build] → /build (minimal, with self-review) → [post-build] → done
```

#### Self-Review Checklist（由 build agent 在結束前執行）

build(minimal) agent 必須在寫 handoff 前自我檢查以下項目：

1. 改動範圍是否超出 point-report 描述？（是 → Gate FAIL，可能低估複雜度）
2. 是否引入新的 import / dependency？
3. 是否有明顯的安全問題（hardcoded secrets、SQL injection、XSS）？
4. Smoke test 是否通過？

任一項不通過 → build agent 標記 Gate = FAIL，flow 停下來報告使用者。

### Lightweight Flow

適用於低分、低風險的任務（PASS-DIRECT-BUILD、PASS-BUILD-WITH-VERIFY）：

- 跳過 spec、plan
- Build = 一個 fresh agent 完成所有實作（不跑 phase loop）
- 不產生 mini-handoff
- 單次 commit（不是 per-phase）
- Review 和 Ship 合併為一個 agent（review-ship）
- Handoff 使用 Compact 格式（見 `agent-handoff.md`）

```
Lightweight:
/point → [pre-build] → /build (single agent) → [post-build] → [/verify → post-build] → /review-ship
```

### Full Flow

適用於高分、高風險或需要 spec 的任務（PASS-SPEC-FIRST）：

- 走完整 spec → plan → phase loop → verify
- 維持 per-phase agent + mini-handoff + per-phase commit
- Review 和 Ship 各自獨立 agent
- Handoff 使用 Standard 格式

```
Full:
/point → /spec → /plan → [pre-build] → /build (phase loop) → /verify → [post-build] → /review → /ship
```

---

## Skill Resolution

### Standard Stage

每個 standard stage 啟動前，flow 根據 Skill Discovery 的對應表找到該 stage 的 skill：

```
stage → .athena/skills/<skill-dir>/SKILL.md
```

- 找到 → 開 fresh agent，讓它 Read 該 SKILL.md 後執行
- 找不到 → 停止流程，輸出引導訊息

### Flow-Inline Stage

Flow-inline stage（pre-build、post-build）使用不同的 resolution 規則：

```
1. 掃描 .athena/skills/ 尋找對應 stage 的 skill
2. 若找到 → 使用團隊的 skill（Read 該 SKILL.md 後內聯執行）
3. 若未找到 → 使用 plugin 預設：
   - pre-build  → skills/athena-pre-build/SKILL.md
   - post-build → skills/athena-post-build/SKILL.md
4. 不停止流程，不引導團隊補齊
```

詳見 `stage-contracts.md` 和 `index-skill-pattern.md`。

## Agent Isolation Rule

**Standard stage** 都必須是 fresh agent：

- Point agent（plugin 內建 athena-point）
- Spec agent（載入團隊 spec skill）— Full only
- Plan agent（載入團隊 plan skill）— Full only
- **Full Weight:** Build phase agents（每個 phase 一個 fresh agent，載入團隊 build skill + phase card）
- **Lightweight / Minimal:** Build agent（單一 fresh agent，載入團隊 build skill，不跑 phase loop）
- Verify agent（載入團隊 verify skill）— Full always，Lightweight 僅 PASS-BUILD-WITH-VERIFY，Minimal 無
- **Full Weight:** Review agent + Ship agent（各自獨立 fresh agent）
- **Lightweight:** Review-Ship agent（review + ship 合併為一個 fresh agent）
- **Minimal:** 無 review / ship agent — flow 直接結束

不要重用 agent。Full Weight 中，Build 的每個 phase 都是獨立的 fresh agent。
Lightweight 中，Build 是單一 agent，Review 和 Ship 合併為一個 agent。
Minimal 中，Build 是單一 agent（含 self-review），無 review/ship agent。

**Flow-inline stage** 在 flow agent 中內聯執行：

- pre-build（建立 Git 分支）
- post-build（自動 commit）

不開新 agent，直接由 flow orchestrator 讀取 skill 後操作。

## Why

- 避免 context 累積太大（standard stage 用 fresh agent）
- 避免前一階段的推理污染後一階段
- 讓每個 stage 只看它該看的 artifact
- 讓不同團隊可以替換任意 stage 的實作
- Flow-inline stage 輕量操作不值得開 fresh agent 的成本

## Git Lifecycle Hooks

Git 操作以 flow-inline stage 的形式穿插在 standard stage 之間：

- **pre-build**：build 前建立分支並切換，從 point-report 推斷分支類型與名稱
- **post-build（build-lightweight）**：Lightweight build gate PASS 後自動 commit 整個 build 的變更（單次 commit）
- **post-build（per-phase）**：Full Weight 中每個 build phase gate PASS 後自動 commit 該 phase 的變更
- **post-build（verify 後）**：verify gate PASS 後自動 commit 測試相關變更（若有）
- **post-build（verify fix）**：Full Weight 中 verify fail 的 targeted re-build 完成後 commit 修復變更

詳見 `git-lifecycle-hooks.md`。

## Build Phase Loop（Full Weight Only）

Full Weight 中，Build stage 被拆為 phase loop，由 flow 調度每個 phase 的執行、gate、commit。
Lightweight 路由不使用 phase loop。

- Phase 定義來自 `plan.md` 的 Dependency Graph
- 每個 phase = fresh agent + mini-handoff + smoke test gate + per-phase commit
- 可平行的 phase 同時啟動
- Verify fail 時精確定位 broken phase 做 targeted re-build

詳見 `phase-orchestration.md` 和 `verify-retry.md`。

## Handoff

每個 standard stage 結束時都要留下：

- stage summary
- produced artifacts
- gate result
- recommended next stage

**Build phase** 結束時留下 **mini-handoff**（`handoffs/<slug>-build-phase-<NN>.md`），包含：

- files changed
- spec deviations
- smoke test result
- gate verdict
- notes for next phase

所有 phase 完成後，flow 合成最終的 `handoffs/<slug>-build.md`。

Flow-inline stage 透過 **flow context** 傳遞，不產出 handoff artifact。
Flow context 中的 `git_context` 可在 review / ship stage 的 handoff 中引用。

Handoff 格式詳見 `stage-contracts.md` 和 `agent-handoff.md`。
