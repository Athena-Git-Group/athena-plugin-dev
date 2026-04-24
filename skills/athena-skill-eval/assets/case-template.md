---
eval-case-version: 1
target-stage: <build | spec | plan | verify | review | ship>
description: <一句話描述這 case 在驗證什麼行為>
expected_max_steps: 20
---

# Case：<簡短標題>

<選填：寫一段背景說明這個 case 的動機與要驗證的 skill 行為>

## Setup

<列出 mock 環境的檔案。每個檔案用反引號包檔名，後接 fenced code block 給 verbatim 內容>

`points/<slug>.md`:
```
- Summary: <mock point-report 內容>
- Verdict: <PASS-DIRECT-BUILD | PASS-TRIVIAL | ...>
```

`<other-mock-file>`:
```
<verbatim content>
```

## Task

<給 skill 的指令，會被 eval runner verbatim 傳給 spawn 出來的 sub-agent>

## Expected

<列出期望的輸出特徵，每條前綴 [mechanical] 或 [semantic]>

- [mechanical] handoffs/<slug>-<stage>.md 存在
- [mechanical] handoff 含 "Gate Verdict: PASS"
- [semantic] <用語意條件描述期望，如「沒有 over-engineer」>

## Anti-patterns

<列出反例特徵（不該發生的事）>

- [mechanical] <例：任何 .test.ts 被建立>
- [semantic] <例：handoff 提到 plan.md（這 case 沒走 plan）>

## Notes

<選填，給 case 作者的備註，不參與評分>

---

> **寫 case 的原則**
>
> 1. **小步測試**：一個 case 驗一個行為。怕 over-engineer 就寫一個 case，怕 scope creep 再寫一個。
> 2. **mechanical 為主**：能用 grep / ls 驗的就用 mechanical（便宜、穩定）。
> 3. **semantic 補刀**：判斷意圖、品質、一致性的事，才用 semantic。
> 4. **anti-pattern 反轉**：anti-pattern 沒命中才是好事；別把 expected 跟 anti-pattern 寫反。
> 5. **可重複**：mock 環境完整描述，每次跑都該得到相似結果。
