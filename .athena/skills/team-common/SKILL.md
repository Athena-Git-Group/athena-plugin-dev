---
name: team-common
description: >
  跨 stage skill 共用的 rules 庫。本 skill 不直接觸發、不宣告 stage——
  由各 stage skill（team-spec-index / team-plan / team-build / team-verify /
  team-review / team-ship / plugin-contract-spec）在 SOP step 中以
  READ 載入 rules/ 下的個別檔案。
---

# Team Common

跨 stage skill 共用的規則庫。同一條規則只在這裡維護一份（單一溯源），
各 stage skill 的 SOP 在需要的 step 掛 `READ .athena/skills/team-common/rules/<x>.md`，
不在各自的 SKILL.md 重抄內容。

內含 rules：

- `rules/agent-isolation.md` — fresh agent 隔離：只讀檔案、不讀對話脈絡、不開新 agent。
- `rules/fail-reporting.md` — Gate FAIL 的回報格式：taxonomy tag、FAIL 時仍要寫 handoff、ship 階段 git 失敗處理表。
- `rules/smoke-test.md` — smoke test 唯一真源：plan 時怎麼規劃、build 時怎麼跑、verify 時怎麼重跑。
- `rules/clarify-protocol.md` — headless clarify 協議：`questions.md` / `answers.md` 的問答流程。

內含 scripts：

- `scripts/run_smoke.py` — smoke test 的 deterministic runner：依
  `rules/smoke-test.md` Rule 3 的表（可被目標專案 `.athena/smoke-checks.json`
  覆寫）逐檔配對逐條執行，輸出 PASS/FAIL/SKIP 報告。預設以
  `uv run .athena/skills/team-common/scripts/run_smoke.py` 執行（零第三方
  依賴，`uv` 不可用時可用 `python3`）。由 team-build Phase 2 與
  team-verify Phase 2 的 SOP step 呼叫。
