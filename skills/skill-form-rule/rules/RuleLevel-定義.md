# Rule 1 - `MUST` 只用於不可違反的硬性規則

- Level: `MUST`
- `MUST` 表示硬性規則，預設不可違反。
- 若規則不符合 `MUST`，應視為錯誤、缺漏或違規，而不是單純可改進項。
- 適合用於必要欄位、固定結構、禁止事項或會影響格式正確性的要求。
- 不可把純偏好、可替代寫法或風格建議標成 `MUST`。

## Good Example

- 這個例子是好的，因為它把缺少必要欄位視為明確錯誤，符合 `MUST` 的語意。

````md
# Rule 3 - 每條規則都必須宣告 Level

- Level: `MUST`
- 每條規則都必須包含 `- Level: \`<value>\`` 欄位。

## Bad Example

- 缺少 `Level` 欄位，屬於格式錯誤。

```md
# Rule 4 - Example 區塊不可省略

- 每條規則都必須包含 `## Good Example` 與 `## Bad Example`。
```
````

## Bad Example

- 這個例子是壞的，因為它把純建議性事項標成 `MUST`，讓規則強度過高。

````md
# Rule 8 - 檔名可以更短

- Level: `MUST`
- 檔名最好控制在 12 個字內。
````

# Rule 2 - `SHOULD` 用於預設應遵守但容許具理由偏離的規則

- Level: `MUST`
- `SHOULD` 表示強烈建議，預設應遵守。
- 若不採用 `SHOULD`，應能說明具體理由，而不是任意忽略。
- 適合用於提升可讀性、一致性、維護性或協作效率的規則。
- 不應把缺少就會造成明確錯誤的要求標成 `SHOULD`。

## Good Example

- 這個例子是好的，因為它描述的是提升可讀性的偏好，允許在特殊情況下調整。

````md
# Rule 5 - 檔名應清楚表達主題

- Level: `SHOULD`
- 檔名應讓讀者一眼辨識這份 RuleFile 的主題。

## Bad Example

- 檔名過度抽象，降低可讀性，但不一定造成格式錯誤。

```md
foo.md
```
````

## Bad Example

- 這個例子是壞的，因為它把會造成格式缺漏的要求降成 `SHOULD`。

````md
# Rule 6 - 每條規則都應包含 Good Example

- Level: `SHOULD`
- 每條規則都應包含 `## Good Example`。
````

# Rule 3 - `MAY` 用於可選寫法、替代方案或延伸彈性

- Level: `MUST`
- `MAY` 表示可選規則，可採用也可不採用。
- 適合用於補充替代寫法、可選欄位、語法變體或非必要優化。
- `MAY` 不應承擔必要結構，也不應偽裝成實際上的硬限制。
- 若使用 `MAY`，應讓讀者清楚知道「不採用也仍然合格」。

## Good Example

- 這個例子是好的，因為它提供可選的表達方式，不採用也不影響格式正確性。

````md
# Rule 7 - Example 的 code fence 可以標示語言

- Level: `MAY`
- 若示範內容有明確語言類型，可以在 code fence 上加上對應 language tag。
````

## Bad Example

- 這個例子是壞的，因為它把必要欄位包裝成可選項，會誤導讀者對規則強度的理解。

````md
# Rule 9 - 每條規則可以宣告 Level

- Level: `MAY`
- 規則可視情況決定是否加入 `- Level: \`<value>\`` 欄位。
````
