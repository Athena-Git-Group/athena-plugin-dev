# CH2（Skill Engineering）工具組

這個 package 收錄 AIxBDD 2.0 課程 CH2（Skill Engineering）使用的 8 支 Skills。它們負責把一支 Skill 從最小 SOP，逐步演進成由 RuleFile、Template、Script 與多支 Skills 組成的工具。

8 支 Skills 分成三層：

- 4 支 Form Skills：分別把 SOP、RuleFile、Template、Script 寫成一致格式。
- 3 支 Derive Skills：從既有 SOP step 展開 RuleFile、Template 或 Script，並把新資源回掛原 step。
- 1 支 `skill-engineering`（Skill Engineering）：在創建或優化整支 Skill／Skill chain 時，負責重建 SOP、選擇模組、調度 Derive Skills 與驗證結果。

如果你只要建立一份特定類型的檔案，使用 Form Skill。如果你要從既有 SOP step 展開細節，使用 Derive Skill。如果你要創建或優化整支 Skill，使用 `skill-engineering`（Skill Engineering）。

## 這組工具為什麼存在

### Problem：Anthropic 官方 `/skill-creator`（官方 Skill Creator）產出的 Skill 關注點混雜

Anthropic 官方 `/skill-creator`（官方 Skill Creator）的問題，不是它產不出一支完整的 Skill，而是它沒有替產物建立清楚的關注點邊界。主流程、規則、提示、範例與參考資料都可能存在，但它們被混在同一個檔案或同一層目錄裡，讀者無法從檔案的位置判斷它負責什麼。

這種混雜會出現幾個具體問題：

- 一段子流程已經寫在參考檔裡，主 `SKILL.md`（Skill 主檔）卻沒有寫清楚哪一個 step 要讀取與執行。
- 原本必須遵守的流程被寫成說明或提示，AI 執行時仍然可以跳過。
- 不同階段的 Gates 放在同一個檔案；只想載入其中一個 Gate，也會把其他階段一起帶進 context。
- 同一個判斷散落在主流程與參考檔裡，人無法確定哪一份才是唯一來源。

因此，真正困難的不是讓 AI 產生更多內容，而是讓人理解這支 Skill 如何運作。當結果出錯時，人很難判斷應該修改流程、規則、Template，還是 Script；最後只能繼續請 AI 修改整支 Skill，人的理解沒有跟著 Skill 一起演進。這是關注點混雜造成的模組化問題。

### Solution：水球把 Skill 拆成人能理解與控制的模組

水球先把整支 Skill 攤開，逐段辨認哪些內容是 process、哪些是 rule、哪些只是 hint，再從混雜的位置反推模組邊界。解法不是替 `/skill-creator`（官方 Skill Creator）補一段更長的 prompt，而是重新定義 Skill 的組成方式：

1. 主 `SKILL.md`（Skill 主檔）只保留最小可執行 SOP，讓人能像讀演算法一樣讀懂完整流程。
2. 每個 step 都要寫出確切動作，以及當下必須讀取或委派的資源。
3. 判斷規則放進 RuleFile，穩定的輸出結構放進 Template，機械工作放進 Script。
4. RuleFile、Template 與 Script 只在需要它們的 step 按需載入。
5. 同一條規則只保留一個來源；主 SOP 不重述已經委派出去的內容。
6. 先從只有 SOP 的最小 Skill 開始，再根據真實任務中出現的複雜度展開模組。

這樣做的目的，是讓人知道每個判斷放在哪裡、為什麼存在，以及失敗時要改哪一個模組。Skill 的能力增加時，人的理解也必須一起增加。

### Design：4 支 Form、3 支 Derive、1 支 `skill-engineering`（Skill Engineering）

為了讓這套 Solution 可以重複執行，CH2（Skill Engineering）把它做成三層工具：

- 4 支 Form Skills 分別定義 SOP、RuleFile、Template 與 Script 應該怎麼寫，讓每種模組維持自己的責任與格式。
- 3 支 Derive Skills 從一個指定的 SOP step 展開 RuleFile、Template 或 Script，再把讀取或委派時機回寫到原 step。
- `skill-engineering`（Skill Engineering）負責創建或優化整支 Skill。它先重建主 SOP，再判斷哪些 step 應該保留、重寫、展開或刪除，最後才調度 Derive Skills。

