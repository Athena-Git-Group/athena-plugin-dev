---
name: team-build
description: >
  本 repo（athena-dev-plugin）的 build stage skill。產物是 markdown skill
  文件、bash hooks 與少量 python script——不是一般 app。依 point-report
  （Minimal/Lightweight）或 phase card + mini-handoff（Full）實作，
  依改動類型執行對應 smoke test，寫 Compact 格式 build handoff。
stage: build
---

# Team Build（athena-dev-plugin）

你是 build 階段的執行者。

> **Agent 隔離**：你在全新的 agent 中執行，沒有前一個 stage 的對話脈絡。
> 所有前置資訊都必須從檔案讀取。

## 先讀哪些檔

- Minimal / Lightweight：`points/<slug>.md`（point-report——任務描述、驗收條件與 **Risks 段**）
- Full（phase loop）：`plans/<slug>/doing/<NN>-<name>.md`（phase card）+
  `handoffs/<slug>-build-phase-<prev-NN>.md`（前一 phase 的 mini-handoff，若有）

## 職責

依 point-report 的任務描述實作，**改動範圍不得超出 point-report**。
特別注意 point-report 的 Risks 段——實作時逐條避開列出的風險。

## 執行步驟

1. （選填）取 `Started At:`：`date -u +%Y-%m-%dT%H:%M:%SZ`
2. 讀輸入檔，列出要改的檔案清單，確認全部落在 point-report 範圍內
3. 實作
4. 依改動類型執行 smoke test（見下）
5. 寫 handoff（見下）

## Smoke Test（依改動類型選擇）

| 改動類型 | 檢查指令 |
|----------|----------|
| bash（`.sh`） | `bash -n <file>` |
| python（`.py`） | `python3 -m py_compile <file>` |
| markdown / SKILL.md | frontmatter 可被解析（YAML 區塊完整、必填欄位存在）+ 檔內相對路徑引用的檔案實際存在（逐一 `ls` 查證） |
| Gherkin `.feature`（若任務涉及） | gherkin parser 可用則跑之；否則至少 grep 檢查 `Feature:` / `Scenario:` / `Given/When/Then` 關鍵字結構一致 |

多類型混合改動就每類都跑。任一失敗 → Gate FAIL。

## 明確禁止

- 禁止 `git push`
- 禁止修改 `points/<slug>.md`（point-report 是唯讀輸入）
- 禁止超出 point-report 範圍的改動（發現必要的範圍外改動 → 記入 Risks，不動手）

## Handoff 輸出

- Minimal / Lightweight：寫 `handoffs/<slug>-build.md`（Compact 格式）
- Full：寫 `handoffs/<slug>-build-phase-<NN>.md`（mini-handoff 格式，見
  `skills/athena-flow/references/agent-handoff.md`；最終 build handoff 由 flow 合成，不由你寫）

Compact 格式標題級骨架如下；完整欄位與變體差異（Compact 相對 base 刪 `## Stage` / `## Inputs Used` /
`## Artifacts Produced` / `## Next Recommended Stage`，Minimal 另加 `## Self-Review`）見
`skills/athena-flow/references/agent-handoff.md` 變體差異表：

```markdown
# Handoff: build (lightweight)

<一行摘要——H1 後隔一空行的第 3 行>

## Gate Verdict
PASS / FAIL — <一句話原因> #<tag>（本行緊貼標題；FAIL 必帶 taxonomy tag，enum 見 skills/athena-flow/references/run-trace.md Failure Taxonomy 段）

## Files Changed
## Smoke Test Result
## Risks / Unresolved Issues
## Timing（選填）
```

## 非協商規則

1. 只做本 stage 契約定義的工作，不越界幫 verify/review 做事
2. 完成後必須寫 handoff，不可省略
3. Gate Verdict 為 FAIL 時必須帶 failure taxonomy tag
