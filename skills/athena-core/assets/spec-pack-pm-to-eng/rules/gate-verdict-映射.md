# Rule 1 - Gate Verdict 映射表是最終 handoff verdict 的唯一來源，FAIL 字串一字不得改

- Level: `MUST`
- 最終 handoff `## Gate Verdict` 欄位的內容一律照下表逐字填寫。下表的 FAIL 字串是 athena-flow 的**機械契約**，由 flow 解析 verdict 與 taxonomy tag，**一字不得改**——不得改標點（含全形括號與破折號 `—`）、不得改 tag、不得自行翻譯或縮寫。
- `<slug>` 與 `<phase>` 是填位符號，填入本次實際的 slug 與 phase 名稱；其餘字元逐字照抄。

| 情況 | 最終 handoff Gate Verdict |
|------|--------------------------|
| score VERDICT = `BLOCKED` | `FAIL — 需求可譯性不足（score BLOCKED），退回 PM 補件 #spec-gap` |
| score VERDICT = `PASS-WITH-GAPS` | **不影響 verdict**（續跑）；缺口記入 Risks |
| score VERDICT = `PASS-CLEAN` | **不影響 verdict**（無缺口，不必為 score 補 Risks 行） |
| clarify gate 未過（仍有未解問題，**或** `clarified.md` 首行 `STATUS: BLOCKED`） | `FAIL — clarify 待使用者澄清，見 specs/<slug>/clarify/questions.md #spec-gap`（BLOCKED 時 Risks 另記成因） |
| specify `STATUS: NEEDS-CLARIFICATION` | `FAIL — specify 待澄清（spec.md STATUS: NEEDS-CLARIFICATION），見 specs/<slug>/clarify/questions.md #spec-gap` |
| `spec.md` 缺失 / 為空 / 首行非 `STATUS: READY` 而下游被觸發 | `FAIL — specify 產出缺失 #skill-defect` |
| frontend / fullstack track 的 `ui_prototype` 產出缺失或為空 | `FAIL — ui_prototype 產出缺失 #skill-defect` |
| `ui_prototype`（**非 gate**）追寫 `clarify/questions.md` | **不影響 verdict**（不 FAIL、不停止）；Risks **必須**記「`ui_prototype` 追寫 N 題待澄清，見 `specs/<slug>/clarify/questions.md`」，且該檔列入 Artifacts Produced。**不得靜默吞掉** |
| 任一 phase artifact 缺失或為空 | `FAIL — <phase> 產出缺失 #skill-defect` |
| api transpiler 環境缺失 | `FAIL — 需 python3 + pyyaml #env` |
| 全部 phase 完成 | `PASS` |

## Good Example

- 這個例子是好的，因為 verdict 行逐字照抄映射表，flow 能機械解析出 FAIL 與 `#spec-gap` tag。

````md
## Gate Verdict
FAIL — clarify 待使用者澄清，見 specs/refund/clarify/questions.md #spec-gap
````

## Bad Example

- 這個例子是壞的，因為它改寫了契約字串、丟掉 taxonomy tag，flow 無法判讀失敗類別。

````md
## Gate Verdict
FAIL: clarify 還有問題沒解決，請看 questions.md
````

# Rule 2 - 三道 gate 依序把關，前一道未過不得進入下一道

- Level: `MUST`
- **三道 gate**：score BLOCKED 不得進 clarify；clarify 未 RESOLVED 不得進 specify；**specify 未 READY 不得進結構層**。
- `clarified.md` 首行為 `STATUS: BLOCKED`（clarify 自判完成判準未達成）與「clarify 仍有未解問題」是**同一道 gate**：兩者都**不得進 specify**，最終 handoff 用**相同**的字串 `FAIL — clarify 待使用者澄清，見 specs/<slug>/clarify/questions.md #spec-gap`，**停止**；BLOCKED 時 Risks 另記一行「clarify STATUS: BLOCKED」以區分成因。
- score VERDICT 只會是 `BLOCKED` / `PASS-WITH-GAPS` / `PASS-CLEAN` 三個值：`BLOCKED` 寫 FAIL 並停止；`PASS-WITH-GAPS` 續跑且缺口記入 Risks；`PASS-CLEAN` 續跑且**無缺口需記入 Risks**。

## Good Example

- 這個例子是好的，因為 clarify 未過時直接收 FAIL 停止，沒有硬闖 specify。

