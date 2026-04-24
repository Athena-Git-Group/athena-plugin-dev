# Executor Protocol

定義 Phase B（執行目標 skill）的規範。

## 目標

用 fresh sub-agent 執行目標 skill，捕捉它的所有產出（檔案 + 最終回報）。

## Spawn 規範

用 Agent tool，`subagent_type = "general-purpose"`。

### 為什麼用 general-purpose

- 工具齊全，能模擬真實 skill 執行環境
- 不依賴特定 plugin 內建 subagent
- 可被任何 Claude Code 實例使用

### Prompt template

Prompt 必須包含以下五段（依序），全部 verbatim 套用：

```
你是被指派執行一個 skill 的 sub-agent。這是 evaluation 跑分情境，
不是真實工作 — 你的所有檔案操作都應在指定的 temp dir 內進行。

## 你要執行的 skill

完整 SKILL.md 路徑：
<absolute path to target SKILL.md>

讀取這個檔案，理解該 skill 的職責、執行流程、輸出規範，並按其指示執行。

## 你的工作目錄（mock 環境）

絕對路徑：<absolute temp dir path>

**極重要**：Bash 的 `cd` 不會在 call 之間持久（每次 Bash 是新 shell）。
所有檔案操作（Read / Write / Edit / Bash）**必須使用以這個 temp dir 為前綴的絕對路徑**。

✅ 正確：
- Read("<temp_dir>/handoffs/foo-build.md")
- Write("<temp_dir>/handoffs/foo-build.md", ...)
- Bash("cat <temp_dir>/points/foo.md")

❌ 錯誤：
- cd <temp_dir> && cat handoffs/foo-build.md   ← cd 失效
- Read("handoffs/foo-build.md")                 ← 相對路徑會找錯地方

## 已預先放在你的 temp dir 中的 mock 檔案

<list of files from case Setup section, with absolute paths>

## 任務

<verbatim Task content from case>

## 約束（必須遵守）

1. **絕不在 temp dir 之外建立、修改、刪除任何檔案**（包括 git config、shell rc 等）
2. **絕不執行 git commit / push**（這是 mock 環境，git 操作沒意義）
3. **絕不執行需要網路的指令**（除非 task 明確要求且能在 mock 環境內完成）
4. **完成後回報**：
   - 你產出 / 修改了哪些檔案（用絕對路徑列出）
   - 你的 handoff（如果該 skill 要求產出）內容摘要
   - 任何你決定不執行的操作 + 理由
   - 你預估自己用了幾個 step

回報格式：

\`\`\`
## Files produced/modified
- <absolute path>: <created | modified>
- ...

## Handoff summary
<key fields from your handoff if applicable>

## Decisions skipped
- <action>: <reason>
- ...

## Steps taken
~<N> steps
\`\`\`
```

## 設定

| 參數 | 預設 | 用途 |
|------|------|------|
| timeout | 300 秒（5 分鐘） | 防止 sub-agent 失控 |
| run_in_background | false | 同步等待結果（foreground） |

## 輸出捕捉

從 sub-agent 的回應（Agent tool return value）取得：

1. **最終文字輸出**：sub-agent 的回報內容（給 Grader 的 semantic check 看）
2. **產出檔案清單**：sub-agent 自己列出 + `find <temp_dir> -type f` 交叉核對（避免 sub-agent 漏報）
3. **執行步驟摘要**：sub-agent 自己描述（含跳過了什麼）

打包成 `executor_output` 物件交給 Grader：

```yaml
executor_output:
  temp_dir: "/var/folders/.../T/athena-eval-xxx"
  files_produced:
    - "/var/folders/.../T/athena-eval-xxx/handoffs/typo-fix-build.md"
    - "/var/folders/.../T/athena-eval-xxx/README.md"  # modified
  final_text: "I read the skill and ..."
  steps_taken: 8
  status: success | timeout | error
  isolation_violations:
    - "/Users/Caresys/IdeaProjects/crs/some-file.md"   # 在 temp dir 之外被改的檔案（理想為空）
```

## Sub-agent 失敗處理

| 狀況 | 處理 |
|------|------|
| Timeout | `status: timeout`，產出檔案仍交給 Grader 評分 |
| Error / 拒絕執行 | `status: error`，記錄拒絕理由 |
| 寫入 temp dir 之外 | 不阻擋（已盡力 prompt 約束），記入 `isolation_violations`，報告中標 🟡 |
| 沒產出任何檔案 | `status: success` 但 `files_produced` 為空，Expected 多半失敗 |

## 隔離邊界檢查

執行前快照：
```bash
git -C <user_repo> status --porcelain > <temp_dir>/.before_status
```

執行後比對：
```bash
git -C <user_repo> status --porcelain > <temp_dir>/.after_status
diff <temp_dir>/.before_status <temp_dir>/.after_status
```

如有差異 → 把差異中的檔案路徑加入 `isolation_violations`。

> 此檢查只能偵測 user repo 內的變更；temp dir 外其他位置（如系統 config）無法保證偵測。

## 為什麼 prompt 要這麼長

Phase 0 spike 揭示：sub-agent 預設行為是用 `cd` + 相對路徑（自然的 shell 直覺）。
不嚴格 prompt 約束的話，sub-agent 會默默地把檔案寫到錯位置。
故本 protocol 使用較長 prompt 換取行為一致性。

## 為什麼不用 inline 執行（不 spawn）

- inline 執行讓 audit 自己「假裝」是 build skill — 上下文混雜，不可信
- spawn fresh agent = 真實重現「skill 在獨立 agent 內執行」的 flow 行為
- 雖然成本較高，但 eval 本來就是離線重型工具
