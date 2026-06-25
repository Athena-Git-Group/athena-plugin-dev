# Hill-Climb Proposals — <date>

> 由 `athena-hill-climb` 產出。**不是 CI gate**——這是改進建議，採納與否由人決定。
> 採納的提案請走 `/athena-flow` 實作（系統用自己改進自己）。

- Window: <起始 watermark> → <本輪結束時間>
- Runs analyzed: <N>（其中失敗 <M>）
- Metrics 趨勢: <一句話，對照上一輪>

---

## ✅ 穩定 / 正在改善

- <指標或面向>：<證據，如「gate 一次過率 0.65 → 0.72」>

## 🟡 系統性問題（建議處理）

### P1 — <一句話標題>

- **嚴重度**: 🟡
- **診斷**: <什麼系統性問題>
- **Trace 證據**: <run_ids，例 `2026-06-20-x-01`, `2026-06-22-y-03`（4/9 Full run）>
- **失敗 tag**: `<taxonomy tag>`
- **改進目標**: <build skill / point rubric / stage contract / team skill / verify / memory>
- **建議改動**: <具體要改什麼>
- **驗證方式**: <skill-eval 跑 case X / 重新 point 歷史 intake / skill-audit 靜態檢查>
- **採納?**: [ ] 採納 → 轉 `/athena-flow` intake　[ ] 暫不　[ ] 否決（原因: ____）

## 💡 可考慮（證據較弱，先觀察）

### P<n> — <一句話標題>

- **嚴重度**: 💡
- **訊號**: <觀察到什麼，為何證據還不夠強>
- **Trace 證據**: <run_ids>
- **建議**: <繼續觀察 / 補哪種資料>
