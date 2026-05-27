# Eval Report 對話模板

每次 eval 跑完輸出此格式。**純對話，不寫檔**。

## 標準結構

```markdown
## Eval Report — <target-skill> × <case-name>

Mock dir: `<temp_dir_path>`（已清理 / 已保留供除錯）
Executor: success | timeout | error
Steps taken: <N>（case expected_max_steps: <M>）

### ✅ 達成（X/N）
- [tag] <criterion 內容>
  → <grading 依據（mechanical 給工具輸出；semantic 給 evidence + reasoning）>

### 🟡 部分達成（Y/N）
- **[tag] <criterion 內容>**
  Why: <為什麼這條重要>
  What: <實際發生什麼>
  How: <可能的改善方向>

### 💡 進階建議
- <case 設計建議或未來擴充建議>

---

（這份 eval 是輔導建議，不阻擋任何 flow / CI / pipeline。）
```

## 各段空時的寫法

| 段 | 空時 |
|----|------|
| ✅ | `- （所有 criterion 都未達成 — 看下方 🟡 找原因）` |
| 🟡 | `- 全部 criterion 都達成 ✨` |
| 💡 | `- （無）` |

## 隔離違規警告（單獨段）

如果 `isolation_violations` 非空，在 🟡 段之前插入：

```markdown
### ⚠️ 隔離邊界警告
Sub-agent 在 temp dir 之外建立 / 修改了檔案：
- <absolute path>
- ...

Why: 這代表 skill 在 prompt 教學時可能沒明確告知 sub-agent 用相對 / 隔離路徑
How: 檢查 skill 的「先讀哪些檔」「執行步驟」段，是否教 sub-agent 用 cwd-relative 操作

Mock dir 已保留供除錯：<absolute path>
```

## 失敗報告

### Case 格式錯誤（不執行 eval）

```markdown
## Eval Report — <case-name>

無法執行 — case 格式有問題：
- <issue 1>
- <issue 2>

請參考 `assets/case-template.md` 修正後重試。

（這份 eval 是輔導建議，不阻擋任何 flow / CI / pipeline。）
```

### Case 檔不存在

```markdown
## Eval Report

找不到 case 檔：`.athena/evals/<stage>-cases/<case-name>.md`

可能原因：
- 檔名拼錯（檢查 `<case-name>` 引數）
- stage 推斷錯誤（檢查目標 skill 的 frontmatter `stage` 值）
- 還沒建立 case（複製 `assets/case-template.md` 起手）

（這份 eval 是輔導建議，不阻擋任何 flow / CI / pipeline。）
```

### 目標 skill 不存在

```markdown
## Eval Report

找不到目標 skill：`.athena/skills/<target-skill>/SKILL.md`

可能原因：
- skill 名稱拼錯
- skill 還沒被建立
- 路徑非團隊 skill（plugin-internal skill 暫不支援 eval）

（這份 eval 是輔導建議，不阻擋任何 flow / CI / pipeline。）
```

## 不要產出的內容

- ❌ 「總分」「合格率」「PASS / FAIL」字眼
- ❌ 機器可解析的 JSON / YAML 結果區段（避免被當 CI gate）
- ❌ 「建議接到 CI」之類引導
- ❌ 任何「寫入磁碟」的建議

## 多 case 模式（v2 預留）

v1 只支援單 case，每次輸出一份報告。
v2 批量時，每 case 獨立一段，最後加總結。

## 格式檢查清單（每次輸出前自檢）

- [ ] 三段順序：✅ → 🟡 → 💡
- [ ] 沒有 PASS / FAIL / 通過 / 違規 / 錯誤 等禁用詞
- [ ] 結尾固定句存在
- [ ] 每個 🟡 都有 Why / What / How
- [ ] 每個 ✅ 都附 grading 依據
- [ ] 沒有 JSON / YAML 機器格式
