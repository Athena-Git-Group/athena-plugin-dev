# L1 Static Checks

純結構性檢查，無需理解 SKILL.md 內容語意。

## 分工原則（2026-08-04 修訂）

官方在 Claude Code v2.1.221 已提供三樣覆蓋通用 skill 規範的工具，本表**不重複實作**它們做得更好的事：

| 官方工具 | 覆蓋什麼 | 取得方式 |
|---------|---------|---------|
| `claude plugin details <plugin>` | 元件盤點 + always-on / on-invoke 逐元件 token 成本 | CLI 內建，無需裝 plugin |
| `plugin-dev:plugin-validator` | plugin 結構、manifest、元件檔、命名慣例、anti-pattern | 需 `claude plugin enable plugin-dev@claude-plugins-official`，或 `claude --plugin-dir <path>` 單次載入 |
| `plugin-dev:skill-reviewer` | description 觸發效果的**語意**審查 | 同上 |

本表保留的價值在兩處，官方工具都做不到：

1. **目標不同**——audit 掃的是 `.athena/skills/`（團隊上繳的 stage skill），那不是 plugin，官方三樣工具都以 plugin 為單位。
2. **規則不同**——`stage` 契約、index skill 規則、athena 專屬命名慣例是本 harness 的約定，通用工具不可能知道。

> ⚠️ plugin-dev **預設未安裝**（只 clone marketplace 不等於 enable）。執行 audit 前若無法叫到
> `plugin-validator` / `skill-reviewer`，就把標記為「官方覆蓋」的項目**照本表自行檢查**，
> 並在報告中註明「官方工具不可用，已回退本地檢查」——不得直接跳過留下覆蓋空洞。

## 規則總覽

| 檢查項 | 通過條件 | 失敗對應 tier | 官方是否已覆蓋 |
|--------|---------|--------------|--------------|
| Frontmatter 存在 | SKILL.md 開頭有 `---` 包圍的 YAML | 🟡（無 frontmatter 的 skill 無法被識別） | ✅ plugin-validator（`.athena/skills/` 路徑仍須本地查） |
| `name` 欄位 | 必填、字串、非空 | 🟡 | ✅ 同上 |
| `description` 欄位 | 必填、字串、非空 | 🟡 | ✅ 同上 |
| `name` 命名規範 | `^[a-z][a-z0-9-]*$` | 🟡 | ✅ 同上 |
| `name` 長度 | ≤ 64 字元；不含 `anthropic` / `claude` | 🟡 | ✅ 同上 |
| `description` 字數下限 | ≥ 30 字元 | 🟡 | ❌ 官方無下限規定，本表獨有 |
| `description` 字數上限 | ≤ 1,024 字元（官方硬性驗證上限） | 🟡 | ❌ 需本地查 |
| `description` + `when_to_use` 合併長度 | ≤ per-skill cap（查證時為 1,536 字元，見下） | 🟡（超額會**截尾**，關鍵字可能被切掉） | ❌ 需本地查 |
| SKILL.md body 行數 | < 500 行 | 💡（官方為 Tip 非硬限；超過建議把細節搬 `references/`） | ❌ 需本地查 |
| `references/` 死檔 | `references/` 下每個檔案都在 SKILL.md 內被提及**且**說明何時載入 | 🟡（未被提及＝Claude 不知道它存在，永遠不會讀） | ❌ 官方不查跨檔引用 |
| `stage` 欄位 | 若是要被 flow 編排的 skill 則必填 | 🟡（只在 `.athena/skills/` 路徑下要求） | ❌ athena 專屬 |
| `stage` 值合法 | 在合法清單內 | 🟡（值不合法 flow 會 discovery 失敗） | ❌ athena 專屬 |
| Index skill 子 skill | 子 skill 不宣告 `stage` | 🟡 | ❌ athena 專屬 |
| `description` 泛詞 | 不命中黑名單 | 💡（建議改寫） | ✅ skill-reviewer 的語意判斷更佳，本表僅作為 fallback |
| token 成本 / listing 預算 | — | — | ✅ **一律改跑 `claude plugin details`，本 skill 不自行估算** |

## 官方硬門檻與查證紀律

上表三個數值門檻（1,024 / per-skill cap / 500 行）的來源與**易漂移性**：

| 門檻 | 來源 | 漂移史 |
|------|------|--------|
| `description` ≤ 1,024 字元 | `platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices`（Token budgets 節） | 查證日 2026-08-04 |
| `description` + `when_to_use` per-skill cap | `code.claude.com/docs/en/skills` | **v2.1.86 為 250 → v2.1.105 起為 1,536**；可用 settings `skillListingMaxDescChars` 覆寫 |
| body < 500 行 | `code.claude.com/docs/en/skills`（Tip） | 查證日 2026-08-04 |

**紀律**：這些數字**不得寫死**在檢查邏輯裡。執行 audit 時以「當前 docs 或當前 settings schema 的值」為準；
若無法查證，就用本表數值並在報告註明「門檻依 2026-08-04 查證值，未重新確認」。

listing 總預算為模型 context window 的 **1%**（settings `skillListingBudgetFraction` 預設 `0.01`，字元預算 ≈ context window × 4 × fraction）；
溢出時 Claude Code **從最少被調用的 skill 開始，把 description 整條降為 name-only**，這是路由退化的實際機制。
但「哪些 skill 會被降級」取決於官方未公開定義的調用計數視窗，**無法事前機械推算**——
要判斷是否已溢出，一律以 `claude plugin details` 與 `/context` 的 Skills 列**實跑輸出**為準，不用算式估。

