# Grader Protocol

定義 Phase C（評分）的規範。

## 目標

對 case 的每個 Expected / Anti-pattern criterion 給出 ✓ / ✗ / ⚠️ + 一句理由，
最後分類到 ✅ / 🟡 / 💡 三段。

## 流程概覽

```
For each criterion in (Expected ∪ Anti-patterns):
  1. 解析前綴標記 [mechanical] | [semantic]
  2. mechanical → 直接機械比對（grader 主流程）
  3. semantic   → spawn fresh sub-agent 用 rubric judging
  4. 收集結果（verdict + 理由）

最後按邏輯（含 anti-pattern 反轉）彙整為三段式報告
```

## Mechanical Check

直接在 grader 主流程（**不 spawn sub-agent**），用以下工具判斷：

| 判準類型 | 工具 |
|---------|------|
| 檔案存在 | `test -f <path>` 或 `ls <path>` |
| 字串包含 | `grep -q "<pattern>" <file>` |
| 不存在某類檔 | `find <dir> -name "<pattern>" \| head -1`（空輸出 = 不存在） |
| 檔案數量 | `find <dir> -type f \| wc -l` |
| Frontmatter 欄位值 | Read 該檔，parse frontmatter |
| diff 行數 / 範圍 | git diff（temp dir 內 git init 後比對）或人工計算 |
| 路徑等於 | `[ "<a>" = "<b>" ]` |

### 判定結果

每個 mechanical criterion 給：

- ✓：條件成立
- ✗：條件不成立
- ⚠️：無法判斷（如目標檔根本沒被產出 — 通常等同 ✗，但分到「無法判定」可給較寬容語氣）

附上「mechanical 依據」一句，例如：

> 「`<temp_dir>/handoffs/typo-fix-build.md` 存在（`ls` 確認）」  
> 「handoff 含 `Gate Verdict: PASS`（`grep -q` 命中）」  
> 「`.test.ts` 未建立（`find ... -name "*.test.ts"` 無輸出）」

## Semantic Check

每個 `[semantic]` criterion **獨立 spawn 一個 grader sub-agent**（避免 criterion 互相污染）。

### Spawn 規範

用 Agent tool，`subagent_type = "general-purpose"`。

### Grader sub-agent prompt template

```
你是 evaluation grader sub-agent。判斷一個語意性 criterion 是否符合。

## Criterion
<verbatim criterion text without [semantic] prefix>

## 上下文（被測 skill 的執行結果）

### Skill 最終回報
<executor_output.final_text>

### Skill 產出 / 修改的檔案

<for each file in executor_output.files_produced:>
#### <absolute path>
\`\`\`
<file content>
\`\`\`
</for>

### Mock 環境（執行前）
<verbatim case Setup>

### 原始任務
<verbatim case Task>

## 評分 Rubric

請依以下三步思考：

1. **解讀 criterion**：這條期望「具體在說什麼行為」？
2. **檢視證據**：在上下文中，哪些片段直接相關？
3. **判定**：

   - ✓：證據明確支持 criterion
   - ✗：證據明確違反 criterion
   - ⚠️：證據不足無法判斷

避免想太多，避免找藉口。看到什麼說什麼。

## 輸出格式

只輸出以下三行（不要加其他內容、不要 markdown headings）：

verdict: ✓ | ✗ | ⚠️
evidence: <一句話引用具體證據，例如「handoff 第 18 行寫 extract helper」>
reasoning: <一句話解釋為什麼依該證據得出該判定>
```

### Semantic 判定的特性

- **不完全 deterministic**：同 criterion 跑兩次可能略有差異（接受 ~80% 一致）
- **避免問開放問題**：rubric 強迫 ✓/✗/⚠️ 三選一
- **獨立 spawn 避免污染**：每個 criterion 一個新 sub-agent
- **輕量 sub-agent**：只判斷一條，timeout 設 60 秒

## 結果分類到三段

| 條件 | 分到哪段 | 備註 |
|------|---------|------|
| Expected 條目 verdict = ✓ | ✅ 達成 | |
| Anti-pattern 條目 verdict = ✗ | ✅ 達成 | **反轉邏輯**：anti-pattern 沒命中 = 好事 |
| Expected 條目 verdict = ✗ | 🟡 部分達成 | |
| Anti-pattern 條目 verdict = ✓ | 🟡 部分達成 | **反轉邏輯**：anti-pattern 命中 = 踩雷 |
| 任何 verdict = ⚠️ | 🟡 部分達成 | 標示「無法判定」 |
| Sub-agent isolation_violations 非空 | 🟡（額外警告段） | 「Skill 違反隔離邊界」單獨提示 |
| `executor_output.steps_taken > expected_max_steps` | 💡 進階建議 | 「可能偏離預期路徑」 |
| Expected 列表少於 3 條 | 💡 進階建議 | 「case 太簡單，建議加 edge case」 |

每條 🟡 都按 `../../athena-skill-audit/references/mentoring-style.md` 的 **Why / What / How** 句型寫。

## Anti-pattern 邏輯（再次強調）

Anti-pattern 是「**不該出現**的事」：

| Anti-pattern grader verdict | 意義 | 分到 |
|----------------------------|------|------|
| ✗（沒命中） | 反例沒踩到 → 好事 | ✅ |
| ✓（命中） | 反例踩到了 → 不好 | 🟡 |
| ⚠️（無法判定） | — | 🟡（無法判定） |

也就是 anti-pattern 的 verdict 邏輯與 expected **相反**：要的是 ✗。

實作時容易搞錯，請在 grader 主流程明確分流：

```
if criterion in expected:
    if verdict == ✓ → ✅
    if verdict == ✗ → 🟡
elif criterion in anti_patterns:
    if verdict == ✗ → ✅   # 沒踩到反例
    if verdict == ✓ → 🟡   # 踩到反例
```

## 禁用詞檢查

Grader 輸出文字時遵守 `../../athena-skill-audit/references/mentoring-style.md` 的禁用詞清單：

- 不用 PASS / FAIL / 通過 / 不通過 / 錯誤 / 違規 等
- 用 ✓/✗ 是 grader 內部記號；對使用者輸出時轉成 ✅/🟡

## 為什麼 mechanical 不也 spawn sub-agent

- mechanical 是純機械比對，可確定性結果，不需要 LLM 判斷
- 省 token、省時間、結果穩定
- LLM 反而可能幻覺出不存在的檔案
