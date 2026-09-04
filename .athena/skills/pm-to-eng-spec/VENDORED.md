# Vendored 來源與同步

- **來源**：內部 `athena-skills` 目錄（keer.huang 維護的 PM→工程文件 skill 集；vendor 當時尚未版控）
- **初次 vendor 日期**：2026-07-17
- **最後同步日期**：2026-08-04
- **來源版控狀態**：來源**仍不是 git repo**（無 commit hash 可釘）。同步時以
  `diff -rq` 逐檔比對＋`find -newermt <上次同步日>` 交叉確認變動檔。
  建議來源目錄 `git init` 後在此補記 hash，否則漂移無從比對。

## 來源分組（先看這張表：某個檔該不該被上游覆蓋）

`phases/` 底下不再全部都是 vendored。任何同步動作前先判斷檔案屬於哪一組：

| 組 | 內容 | 上游 | 重新 vendor 時 |
|----|------|------|---------------|
| **A. vendored（原樣）** | 未被本地改寫的 vendored 檔——`phases/score/`、`phases/pm-to-eng-flow/references/`、以及各 phase 目錄下未列入下方「本地改寫清單」的檔案 | athena-skills | rsync 覆蓋，**上游全勝** |
| **B. vendored + 本地改寫** | 因本次「下游改讀 `specify/spec.md`」而改寫的 vendored 檔——**逐檔見下方「本地改寫清單」** | athena-skills | rsync 覆蓋後**必須依「本地改寫清單」重新套用本地改寫**；沒有那份清單，改寫會靜默丟失 |
| **C. plugin 原創** | `phases/specify/`、`phases/ui_prototype/`（判準借鑑外部、檔案本身是本 repo 寫的）＋根層 `SKILL.md` / `README.md` / `VENDORED.md` | 無（本 repo） | **不參與上游 re-vendor**——`scripts/sync-spec-pack.sh` 的 `PLUGIN_OWN_PHASE_DIRS` 清單保護它們；誤登記進 `UPSTREAM_PHASE_DIRS` 會在 ownership guard 直接中止 |

## 帶了什麼、沒帶什麼

| 項目 | 處置 | 原因 |
|------|------|------|
| `score` `clarify` `data_model` `class_diagram` `db_table` `api` `screens` `ui_contract` `gherkin` | ✅ vendor 至 `phases/<name>/` | 上游的 phase skill 本體（A 組；其中被本地改寫的檔屬 B 組，見「本地改寫清單」） |
| `pm-to-eng-flow/references/` | ✅ vendor 至 `phases/pm-to-eng-flow/references/` | phase skills 以 `../pm-to-eng-flow/references/` 相對路徑引用，保留 sibling 佈局使引用不斷鏈 |
| `phases/specify/` | 🆕 **本 repo 原創**（C 組） | 需求結構化層，上游沒有對應目錄；概念來源與授權見下方標註 |
| `phases/ui_prototype/` | 🆕 **本 repo 原創**（C 組） | 前端 / fullstack 的高保真靜態 HTML 雛形，上游沒有對應目錄 |
| `pm-to-eng-flow/SKILL.md` | ❌ 不帶 | 編排職責由本 pack 根目錄的 `SKILL.md`（stage: spec wrapper）取代，帶了會出現兩個編排器 |
| `arguments.yml` `Index.md` | ❌ 不帶 | 設定改併入 consumer 專案 `specs/arguments.yml` 的 `spec_pack:` 段，避免同名設定檔並存 |
| `design-prototype/` | ❌ 不帶 | 大型範例專案且**內嵌 .git**，複製進 plugin repo 會出事 |
| `doc-requirement/` | ❌ 不帶 | PM 需求單樣例，非 skill 本體 |
| `.DS_Store` `__pycache__` | ❌ 排除 | 雜物 |

## 對 vendored 檔案做過的機械轉換

1. `eng-output/` → `specs/`（全部文字檔，含 `openapi.py` docstring）——
   對齊 spec stage shell 的 Write 範圍（只允許 `specs/` 與 `handoffs/`）。

