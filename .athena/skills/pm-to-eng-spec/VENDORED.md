# Fork 聲明與同步紀律

## 血緣

本 pack 最初改編自內部 `athena-skills` 目錄（keer.huang 維護的 PM→工程文件
skill 集；vendor 當時尚未版控）——初次 vendor 於 2026-07-17，最後一次對齊
上游於 2026-08-04。`phases/score/`、`phases/clarify/` 等多數 phase 的判準與文字
骨架源出於此；`phases/specify/`、`phases/ui_prototype/` 則是本 repo 原創（概念
來源另見下方「概念來源與授權標註」）。

## Fork 定調（2026-10-27）

本 pack 自本日起正式 fork，不再是 `athena-skills` 的 vendored 副本：

- **理由**：本次依 `skill-engineering` 方法論對全 pack 做了結構性重排——
  根層新增 `rules/` / `templates/`，各 phase 的 `references/` 拆分為
  `rules/` / `templates/` / `scripts/`，`phases/pm-to-eng-flow/` 更名為
  `phases/common/`，api 的 transpiler 移至 `phases/api/scripts/openapi.py`。
  新拓樸與上游既有目錄佈局不再相容，繼續宣稱「vendored」已名不副實。
- **上游不再是真源**：`athena-skills` 不再是本 pack 任何檔案的權威來源，
  本 pack 後續的修改、新增、刪除一律以自身為準。
- **不再 re-vendor**：不會再從 `athena-skills` 拉取更新覆蓋本 pack；過去
  用來重新 vendor 的腳本步驟（`sync-spec-pack.sh` 的上游參數與相關 guard）
  已一併移除。
- **舊分組與重放清單作廢**：舊版此檔用來標示「哪些檔案會被上游覆蓋、覆蓋
  後要重放哪些本地改寫」的 A / B / C 三組分類、22 檔逐檔重放清單、以及
  「B 組不得被上游覆蓋後靜默丟失本地改寫」等約束，隨 fork 全部作廢，不再
  適用，也不再維護。

## 現行紀律（真源 → dogfood 單向同步）

Fork 之後，本 pack 仍維持兩份拷貝，但同步方向只剩「自己對自己」一段，
不再涉及外部上游：

- **真源方向**：`skills/athena-core/assets/spec-pack-pm-to-eng/`（真源）
  → `.athena/skills/pm-to-eng-spec/`（dogfood 安裝）。
- **只改真源側**：任何內容變更一律先改真源側；dogfood 側絕不手改，它只是
  同步的目的地。
- **同步工具**：`scripts/sync-spec-pack.sh`——把真源整個 pack 目錄（根層
  `SKILL.md` 除外）鏡像到 dogfood 安裝。
- **drift 把關**：`scripts/lint-plugin.sh` 的「spec-pack drift check」步驟
  比對兩側內容，發現未經同步的差異即 FAIL。
- **唯一合法分歧**：根層 `SKILL.md`——真源側 frontmatter 多宣告一行
  `stage: spec`（供 `/athena-flow` 的 skill discovery 辨識），dogfood 側不
  宣告；兩側 `SKILL.md` 的其餘內容仍應保持一致。

## 歷史記錄（濃縮）

- **2026-07-17**：初次 vendor；wrapper `SKILL.md` 當時即為本 repo 原創。
- **`eng-output/` → `specs/` 改寫**：vendor 進來的檔案原本引用上游的
  `eng-output/` 目錄名，machine 轉換為 `specs/`（含 transpiler 腳本
  docstring 內的路徑字樣），目的是對齊 spec stage shell 的 Write 範圍
  （當時只允許 `specs/` 與 `handoffs/`）。此轉換已完成且不再是進行式。
- **2026-09-04（`specify` 導入）**：新增原創 phase `phases/specify/`，需求
  真源自此改為 `specify/spec.md`——`clarify/clarified.md` 僅作為 `specify`
  的輸入，結構層以後的所有 phase 不再直接讀取它。同批導入又撤除的
  `technical_research` phase 已完全移除，不留痕跡。
- 其餘歷次小修（gate 字串調整、回指錯號修正等）已併入各檔案本身，不再於
  本檔逐筆保留；需要追溯細節請查 git log。

## 概念來源與授權標註

`phases/specify/`、`phases/ui_prototype/` 為本 repo 原創檔，其判準與文件
骨架**借鑑**自 AI-x-BDD-Spec-Driven-100-Automation 的 CH3-SDD-workflow：

| 本 pack 的 phase | 概念來源（CH3-SDD-workflow） |
|-----------------|------------------------------|
| `phases/specify/` | `skills/specify` |
| `phases/ui_prototype/` | `skills/ui-plan` |

- CH3 skills 授權：Apache License 2.0（水球球特務有限公司）
- `specify` 另含 GitHub Spec Kit 的 MIT License
  （Copyright GitHub, Inc.，<https://github.com/github/spec-kit>）——依該授權保留標註
- 本 plugin 授權：MIT（`.claude-plugin/plugin.json`）

依 Apache-2.0 §4(b) 的「註明變更」要求，摘要我們改了什麼：未複製 CH3 的
`rules/` / `templates/` 原始檔案，判準與骨架以本 pack既有寫法重新表述；移除
`.agents/constitution/` 硬依賴；互動式 `DELEGATE /clarify` 訪談全數映射為
`clarify/questions.md` / `clarify/answers.md` 的檔案協議；`spec.md` 追加 CH3
骨架沒有的「資料維度與範例資料」段與「承載覆蓋對照表」段；未納入 CH3 的
`tasks` / `implement` / `system-analysis` / `technical-research`；`ui-plan`
的 HTML / md template 未逐檔複製，改寫為 `phases/ui_prototype/` 底下的說明
與片段。未複製 CH3 的原始碼與 `LICENSE` 檔；以本節的出處標註與授權聲明滿足
標示要求。
