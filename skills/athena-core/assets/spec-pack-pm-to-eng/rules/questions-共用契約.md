# Rule 1 - `clarify/questions.md` 是唯一的「問使用者」通道，三個寫入者一律追寫

- Level: `MUST`
- `specs/<slug>/clarify/questions.md` 是本 pack **唯一由 phase 主動追寫**的「問使用者」通道，有 **3 個寫入者**：`clarify`、`specify`、`ui_prototype`。
- 三者一律**追寫（append）**，**不得**重寫全檔、**不得**重編既有題號。
- **不另立第二套協議、不另開新檔**：任何 phase 都不得為了繞開本契約而自創題號規則或另建問題檔。

## Good Example

- 這個例子是好的，因為新題目直接追加在既有題目之後，既有題號原封不動。

````md
### Q1 · [clarify] 退款是否允許部分金額？

### Q2 · [specify] 退款單的審核者由誰指定？
````

## Bad Example

- 這個例子是壞的，因為 `specify` 另開了新檔、另起一套題號，使用者要同時看兩份檔案才知道還有什麼沒回答。

````md
clarify/questions.md
### Q1 · [clarify] 退款是否允許部分金額？

clarify/specify-questions.md
### 問題 1 退款單的審核者由誰指定？
````

# Rule 2 - 題號全檔連號，標題行必須標出提問的 phase

- Level: `MUST`
- **題號**：全檔連號 `Q<n>`。新題取「檔內現有最大題號 + 1」；檔案不存在時自 `Q1` 起。
- **來源標記**：每題標題行必須標出提問的 phase——`### Q<n> · [<phase>] <一句話問題>`，`<phase>` ∈ `clarify` / `specify` / `ui_prototype`。
- 使用者要能一眼看出某題是哪一階段問的，因此來源標記不可省略、不可改寫成其他字樣。

## Good Example

- 這個例子是好的，因為題號接續既有最大號碼，且標題行同時帶出題號、來源 phase 與一句話問題。

````md
### Q3 · [ui_prototype] 退款列表在手機尺寸下要保留哪幾個欄位？
````

## Bad Example

- 這個例子是壞的，因為它從 `Q1` 重新編號，又少了來源 phase 標記，使用者無法分辨這題是誰問的。

````md
### Q1 退款列表在手機尺寸下要保留哪幾個欄位？
````

# Rule 3 - 題目內容必須 PM-friendly 並寫出答案會改變什麼

- Level: `MUST`
- **內容**：PM-friendly 措辭，附建議選項與「答案會改變什麼」的影響說明。
- 不可只丟一個工程術語問句就當作已提問——使用者是 PM，必須看得懂選項與後果才能回答。

## Good Example

- 這個例子是好的，因為它用 PM 看得懂的措辭提問，附上建議選項，並說明答案會改變哪一段規格。

````md
### Q4 · [specify] 退款申請被駁回後，使用者可以再次申請嗎？

- 建議選項：(a) 可無限次重送 (b) 同一筆訂單限重送 1 次 (c) 駁回後不可再申請
- 影響：決定 spec.md 的「退款狀態機」要不要有「駁回 → 重新申請」這條轉移，也決定 db_table 要不要存重送次數。
````

## Bad Example

- 這個例子是壞的，因為它只有一句工程術語問句，沒有選項也沒有影響說明，PM 無從判斷怎麼回答。

````md
### Q4 · [specify] refund retry policy?
````

# Rule 4 - 已回答的題目只追加標記，不刪題、不改號

- Level: `MUST`
- **已回答標示**：使用者的回答由 flow 主對話寫入 `clarify/answers.md`。
- 後續輪次讀到 `answers.md` 已涵蓋的題目時，在該題標題行末追加 `（已回答）`——**不刪題、不改號**，歷史必須可追。

## Good Example

- 這個例子是好的，因為它只在原題標題行末追加標記，題號與題目文字都保持原樣，可以回溯問過什麼。

````md
### Q1 · [clarify] 退款是否允許部分金額？（已回答）
### Q2 · [specify] 退款單的審核者由誰指定？
````

## Bad Example

- 這個例子是壞的，因為它把已回答的題目刪掉並把後面的題目往前遞補，歷史無法追溯。