````md
clarified.md 首行：STATUS: BLOCKED
→ 追寫 clarify/questions.md，寫最終 handoff FAIL，停止；Risks 另記「clarify STATUS: BLOCKED」
````

## Bad Example

- 這個例子是壞的，因為它把 BLOCKED 當成「大致可用」就往下跑，後面所有 phase 都建立在未澄清的需求上。

````md
clarified.md 首行：STATUS: BLOCKED
→ 先照既有內容跑 specify，最後再在 Risks 補一句「clarify 尚未完全澄清」
````

# Rule 3 - 任一 phase artifact 缺失或為空即 FAIL 停止，不硬闖下一 phase

- Level: `MUST`
- 每個 phase 執行完必須確認其 artifact 存在且非空、內部 handoff 已寫；任一 phase artifact 缺失或為空 → FAIL 停止，**不硬闖下一 phase**。
- `api` phase 執行前先驗 `command -v python3` 與 `python3 -c "import yaml"`；缺任一項時保留已產出的 `*.intent.yaml`，最終 handoff 寫 `FAIL — api phase 需 python3 + pyyaml，環境缺失 #env`，明說 openapi.yaml 未產出，**停止**。
- `phases/api` 建議的 spec 驗證工具（`openapi-spec-validator` / `npx @redocly/cli`）屬**選用**：兩者皆不可用時**跳過驗證、不 FAIL、不觸網安裝**，在最終 handoff 的 Risks 記「openapi.yaml 未經 validator 驗證」。

## Good Example

- 這個例子是好的，因為缺少的是選用的 validator（跳過並記 Risks），缺少的是必要的 pyyaml 才停止。

````md
python3 -c "import yaml" 失敗 → 保留 *.intent.yaml，FAIL — api phase 需 python3 + pyyaml，環境缺失 #env，停止
openapi-spec-validator 與 npx @redocly/cli 都不可用 → 跳過驗證、續跑，Risks 記「openapi.yaml 未經 validator 驗證」
````

## Bad Example

- 這個例子是壞的，因為它在必要環境缺失時仍硬闖下一 phase，又為了選用工具觸網安裝。

````md
python3 -c "import yaml" 失敗 → 先跳過 openapi.yaml，直接跑 gherkin
openapi-spec-validator 不可用 → npm install -g @redocly/cli
````

# Rule 4 - clarify 不得腦補使用者未給的答案

- Level: `MUST`
- clarify 不得腦補使用者未給的答案——能從需求文件 + `clarify/answers.md` 客觀回答的問題才就地解決。
- 不確定就寫進 `clarify/questions.md` 走 FAIL 協議（題號與標記依 `rules/questions-共用契約.md`），由使用者回答後重跑 spec stage。

## Good Example

- 這個例子是好的，因為沒有依據的問題被升級成題目，而不是被自行填上一個看似合理的值。

````md
需求未提退款期限 → 追寫 Q5 · [clarify] 退款可申請的期限是多久？，FAIL 停止
````

## Bad Example

- 這個例子是壞的，因為它用「業界慣例」替使用者決定了一條會進 spec.md 的業務規則。

````md
需求未提退款期限 → 依業界慣例填 30 天，寫入 clarified.md 續跑
````

# Rule 5 - 最終 handoff 必含 Minimum Contents 六欄，FAIL 必帶 taxonomy tag

- Level: `MUST`
- 最終 handoff 必含 athena-flow `agent-handoff.md` 契約的 Minimum Contents 六欄：`## Stage`、`## Inputs Used`、`## Artifacts Produced`、`## Gate Verdict`、`## Risks / Unresolved Issues`、`## Next Recommended Stage`。
- FAIL 必帶 taxonomy tag（`#spec-gap` / `#skill-defect` / `#env`），tag 照映射表，不得自創。

## Good Example

- 這個例子是好的，因為六欄齊備，FAIL 行帶著映射表指定的 taxonomy tag。

````md
## Gate Verdict
FAIL — specify 產出缺失 #skill-defect

## Risks / Unresolved Issues
- specify phase 未產出 spec.md
````

## Bad Example

- 這個例子是壞的，因為它少了 taxonomy tag，也漏掉 Risks 欄，flow 無法分流也看不到未解事項。

````md
## Gate Verdict
FAIL — specify 產出缺失
````
