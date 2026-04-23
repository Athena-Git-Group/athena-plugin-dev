# Agent Handoff Contract

## Principle

agent 之間不共享上下文，靠檔案交接。

## Handoff Artifact

每個 stage 在 `handoffs/` 下留下對應的 artifact：

- `handoffs/<slug>-spec.md`
- `handoffs/<slug>-plan.md`
- `handoffs/<slug>-build.md`
- `handoffs/<slug>-verify.md`
- `handoffs/<slug>-review.md`
- `handoffs/<slug>-ship.md`

> **例外**：point stage 的輸出在 `points/<slug>.md`（由 plugin 內建的 athena-point 控制）。

## Minimum Contents

- Stage name
- Inputs used
- Artifacts produced
- Gate verdict
- Risks / unresolved issues
- Next recommended stage

## Phase-Level Handoff（Build 內部）

Build stage 被拆解為多個 phase，每個 phase 由 fresh agent 執行。
Phase 之間的交接使用 **mini-handoff**，格式比 stage handoff 更聚焦。

### Mini-Handoff 路徑

```
handoffs/<slug>-build-phase-<NN>.md
```

範例：`handoffs/approval-workflow-build-phase-05.md`

### Mini-Handoff 格式

```markdown
# Phase Handoff: Phase <NN> — <Phase Name>

## Phase
<phase 編號與名稱>

## Inputs Used
- plans/<slug>/phase-cards/<NN>-<name>.md
- handoffs/<slug>-build-phase-<prev-NN>.md（若有）
- spec Section <X>, <Y>

## Files Changed
- src/api/approval.rs (new)
- src/api/approval_test.rs (new)
- migrations/003_approval_table.sql (new)

## Spec Deviations
[若實作偏離 spec，明確記錄偏離內容與原因。無偏離則寫「None」]

## Smoke Test Result
- <test command>: <result summary>
- 例：cargo test: 12 passed, 0 failed
- 例：cargo clippy: no warnings

## Gate Verdict
<PASS / FAIL + 原因>

## Notes for Next Phase
[下一個 phase agent 需要知道的資訊，如實際 API path、schema 細節等]
```

### 必要欄位

| 欄位 | 必要性 | 說明 |
|------|--------|------|
| Phase | 必要 | 識別是哪個 phase |
| Inputs Used | 必要 | 可追溯性 |
| Files Changed | 必要 | 讓下一個 phase 知道改了什麼 |
| Spec Deviations | 必要 | 防止下游在錯誤基礎上繼續 |
| Smoke Test Result | 必要 | Gate 判定依據 |
| Gate Verdict | 必要 | Flow 讀取此欄位決定是否繼續 |
| Notes for Next Phase | 選填 | 跨 phase 的實作細節傳遞 |

### Build Handoff 合成

所有 phase 完成後，flow 自動合成最終的 `handoffs/<slug>-build.md`，
彙整所有 phase 的 mini-handoff 資訊。格式見 `phase-orchestration.md`。

## Minimal Handoff（PASS-TRIVIAL 路由）

Minimal 路由（`PASS-TRIVIAL`）使用最精簡的 handoff 模式：

- 只產出 **2 個 handoff 檔案**：point-report + compact build handoff（含 self-review）
- **不產出** review-ship handoff — 流程在 build + commit 後直接結束
- Build handoff 附帶 self-review 結果（取代獨立 review agent）

### Minimal Build Handoff

```markdown
# Handoff: build (minimal)

## Gate Verdict
PASS / FAIL + 原因

## Files Changed
- <file list with new/modified annotation>

## Smoke Test Result
- <command>: <result>

## Self-Review
- Scope within point-report: yes/no
- New dependencies: none / <list>
- Security concerns: none / <list>

## Risks / Unresolved Issues
<若無則 None>
```

### 預期 Handoff 檔案數量（Minimal）

| 路由 | Handoff 檔案 | 總數 |
|------|-------------|------|
| `PASS-TRIVIAL` | point + build(minimal) | **2** |

---

## Compact Handoff（Lightweight 路由）

Lightweight 路由（`PASS-DIRECT-BUILD`、`PASS-BUILD-WITH-VERIFY`）使用精簡的 Compact Handoff 模式，
減少 artifact 數量與必要欄位。

### Standard vs Compact 差異

| 項目 | Standard（Full Weight） | Compact（Lightweight） |
|------|------------------------|----------------------|
| Mini-handoff | 每 phase 一個 | 無（無 phase loop） |
| Build handoff | 合成自多個 mini-handoff | Build agent 直接寫 |
| Review + Ship | 各自獨立 handoff | 合併為 `handoffs/<slug>-review-ship.md` |
| 必要欄位 | 全部 6 欄（Stage, Inputs, Artifacts, Gate, Risks, Next） | Gate Verdict + Files Changed + Risks |

### Compact Build Handoff

```markdown
# Handoff: build (lightweight)

## Gate Verdict
PASS / FAIL + 原因

## Files Changed
- src/api/member.rs (modified)
- src/api/member_test.rs (new)

## Smoke Test Result
- cargo test: 8 passed, 0 failed

## Risks / Unresolved Issues
None
```

### Compact Review-Ship Handoff

Review 和 Ship 在 Lightweight 路由中由同一個 agent 執行，產出合併的 handoff：

```markdown
# Handoff: review-ship

## Review Verdict
PASS — <一句話摘要>

## Review Notes
<重要的 code review 發現，若無則省略此段>

## Ship Result
- Pushed: <branch_name> → origin
- Merged: <branch_name> → <merge_target>
- Merge commit: <hash>

## Commits Shipped
| Hash | Message |
|------|---------|
| abc1234 | [HAP-3621] feat(member): add export API |

## Gate Verdict
PASS — reviewed, pushed and merged to <merge_target>
```

### 預期 Handoff 檔案數量

| 路由 | Handoff 檔案 | 總數 |
|------|-------------|------|
| `PASS-TRIVIAL` | point + build(minimal) | **2** |
| `PASS-DIRECT-BUILD` | point + build + review-ship | **3** |
| `PASS-BUILD-WITH-VERIFY` | point + build + verify + review-ship | **4** |
| `PASS-SPEC-FIRST` | point + spec + plan + N × mini-handoff + build(合成) + verify + review + ship | **7+N** |

---

## 非協商規則

1. **每個 stage 必須由全新的 agent 執行**——不得讓同一個 agent 處理多個 stage，避免 context window 過大與推理污染
2. **每個 build phase 必須由全新的 agent 執行**——phase 之間不共享 context（僅 Full Weight）
3. 下一個 agent 先讀 handoff artifact（或 mini-handoff），再開始工作
4. 不得從對話脈絡取得前一 stage 或前一 phase 的資訊——一切靠 artifact 檔案
5. 每個 stage 結束時必須寫入完整的 handoff artifact，不可省略
6. 每個 build phase 結束時必須寫入 mini-handoff，不可省略（僅 Full Weight）
7. **Lightweight 路由的 review-ship 可合併為一個 agent**——這是唯一允許同一 agent 處理多個 stage 的例外
8. **Minimal 路由不產出 review-ship handoff**——build handoff 的 self-review 段落取代獨立 review