除本節列出的機械轉換與「本地改寫清單」所列項目外，**A 組** vendored 檔案**零改動**。
重新同步時 diff 若出現**不在上述兩份清單內**的差異，才是上游演進或本地漂移，需人工裁決。

> 這條規則的意圖沒有變（保護 vendored 內容不被偷改），只是把作用域寫精確：
> 它管的是 A 組，不是整個 `phases/`。

## 本地改寫清單（B 組逐檔紀錄 · re-vendor 後的重放依據）

**改動依據**：`specs/spec-pack-default-with-sdd-borrow/`（change ID `A-INPUTS`，
澄清結論 Q3 = B）。一句話規則：

> `specs/<slug>/specify/spec.md` 是**結構層與其後所有 phase 的唯一需求真源**；
> `specs/<slug>/clarify/clarified.md` 是 `specify` 的輸入，結構層之後不再被直接讀取。

**重放的通則**（先套這條，再看逐檔的額外要點）：把檔內指向
`clarify/clarified.md` 的需求真源宣告改指 `specify/spec.md`；
`STATUS 必須為 RESOLVED` 改為 `首行 STATUS 必須為 READY`；
「範例資料 / 資料維度」的段名改為 `spec.md` 的「資料維度與範例資料」段。
**驗收指令**（重放後必跑，命中即代表沒改乾淨）：

```bash
grep -rn 'clarified\.md' skills/athena-core/assets/spec-pack-pm-to-eng/phases/ \
  | grep -v 'phases/clarify/' | grep -v 'phases/specify/' | grep -v 'handoff-contract.md'
# 期望：無輸出
```

