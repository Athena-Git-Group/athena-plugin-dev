# Skill 品質輔導（athena-skill-audit）

> 與 `/athena-point` 不同 —— audit 是**團隊主動觸發**的健檢工具，**不是 plugin 強制執行的閘門**。沒跑 audit 不會阻擋任何上繳、build 或合併動作。

獨立於 flow 的 **skill 健檢工具**，協助團隊檢查上繳到 `.athena/skills/` 的 skill 是否符合契約與命名規範。**輔導風格**，不阻擋任何 flow / CI。

## 用法

```bash
# 全掃 .athena/skills/ 下所有 skill
/athena-dev-plugin:athena-skill-audit

# 只檢查單一 skill
/athena-dev-plugin:athena-skill-audit my-team-build
```

## 檢查層級

| Tier | 內容 | 第一版實作 |
|------|------|-----------|
| **L1 靜態結構** | frontmatter 必填欄位、`name` 命名規範、`stage` 值合法性、`description` 品質 | ✅ |
| **L2 契約遵守** | 對照 `stage-contracts.md` 檢查 SKILL.md 是否提及讀寫對應 handoff | ✅ |
| **L3 description 主觀評估** | 用 LLM 評估描述是否清楚 | ❌（未來） |
| **L4 動態 eval** | 餵 test case 給 skill，檢查實際輸出 | ✅（由獨立 skill `athena-skill-eval` 提供，見 [skill-eval.md](skill-eval.md)） |

## 輸出風格

採三段式建議格式（**不使用 PASS / FAIL**）：

- ✅ **做得好的地方** — 通過所有客觀規則
- 🟡 **可以更好的地方** — 命中規則但不影響運作，附 Why / What / How 改寫範例
- 💡 **進階建議** — 未來可考慮的強化（如建立 L4 eval cases）

純對話輸出，**不寫入任何檔案**，不輸出機器可解析的 verdict（避免被誤用為 CI gate）。

## 與其他 skill 的邊界

| 比較對象 | 差別 |
|---------|------|
| `athena-point` | point 是流程閘門（評估「需求要走哪條路」），audit 是 skill 品質顧問（檢查 skill 寫得好不好） |
| `athena-flow` | flow 編排執行，audit 與 flow 完全解耦，不被 stage discovery |
| `athena-skill-eval` | audit 是**靜態**檢查（L1+L2），eval 是**動態**執行驗證（L4），兩者互補 |

---

← 回 [README](../../README.md)