`skill-engineering`（Skill Engineering）因此取代 Anthropic 官方 `/skill-creator`（官方 Skill Creator）成為這組工具的入口，但它不會再次把所有工作包進一支工具裡。它只負責選擇正確的模組與順序；每一種檔案的寫法，仍然交給對應的 Form Skill。這個 Design 讓創建與優化使用同一套模組，也讓工具可以回頭優化自己。

## Skill package 的四種責任

| 類型 | 負責什麼 | 不負責什麼 |
|---|---|---|
| SOP | 定義 Phase、step 順序、讀取與委派時機，以及 step 之間的 handoff。 | 不重述 RuleFile 的細部判準，不內嵌完整 Template，不承擔機械處理。 |
| RuleFile | 保存判準、限制、品質要求與 Good/Bad Example。 | 不重新描述完整流程，不定義輸出檔案的固定骨架。 |
| Template | 保存穩定的輸出結構，並提供骨架檔與範例檔。 | 不取代判斷規則，也不決定何時產出。 |
| Script | 執行可重複、機械、輸入輸出清楚的工作。 | 不替人做需求理解、設計取捨或開放式判斷。 |

SOP step 使用四種動詞：

| 動詞 | 用途 |
|---|---|
| `READ` | 讀取需求、檔案、規則、Template 或使用者回應。 |
| `THINK` | 比較、判斷、收斂與決策。 |
| `WRITE` | 建立或修改產物。 |
| `DELEGATE` | 執行 Script，或把工作交給另一支 Skill。 |

## 8 支 Skills 的分工

### Form Skills：把一種檔案寫對

#### [`skill-form-sop`（Skill SOP 格式把關）](./skill-form-sop/)

建立或重寫 `SKILL.md` 裡的 SOP section。

它會把流程整理成 Phase 與 steps，並使用 `READ`、`THINK`、`WRITE`、`DELEGATE` 表示實際動作。它也會檢查 SOP 是否仍是最短可執行路徑，以及 RuleFile、Template、Script 是否只在需要的 step 載入。

適合直接使用的情況：

- 新 Skill 目前只有需求，還沒有可執行 SOP。
- 既有 SOP 混入大量規則、背景說明或重複內容。
- Phase 與 step 的順序、動作或 handoff 不清楚。

#### [`skill-form-rule`（RuleFile 格式把關）](./skill-form-rule/)

建立或修改 `rules/` 裡的 RuleFile。

每條規則包含 Level、規則內容、Good Example 與 Bad Example。Rule Level 分成：

| Level | 意思 |
|---|---|
| `MUST` | 不可違反的硬性要求。 |
| `SHOULD` | 預設遵守；偏離時需要明確理由。 |
| `MAY` | 可以依情境選擇的做法。 |

RuleFile 可以保留完整 taxonomy、checklist、排序方式、排除條件與 Examples。主 SOP 要短，不代表 RuleFile 也要縮短到無法重演原本判斷。

適合直接使用的情況：

- 已經知道要建立哪一份 RuleFile。
- 要修正既有 RuleFile 的格式、Level 或 Examples。
- 要把來源判準整理成一份能獨立執行的規則檔。

#### [`skill-form-template`（Template 格式把關）](./skill-form-template/)

建立或修改 `templates/` 裡的 Template。

每一份 Template 必須提供同 basename、同副檔名的兩個檔案：

- `<name>.<ext>`：骨架檔，保留固定結構與填位符號。
- `<name>.example.<ext>`：範例檔，提供填完後的完整成品。

骨架檔使用 `{{UPPER_SNAKE_CASE}}` 表示可變內容。固定的 Markdown、程式或圖表語法不放進填位符號。

適合直接使用的情況：

- 已經知道某項產物有穩定結構。
- 需要補上骨架檔或對應範例檔。
- 需要修正填位符號、檔名或雙檔責任。

#### [`skill-form-script`（Script 格式把關）](./skill-form-script/)

建立或修改 `scripts/` 裡的 Python Script。

Script 應維持單檔、單一自動化目的，並使用 `PEP 723`（單檔腳本依賴宣告）在檔頭宣告 Python 版本與 dependencies。預設執行方式是 `uv run <script.py>`。

Script 的介面應清楚交代輸入、輸出與失敗訊號。它不能依賴使用者手動改碼，也不能把特定作業系統的 shell 行為當成前提。

