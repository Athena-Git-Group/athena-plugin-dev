# Phase Orchestration

## 適用條件

Phase loop **僅在 Full Weight 流程中執行**（`PASS-SPEC-FIRST`）。

若路由為 `PASS-DIRECT-BUILD` 或 `PASS-BUILD-WITH-VERIFY`：
- **不進入 phase loop** — 沒有 `plan.md`，沒有 Dependency Graph
- Build 以 Lightweight 模式執行（見 `stage-contracts.md`「build（Lightweight）」段落）
- 本文件的所有規則不適用於 Lightweight 模式

---

## 概述

Build stage 不再是單一 agent 執行的 opaque stage。
Flow 讀取 `plans/<slug>/plan.md` 的 Dependency Graph，將 **implementation phases**（通常 Phase 05-07）拆解為獨立的 sub-stage，逐一（或平行）調度。

每個 phase 獲得與 standard stage 相同等級的：
- **Agent 隔離** — fresh agent
- **Handoff** — mini-handoff artifact
- **Gate** — smoke test 驗證
- **Commit** — per-phase git commit

## Phase 與 Stage 的關係

```
Standard Stage（spec, plan, build, verify, review, ship）
    └── Build Stage
         └── Phase Loop（由 flow 驅動）
              ├── Phase 05: Backend TDD
              ├── Phase 06: Frontend Build
              └── Phase 07: Integration
```

- **Stage** = flow 的一級調度單位（fresh agent + handoff artifact）
- **Phase** = Build 內的二級調度單位（fresh agent + mini-handoff）
- Phase 的定義來自 `plan.md` 的 Dependency Graph，不是 flow 硬編碼
- Flow 只認 Dependency Graph 中 `狀態` 欄位為 `todo` 的 implementation phase

## Phase 識別

Flow 從 `plans/<slug>/plan.md` 的 Dependency Graph 表格中識別 implementation phases：

```markdown
| Phase | Name | Depends On | 狀態 |
|-------|------|------------|------|
| 01 | Requirement Analysis | — | done |
| 02 | Entity Modeling | 01 | done |
| 03 | BDD Analysis | 02 | done |
| 04 | API Contract | 03 | done |
| 05 | Backend TDD Track | 04 | todo |    ← implementation phase
| 06 | Frontend Build Track | 04 | todo | ← implementation phase
| 07 | Integration Validation | 05, 06 | todo | ← implementation phase
```

**識別規則：**
1. 狀態為 `done` 的 phase 跳過（spec/plan 階段已完成的外部品質 phase）
2. 狀態為 `todo` 的 phase 進入 phase loop
3. 依照 `Depends On` 欄位建立執行順序

## Phase Loop 執行流程

```
Flow 讀 plan.md → 識別 todo phases → 建立依賴圖
    │
    ├── 順序執行（預設）
    │   for each phase in dependency order:
    │     1. 開 fresh agent
    │     2. 載入 build skill + phase card
    │     3. Agent 讀取前一個 phase 的 mini-handoff（若有）
    │     4. Agent 讀取指定的 spec sections（由 phase card 標明）
    │     5. Agent 執行實作
    │     6. Agent 執行 smoke test（phase card 中定義的指令）
    │     7. Agent 寫 mini-handoff（含 smoke test 結果）
    │     8. Flow 讀 mini-handoff → 檢查 Gate Verdict
    │     9. PASS → post-build commit（per-phase）→ 繼續
    │     10. FAIL → 停止 phase loop → 進入 phase retry
    │
    └── 平行執行（當依賴允許時）
        見「平行 Phase 執行」段落
```

## Phase Agent 的載入內容

每個 phase agent 被啟動時，flow 指示它讀取以下資料：

| 資料 | 路徑 | 說明 |
|------|------|------|
| Build skill | `.athena/skills/<build-skill>/SKILL.md` | 團隊的 build skill（同一份，每個 phase 都讀） |
| Phase card | `plans/<slug>/phase-cards/<NN>-<name>.md` | 該 phase 的具體任務卡片 |
| 前一個 phase 的 mini-handoff | `handoffs/<slug>-build-phase-<prev-NN>.md` | 知道上一個 phase 做了什麼（首個 phase 無此項） |
| Spec（指定 section） | 由 phase card 的 `spec_sections` 欄位指定 | 只讀需要的 section，不全讀 |
| Plan handoff | `handoffs/<slug>-plan.md` | 整體計畫的概覽（只讀一次，不用每個 phase 都讀） |

### Agent Prompt 模板

```
你正在執行 Phase <NN>: <Phase Name>。

讀取以下資料：
1. .athena/skills/<build-skill>/SKILL.md（你的 build skill）
2. plans/<slug>/phase-cards/<NN>-<name>.md（你的任務卡片）
3. handoffs/<slug>-build-phase-<prev-NN>.md（上一個 phase 的交接）
4. spec 的 Section <X>, <Y>（phase card 中 spec_sections 指定的）

完成實作後：
1. 執行 smoke test：<phase card 中的 smoke_test 指令>
2. 寫 mini-handoff 到 handoffs/<slug>-build-phase-<NN>.md
```

## Smoke Test Gate

Phase agent 在實作完成後、寫 mini-handoff 之前，執行 phase card 中定義的 `smoke_test` 指令。

- Smoke test 由 **phase agent 自己執行**，不另開 agent
- 結果寫入 mini-handoff 的 `Smoke Test Result` 欄位
- Flow 讀取 mini-handoff 的 `Gate Verdict` 欄位決定是否繼續

