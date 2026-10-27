---
name: team-spec-index
description: >
  Spec stage 的路由索引。本 repo 有兩種需求輸入：PM 的產品功能需求單
  （有實體、畫面、endpoint），以及 plugin 自身的 prompt 契約改動
  （skills / agents / hooks / scripts，沒有資料模型也沒有畫面）。
  兩者需要完全不同的 spec 流程，由本 index 依機械判準分流到
  pm-to-eng-spec 或 plugin-contract-spec。
stage: spec
---

# Spec Index（athena-dev-plugin）

你是 spec stage 的**路由器**（router：只判定該走哪條 spec 流程，不自己寫規格）。

# SOP

## Phase 1 -- 判定路由並寫 route.md

1. READ 讀取 `.athena/skills/team-common/rules/agent-isolation.md`，確認 fresh agent 的輸入來源與「同一個 agent 內 DELEGATE」的邊界。
2. READ 讀取 `points/<slug>.md`，取需求原文與改動標的清單；若 `specs/<slug>/clarify/answers.md` 存在，一併讀入納為判準依據。
3. READ 讀取 `rules/routing.md`，取得分流判準表與路由器行為規則。
4. THINK 依判準表**依序**檢查改動標的落在哪些路徑，第一個命中就決定路由；標的清單不足時用 Grep 自己查證。
5. READ 若判不出來：讀取 `.athena/skills/team-common/rules/clarify-protocol.md`，照協議寫 `specs/<slug>/clarify/questions.md` 與 FAIL handoff（`#spec-gap`）後停止。
6. WRITE 依 `templates/route.md` 骨架（成品樣貌見 `templates/route.example.md`）把路由結果與依據寫入 `specs/<slug>/route.md`。

## Phase 2 -- DELEGATE 子 skill 並產出最終 handoff

1. READ 讀取中選子 skill 的 SKILL.md（`.athena/skills/plugin-contract-spec/SKILL.md` 或 `.athena/skills/pm-to-eng-spec/` 的入口）——判完路由才讀，不預先讀兩份。
2. DELEGATE 在**本 agent 內**依中選子 skill 的步驟執行；路由為「兩者依序」時，先跑 `plugin-contract-spec`，再跑 `pm-to-eng-spec`。
3. READ 確認 `handoffs/<slug>-spec.md` 已由子 skill 寫出；缺少或需要合成時，依 `rules/routing.md` 的 verdict 與合成規則處理。
4. WRITE 路由為「兩者依序」時：讀取 `skills/athena-flow/references/agent-handoff.md` 的 Spec 變體，照 `rules/routing.md` 的合成規則把兩份產出合成**一份** `handoffs/<slug>-spec.md`。
