---
name: plugin-contract-spec
description: >
  plugin 自身的 spec skill。標的是 LLM 讀的行為契約（skills / agents /
  commands / hooks / scripts），這類需求沒有資料模型、資料表、畫面或
  endpoint。產出：契約面盤點（grep 實據）→ 逐項改動規格 → 既有規則衝突
  檢查 → 驗收條件。由 team-spec-index DELEGATE，不自行宣告 stage。
---

# Plugin Contract Spec

你在寫的規格，標的是**行為契約**（給 LLM agent 讀、決定它怎麼行動的文字檔）：`skills/**/SKILL.md`、`skills/**/references/*.md`、`agents/*.md`、`commands/*.md`，以及支撐它們的 shell hook（`hooks` 下的 `*.sh`）與 python script（`scripts` 下的 `*.py`）。

# SOP

## Phase 1 -- 讀輸入並盤點契約面

1. READ 讀取 `.hxde/skills/team-common/rules/agent-isolation.md`，確認 fresh agent 的輸入來源與邊界。
2. READ 讀取 `rules/gates.md`，確認工具邊界、範圍邊界與各產出物的 gate 條件。
3. READ 讀取 `points/<slug>.md`（需求原文、scorecard、Risks 段、point 已查證的消費者清單——是起點不是終點）與 `specs/<slug>/route.md`；若 `specs/<slug>/clarify/answers.md` 存在，一併讀入。
4. READ 讀取每個改動標的檔案本身的原文——規格要引用現況，不能憑印象描述。
5. WRITE 把需求原文自 point-report 抄錄到 `specs/<slug>/source/requirement.md`（不可變、不改寫、不摘要）。
6. READ 讀取 `rules/failure-shapes.md` 與 `rules/consumer-detection.md`，確認這類改動為何必須窮舉消費者、以及消費者怎麼分類與舉證。
7. THINK 對每個改動項窮舉消費者：擬搜尋字串、實跑 grep、依已載入判準分類（逐項列舉式／指標式／跨語言）。
8. WRITE 依 `templates/contract-surface.md` 骨架（成品樣貌見 `templates/contract-surface.example.md`）寫 `specs/<slug>/contract-surface.md`，每列附真實 grep 輸出。

## Phase 2 -- 逐項改動規格、衝突檢查與驗收條件

1. WRITE 依 `templates/change.md` 骨架（成品樣貌見 `templates/change.example.md`）為每個改動項寫 `specs/<slug>/changes/<ID>.md`，一項一檔，現況原文引用帶檔案:行號。
2. THINK 對每個改動項檢查與既有非協商規則的衝突：掃 `skills/*/SKILL.md`、`.hxde/skills/*/SKILL.md` 的非協商段與相關 references，依 `rules/gates.md` 的衝突判準逐項給結論。
3. WRITE 依 `templates/conflicts.md` 骨架（成品樣貌見 `templates/conflicts.example.md`）寫 `specs/<slug>/conflicts.md`。
4. WRITE 依 `templates/acceptance.md` 骨架（成品樣貌見 `templates/acceptance.example.md`）寫 `specs/<slug>/acceptance.md`，機械與通讀兩類都要。

## Phase 3 -- Clarify 與 handoff

1. THINK 檢查是否仍有未解問題；有則 READ `.hxde/skills/team-common/rules/clarify-protocol.md`，照協議寫 `specs/<slug>/clarify/questions.md`。
2. READ 讀取 `skills/hxde-flow/references/agent-handoff.md` 的 Spec 變體與機械契約紅線，以及 `.hxde/skills/team-common/rules/fail-reporting.md` 的 FAIL 格式與 taxonomy tag 規則。
3. THINK 依 `rules/gates.md` 的 gate 條件判定 Gate Verdict（PASS 或 FAIL 帶 tag）。
4. WRITE 照 Spec 變體格式寫 `handoffs/<slug>-spec.md`，並在 `## Artifacts Produced` 之後加一段本 skill 自有的 `## 契約面摘要`（表格欄位：改動項／錨點／必須同步的消費者／跨語言），`## Next Recommended Stage` 填 plan。
