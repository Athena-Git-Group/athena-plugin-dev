# L4 動態評估（athena-skill-eval）

> 與 `/athena-point` 不同 —— eval 是**團隊主動觸發**的離線回歸測試工具，**不是 plugin 強制執行的閘門**。

對 skill 進行**行為測試** — 給 skill 一個具象 case → spawn fresh sub-agent 真實執行 → 評分。L1+L2 ([audit](skill-audit.md)) 看 skill 寫得好不好；L4 (eval) 看 skill 跑出來對不對。

## 用法

```bash
/athena-dev-plugin:athena-skill-eval <target-skill> <case-name>
```

範例：

```bash
/athena-dev-plugin:athena-skill-eval crs-build-impl typo-fix
```

## Case 檔案位置

```
<project>/.athena/evals/
├── spec-cases/
├── plan-cases/
├── build-cases/
├── verify-cases/
├── review-cases/
└── ship-cases/
```

每個 case 一個 `.md`，依 `skills/athena-skill-eval/references/case-spec.md` 格式撰寫。
起手請複製 `skills/athena-skill-eval/assets/case-template.md`。
完整範例見 `skills/athena-skill-eval/assets/case-example-build.md`。

## 評分機制

每個 criterion 在 case 裡標記 `[mechanical]` 或 `[semantic]`：

- **`[mechanical]`** — 純結構/字串/檔案存在性（grep / Read 機械比對，便宜穩定）
- **`[semantic]`** — 需要意圖判斷（spawn 第二個 sub-agent 用 LLM rubric 判定）

判別小測驗：「這條 criterion 需要看內容判斷意圖嗎？需要 → semantic；不需要 → mechanical」

## 執行流程

```
case file → mock env (temp dir) → spawn fresh sub-agent (Executor) →
  capture output → grade per-criterion → cleanup → 三段式報告
```

## 與 audit 的分工

| | audit | eval |
|---|------|------|
| 層級 | L1+L2 靜態 | L4 動態 |
| 看什麼 | SKILL.md 文字結構 | skill 真實執行行為 |
| 成本 | 低（純 grep） | 高（spawn agent + LLM grading） |
| 何時用 | 隨手檢查、定期掃 | 改 skill 後驗證、regression test |

兩者互補：先用 [audit](skill-audit.md) 確認結構合規，再用 eval 確認行為符合期望。

---

← 回 [README](../../README.md)
