---
name: team-review
description: >
  本 repo（athena-dev-plugin）的 review stage skill。品質視角 review
  markdown skill 文件、bash hooks、python script：正確性、一致性、
  與 repo 慣例對齊、文件內部引用完整。✅/🟡/💡 三段式輸出；只有
  正確性/一致性問題才 request-changes，品質建議不擋流程。
stage: review
---

# Team Review（athena-dev-plugin）

你是 review 階段的執行者。**你沒有 Edit 權限——指出問題，不修問題。**

> **Agent 隔離**：你在全新的 agent 中執行，一切依據來自檔案。

## 先讀哪些檔

1. `handoffs/<slug>-build.md` + `handoffs/<slug>-verify.md`（若有）
2. 實際 diff：`git diff <base>...HEAD` 或 `git show`

## Review 視角（針對本 repo 的產物型態）

| 面向 | 檢查內容 | FAIL？ |
|------|----------|--------|
| 正確性 | 指令/路徑/格式範例是否正確；bash/python 邏輯錯誤；frontmatter 欄位值合法 | 是（request-changes） |
| 一致性 | 與既有契約檔（stage-contracts、agent-handoff）不矛盾；同一概念用同一術語 | 是（request-changes） |
| repo 慣例 | 命名（小寫連字號）、中文 description、指令式寫法、與鄰近 skill 風格對齊 | 否（🟡 建議） |
| 引用完整 | 文件內相對路徑引用的檔案存在（逐一查證）；死連結 | 是（request-changes） |
| 品質 | 精簡度、可讀性、更好的寫法 | 否（💡 建議） |

## 輸出格式（三段式）

- **✅ 通過項**：確認無誤的面向，一行一條
- **🟡 建議修**：不擋流程的一致性/慣例建議，附 檔案:行號
- **💡 可選優化**：品質建議

**只有正確性、一致性、引用完整的問題才判 FAIL（request-changes）**；🟡/💡 不影響 Gate Verdict。

## Handoff 輸出

- 獨立 review stage（Full 路由）：寫 `handoffs/<slug>-review.md`
- Lightweight 合併模式：由 flow prompt 指定併入 `handoffs/<slug>-review-ship.md`
  （Review Verdict 段），格式見 `skills/athena-flow/references/agent-handoff.md`
  「Compact Review-Ship Handoff」；request-changes 時**停止 ship**，Gate Verdict = FAIL

獨立 handoff 格式：

```markdown
# Handoff: review

## Stage
review

## Inputs Used
- handoffs/<slug>-verify.md
- git diff <range>

## Review Result
### ✅ 通過項
### 🟡 建議修（不擋）
### 💡 可選優化

## Artifacts Produced
- handoffs/<slug>-review.md

## Gate Verdict
PASS — approved, <一句話摘要>
（request-changes 時：FAIL — <正確性/一致性問題一句話> #review-finding）

## Risks / Unresolved Issues
<若無則 None>

## Next Recommended Stage
ship
```

## 非協商規則

1. **只指出問題，不修**——修改由 build agent 執行
2. FAIL 只能因正確性/一致性/引用完整問題；品質建議一律放 🟡/💡
3. FAIL 時 Gate Verdict 必須帶 `#review-finding` tag
4. 完成後必須寫 handoff（或依 flow 指定併入 review-ship handoff），不可省略
