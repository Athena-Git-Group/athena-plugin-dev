# Eval Case Example（L4 引導）

> 本 skill 第一版**不**實作 L4 runner（Executor / Grader）。
> 此檔案僅供團隊未來建立自己的 eval case 時參考。

> **語意提醒**：本檔內出現的 `PASS-DIRECT-BUILD` / `Gate Verdict: PASS` / 「case 不通過」
> 是「被測 skill 產出 handoff」的契約欄位（athena 既有規則）+ 對 build agent 輸出的判定條件，
> **不是 audit 對你 skill 的判定**。Audit 自己的輸出仍只用 ✅ / 🟡 / 💡，無 PASS/FAIL。

## 背景：什麼是 eval case

L4 動態 eval 的概念：給 skill 一個具象任務，看它實際的輸出是否符合期望。
類似「單元測試」之於程式碼，eval case 之於 skill。

## 建議目錄結構

```
.athena/
└── evals/
    ├── spec-cases/
    │   ├── case-001.md
    │   └── case-002.md
    ├── plan-cases/
    └── build-cases/
        └── case-001.md
```

每個 stage 一個目錄，每個 case 一個檔案。

## Case 檔案範本（給 build skill 用）

````markdown
# Build Case 001 — 修正 typo

## Setup（給定的前置條件）

### Mock point-report（points/typo-fix.md）

```yaml
- Summary: 修正 README 第 23 行的 typo「memberhip」→「membership」
- Route: Direct Build
- Verdict: PASS-DIRECT-BUILD
```

### Mock plan handoff

（無 — Direct Build 不走 plan）

### 實際檔案環境

- README.md 第 23 行包含 typo「memberhip」（少一個 s）

## Task 給 skill 的指令

> 執行 build。讀 `points/typo-fix.md`，依 point-report 完成實作。

## 期望輸出特徵（Grader 會檢查的條件）

- [ ] `handoffs/typo-fix-build.md` 被建立
- [ ] handoff 中 `Gate Verdict: PASS`
- [ ] handoff 中 `Files Changed` 只包含 `README.md`（不擴大 scope）
- [ ] README.md 第 23 行的 typo 已修正為正確拼寫
- [ ] handoff 中提到執行了某種 smoke test（grep / 視覺確認都可）
- [ ] 沒有引入新的 dependency

## 反例特徵（命中即視為 case 不通過）

- 同時改了第 23 行以外的內容（scope creep）
- handoff 沒寫 Gate Verdict
- 在 handoff 中引用 `plan.md`（這個 case 沒走 plan）

## Notes

- 這個 case 是 Minimal scope 的 sanity check，主要驗證 build skill 不會 over-engineer
- 想加更難的 case？試試「修一個會影響多檔的 bug」「實作一個有 3 個邊界條件的小函式」
````

## 給其他 stage 寫 case 的提示

| Stage | 適合的 case 類型 |
|-------|---------------|
| `spec` | 模糊需求 → 期望 spec 能識別模糊點並提問；明確需求 → 期望 spec 不過度設計 |
| `plan` | 給 spec → 期望 plan 拆分合理、phase 順序對 |
| `verify` | 給 build handoff + 真實 code → 期望抓到刻意埋的 bug |
| `review` | 給含 code smell 的 diff → 期望被指出 |
| `ship` | 給乾淨的 review handoff → 期望 push + merge 順利完成 |

## 為什麼第一版不實作 runner

- L4 需要 Executor（跑 skill）+ Grader（評分）兩個子 agent，複雜度顯著高於 L1+L2
- 沒有實際使用後的回饋之前，runner 可能設計過頭
- 先把 L1+L2 用穩、收集團隊真實 case 寫法，再決定 runner 介面

## 未來路徑

當團隊累積足夠的 case，且有人主動要求「我想自動跑這些 case」時：

- 再來新增 `athena-skill-audit` 的 L4 模式，或
- 拆出獨立的 `athena-skill-eval` skill
