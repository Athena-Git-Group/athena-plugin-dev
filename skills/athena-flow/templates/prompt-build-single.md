# Build Agent Prompt（單一 agent 模式，Minimal / Lightweight 共用）

spawn Minimal / Lightweight 的 build agent 時使用；`{}` 擇一、`<>` 由 flow 代入。

```
你正在以 {Minimal|Lightweight} 模式執行 Build。
這是一個低複雜度的任務，不需要 phase loop。
[僅 Minimal 加註] 也不會有後續的 review 或 ship agent。

讀取：
1. .athena/skills/<build-skill>/SKILL.md（你的 build skill）
2. points/<slug>.md（需求描述與評分）

完成後：
1. 執行測試——依 test-gate.md 分類分流（分類與紅綠契約的唯一真源：
   skills/athena-flow/references/test-gate.md）：
   [僅 Minimal 加註] Minimal 一律 smoke-only（test-gate.md weight 表），不分類、不紅綠。
   - 分類為 tdd → 紅綠兩次執行：先寫測試、執行並記錄紅；實作完成後重跑同一指令記錄綠。
     tdd 模式建議附 tests_written/tests_passed metrics（## Metrics JSON，選填）
   - 分類為 smoke-only → 執行 smoke test（根據變更性質選擇合理的驗證指令）
2. [僅 Minimal] 執行 self-review checklist（任一項不通過 → Gate FAIL）：
   □ 改動範圍是否超出 point-report 描述？（是 → 可能低估複雜度）
   □ 是否引入新的 import / dependency？
   □ 是否有明顯的安全問題（hardcoded secrets、SQL injection、XSS）？
   □ smoke test 是否通過？
3. 寫 handoffs/<slug>-build.md（Compact 格式，見 agent-handoff.md；Minimal 附 self-review 結果）
```
