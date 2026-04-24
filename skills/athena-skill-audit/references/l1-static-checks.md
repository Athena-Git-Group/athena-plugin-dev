# L1 Static Checks

純結構性檢查，無需理解 SKILL.md 內容語意。

## 規則總覽

| 檢查項 | 通過條件 | 失敗對應 tier |
|--------|---------|--------------|
| Frontmatter 存在 | SKILL.md 開頭有 `---` 包圍的 YAML | 🟡（無 frontmatter 的 skill 無法被識別） |
| `name` 欄位 | 必填、字串、非空 | 🟡 |
| `description` 欄位 | 必填、字串、非空 | 🟡 |
| `stage` 欄位 | 若是要被 flow 編排的 skill 則必填 | 🟡（只在 `.athena/skills/` 路徑下要求） |
| `name` 命名規範 | 小寫英文 + 連字號 + 數字 | 🟡 |
| `stage` 值合法 | 在合法清單內 | 🟡（值不合法 flow 會 discovery 失敗） |
| `description` 字數 | ≥ 30 字元 | 🟡 |
| `description` 泛詞 | 不命中黑名單 | 💡（建議改寫） |
| Index skill 子 skill | 子 skill 不宣告 `stage` | 🟡 |

## Frontmatter 必填欄位

依 `skills/athena-core/references/skill-metadata-spec.md`：

- `name`（必填）
- `description`（必填）
- `stage`（條件必填：要被 flow 編排的 skill）
- `user-invocable`（選填，預設 false）

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