適合直接使用的情況：

- 已經知道要自動化的單一步驟。
- 要補上 CLI、錯誤訊息、exit code 或 dependencies。
- 要修正 Script 的跨平台執行方式。

### Derive Skills：從 SOP step 展開模組

#### [`skill-derive-rule`（從 SOP 展開規則）](./skill-derive-rule/)

從一支既有 Skill 的指定 SOP step 展開 RuleFile。

它會保留來源 step 的實際動作，委派 `skill-form-rule`（RuleFile 格式把關）建立規則，再把 RuleFile 的路徑與讀取時機回寫原 step。完成後，執行者只讀目標 Skill 與新 RuleFile，也應能重演來源內容的核心判斷。

適合使用的情況：

- 同一個 step 反覆出現品質不穩。
- 判準、限制或 Examples 已經讓 step 難以閱讀。
- 來源內容有完整 taxonomy 或 checklist，不能只濃縮成一句提示。

#### [`skill-derive-template`（從 SOP 展開樣板）](./skill-derive-template/)

從一支既有 Skill 的指定 SOP step 展開 Template。

它會委派 `skill-form-template`（Template 格式把關）建立骨架檔與範例檔，再把兩個路徑、載入時機與使用方式回寫原 step。原 step 應明確要求執行者複製骨架，並用範例檢查結果。

適合使用的情況：

- 同一個 step 每次都要建立相同章節或檔案格式。
- 輸出格式已經穩定，但內容每次不同。
- 只用文字說明格式仍會讓產物結構漂移。

#### [`skill-derive-script`（從 SOP 展開腳本）](./skill-derive-script/)

從一支既有 Skill 的指定 SOP step 展開 Python Script。

它會委派 `skill-form-script`（Script 格式把關）建立 Script，再把執行時機、路徑、命令、輸入、輸出與後續 handoff 回寫原 step。Script 只承接機械工作；需要判斷的部分仍留在 SOP。

適合使用的情況：

- AI 每次都在重複掃描、解析、轉換或檢查相同格式。
- 工作可以用明確輸入與輸出描述。
- 自動化後能減少後續 step 需要載入的 context。

### Orchestrator：編排整支 Skill／Skill chain

#### [`skill-engineering`（Skill Engineering）](./skill-engineering/)

`skill-engineering`（Skill Engineering）有 create lane 與 optimize lane。

create lane 用來創建新 Skill：

1. 收斂目標 Skill、關聯 Skills 與預期產物。
2. 呼叫 `skill-form-sop`（Skill SOP 格式把關）建立最小 SOP。
3. 逐 step 判斷 keep-inline、rewrite、derive-rule、derive-template、derive-script 或 delete。
4. 提出控制平面、來源能力保留、檔案動作與驗證方式。
5. 取得確認後，調度 3 支 Derive Skills 完成模組。
6. 清理已被新設計取代的 step 與孤兒檔案。

optimize lane 用來優化既有 Skill／Skill chain：

1. 重演不滿意結果如何由目前流程產生。
2. 對齊預期結果、現況與落差。
3. 收斂根因、影響範圍、改動層級與候選刪除項。
4. 在這份課程 package 的目前版本裡，先等待使用者確認根因。
5. 依根因選擇 `local patch`、`step rewrite`、`skill rewrite` 或 `chain rewrite`。
6. 重建 SOP，再依 step 決定保留、重寫、展開或刪除。
7. 使用代表性案例重跑，檢查能力是否真的改善。

如果問題發生在上游輸出被下游漏接或誤用，optimize lane 會把分析範圍擴到相關 Skill chain，而不是只修改單一檔案。

## 怎麼選入口

| 目前的任務 | 使用入口 |
|---|---|
| 只有需求，想先建立最小 SOP | `skill-form-sop`（Skill SOP 格式把關） |
| 已經知道要建立或修正哪份 RuleFile | `skill-form-rule`（RuleFile 格式把關） |
| 已經知道要建立或修正哪組 Template | `skill-form-template`（Template 格式把關） |
| 已經知道要建立或修正哪支 Script | `skill-form-script`（Script 格式把關） |
| 要從既有 SOP step 展開判準 | `skill-derive-rule`（從 SOP 展開規則） |
| 要從既有 SOP step 展開穩定產物格式 | `skill-derive-template`（從 SOP 展開樣板） |
| 要從既有 SOP step 展開機械工作 | `skill-derive-script`（從 SOP 展開腳本） |
| 要創建整支 Skill 或重新編排既有 Skill／Skill chain | `skill-engineering`（Skill Engineering） |

