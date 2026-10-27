# Rule 1 - 改動範圍不得超出任務輸入

- Level: `MUST`
- Minimal / Lightweight 的範圍由 `points/<slug>.md`（point-report）定義；Full 的範圍由 phase card 的 `Touches` 宣告定義。
- 動手前先列出要改的檔案清單，逐一確認落在範圍內。
- 發現必要的範圍外改動 → 記入 handoff 的 Risks / Unresolved Issues，不動手。

## Good Example

- 這個例子是好的，因為範圍外的必要改動被記錄而不是偷做。

```md
point-report 範圍是 hooks/require-point.sh。實作中發現 README 的說明也該同步，
但 README 不在範圍內——記入 Risks：「README 強制規則段需同步更新」，不改它。
```

## Bad Example

- 這個例子是壞的，因為 agent 自行擴大範圍。

```md
point-report 只提 hooks/require-point.sh，但我順手把 README 和兩個 skill 的
相關段落都改了，反正方向一致。
```

# Rule 2 - 禁止 git push

- Level: `MUST`
- build 階段不得執行 `git push`——push 是 ship 階段的職責。

## Good Example

- 這個例子是好的，因為 build 只留下本地改動，交給後續 stage。

```md
實作完成、smoke 通過，寫 handoff 後結束。commit / push 由 flow 與 ship 處理。
```

## Bad Example

- 這個例子是壞的，因為 build agent 自己 push。

```md
改完順手 git push origin feature/add-tag，幫 ship 省一步。
```

# Rule 3 - point-report 是唯讀輸入

- Level: `MUST`
- 禁止修改 `points/<slug>.md`。
- 覺得 point-report 寫錯或範圍不合理 → 記入 handoff 的 Risks，不改它。

## Good Example

- 這個例子是好的，因為對 point-report 的異議走回報而不是改檔。

```md
point-report 的驗收條件疑似漏了一條，記入 Risks：「驗收條件未涵蓋空輸入case」。
points/add-tag.md 保持原樣。
```

## Bad Example

- 這個例子是壞的，因為 agent 改寫了唯讀輸入。

```md
point-report 的範圍寫得太窄，我直接編輯 points/add-tag.md 把範圍加寬再實作。
```

# Rule 4 - 只做 build 的工作，不越界幫 verify / review 做事

- Level: `MUST`
- 只做本 stage 契約定義的工作：實作、smoke test、handoff。
- 不代替 verify 做獨立驗證、不代替 review 寫審查意見——那些 stage 需要 fresh context 才有效。

## Good Example

- 這個例子是好的，因為 build 把疑慮留給下游 stage。

```md
smoke 過了，但我對跨檔一致性沒把握——記入 Risks 讓 verify 重點檢查，
不在 build handoff 裡自己宣告「已全面驗證」。
```

## Bad Example

- 這個例子是壞的，因為 build 越界宣告了 verify / review 的結論。

```md
我已經自己做完完整驗證與 code review，verify 和 review 階段可以跳過。
```