````md
### Q1 · [specify] 退款單的審核者由誰指定？
````

# Rule 5 - 每支 phase 每輪最多追寫三題

- Level: `MUST`
- **每輪題數**：每支 phase 每輪 ≤ 3 題（各 phase 自己的「缺口升級協議」）。
- 超出三題時，由該 phase 自行挑出阻塞程度最高的三題，其餘缺口留待下一輪再問。

## Good Example

- 這個例子是好的，因為 `clarify` 本輪只追寫三題，把最阻塞的缺口問完，其餘留到下一輪。

````md
### Q1 · [clarify] ...
### Q2 · [clarify] ...
### Q3 · [clarify] ...
````

## Bad Example

- 這個例子是壞的，因為單一 phase 一輪就追寫了五題，使用者一次要回答的量超出協議上限。

````md
### Q1 · [clarify] ...
### Q2 · [clarify] ...
### Q3 · [clarify] ...
### Q4 · [clarify] ...
### Q5 · [clarify] ...
````

# Rule 6 - 編排器必須在最終 handoff 收斂 questions.md，不得靜默吞掉非 gate 的缺口

- Level: `MUST`
- **編排器責任**：本檔負責在最終 handoff 收斂——gate 型寫入者（`clarify` / `specify`）走 FAIL 停止；非 gate 型寫入者（`ui_prototype`）不改 verdict，但**必須**進 Risks（見 `rules/gate-verdict-映射.md` 對應列）。
- `ui_prototype` 追寫 `clarify/questions.md` 時**不改變 Gate Verdict、不停止**（它不是 gate），但編排器**必須**在最終 handoff 的 Risks 記「`ui_prototype` 追寫 N 題待澄清」，並把 `questions.md` 列入 `## Artifacts Produced`。
- 收在 `PASS` 卻讓使用者不知道 `questions.md` 有新題，即為流程缺陷。

## Good Example

- 這個例子是好的，因為 verdict 仍是 PASS（`ui_prototype` 不是 gate），但 Risks 明寫了題數與檔案路徑，使用者不會漏看新題。

````md
## Gate Verdict
PASS

## Risks / Unresolved Issues
- ui_prototype 追寫 2 題待澄清，見 specs/refund/clarify/questions.md（已知落差記於 ui-plan.md）
````

## Bad Example

- 這個例子是壞的，因為 `ui_prototype` 追寫了新題卻只收在 PASS，Risks 與 Artifacts Produced 都沒有任何痕跡。

````md
## Gate Verdict
PASS

## Risks / Unresolved Issues
- 無
````

# Rule 7 - `gherkin` 的待釐清缺口不走 questions.md，改走 `.feature` 標記並逐題轉錄進 Risks

- Level: `MUST`
- **`gherkin` 的待釐清缺口不走本檔**（唯一的例外，明文釘死以免出現第二套題號）：`gherkin` 在 `.feature` 上標 `@待釐清`、並在 `handoffs/gherkin.md` 的「回饋訊號」段列出缺口，**不追寫 `questions.md`、不編 `Q<n>` 題號**。
- 編排器把那些缺口**逐題轉錄**進最終 handoff 的 Risks；答案同樣經使用者 → `clarify/answers.md` → 下一輪 spec stage 回來。本 run 內**不回退階段**。
- 理由：`gherkin` 是最末階段，缺口已具體綁在某條 `Scenario` 上，溯源靠 `.feature` 的 `@待釐清` 標記即足；把它塞進 `questions.md` 會讓「gate 型 / 非 gate 型寫入者」的二分法多出第三類。

## Good Example

- 這個例子是好的，因為缺口標在它所屬的 `Scenario` 上，而且編排器把它逐題轉錄進 Risks，使用者仍然看得到。

````md
@待釐清
Scenario: 退款金額超過原訂單金額

## Risks / Unresolved Issues
- gherkin 待釐清：退款金額超過原訂單金額時的預期行為未定義（見 gherkin/*.feature 的 @待釐清）
````

## Bad Example

- 這個例子是壞的，因為 `gherkin` 去追寫了 `questions.md` 並自編題號，違反唯一例外的明文規定，也讓寫入者分類多出第三類。

````md
### Q7 · [gherkin] 退款金額超過原訂單金額時要怎麼處理？
````
