# Skill 工程編排提案

## 任務資訊

- 處理路徑: `optimize`
- 改動範圍: `skill rewrite`
- 目標 Skills: `skill-engineering`

## 控制平面重建

- 把原本單一路徑流程重構成 `create lane` 與 `optimize lane`。
- 在 optimize lane 前面新增根因確認閘門，並要求使用者先確認分析觀點。
- 讓兩條入口在「重建 SOP 控制平面與逐 step 編排」會合，避免方法論分叉。

## 來源能力保留策略

- 來源能力：既有 optimize 流程中缺失的 root cause gate、delete-friendly 編排，以及引用盤點自動化。
- 保留位置：root cause gate 留在 `SKILL.md` 控制平面；細部 gate 判準放入 `rules/優化時先做根因分析與確認閘門.md`；固定輸出骨架放入 `templates/skill-root-cause-report.md`。
- 保留粒度：保留預期、現況、落差、根因、改動層級與候選刪除項，不壓縮成「先分析再改」一句話。
- 可安全摘要：舊流程中只描述背景的說明文字可刪除，不保留為獨立規則。

## 步驟決策

- `入口判斷`：keep inline，保留在主 SOP。
- `優化前根因分析`：keep inline，並追加根因確認閘門樣板。
- `編排決策`：keep inline，但改寫成逐 step 的 keep / rewrite / derive / delete triage。
- `編排規則`：derive rule，拆出 optimize gate、編排判準、刪除與改動層級三份 RuleFile。
- `提案格式`：derive template，新增 RCA report 與 skill engineering plan 兩組樣板。
- `盤點 skill 引用與孤兒檔案`：derive script，新增 `scripts/analyze_skill_references.py`。
- `舊版直接從問題跳到實作的 wording`：delete。

## 檔案動作

### 新增 / 更新

- Update `skill-engineering/SKILL.md`
- Create `rules/優化時先做根因分析與確認閘門.md`
- Create `rules/主流程重建與模組編排判準.md`
- Create `rules/刪除與改動層級判準.md`
- Create `templates/skill-root-cause-report.md`
- Create `templates/skill-root-cause-report.example.md`
- Create `templates/skill-engineering-plan.md`
- Create `templates/skill-engineering-plan.example.md`
- Create `scripts/analyze_skill_references.py`

### 刪除

- 刪除舊版 SOP 中「尚未診斷就直接進編排」的 phase 或 step。
- 刪除任何不再被新 SOP 回掛的孤兒 artifact。

## 驗證方式

- 重新閱讀 `SKILL.md`，確認 optimize lane 在確認閘門之前不會進入後續編排。
- 執行 `uv run scripts/analyze_skill_references.py --skill .agents/skills/skill-engineering`，確認引用與實體檔案一致，沒有遺漏或孤兒檔案。
- 檢查每個新增 module 是否都能對應回主 SOP 的實際讀取或執行時機。

## 實作閘門

- 若使用者只要求提案，停在此處。
- 若使用者已確認 plan 並要求落地，依本 plan 實作與清理。
