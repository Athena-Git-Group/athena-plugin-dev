# Audit Report 對話模板

每個 skill 的對話輸出依此結構：

```markdown
## <skill-name>
路徑：`.athena/skills/<skill-name>/SKILL.md`
Stage：`<stage value>` 或 `(無 stage 宣告)`

### ✅ 做得好的地方
- <列點，每點一句>

### 🟡 可以更好的地方
- **<簡短結論>**
  Why: <為什麼這影響 skill 品質>
  What: <SKILL.md 的具體位置>
  How: <可直接複製的改寫片段>

### 💡 進階建議
- <未來可考慮的強化>

---
```

## 全掃模式的開頭

```markdown
# Skill Audit Report

掃描範圍：`.athena/skills/`
找到 N 個 skill：<逐一列出名稱>

開始輔導 ↓
```

## 全掃模式的結尾

```markdown
---

掃描完成。共 N 個 skill：
- ✅ 全綠：<count>
- 🟡 有可改善項：<count>
- 💡 有進階建議：<count>

（這份 audit 是輔導建議，不阻擋任何 flow / CI / pipeline。）
```

## 單一模式的結尾

```markdown
---

（這份 audit 是輔導建議，不阻擋任何 flow / CI / pipeline。）
```

## 各段空的時候

| 段 | 空時的寫法 |
|----|-----------|
| ✅ | `- （此 skill 在客觀規則上無明顯亮點，但也無問題）` |
| 🟡 | `- 沒有發現可改善的客觀問題，做得不錯` |
| 💡 | `- （無）` |

## 不要產出的內容

- ❌ 不要寫「總分」「PASS/FAIL 統計」
- ❌ 不要寫「需修復項目清單」
- ❌ 不要產出可被腳本解析的 JSON / YAML 區段
- ❌ 不要建議使用者把 audit 接到 CI

## `.athena/skills/` 不存在時的引導

```markdown
# Skill Audit Report

`.athena/skills/` 在當前專案不存在。

這個目錄是團隊上繳 skill 給 athena-flow 編排用的位置。
如果你還沒開始用 athena-flow，可以先：

1. 建立目錄：`mkdir -p .athena/skills/<your-team>-build`
2. 複製模板：參考 plugin 提供的 `skills/athena-core/assets/skill-template/SKILL.md`
3. 填入 frontmatter（`name`、`description`、`stage`）
4. 再回來跑這個 audit

（這份 audit 是輔導建議，不阻擋任何 flow / CI / pipeline。）
```
