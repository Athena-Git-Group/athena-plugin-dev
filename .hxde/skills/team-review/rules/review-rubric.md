本檔是 review 視角的唯一真源，針對本 repo 的產物型態（markdown skill 文件、
bash hooks、python script）。每個視角一條 Rule；Level 決定是否擋流程：
`MUST` 視角的問題 → request-changes（Gate FAIL）；`SHOULD` 視角 → 🟡 建議修
（不擋）；`MAY` 視角 → 💡 可選優化（不擋）。輸出格式見 `review-output.md`。

# Rule 1 - 正確性

- Level: `MUST`
- 文件中的指令、路徑、格式範例必須正確可用。
- bash / python 程式不得有邏輯錯誤。
- frontmatter 欄位值必須合法（name、stage 等欄位符合既有 enum 與命名規範）。
- 本視角的問題構成 request-changes。

## Good Example

- 這個例子是好的，因為 reviewer 實際驗證了指令，發現範例跑不起來。

```md
🟥 正確性：SKILL.md:31 的範例指令 `python skills/x/run.py` 實跑報
ModuleNotFoundError（repo 內該路徑不存在，應為 scripts/run.py）→ request-changes
```

## Bad Example

- 這個例子是壞的，因為只憑觀感放過了可驗證的錯誤。

```md
✅ 正確性：指令看起來都合理，通過。
```

# Rule 2 - 一致性

- Level: `MUST`
- 不得與既有契約檔（`skills/hxde-flow/references/stage-contracts.md`、
  `skills/hxde-flow/references/agent-handoff.md`）矛盾。
- 同一概念在全文必須使用同一術語，不得混用。
- 本視角的問題構成 request-changes。

## Good Example

- 這個例子是好的，因為 reviewer 對照了契約檔原文找到矛盾。

```md
🟥 一致性：SKILL.md:58 說「verify FAIL 時 Next = re-verify」，但
agent-handoff.md 變體差異表規定 Verify Full 的 Next = review 或
re-build (targeted) → request-changes
```

## Bad Example

- 這個例子是壞的，因為同一概念兩種叫法被當成風格問題放過。

```md
💡 文件裡「phase 卡」和「階段卡片」交替出現，讀起來稍微不順，可選優化。
```

# Rule 3 - 引用完整

- Level: `MUST`
- 文件內相對路徑引用的檔案必須存在，逐一查證（`ls` 每個被引用路徑），不得抽查。
- 不得有死連結（引用不存在的檔案、段落名或錨點）。
- 本視角的問題構成 request-changes。

## Good Example

- 這個例子是好的，因為每個引用都被逐一查證並記錄。

```md
✅ 引用完整：SKILL.md 引用 3 個相對路徑
（rules/a.md、templates/b.md、.hxde/skills/team-common/rules/c.md），逐一 ls 皆存在。
```

## Bad Example

- 這個例子是壞的，因為只抽查了一個引用就下通過結論。

```md
✅ 引用完整：抽查 rules/a.md 存在，其餘應該也沒問題。
```

# Rule 4 - repo 慣例

- Level: `SHOULD`
- 命名使用小寫連字號（kebab-case）。
- description 使用中文、指令式寫法。
- 與鄰近 skill 的結構與風格對齊。
- 本視角的問題放 🟡 建議修，不擋流程。

## Good Example

- 這個例子是好的，因為慣例偏離被記為建議而不是 FAIL。

```md
🟡 repo 慣例：rules/IssueReporting.md 應改為小寫連字號
（issue-reporting.md），與鄰近 skill 對齊。檔案:行號已附。不擋流程。
```

## Bad Example

- 這個例子是壞的，因為把慣例問題升級成 request-changes，錯誤地擋了流程。

```md
🟥 檔名不是 kebab-case → Gate Verdict: FAIL #review-finding
```

# Rule 5 - 品質

- Level: `MAY`
- 精簡度、可讀性、更好的寫法。
- 本視角的建議放 💡 可選優化，不影響 Gate Verdict。

## Good Example

- 這個例子是好的，因為品質建議具體且明確標示為可選。

```md
💡 品質：SKILL.md Phase 2 的三個 THINK step 可合併為一步，減少重複載入描述。
```

## Bad Example

- 這個例子是壞的，因為空泛的品味評論沒有給出可行動的建議。

```md
💡 整體寫得不夠優雅，建議重寫。
```

---

> **新增視角：加一節即可。** 要擴展新的 review 面向（例如安全性、i18n），
> 在本檔末尾依相同格式新增一條 `# Rule N - <視角名>`：寫明檢查內容、
> 用 Level 宣告分級（`MUST` → request-changes；`SHOULD` → 🟡；`MAY` → 💡），
> 並附 Good/Bad Example。SOP 與輸出格式不需要改。