Form Skill 的輸入是「我要這一類檔案」。Derive Skill 的輸入是「我要從這個 step 展開一個模組」。`skill-engineering`（Skill Engineering）的輸入是「我要創建或優化這支 Skill／Skill chain」。

## Skill 的演進方式

### Level 0（只有 SOP）

只有 `SKILL.md` 與最小 SOP。問題與流程仍在理解中時，先維持這個層級。

### Level 1（展開模組）

真實執行已經顯示某個 step 需要穩定判準、輸出格式或機械處理，因此從該 step 展開 RuleFile、Template 或 Script。

### Level 2（拆分 Skill）

同一份 SOP 已經包含多條不同 workflow，或單一 Skill 已經讓人無法快速理解，因此把 workflow 拆成多支 Skills，由主 Skill 按需委派。

層級不是成熟度排名。工具會依實際問題逐步增加結構，不會要求每支 Skill 最後都進入 Level 2（拆分 Skill）。

## 安裝

把本目錄中的 8 支 Skills 複製到專案的 Skill 目錄：

- Claude Code 專案：`.claude/skills/`（Claude Code 專案 Skills）
- 使用 `.agents` 的專案：`.agents/skills/`（Agents 專案 Skills）

複製、移動或改名後，開一個新的對話，讓 AI 重新載入 Skill metadata。

本 package 的 8 支 CH2（Skill Engineering）Skills 是：

- `skill-form-sop`（Skill SOP 格式把關）
- `skill-form-rule`（RuleFile 格式把關）
- `skill-form-template`（Template 格式把關）
- `skill-form-script`（Script 格式把關）
- `skill-derive-rule`（從 SOP 展開規則）
- `skill-derive-template`（從 SOP 展開樣板）
- `skill-derive-script`（從 SOP 展開腳本）
- `skill-engineering`（Skill Engineering）

同一個 repo 裡另有 `artifact-to-skill-engineering`（產物轉 Skill Engineering），但它不在 CH2（Skill Engineering）逐字稿對應的 8 支工具內，本 README 不解說它。

## 驗證 Skill 的方式

Skill 的驗證不能只看 `SKILL.md` 是否合理，也不能只看引用路徑是否存在。至少要做四件事：

1. 開新對話執行真實任務，避免舊 context 補足 Skill 本身缺少的內容。
2. 用人能判斷對錯的產物 review Examples、規則與設計意圖。
3. 用較快或較弱的模型再跑一次，確認 SOP、規則與 handoff 足夠清楚。
4. 修改後重跑同一案例，確認能力改善，而不是只增加檔案。

`skill-engineering`（Skill Engineering）附帶 `analyze_skill_references.py`（Skill 引用盤點腳本），可以盤點 Skill references、`rules/`、`templates/`、`scripts/`、missing references 與未被引用的本地資源。

這支 Script 只能驗證引用關係，不能驗證 RuleFile 是否保留來源 taxonomy，也不能判斷新流程是否仍能產生原本的品質。

目前這份課程 package 的引用盤點 Script 還有一個已知限制：資源檔名含空白時，路徑可能在第一個空白處被截斷，因而同時出現 missing reference 與孤兒檔案的誤報。遇到這種結果時，先手動核對 `SKILL.md` 中的完整路徑與實體檔案。

## 這組工具維持的邊界

- Form Skill 只把一種檔案寫對，不決定原 SOP 的哪個 step 應該展開。
- Derive Skill 不只建立檔案，也必須把新資源回掛原 SOP。
- `skill-engineering`（Skill Engineering）負責編排，不繞過 Derive Skills 直接散寫模組。
- 主 SOP 保存控制資訊，RuleFile 保存判準，Template 保存產物結構，Script 保存機械處理。
- 高判斷工作留在 SOP。穩定判準、格式與自動化才展開成模組。
- 優化可以刪除或重寫既有設計，不預設所有檔案都要保留。
- 沒有 missing reference 不代表能力保留成功，最後仍要用代表性案例重演。

這些邊界讓人可以看懂一支 Skill 現在做到哪裡、知道失敗應該改哪個位置，也能在需求與公司限制改變時繼續調整。