| 檔案（相對 pack 根） | 改了什麼 | 依據 | 重放要點 |
|---------------------|---------|------|---------|
| `phases/data_model/SKILL.md` | 「唯一資料來源」改指 `specify/spec.md`；素材段改「資料維度與範例資料」；覆蓋帳本掃描對象改 `spec.md`；非協商規則末尾加「`spec.md` 缺失／為空／非 READY 即中止」 | A-INPUTS | 保留「唯一資料來源」字樣**恰一處**且同行含 `spec.md`；新規則**附加在清單末尾**，不得插入既有條目之間 |
| `phases/class_diagram/SKILL.md` | 行為 / 規則來源與複雜度判斷改指 `spec.md`；非協商規則 1、4 改寫並於末尾加新規則 | A-INPUTS | 同上（末尾附加） |
| `phases/db_table/SKILL.md` | 輸入優先序與「底層權威」改指 `spec.md`；**不得留下「回查 clarified.md」殘句**；末尾加新規則 | A-INPUTS | `references/persistence-allowlist.md:3` 以 `#2` 回指本檔規則，編號不得位移 |
| `phases/screens/SKILL.md` | 行為 / 規則 / 權限真相改指 `spec.md`；`design/ ↔ spec.md` 對照；末尾加新規則 | A-INPUTS | `design/` 角色不變（視覺真相）；`sitemap-guide.md:70`、`screen-breakdown.md:44` 以 `#1` 回指本檔規則，編號不得位移 |
| `phases/api/SKILL.md` | 需求層檔名改 `spec.md`；末尾加新規則 | A-INPUTS | **優先序語意不變**（行為/資源看需求層、型別/值域看 erm.dbml + data_model）；`references/api-conventions.md:119` 以 `#3` 回指，編號不得位移 |
| `phases/ui_contract/SKILL.md` | 格式值與 fixtures 素材來源改指 `spec.md` 的「資料維度與範例資料」段；末尾加新規則 | A-INPUTS | 規則 1（openapi 為單一事實來源）語意不變 |
| `phases/gherkin/SKILL.md` | 範例資料 / 邊界素材來源改指 `spec.md`；完成判準新增「每個 `SC-nnn` 至少被一個 `Rule` 涵蓋，或 handoff 明列不涵蓋 + 理由」；末尾加新規則；**前端輸入清單（`## 輸入` 段）新增 `specs/<slug>/ui_prototype/`（選讀，供視覺斷言），與既有的 `design/` 並列** | A-INPUTS ＋ A-UIPROTO | **風險最高**：前提是 `spec.md` 真的承載了範例資料與邊界；重放後務必確認完成判準的 SC 覆蓋條款還在，且前端輸入清單的 `ui_prototype/` 一項沒被上游版本蓋掉（`grep -n 'ui_prototype' phases/gherkin/SKILL.md` 須有命中） |
| `phases/clarify/SKILL.md` | **只加定位補述**（本檔是 `specify` 的輸入、結構層以後不直接讀它）；**執行步驟 2 的「下游迴圈」註記改寫**——原版寫「編排器決定補進 `clarified.md` 重跑或回退本階段」，該路徑在本 pack 不存在且與「下游不得回讀 `clarified.md`」反向，改為「`gherkin` 標 `@待釐清` → 寫進 `handoffs/gherkin.md` 回饋訊號 → 編排器收進最終 handoff Risks → 使用者經 `answers.md` 進入下一輪」；**`## 輸出` 新增 `clarify/questions.md`（有高影響缺口時）並新增「缺口升級協議」段**（`[clarify]` 來源標記、每輪 ≤ 3 題、回指 wrapper 的共用契約），補上原本 wrapper 把 clarify 列為寫入者、但本檔全文不提 `questions.md` 的落差 | A-INPUTS ＋ A-WRAPPER | **輸出格式（`clarified.md` 的內容契約、STATUS 值域）與完成判準不得變動**；非協商規則不得動（`clarify/SKILL.md` 完成判準以「第 1 條」回指）；grill 流程不得動；新增段須置於「執行步驟」之前，不得改動既有段落編號 |
| `phases/gherkin/references/boundary-checklist.md` | 「來源」欄與範例敘述改指 `spec.md`；**回饋迴圈第 4 點改為「本階段不擋、缺口收進最終 handoff Risks、經 `answers.md` 進下一輪」**（原寫「編排器決定補進 `spec.md` 或回退 clarify → specify」，wrapper 無該裁決） | A-INPUTS ＋ A-WRAPPER | `erm.dbml` / `openapi.yaml` 兩欄不動；此處措辭須與 `phases/clarify/SKILL.md` 的「下游回饋」註記一致 |
| `phases/gherkin/references/gherkin-guide.md` | §2 / §4 / §7 的來源宣告改寫；回指格式 `clarified.md#規則X` → `spec.md#FR-00X`；**§7 第 3 點的反向裁決改寫**——原寫「交由編排器決定：補進 `specify/spec.md` 後重跑本階段，或回退 clarify → specify」（wrapper 明文「本 run 不回退階段」，該路徑不存在），改為與 `boundary-checklist.md` §缺則回報**同一套措辭**（不擋本階段、缺口收進最終 handoff Risks、經 `answers.md` 進下一輪、編排器不代筆改寫 `spec.md`） | A-INPUTS ＋ A-WRAPPER | §4 對「≥3 筆範例資料」的說明改指 `../../specify/references/spec-structure.md` §6；**§7 與 `boundary-checklist.md` §缺則回報互相回指，措辭必須逐句一致**（兩處任一被上游覆蓋都要一起重放） |
| `phases/gherkin/references/example.feature` | 註解內的溯源錨點改寫為 `spec.md#...` | A-INPUTS | **模板性範例**，agent 會照抄格式——錨點寫錯會被複製到實際產出 |
| `phases/screens/references/sitemap-guide.md` | §0 對照原則兩方由 `design/ ↔ clarified.md` 改為 `design/ ↔ spec.md` | A-INPUTS | L70 的「非協商規則 #1」回指不得失效 |
| `phases/screens/references/screen-breakdown.md` | 元素出現 / 啟用條件的來源改指 `spec.md` | A-INPUTS | L44 的「非協商規則 #1」回指不得失效 |
| `phases/screens/references/example-screen-map.md` | 「行為真相」來源列改寫為 `specify/spec.md` | A-INPUTS | 範例檔，格式會被照抄 |
| `phases/ui_contract/references/api-layer-guide.md` | fixtures 素材來源改指 `spec.md` 的「資料維度與範例資料」段 | A-INPUTS | — |
| `phases/ui_contract/references/example-ui-contract.md` | 輸入清單與 fixtures 段改寫 | A-INPUTS | 範例檔，格式會被照抄 |
| `phases/api/references/example.intent.yaml` | `sources:` 錨點改為 `specify/spec.md#FR-...` | A-INPUTS | DSL 的 `sources:` 欄位會被照抄進實際產出 |
| `phases/api/references/dsl-format-anchor.md` | 同上（`sources:` 錨點） | A-INPUTS | — |
| `phases/api/references/haapi-format-anchor.md` | 同上（`sources:` 錨點） | A-INPUTS | — |

