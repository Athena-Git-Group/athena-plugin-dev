# 契約面盤點 — {{SLUG}}

## 改動項 {{CHANGE_ID}}：{{CHANGE_SUMMARY}}

### 錨點（要改的地方）
- `{{ANCHOR_PATH}}:{{LINE_NUMBER}}` — {{CURRENT_TEXT_QUOTE}}

### 消費者搜尋
指令：
```bash
grep -rn "{{SEARCH_STRING}}" skills/ agents/ commands/ hooks/ scripts/ .athena/skills/ docs/
```
實際輸出：
```
{{REAL_GREP_OUTPUT}}
```

### 消費者判定
| 檔案:行號 | 引用形式 | 需要同步？ | 理由 |
|-----------|---------|-----------|------|
| `{{CONSUMER_PATH}}:{{CONSUMER_LINE}}` | {{REFERENCE_KIND}} | {{SYNC_REQUIRED}} | {{SYNC_REASON}} |

### 跨語言消費者
| 檔案:行號 | 語言 | 消費方式 | 壞掉時會不會報錯 |
|-----------|------|---------|-----------------|
| `{{SCRIPT_PATH}}:{{SCRIPT_LINE}}` | {{LANGUAGE}} | {{CONSUME_METHOD}} | {{FAILS_LOUDLY}} |
