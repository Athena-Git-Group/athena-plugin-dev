# Rule 1 - Review 結果用 ✅/🟡/💡 三段式輸出

- Level: `MUST`
- review 結果必須分三段呈現，寫入 handoff 的 `## Review Result` 段
  （內含 `### ✅ 通過項`、`### 🟡 建議修（不擋）`、`### 💡 可選優化` 三個子段）：
  - **✅ 通過項**：確認無誤的面向，一行一條。
  - **🟡 建議修**：不擋流程的一致性/慣例建議，附 `檔案:行號`。
  - **💡 可選優化**：品質建議。
- 三段都要出現；某段沒有內容時寫 None，不可整段省略。

## Good Example

- 這個例子是好的，因為三段俱全且 🟡 附了檔案:行號。

```md
## Review Result

### ✅ 通過項
- 正確性：範例指令實跑通過
- 引用完整：3 個相對路徑逐一 ls 皆存在

### 🟡 建議修（不擋）
- .hxde/skills/team-x/SKILL.md:12 — description 應改指令式寫法

### 💡 可選優化
None
```

## Bad Example

- 這個例子是壞的，因為缺段、混段，🟡 也沒附位置。

```md
## Review Result
大致沒問題，有個 description 寫法建議改一下。
```

# Rule 2 - 只有 MUST 級視角的問題才判 FAIL（request-changes）

- Level: `MUST`
- 只有正確性、一致性、引用完整（`review-rubric.md` 中 Level 為 `MUST` 的視角）
  的問題才判 FAIL（request-changes）；🟡/💡 不影響 Gate Verdict。
- FAIL 時 Gate Verdict 必須帶 `#review-finding` tag。
- PASS 時 Gate Verdict 寫 `PASS — approved, <摘要>`（本行緊貼標題）。

## Good Example

- 這個例子是好的，因為 FAIL 來自 MUST 級視角且帶正確的 tag。

```md
## Gate Verdict
FAIL — SKILL.md:58 與 agent-handoff.md 變體差異表矛盾 #review-finding
```

## Bad Example

- 這個例子是壞的，因為用品質建議（💡 級）判了 FAIL。

```md
## Gate Verdict
FAIL — SOP 步驟可以更精簡 #review-finding
```

# Rule 3 - 只指出問題，不修

- Level: `MUST`
- review 階段沒有 Edit 權限：指出問題並寫入 handoff，修改由 build agent 執行。
- 不得嘗試自己修改任何產出檔案，也不得在回報中宣稱「已順手修正」。

## Good Example

- 這個例子是好的，因為問題被記載並交回 build。

```md
🟡 .hxde/skills/team-x/rules/a.md:9 — 術語「phase 卡」應統一為全文用法；
由 build agent 修正。
```

## Bad Example

- 這個例子是壞的，因為 review 自己動手改了檔案。

```md
發現術語不一致，我直接把 rules/a.md 的三處都改掉了。
```