**明確不改的 vendored 檔**（重放時也不要動，它們描述的是 `clarified.md` 自身的契約）：
`phases/clarify/references/grill-with-docs.md`、
`phases/pm-to-eng-flow/references/handoff-contract.md`、
`phases/pm-to-eng-flow/references/frontend-stack-conventions.md`、
`phases/score/`（只讀 `source/requirement.md`，不涉及）。

## 概念來源與授權標註

`phases/specify/`、`phases/ui_prototype/` 為本 repo
原創檔，**判準與文件骨架借鑑**自 AI-x-BDD-Spec-Driven-100-Automation 的
CH3-SDD-workflow，逐一對應：

| 本 pack 的 phase | 概念來源（CH3-SDD-workflow） |
|-----------------|------------------------------|
| `phases/specify/` | `skills/specify` |
| `phases/ui_prototype/` | `skills/ui-plan` |

- CH3 skills 授權：Apache License 2.0（水球球特務有限公司）
- `specify` 另含 GitHub Spec Kit 的 MIT License
  （Copyright GitHub, Inc.，<https://github.com/github/spec-kit>）——依該授權保留標註
- 本 plugin 授權：MIT（`.claude-plugin/plugin.json`）

**我們改了什麼**（依 Apache-2.0 §4(b) 的「註明變更」要求）：

1. 未複製 CH3 的 `rules/` 與 `templates/` 任何檔案；判準與骨架以本 pack
   既有寫法重新表述（`## 輸入` / `## 輸出` / `## 執行步驟` / `## 完成判準` / `## 非協商規則`）
2. 移除 `.agents/constitution/` 硬依賴，改為選讀增益、缺檔照常執行
3. 互動式 `DELEGATE /clarify` 訪談與跨 skill slash 委派，全數映射為
   `clarify/questions.md` / `clarify/answers.md` 檔案協議（spec shell headless 契約）
4. `spec.md` 追加 CH3 骨架沒有的「資料維度與範例資料」段與「承載覆蓋帳本」段，
   以承接本 pack 下游 phase 的既有素材需求
5. 未納入 CH3 的 `tasks` / `implement` / `system-analysis`（屬 athena 的 plan / build stage）
6. **未借鑑 CH3 的 `technical-research`**（本版不納入；前端棧一律依
   `phases/pm-to-eng-flow/references/frontend-stack-conventions.md` 的單一事實來源，
   本 pack 不提供專案級棧覆寫）
7. `ui-plan` 的 6 份 HTML / md template **未逐檔複製**，改寫為
   `phases/ui_prototype/references/prototype-skeleton.md` 的說明 + 片段；
   輸出位置由 `ui/` 改為 `specs/<slug>/ui_prototype/`，並明確與本 pack 既有的
   `specs/<slug>/design/`（人給的唯讀輸入）分離

未複製 CH3 的原始碼與 `LICENSE` 檔；以本節的出處標註與授權聲明滿足標示要求。

## 重新同步（腳本已抽出：`scripts/sync-spec-pack.sh`）

原本內嵌於本節的同步腳本已抽出為 plugin root 的 `scripts/sync-spec-pack.sh`
（2026-08-27），轉換規則不變（rsync `UPSTREAM_PHASE_DIRS` 列出的 phase dirs
＋ `pm-to-eng-flow/references/`、`eng-output/` → `specs/` 只掃 `phases/`）：

```bash
# 只做 plugin pack → dogfood 安裝（.athena/skills/pm-to-eng-spec/phases/）：
bash scripts/sync-spec-pack.sh

# 先從上游 athena-skills 重新 vendor（rsync + eng-output/→specs/ 轉換），
# 再接著同步到 dogfood：
bash scripts/sync-spec-pack.sh <athena-skills 路徑>
```

