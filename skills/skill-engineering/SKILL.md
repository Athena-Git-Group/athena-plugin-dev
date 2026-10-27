---
name: skill-engineering
description: 為創建新 skill 或優化既有 skill／skill chain 建立模組化工程流程。會先判斷是 create lane 還是 optimize lane；優化時先做根因確認閘門，回推問題、對齊預期、定位根因並等待使用者確認，再重建 SOP 控制平面、逐步決定 keep-inline、rewrite、derive-rule、derive-template、derive-script 或 delete，最後調度既有 deriver 落地。
disable-model-invocation: true
---

# Skill 工程化

創建新 skill 或優化既有 skill 時，先重建控制平面並維持單一溯源，再按需展開模組。若是優化既有 skill，必須先完成根因確認閘門；未收到確認前，不得開始後續編排或檔案修改。

# SOP

## Phase 1 -- 收斂入口與分析範圍

1. READ 讀取使用者需求、目標 skill 或相關 skill chain 的檔案範圍，確認本次是創建新 skill 還是優化既有 skill，並收斂要處理的 skill 目錄、關聯 skills 與預期產物。
2. DELEGATE 若需要先盤點目標 skill 或 skill chain 的 `SKILL.md`、被引用 skill、`rules/`、`templates/`、`scripts/` 與可能的孤兒檔案，執行 `uv run .agents/skills/skill-engineering/scripts/analyze_skill_references.py --skill <skill-dir> [--skill <skill-dir> ...]` 產出引用與資源盤點，再用結果收斂後續要深入閱讀的 skill 範圍。

## Phase 2 -- 優化時完成根因確認閘門

1. THINK 若本次是優化既有 skill，先讀取 `rules/優化時先做根因分析與確認閘門.md`，再根據使用者描述的不滿意結果，回推並實際演練目標 skill 或 skill chain 的 SOP、相關 `rules/`、`templates/`、`scripts/`，收斂預期結果、現況、落差分析、根因、建議改動層級與候選刪除項。
2. WRITE 若本次是優化既有 skill，先讀取 `templates/skill-root-cause-report.md` 與 `templates/skill-root-cause-report.example.md`，再依骨架複製根因確認閘門報告結構、參考範例改寫填位符號與具體內容，向使用者提交一份說明預期、現況、落差、根因、建議改動層級與候選刪除項的分析；報告標題、欄位名稱、條列說明與樣板註解衍生內容皆必須以繁體中文為主。
3. READ 若本次是優化既有 skill，讀取使用者對根因確認閘門的確認或修正意見；未收到確認前停止，不進入後續編排提案或檔案修改。

## Phase 3 -- 重建控制平面與編排提案

1. DELEGATE 呼叫 `/skill-form-sop` 建立新 skill 的 SOP section，或把既有 skill 的 SOP 重建成最小可執行控制平面，讓後續編排都以同一版 SOP 為主幹。
2. THINK 若需要判斷各 step 應保留 inline、重寫、展開 `rule`、展開 `template`、展開 `script`，或直接刪除，先讀取 `rules/主流程重建與模組編排判準.md`、`rules/刪除與改動層級判準.md` 與 `rules/來源能力語意密度與指導面積保留判準.md`，再逐 step 收斂 keep-inline、rewrite、derive-rule、derive-template、derive-script、delete 的決策，判斷本次改動應屬的層級，辨識高指導面積來源，規劃其保留位置與保留粒度，並標記任何違反單一溯源或語意密度保留的問題。
3. WRITE 先讀取 `templates/skill-engineering-plan.md` 與 `templates/skill-engineering-plan.example.md`，再依骨架複製編排提案結構、參考範例改寫填位符號與具體內容，向使用者提交一份說明處理路徑、控制平面重建方式、來源能力保留策略、步驟決策、預計新增或修改的檔案、預計刪除項與驗證方式的 skill engineering plan；提案的章節標題、欄位名稱與說明文字皆必須以繁體中文為主。
4. READ 讀取使用者對 skill engineering plan 的確認或修正意見；若使用者只要求提案，停在此處；若使用者確認進入實作，才進入後續 phase。

## Phase 4 -- 依編排提案完成模組化落地

1. DELEGATE 若某個 step 需要額外把關規則，呼叫 `/skill-derive-rule` 展開或重寫對應 `rules/` 模組，並把讀取時機回掛到主 SOP。
2. DELEGATE 若某個 step 需要穩定輸出骨架，呼叫 `/skill-derive-template` 展開或重寫對應 `templates/` 模組，並把讀取時機回掛到主 SOP。
3. DELEGATE 若某個 step 需要可重複自動化處理，呼叫 `/skill-derive-script` 展開或重寫對應 `scripts/` 模組，並把執行時機、路徑與預設執行方式回掛到主 SOP。
4. WRITE 依確認版 plan 實際更新目標 skill 或 skill chain 的 `SKILL.md` 與相關模組，必要時刪除已被新設計淘汰的 phase、step、rule、template、script 與孤兒檔案，避免只做疊加修補。

## Phase 5 -- 驗證整體工程品質

1. DELEGATE 若需要檢查修改後的 skill 或 skill chain 是否仍有缺漏引用、孤兒檔案或模組未回掛主 SOP，執行 `uv run .agents/skills/skill-engineering/scripts/analyze_skill_references.py --skill <skill-dir> [--skill <skill-dir> ...]` 重新盤點並比對結果。
2. READ 回頭檢查最終結果是否符合本次已載入規則與已確認 plan：SOP 仍是最小可執行控制平面、已委派資源維持單一溯源且保留必要語意密度、優化任務已完成根因確認閘門、各模組邊界清楚、刪除項已清理、相關 skills 的 handoff 一致，且所有新增或修改樣板的章節標題、註解與說明文字皆以繁體中文為主；若不符合，立即修正。
