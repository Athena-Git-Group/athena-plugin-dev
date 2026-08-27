---
name: team-verify
description: >
  本 repo（athena-dev-plugin）的 verify stage skill。獨立驗證 build 宣稱的
  完成項：逐條對 point-report 驗收、重跑 smoke 檢查、針對 Risks 段做機械查證。
  只回報不修（無 Edit 權限），issues 具體到檔案:行號。Handoff 兩種模式：
  Full（PASS-SPEC-FIRST）完整格式（讀 mini-handoff、issues 標 affected_phase）；
  Lightweight（PASS-BUILD-WITH-VERIFY）= Full + 差異表。
stage: verify
---

# Team Verify（athena-dev-plugin）

你是 verify 階段的執行者。**你沒有 Edit 權限——只回報，不修。**

> **Agent 隔離**：你在全新的 agent 中執行，一切依據來自檔案，
> 不得信任 build handoff 的宣稱——要自己重新查證。

## 先讀哪些檔

1. `handoffs/<slug>-build.md`（build 宣稱的完成項與 smoke 結果）
2. `points/<slug>.md` 的任務描述與 **Risks 段**
3. 實際 diff：`git diff <base>...HEAD` 或 `git show`（以 git 為準，不以 handoff 敘述為準）
4. **僅 Full Weight（PASS-SPEC-FIRST）**：所有 mini-handoff `handoffs/<slug>-build-phase-*.md`——用來把 issue 對回 affected phase

## 執行步驟

1. （選填）取 `Started At:`（`date -u +%Y-%m-%dT%H:%M:%SZ`）
2. **逐條驗收**：把 point-report 的任務描述/驗收條件拆成清單，逐條對 diff 查證有做且做對
3. **重跑 smoke**：不信 build handoff 的結果，依改動類型自己重跑（bash → `bash -n`；
   python → `python3 -m py_compile`；markdown/skill → frontmatter 可解析 + 相對路徑引用存在；feature 檔 → 關鍵字結構檢查）
4. **Risks 機械查證**：對 point-report Risks 段列的每一條風險，設計一個機械檢查
   （例如「可能漏改其他引用處」→ `grep -rn` 全 repo 查舊字串殘留）並執行
5. **範圍檢查**：diff 中是否有 point-report 範圍外的改動
6. 寫 handoff

## Issue 回報要求

- 每個 issue 必須具體到 `檔案:行號`，附一句話說明與判定依據（指令輸出或 diff 行），並各帶自己的 taxonomy tag
- **僅 Full Weight**：每個 issue 以 `[Phase NN]` 開頭標記 affected phase（慣例見
  `skills/athena-flow/references/verify-retry.md`；未標記的 issue 視為 verify skill 的 bug）

## Handoff 輸出

寫 `handoffs/<slug>-verify.md`。兩種模式都必須包含 `skills/athena-flow/references/stage-contracts.md`
「Handoff 契約（通用）」的 6 欄：Stage / Inputs Used / Artifacts Produced / Gate Verdict / Risks / Next Recommended Stage。

### Full 格式（PASS-SPEC-FIRST，權威全文）

完整 6 欄 + issue 逐條標 `[Phase NN]`（供 flow 按 affected_phase 分組做
per-phase targeted fix，見 `skills/athena-flow/references/verify-retry.md`）。

```markdown
# Handoff: verify

## Stage
verify

## Inputs Used
- points/<slug>.md
- handoffs/<slug>-build.md（flow 合成的最終 build handoff）
- handoffs/<slug>-build-phase-<NN>.md（所有 mini-handoff，逐一列出）
- git diff <base>...HEAD

## Artifacts Produced
- handoffs/<slug>-verify.md（本檔；verify 只回報，不產出程式碼）

## Gate Verdict
PASS — <一句話原因>
（FAIL 時：FAIL — <原因> #<tag>，enum 見 skills/athena-flow/references/run-trace.md Failure Taxonomy 段）

## Checks Performed
- <驗收條目>: PASS/FAIL
- <smoke 重跑指令>: <result>
- <risk 查證指令>: <result>

## Issues Found
1. **[Phase NN]** <檔案:行號> — <問題> #<tag>
（若無則 None；每條必標 [Phase NN]）

## Affected Phases
- Phase <NN>: <issue 數>
（若無 issue 則 None）

## Risks / Unresolved Issues
<若無則 None>

## Next Recommended Stage
review（PASS 時）/ build（FAIL 時，flow 按 affected_phase 做 per-phase targeted fix）

## Timing
- Started At: <ISO-8601 UTC，選填>
- Ended At: <ISO-8601 UTC，選填>
```

### Lightweight 格式（PASS-BUILD-WITH-VERIFY）= Full 格式 + 下列差異

| 差異點 | Lightweight 寫法 |
|--------|-----------------|
| H1 | `# Handoff: verify (lightweight)` |
| Inputs Used | 不含 mini-handoff（無 phase loop；只列 points/<slug>.md、handoffs/<slug>-build.md、git diff） |
| Issues Found | 每條**不加** `[Phase NN]` 前綴 |
| `## Affected Phases` | **整段無** |
| Next Recommended Stage | review-ship（PASS 時）/ build（FAIL 時，targeted re-build） |

## 非協商規則

1. **只回報不修**——發現問題寫進 Issues Found，由 build agent 做 targeted re-build
2. 所有判定依據來自實際 diff 與自己重跑的指令，不採信 build handoff 的宣稱
3. Gate Verdict 為 FAIL 時必須帶 failure taxonomy tag；多個獨立問題各帶各的 tag
4. 完成後必須寫 handoff，不可省略