- **真源方向**：上游 athena-skills → plugin pack
  （`skills/athena-core/assets/spec-pack-pm-to-eng/`）→ dogfood 安裝
  （`.athena/skills/pm-to-eng-spec/`）。dogfood 側 `phases/` 絕不手改。
- **新增 phase 目錄時**：本 repo 原創的目錄要加進腳本的 `PLUGIN_OWN_PHASE_DIRS`
  （C 組），**不是** `UPSTREAM_PHASE_DIRS`。放錯組會讓下一次
  `sync-spec-pack.sh <上游>` 在 ownership guard 或第 0 步中止，
  訊息會提示「該目錄不來自上游」。
- **re-vendor 之後**：B 組檔案會被上游覆蓋——**必須**依上方「本地改寫清單」逐檔重放，
  再跑該節的驗收 grep 確認無殘留。
- **漂移閘**：`scripts/lint-plugin.sh` 的「spec-pack drift check」step 以
  `diff -rq` 比對兩側 `phases/`，有任何差異即 lint FAIL。根層 `SKILL.md`
  是兩份 copy 唯一合法差異（plugin 側 frontmatter 宣告 `stage: spec`，
  dogfood 側不宣告），不在比對範圍；根層 README / VENDORED 也不在閘內，
  但兩側應保持同步更新。
- 腳本內建完整性檢查：同步後兩側 `phases/` `diff -rq` 不乾淨即非零退出。

同步後：更新本檔的 Vendor 日期（與 hash，若來源已 git init）。

## 變更紀錄

- 2026-07-17：初次 vendor（wrapper SKILL.md 為本 repo 原創，非 vendored）
- 2026-08-04：同步上游。僅 `phases/screens/SKILL.md`（新增 NFR 表態節：
  a11y / i18n / 效能 / 瀏覽器四項顯式表態，含執行步驟 7 與一條完成判準）與
  `phases/ui_contract/SKILL.md`（新增欄位級 client 驗證規則與金額 / 日期 /
  數值呈現格式規格，含執行步驟 8、兩條完成判準、非協商規則 7）有變動，
  皆為上游純新增；無檔案新增 / 刪除，無 `eng-output/` 路徑需再轉換。
  wrapper SKILL.md 不受影響（phase 順序、gate 映射、workspace 路徑均未變）。
  dogfood 安裝 `.athena/skills/pm-to-eng-spec/` 已整目錄重拷同步。
- 2026-09-04（slug `spec-pack-default-with-sdd-borrow`，改動項 `A-SPECIFY` /
  `A-INPUTS` / `A-WRAPPER` / `A-PROVENANCE`）：**新增 plugin 原創 phase
  `phases/specify/`**（C 組），需求真源改為 `specify/spec.md`；19 份 vendored 檔
  依此改寫（B 組，逐檔見「本地改寫清單」）；本檔改為 A / B / C 三組分離、
  「零改動」條款作用域收斂為 A 組、新增「本地改寫清單」與「概念來源與授權標註」。
  **上游 athena-skills 未變動**，本次無 re-vendor。
- 2026-09-04（slug `spec-pack-default-with-sdd-borrow`，改動項 `A-RESEARCH` /
  `A-UIPROTO`；⚠️ **本條的 `technical_research` 部分已於同日後續決策整支撤除——
  以本節最後一條為現行狀態**）：**新增兩個 plugin 原創 phase**（C 組）——
  `phases/technical_research/`（條件式，設定鍵 `spec_pack.technical_research`，
  **缺鍵預設 `skip`**，產 `research.md` + `techstack.md`）與
  `phases/ui_prototype/`（前端 / fullstack 的高保真靜態 HTML 雛形，
  產 `ui-plan.md` + `index.html` + `<screen>.html`）。
  wrapper `SKILL.md` 同步：設定解析表 +1 列、Workspace 樹 +2 節、執行程序插入
  條件式步驟、三條 track 順序表、Gate 映射 +3 列、非協商規則 5 改寫為
  「`techstack.md` 優先、缺檔退回 Nuxt 4」、末尾新增規則 8（`design/` 是輸入）。
  vendored 檔只動 `phases/gherkin/SKILL.md`（前端輸入清單 +1 項，見「本地改寫清單」）；
  `phases/pm-to-eng-flow/references/` **零改動**。**上游 athena-skills 未變動**，本次無 re-vendor。
