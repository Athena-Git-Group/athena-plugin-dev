---
name: team-build
description: >
  本 repo（hxde）的 build stage skill。產物是 markdown skill 文件、bash hooks
  與少量 python script——不是一般 app。依 point-report（Minimal / Lightweight）
  或 phase card + mini-handoff（Full）實作，依改動類型執行對應 smoke test，
  寫 Compact 格式 build handoff。
stage: build
---

# Team Build（hxde）

你是 build 階段的執行者：依任務輸入實作、跑 smoke test、寫 handoff。

# SOP

## Phase 1 -- 讀取輸入並確認改動範圍

1. READ 讀取 `.hxde/skills/team-common/rules/agent-isolation.md`，確認 fresh agent 的輸入紀律。
2. DELEGATE （選填）執行 `date -u +%Y-%m-%dT%H:%M:%SZ` 取 `Started At:`。
3. READ 依路徑讀取任務輸入：Minimal / Lightweight 讀 `points/<slug>.md`（point-report——任務描述、驗收條件與 Risks 段）；Full（phase loop）讀 `plans/<slug>/doing/<NN>-<name>.md`（phase card），且若有前一 phase 的 mini-handoff，讀 `handoffs/<slug>-build-phase-<prev-NN>.md`。
4. READ 讀取 `rules/build-constraints.md`（本 skill），確認禁令與改動邊界。
5. THINK 列出要改的檔案清單，依已載入規則確認全部落在任務輸入的範圍內。

## Phase 2 -- 實作並跑 smoke test

1. WRITE 依任務描述實作，逐條避開 point-report（或 phase card）Risks 段列出的風險。
2. READ 讀取 `.hxde/skills/team-common/rules/smoke-test.md` 的 Rule 3（build 時怎麼跑）。
3. DELEGATE 依改動類型逐類執行 smoke test 指令，記錄實際輸出；任一失敗即 Gate FAIL。

## Phase 3 -- 寫 handoff 交接

1. READ 讀取 `skills/hxde-flow/references/agent-handoff.md`：Minimal / Lightweight 看變體差異表的 Compact build / Minimal build 變體；Full 看 Mini-Handoff 模板。
2. READ Gate 為 FAIL 時，讀取 `.hxde/skills/team-common/rules/fail-reporting.md`，依其格式填 Gate Verdict（必帶 taxonomy tag）。
3. WRITE 照變體寫 handoff：Minimal / Lightweight 寫 `handoffs/<slug>-build.md`；Full 寫 `handoffs/<slug>-build-phase-<NN>.md`（最終 build handoff 由 flow 合成，不由你寫）。
