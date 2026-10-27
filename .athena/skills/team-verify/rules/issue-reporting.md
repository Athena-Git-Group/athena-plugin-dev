# Rule 1 - 只回報不修

- Level: `MUST`
- verify 階段沒有 Edit 權限：發現問題寫進 handoff 的 Issues Found，由 build agent 做 targeted re-build。
- 不得嘗試自己修改任何產出檔案，也不得在回報中「順手」附上已套用的修正。
- 可以（也應該）附上修正建議的文字描述，但動手修改是 build 的職責。

## Good Example

- 這個例子是好的，因為問題被完整記載並交由 build 處理，verify 自己不動手。

```md
## Issues Found
1. .athena/skills/team-build/SKILL.md:42 — 引用的 rules/build-constraints.md 不存在 #spec-gap
（建議：補建該檔或改掛既有規則檔；由 build agent 執行）
```

## Bad Example

- 這個例子是壞的，因為 verify 自己修了檔案，越過了階段職責。

```md
發現 SKILL.md:42 引用的檔案不存在，我直接把那行引用刪掉了，問題已解決。
```

# Rule 2 - 每個 issue 具體到檔案:行號並附判定依據與 tag

- Level: `MUST`
- 每個 issue 必須具體到 `檔案:行號`，附一句話說明。
- 每個 issue 必須附判定依據：指令輸出或 diff 行，不可只有主觀描述。
- 每個 issue 各帶自己的 taxonomy tag，不共用一個籠統的 tag。

## Good Example

- 這個例子是好的，因為位置、說明、依據、tag 四項俱全。

```md
1. hooks/require-point.sh:17 — 變數未加引號，路徑含空白時會裂開 #spec-gap
   依據：`bash -n` 通過但 `shellcheck` 輸出 SC2086（實跑輸出已附）
```

## Bad Example

- 這個例子是壞的，因為沒有行號、沒有依據、沒有 tag。

```md
1. require-point.sh 裡面有些寫法怪怪的，建議看一下
```

# Rule 3 - Full 模式的 issue 必標 [Phase NN]，Lightweight 不標

- Level: `MUST`
- Full 模式（PASS-SPEC-FIRST）：每個 issue 以 `**[Phase NN]**` 開頭標記 affected phase，供 flow 按 affected_phase 分組做 per-phase targeted fix（慣例見 `skills/athena-flow/references/verify-retry.md`）。
- Full 模式下未標記 phase 的 issue 視為 verify skill 的 bug。
- Lightweight 模式（PASS-BUILD-WITH-VERIFY）：沒有 phase loop，issue **不加** `[Phase NN]` 前綴，handoff 也沒有 `## Affected Phases` 段。

## Good Example

- 這個例子是好的，因為 Full 模式下每條 issue 都標了 affected phase。

```md
## Issues Found
1. **[Phase 03]** scripts/emit_trace.py:88 — stages[] 缺 metrics 欄位 #integration-mismatch
2. **[Phase 05]** skills/athena-flow/SKILL.md:120 — 引用的 verify-retry.md 段落名錯誤 #spec-gap
```

## Bad Example

- 這個例子是壞的，因為 Full 模式下的 issue 漏標 phase，flow 無法做 per-phase targeted fix。

```md
## Issues Found
1. scripts/emit_trace.py:88 — stages[] 缺 metrics 欄位 #integration-mismatch
```