### Phase Card 格式（擴充）

```markdown
## Phase 05: Backend TDD Track

- **Depends On:** 04
- **Spec Sections:** 1, 3, 4
- **Smoke Test:** `cargo test && cargo clippy`
- **Skill:** my-team-build-backend（可選，若省略則使用 stage-level build skill）
```

### Gate 判定

| Smoke Test 結果 | Gate Verdict | Flow 動作 |
|-----------------|-------------|-----------|
| 全部通過 | PASS | post-build commit → 繼續下一個 phase |
| 有失敗 | FAIL | 停止 phase loop → 進入 phase retry |
| 無 smoke test 定義 | PASS（預設） | 繼續（信任 agent 的自我判斷） |

## Phase Retry（單一 Phase 失敗時）

Phase loop 中某個 phase gate FAIL 時：

```
Phase <NN> gate FAIL
    ↓
Flow 讀取該 phase 的 mini-handoff → 取得失敗原因
    ↓
開 fresh agent（repair mode）：
  - 載入 build skill + phase card + 失敗的 mini-handoff
  - Agent 讀取失敗原因並修復
  - Agent 重跑 smoke test
  - Agent 更新 mini-handoff
    ↓
Flow 再次檢查 Gate Verdict
  - PASS → post-build commit → 繼續下一個 phase
  - FAIL → 再 retry 一次（最多 2 輪）
  - 超過 2 輪 → 停止流程，交給使用者
```

## 平行 Phase 執行

Flow 分析 Dependency Graph，識別可平行的 phase。

### 判定規則

```
Phase A 和 Phase B 可平行，當且僅當：
- A 不依賴 B
- B 不依賴 A
- 兩者的所有前置依賴都已完成
```

### 執行方式

```
# 範例：Phase 05 和 06 可平行（都只依賴 04）
04 完成
    ↓
同時啟動 Phase 05 agent + Phase 06 agent（parallel Agent calls）
    ↓
各自獨立執行 → 各自寫 mini-handoff → 各自 gate
    ↓
兩者都 PASS
    ↓
Conflict Detection：比對兩個 mini-handoff 的 Files Changed
  - 無重疊 → 各自 commit → 繼續
  - 有重疊 → 停止，通知使用者處理衝突
    ↓
Phase 07（依賴 05 + 06）可以開始
```

### Conflict Detection

平行 phase 完成後，flow 比對所有平行 phase 的 `Files Changed` 清單：

| 情況 | 處理 |
|------|------|
| 無重疊檔案 | 各自 commit，繼續 |
| 有重疊但都是新增（不同檔案名的 new） | 各自 commit，繼續 |
| 有重疊且修改同一檔案 | 停止流程，報告衝突檔案，交給使用者 |

## Verification Phase Dedup

當路由包含 verify stage 時，flow 檢查 Dependency Graph 的**最後一個 phase**，避免與 verify stage 重複驗證。

### 判定流程

1. 讀取最後一個 phase 的 phase card
2. 判斷是否為「純驗證 phase」——不包含新增/修改程式碼的實作任務，只有測試執行與品質檢查
3. 若是純驗證 → **跳過該 phase**，由 verify stage 覆蓋
4. 若否（有實作 + 驗證混合）→ 正常執行

### 判斷標準

純驗證 phase 的特徵：
- Phase card 的任務描述中**不含**新增檔案、修改程式碼、建立模組等實作動詞
- **只有**執行測試、檢查覆蓋率、驗證整合、品質審查等驗證動詞
- Smoke test 指令涵蓋的範圍與 verify stage 的驗證內容高度重疊

### 處理方式

- 跳過的 phase 在 Build Handoff 中標記為 `skipped (deferred to verify)`
- phase card 仍保留在 `plans/<slug>/phase-cards/` 中，供 verify agent 參考
- Verify agent 可讀取被跳過的 phase card，了解原計畫的驗證內容

---

## Build Handoff 合成

所有 phase 完成後，flow 自動合成最終的 `handoffs/<slug>-build.md`：

```markdown
# Handoff: build

## Stage
build

## Inputs Used
- handoffs/<slug>-plan.md
- plans/<slug>/phase-cards/

## Phase Summary
| Phase | Gate | Commit |
|-------|------|--------|
| 05 - Backend TDD | PASS | abc1234 |
| 06 - Frontend Build | PASS | def5678 |
| 07 - Integration | PASS | ghi9012 |

## Artifacts Produced
[合併所有 phase mini-handoff 的 Files Changed]

## Gate Verdict
PASS — All phases completed successfully

## Risks / Unresolved Issues
[合併所有 phase 的 Spec Deviations 與 Notes]

## Next Recommended Stage
verify
```

## 非協商規則

1. **Phase 定義來自 plan.md** — flow 不硬編碼 phase 列表
2. **每個 phase 一個 fresh agent** — 不共享 context
3. **Mini-handoff 是唯一交接管道** — 不靠 agent 記憶
4. **Phase agent 自己跑 smoke test** — 不另開 agent
5. **Gate 沒過不 commit** — 只有 PASS 才觸發 post-build
6. **Gate 沒過不繼續** — FAIL 停止 phase loop
7. **Phase retry 最多 2 輪** — 超過交給使用者
8. **平行 phase 完成後必須 conflict detection** — 有衝突就停
