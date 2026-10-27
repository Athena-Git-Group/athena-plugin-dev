# Rule 1 - RuleFile 不只要格式正確，也要承載足夠判斷資訊

- Level: `MUST`
- 撰寫或修改 RuleFile 時，除了符合固定格式，也必須檢查規則是否承載足夠判斷資訊，讓執行者能依該檔案完成目標品質把關。
- 若 RuleFile 只有抽象口號、概念摘要或來源名稱，卻沒有具體分類、限制、排除條件或可操作判準，應視為語意承載不足。
- 不可用「已經有 Good/Bad Example」掩蓋規則主體過度空泛的問題。

## Good Example

- 這個例子是好的，因為規則包含可執行的判斷項。

````md
# Rule 1 - 必須以 spec taxonomy 掃描高影響缺口

- Level: `MUST`
- 掃描 Functional Scope & Behavior，包含核心使用者目標、out-of-scope 宣告與角色差異。
- 掃描 Domain & Data Model，包含實體、唯一性、生命週期與資料量假設。
- 每類標記 `Clear`、`Partial` 或 `Missing`。
````

## Bad Example

- 這個例子是壞的，因為格式看似完整，但實際沒有足夠判斷內容。

````md
# Rule 1 - 必須系統性掃描需求缺口

- Level: `MUST`
- 要完整掃描，不要漏掉重要東西。
````

# Rule 2 - 高指導面積來源應保留分類、子項與排序邏輯

- Level: `MUST`
- 若 RuleFile 來源包含 taxonomy、checklist、prompt surface、候選問題 queue 或排序規則，成品必須保留分類、子項與排序邏輯。
- 可改寫語氣與命名以符合目標 skill，但不能刪掉原本會改變判斷結果的掃描項。
- 若刪除來源項目，必須在規則或 example 中說明該項不適用、已被其他模組承接，或應 defer 到其他 skill。

## Good Example

- 這個例子是好的，因為它保留了來源 taxonomy 的可操作結構。

````md
來源 taxonomy：
- Non-Functional Quality Attributes
  - Performance
  - Scalability
  - Reliability
  - Observability
  - Security & privacy

RuleFile 成品：
- 保留 NFR 分類與全部子項
- 補充哪些子項會影響 post-spec clarify
````

## Bad Example

- 這個例子是壞的，因為它只留下分類概念，刪掉會引導 agent 思考的子項。

````md
RuleFile 成品：
- 掃描非功能需求
````

# Rule 3 - Example 應示範語意密度差異，而不只是格式差異

- Level: `SHOULD`
- 當 RuleFile 是從高指導面積來源轉寫而來時，Good/Bad Example 應示範「保留語意密度」與「過度摘要」的差異。
- Example 不應只展示標題、Level、fenced code block 等格式正確性。
- 這樣可讓後續維護者知道本 RuleFile 的品質重點在判斷力，而不只是 Markdown 結構。

## Good Example

- 這個例子是好的，因為它直接對比完整 taxonomy 與過度摘要。

````md
Good：
- 列出 Functional Scope、Data Model、NFR 與 Edge Cases 的子項

Bad：
- 只寫「完整掃描需求」
````

## Bad Example

- 這個例子是壞的，因為它只檢查格式，不檢查 RuleFile 是否真的有判斷力。

````md
Good：
- 有 `# Rule 1`

Bad：
- 沒有 `# Rule 1`
````
