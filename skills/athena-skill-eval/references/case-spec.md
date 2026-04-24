# Case Specification (v1)

定義 eval case 檔案的格式契約。

## 檔案位置

```
<project-root>/.athena/evals/
├── spec-cases/
├── plan-cases/
├── build-cases/
├── verify-cases/
├── review-cases/
└── ship-cases/
```

每個 case 一個 `.md` 檔，檔名即 case 名稱（如 `typo-fix.md` → `typo-fix` 為 case-name 引數值）。

## Frontmatter

```yaml
---
eval-case-version: 1            # 必填，目前固定 1（未來破壞性升級才動）
target-stage: build             # 必填，case 適用的 stage
description: 簡述這個 case 在測什麼   # 選填但建議
expected_max_steps: 20          # 選填，超過此 step 數視為偏離預期（warning）
---
```

| 欄位 | 必填 | 用途 |
|------|------|------|
| `eval-case-version` | ✓ | parser 版本辨識；v1 固定 `1` |
| `target-stage` | ✓ | spec/plan/build/verify/review/ship；決定 case 屬於哪個目錄 |
| `description` | — | 給人讀；不參與評分 |
| `expected_max_steps` | — | sub-agent 用了超過此步數 → eval 報告加 💡 提示 |

## 必要段落

依序固定五段（用 `## ` 標題）：

### `## Setup`

描述 mock 環境。包括：

- 哪些檔案存在於 temp dir、內容是什麼（用 fenced code block 給 verbatim 內容）
- 任何環境前提（如「假設目前 git 分支為 X」）

範例：

````markdown
## Setup

`points/typo-fix.md`:
```
- Summary: 修正 README L23 typo「memberhip」→「membership」
- Verdict: PASS-DIRECT-BUILD
```

`README.md`:
```
# Project
This is our memberhip program.
```
````

Eval runner 解析此段，依檔名（反引號包圍）+ fenced block 內容對應，寫入 temp dir。

### `## Task`

給目標 skill 的指令（一段文字）。Eval runner 會把這段 verbatim 交給 spawn 出來的 sub-agent。

範例：

```markdown
## Task

執行 build skill，依 points/typo-fix.md 完成實作。
```

### `## Expected`

列出期望的輸出特徵。**每條前綴 `[mechanical]` 或 `[semantic]`**。

```markdown
## Expected

- [mechanical] handoffs/typo-fix-build.md 存在
- [mechanical] handoff 內容含「Gate Verdict: PASS」
- [semantic] 沒引入新的 abstraction / helper / class
```

### `## Anti-patterns`

列出反例特徵。同樣 `[mechanical]` / `[semantic]` 前綴。

```markdown
## Anti-patterns

- [mechanical] 任何 .test.ts / .spec.ts 被建立
- [semantic] handoff 提及 plan.md（這 case 沒走 plan）
```

> **注意 verdict 邏輯反轉**：anti-pattern 沒命中（grader 判 ✗）才是好事（✅）。詳見 `grader-protocol.md`。

### `## Notes`（選填）

給 case 作者寫的備註，不參與評分。

## `[mechanical]` / `[semantic]` 標記規則

每個 Expected / Anti-pattern 條目**必須**用其中一個前綴開頭（含中括號）。

| 標記 | 用法 | 判準 |
|------|------|------|
| `[mechanical]` | 純結構/字串/檔案存在性檢查 | 「能不能用 grep / ls / wc 給出 yes/no？」 |
| `[semantic]` | 需要理解內容意圖才能判斷 | 「需要讀懂上下文才能判斷？」 |

### 判斷小測驗

| Criterion | 應該標 |
|-----------|-------|
| handoff 含 `Gate Verdict: PASS` | `[mechanical]` |
| Files Changed 列表只有 README.md | `[mechanical]` |
| handoff 寫了 100 字以上 | `[mechanical]` |
| 沒有 over-engineer | `[semantic]` |
| 修改範圍與任務匹配 | `[semantic]` |
| handoff 寫得有條理 | `[semantic]` |
| smoke test 真的有測到核心邏輯 | `[semantic]` |

無前綴的條目 → eval runner 視為格式錯誤，輸出警告並跳過該條。

## 驗證規則（runner 執行時檢查）

| 問題 | 處理 |
|------|------|
| Frontmatter 缺欄位 | 不執行，提示補齊 |
| 缺必要段落 | 不執行，提示補齊 |
| Expected / Anti-patterns 列表為空 | 警告但繼續執行（這 case 沒驗收條件） |
| 條目無 `[mechanical]`/`[semantic]` 前綴 | 警告該條被跳過 |
| `eval-case-version` 不是 `1` | 不執行，提示版本不匹配 |

## 範例

完整範例見 `assets/case-example-build.md`。
起手模板見 `assets/case-template.md`。

## 為什麼 v1 不引入更多欄位

- 維持低門檻：團隊寫 case 的成本要低，否則沒人寫
- 留升級空間：用 `eval-case-version` 標記，未來想加欄位（如 `weight`、`timeout` per case）有路徑