## Frontmatter 必填欄位

依 `skills/athena-core/references/skill-metadata-spec.md`：

- `name`（必填）
- `description`（必填）
- `stage`（條件必填：要被 flow 編排的 skill）
- `user-invocable`（選填，**預設 true**——2026-08-04 於 v2.1.221 實測：未宣告者可被斜線呼叫；
  要禁止使用者直接呼叫必須顯式寫 `false`）
- `when_to_use`（選填，會被附加到 description 之後併入 listing，佔用同一個 per-skill cap）

## `name` 命名規範

正則：`^[a-z][a-z0-9-]*$`

合法：`payments-build`、`my-team-spec`、`payments-build-index`
不合法：`MyTeamBuild`、`payments_build`、`team build`、`123-build`

> 如果是團隊 skill，**建議**前綴團隊名（如 `payments-`），但這只是 💡 級建議，非 🟡 警告。

## `stage` 合法值

依 metadata spec：

- Standard：`spec` / `plan` / `build` / `verify` / `review` / `ship`
- Flow-inline：`pre-build` / `post-build`

不在此清單內 → 🟡。`point` 與 `flow` 為 plugin 保留，團隊不得宣告 → 🟡。

## `description` 品質規則

### 字數下限：30 字元

太短的 description 會降低 LLM auto-delegation 命中率。低於 30 → 🟡。

### 泛詞黑名單（命中 → 💡 建議改寫）

> **優先改用官方 `plugin-dev:skill-reviewer`**：它做語意判斷，比關鍵字黑名單準得多。
> 本黑名單只在 skill-reviewer 不可用（plugin-dev 未安裝）時作為 fallback 使用。
> 另注意：**不要為了省 token 而縮短 description**——官方把「縮短 description」與
> 「剝掉 Claude 用來匹配需求的關鍵字」寫成同一因果，在 listing 未溢出時縮短是純損失。

整個 description（去掉前後空白）匹配下列任一型態時觸發：

- `^我們團隊的.{0,10}skill$`
- `^team .{0,10} skill$`
- `^[a-z]+ stage skill$`
- 整段只是「執行 X 階段」「處理 X」「跑 X」這類動詞短句

改寫範例（給建議時附上）：

| 原 description | 改寫範例 |
|----------------|---------|
| `我們團隊的 build skill` | `Payments 團隊的 build skill。使用 Java 17 + Spring Boot，遵循 TDD 流程與 ATDD 驗收測試` |
| `執行 spec 階段` | `Member 團隊的 spec skill。產出 BDD scenarios + Activity Diagram，套用團隊的 Feature Rules 模板` |

### 不命中規則的 description（不評論）

- 描述包含技術棧 / 觸發詞 / 適用情境的長 description → 不評論
- 描述包含團隊名 + stage + 觸發詞的標準格式 → 不評論

## Index skill 額外規則

如果 skill 名稱以 `-index` 結尾，且 frontmatter 有 `stage`：
- 該目錄下的 sub-skill 不應再宣告 `stage`
- 詳見 `skills/athena-flow/references/index-skill-pattern.md`

## `references/` 死檔檢查（官方工具不覆蓋）

官方 progressive disclosure 的前提是「SKILL.md 要告訴 Claude 每個 supporting file 裝什麼、何時該載入」
（`code.claude.com/docs/en/skills`：*Reference supporting files from SKILL.md so Claude knows what each file
contains and when to load it*）。沒被提及的 reference 檔＝Claude 不知道它存在＝永遠不會被讀，是死檔。

機械檢查程序：

1. 列出 `<skill>/references/` 下所有檔案
2. 對每個檔名，在同一個 SKILL.md 的 body 內搜尋該檔名字串
3. 未命中 → 🟡（死檔）。命中但只出現在檔案清單、沒說明「何時載入」→ 💡
4. 額外檢查（官方 best-practices 對 partial read 的警告）：
   - `references/` 只應一層深；巢狀引用會讓 Claude 只讀到局部（例如用 `head -100`）而拿到不完整資訊 → 🟡
   - 單一 reference 檔 > 100 行時，該檔開頭應自帶目錄 → 💡
5. 去重檢查：同一段內容不應同時存在於 SKILL.md 與 `references/`
   （官方 plugin-dev：*Information should live in either SKILL.md or references files, not both*）→ 💡

## 何時放寬規則

當被檢查的 skill 是 plugin 內建 skill（路徑為 `skills/` 而非 `.athena/skills/`）：
- `stage` 欄位非必填（plugin 內建 skill 不被 stage discovery 約束）
- 命名前綴規則放寬（不需團隊前綴）

audit 應自動偵測這個情境並調整：若被檢查路徑開頭是 `skills/`（非 `.athena/skills/`），把上述規則降為 💡。

## 輸出對應

| 檢查結果 | Tier |
|---------|------|
| 全部通過 | ✅ 計入「做得好」段 |
| 命中 🟡 規則 | 加入「可以更好」段，附建議與規則出處 |
| 命中 💡 規則 | 加入「進階建議」段，附改寫範例 |
