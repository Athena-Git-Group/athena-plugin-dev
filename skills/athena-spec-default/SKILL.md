---
name: athena-spec-default
description: >
  Spec stage 的 plugin 預設實作。團隊未在 .athena/skills/ 提供 stage: spec 的
  skill 時，flow 退回本 skill；團隊有提供時本 skill 完全不被載入。
  本身不含規格邏輯——指向 athena-core 的 spec pack（pm-to-eng-spec）並在
  同一個 spec agent 內執行它。
stage: spec
user-invocable: false
---

# Athena Spec Default

你在 `athena-stage-spec` 殼內被載入，因為這個專案的 `.athena/skills/` 下
**沒有**任何宣告 `stage: spec` 的團隊 skill。這是正常的預設路徑，不是異常——
不要停下來回報，照下面做即可。

本 skill **不含任何規格邏輯**，只負責把執行權交給真正的實作。

## 你要做什麼

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/athena-core/assets/spec-pack-pm-to-eng/SKILL.md`
   —— 那是 spec 的真源（PM 需求 → 工程化規格的多 phase 編排）。
2. **在同一個 agent 內**依它的指示執行。**不要開新 agent**——spec 殼沒有 Agent 工具，
   pack 本身就是設計成單一 agent 內順序跑完 `phases/`。
   pack 內的相對路徑（`phases/`、`references/`）一律相對於
   `${CLAUDE_PLUGIN_ROOT}/skills/athena-core/assets/spec-pack-pm-to-eng/` 解析。
3. Gate 映射與最終 `handoffs/<slug>-spec.md` **由 pack 的 wrapper 負責**——
   本薄殼不自己產 verdict、不自己寫 handoff。

## 與團隊安裝版的關係

團隊若要修改流程，會把同一份 pack `cp -R` 到 `.athena/skills/pm-to-eng-spec`
（見 pack 的 `README.md`）。那之後 discovery 會掃到團隊副本並綁定 `stage: spec`，
本 skill 就**完全不再被載入**——兩者不會同時生效，也不會互相衝突
（plugin 預設永遠不進 discovery 對應表，見
`${CLAUDE_PLUGIN_ROOT}/skills/athena-flow/references/stage-contracts.md`「Skill Discovery」）。

## 非協商規則

1. **不複製 pack 內容到本檔**——本檔是指標，pack 是唯一真源；兩份會漂移
2. **不自己產 gate verdict、不自己寫 handoff**——那是 pack wrapper 的職責
3. **不開新 agent**——spec 殼無 Agent 工具，pack 在同一 agent 內順序執行