- 2026-09-04（同 slug，verify 通讀缺口修補；**未新增 / 刪除任何檔案**；⚠️ 本條涉及
  `technical_research` 的部分同樣已被下一條撤除）：
  wrapper `SKILL.md` 新增「`clarify/questions.md` 共用契約」段（四個寫入者、題號 `Q<n>`
  全檔連號、`[<phase>]` 來源標記、`（已回答）` 標示）、clarify 分支補 `STATUS: BLOCKED`
  路徑（與未解問題同一道 gate、下一輪不算已完成）、clarify 與 specify 兩道 gate 的
  FAIL 字串改為可區分、`technical_research` / `ui_prototype` 追寫 questions.md 的
  **非 gate 裁決**（不改 verdict 但 Risks 必記）並附加**非協商規則 9**（不得靜默吞掉）；
  `phases/technical_research/SKILL.md` 判準條數由「四條」更正為「判準 1–5」
  （原自報漏掉 `research-artifact.md` 判準 5「偏離預設棧必須寫理由」）、`Rule 2` 統一為「判準 2」；
  `phases/screens|ui_contract|gherkin/SKILL.md` 各加一行**棧覆蓋鏈**指標
  （不逐處改寫 40 處 Nuxt 4 指標式引用）；`phases/clarify/SKILL.md` 與
  `phases/gherkin/references/boundary-checklist.md` 的下游回饋路徑改寫為與 wrapper 一致。
  `phases/pm-to-eng-flow/references/` **仍為零改動**（含 `frontend-stack-conventions.md`）。
- 2026-09-04（同 slug，verify 通讀第 2 輪後的**使用者決策**：`technical_research` 撤除；
  依據記於 `specs/spec-pack-default-with-sdd-borrow/clarify/answers.md`「追加決策」節）：
  **刪除 `phases/technical_research/` 整個目錄**（C 組原創，含 `SKILL.md` 與兩份 references），
  `scripts/sync-spec-pack.sh` 的 `PLUGIN_OWN_PHASE_DIRS` 撤下該名稱。
  撤除理由：該階段承諾「前端棧以 `techstack.md` 為準」，但前端規格層整體硬綁 Nuxt 4
  （`screens` / `ui_contract` 的完成判準打勾項綁 Vue 專屬 API、12 份 references 無條件寫 Nuxt、
  權威文件 `frontend-stack-conventions.md` 自稱單一事實來源且被 acceptance A-R3 鎖為零改動），
  覆蓋鏈在結構上無法自洽。`specify` 與 `ui_prototype` 兩塊借鑑**保留不動**。
  連帶：wrapper `SKILL.md` 移除設定解析表該列 / 執行程序 Phase 3 該步（其後步驟由 7、8 重編為 6、7）/
  Gate 映射兩列 / 三條 track 順序表 / Workspace 樹該節 / 第 0 步該項，**非協商規則 5** 就地改寫為
  「前端棧一律 Nuxt 4 + TypeScript strict」（保留編號、不位移），**非協商規則 9** 只留 `ui_prototype`；
  `questions.md` 共用者由 4 支回為 3 支（clarify / specify / ui_prototype）並明文釘死
  「`gherkin` 的待釐清缺口不走 `questions.md`、只逐題進 Risks」；wrapper 補 score `PASS-CLEAN` 行為
  與 `ui_prototype` 在 backend track 的「視為不適用」豁免；`phases/screens|ui_contract|gherkin/SKILL.md`
  的棧覆蓋句**移回零**（`grep -c techstack` 三支皆 0）；`README.md` 棧敘述與設定範例同步。
  另修兩項與撤除無關的通讀缺口：`phases/gherkin/references/gherkin-guide.md` §7 的反向裁決、
  `phases/clarify/SKILL.md` 的 `questions.md` 落差（皆見「本地改寫清單」）。
  `phases/pm-to-eng-flow/references/` **仍為零改動**。**上游 athena-skills 未變動**，本次無 re-vendor。
