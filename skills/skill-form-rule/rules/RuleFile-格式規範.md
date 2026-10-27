# Rule 1 - 每條規則都使用固定區塊與欄位順序

- Level: `MUST`
- 每條規則必須以 `# Rule N - <Rule name>` 開頭。
- `N` 從 1 開始，依序遞增，不跳號、不重複。
- 標題下方必須緊接 `- Level: \`<value>\`` 欄位。
- `Level` 僅可使用 `MUST`、`SHOULD`、`MAY`，其語意以 `RuleLevel-定義.md` 為準。
- `Level` 之後才寫規則描述條列，接著依序包含 `## Good Example` 與 `## Bad Example`。

## Good Example

- 這個例子是好的，因為它把標題、`Level`、規則描述與 Example 區塊排成固定順序，結構容易被人與 agent 穩定判讀。

````md
# Rule 4 - Example 區塊不可省略

- Level: `MUST`
- 每條規則都必須包含 `## Good Example` 與 `## Bad Example`。
- Example 區塊必須位於規則描述之後。

## Good Example

- 區塊順序完整。

```md
# Rule 5 - 標題層級固定

- Level: `MUST`
- Rule 標題使用 `#`。
```

## Bad Example

- 缺少必要區塊。

```md
# Rule 5 - 標題層級固定

- Level: `MUST`
- Rule 標題使用 `#`。
```
````

## Bad Example

- 這個例子是壞的，因為它缺少 `Level` 欄位，且 Example 區塊順序也不固定。

````md
# Rule 4 - Example 區塊不可省略

- 每條規則都必須包含 `## Good Example` 與 `## Bad Example`。

## Bad Example

```md
內容自己理解
```

## Good Example

```md
差不多像這樣
```
````

# Rule 2 - Example 的示範本體必須包在 fenced code block

- Level: `MUST`
- `Good Example` 與 `Bad Example` 中，實際示範內容必須使用 fenced code block 包裹。
- code block 外只放簡短說明，不放示範本體。
- 若示範內容本身是 Markdown，code fence language 建議使用 `md`。
- 若需要在示範中展示巢狀 code block，外層應改用更長的 fence，例如 ````md。

## Good Example

- 這個例子是好的，因為說明與示範本體分離，示範內容有清楚邊界。

````md
## Good Example

- 先簡短說明這個例子為何符合規則。

```md
# Rule 6 - 檔名應與主題對齊

- Level: `SHOULD`
- 檔名應清楚表達主題。
```
````

## Bad Example

- 這個例子是壞的，因為示範本體直接裸露在段落裡，容易和說明文字混在一起。

````md
## Good Example

- 先簡短說明這個例子為何符合規則。

# Rule 6 - 檔名應與主題對齊

- Level: `SHOULD`
- 檔名應清楚表達主題。
````

# Rule 3 - `Level` 欄位只填值，不在各 RuleFile 重複定義語意

- Level: `MUST`
- 每個 Rule 只需宣告自身 `Level` 值，不在當前 RuleFile 內重複解釋 `MUST`、`SHOULD`、`MAY` 的共用語意。
- `Level` 的語意集中由 `RuleLevel-定義.md` 負責。
- 若該 Rule 有額外限制或例外，寫在規則描述條列中，不覆寫共用 `Level` 定義。

## Good Example

- 這個例子是好的，因為它直接使用 `Level` 值，並把規則內容聚焦在本地限制上，沒有重複抄寫全域定義。

````md
# Rule 7 - Example 說明文字應保持簡短

- Level: `SHOULD`
- `Good Example` 與 `Bad Example` 前的說明應聚焦差異點，不重複定義 `SHOULD` 的語意。

## Good Example

- 說明聚焦在這個例子為何更易讀。

```md
## Good Example

- 說明與示範本體分離。
```

## Bad Example

- 說明冗長，重複了共用定義。

```md
## Good Example

- `SHOULD` 代表強烈建議，預設應遵守；若不採用，應有明確理由。
- 這裡其實只需要說明本例的重點，不需要重複共用語意。
```
````

## Bad Example

- 這個例子是壞的，因為它在單一 Rule 內重新定義 `Level`，造成共用語意分散且難以維護。

````md
# Rule 7 - Example 說明文字應保持簡短

- Level: `SHOULD`
- `SHOULD` 代表強烈建議，預設應遵守；若不採用，應有明確理由。
- `MAY` 代表可選規則。
- `Good Example` 與 `Bad Example` 前的說明應聚焦差異點。
````



