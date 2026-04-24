# Mentoring Style

所有 audit 輸出必須遵守此語氣指引。

## 三段式結構

```
✅ 做得好的地方
- ...

🟡 可以更好的地方
- ...
  → 建議：...

💡 進階建議
- ...
```

順序固定：✅ → 🟡 → 💡。每段內容可空（用「（無）」或對應替代句標示，見後）。

## 嚴禁詞彙

audit 的對話輸出**禁止**出現下列詞彙（避免被誤解為 gate）：

| 禁用 | 替代 |
|------|------|
| PASS / FAIL | ✅ / 🟡 |
| 通過 / 不通過 | ✅ 做得好 / 🟡 可以更好 |
| 錯誤 / 違規 | 與規範不一致 / 與契約有出入 |
| 不合格 / 不符合 | 可以更貼近建議格式 |
| 必須改 / 應該改 | 建議改 / 可考慮改 |
| 拒絕 / 阻擋 | （audit 無此概念，刪除整句） |
| Gate / Verdict | （audit 無此概念，刪除整句） |

## 句型範例

### 🟡 段的句型（Why → What → How）

- **Why**：說明為什麼這個建議重要（影響什麼）
- **What**：指出具體位置（哪一行 / 哪一段）
- **How**：給可直接複製的改寫範例

範例：

```
🟡 description「我們團隊的 build skill」太泛
   Why: auto-delegation 靠 description 命中，太泛會降低被正確觸發的機率
   What: SKILL.md 第 3 行
   How: 改為「Payments 團隊的 build skill。Java 17 + Spring Boot，TDD 流程」
```

### 💡 段的句型（未來導向）

不要寫成「你應該做 X」，而是「未來如果要 Y，可以考慮 X」。

範例：

```
💡 你還沒在 .athena/evals/ 放 test case
   未來如果想做 L4 動態 eval（用實際任務測試 skill 行為），
   plugin 提供 athena-skill-eval — 可以從複製
   skills/athena-skill-eval/assets/case-template.md 建立第一個 case
```

## 結尾句

每次 audit 輸出的最後一句固定為：

```
（這份 audit 是輔導建議，不阻擋任何 flow / CI / pipeline。）
```

提醒讀者本 skill 的非把關性質。

## 多 skill 全掃時

依字母排序逐一輸出，每個 skill 之間用分隔線：

```
## skill-name-1
[三段式輸出]

---

## skill-name-2
[三段式輸出]
```

不彙總「總分」「合格率」之類的數字 — 因為沒有合格不合格的概念。

## 對話內 follow-up

如果使用者追問：

- 「為什麼這個是 🟡 不是 ❌」 → 解釋本 skill 不使用 ❌
- 「我可以強制當 gate 嗎」 → 婉拒，並建議改用 stage-contracts.md 寫團隊自己的 verifier
- 「audit 報告可以匯出嗎」 → 婉拒寫檔，建議直接複製對話內容
- 「想做動態測試 / regression test / 驗證 skill 行為」 → 推薦 `athena-skill-eval`，是 plugin 提供的 L4 動態 runner
