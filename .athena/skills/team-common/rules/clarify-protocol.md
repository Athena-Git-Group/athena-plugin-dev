# Rule 1 - Headless：不互動詢問，能客觀回答的就地解決，不可腦補

- Level: `MUST`
- headless 的意思是：spec stage 在無人值守的 agent 中執行，**不得互動詢問使用者**。
- 能從需求原文（requirement）與標的檔案原文客觀回答的問題，就地解決，不進 clarify。
- 答不出來的，**不可腦補**（不替使用者編造答案、不憑感覺挑一邊）——走 Rule 2 的 clarify 流程。

## Good Example

- 這個例子是好的，因為可查證的就地解決，查不到的才進 clarify。

```md
問題「新 tag 要不要進 hill-climb 的逐 tag 表」：
grep 查證 hill-climb.md 既有 tag 全數列表 → 可客觀判定要同步，就地解決。
問題「Lightweight 模式要不要跳過 review」：需求沒寫、檔案查不到 → 進 questions.md。
```

## Bad Example

- 這個例子是壞的，因為它用猜的補上需求沒給的決策。

```md
需求沒說 Lightweight 要不要跳過 review，
一般來說應該要跳過，就照這個假設寫規格。
```

# Rule 2 - 未解問題寫入 questions.md：逐題編號、附預設選項與影響說明

- Level: `MUST`
- 仍有未解問題時，寫 `specs/<slug>/clarify/questions.md`。
- 格式：逐題編號；每題附預設選項（你建議的答案）與影響說明（選不同答案會差在哪）。
- 這是給使用者離線回答用的——題目要讓沒有上下文的人也能作答。

## Good Example

- 這個例子是好的，因為題目自足、有預設選項、有影響說明。

```md
## Q1. Lightweight 模式是否跳過 review stage？
- 預設選項：否（仍跑 review，但併入 review-ship handoff）
- 影響：選「是」則 ship 前沒有人審 diff，正確性問題會直接進 merge_target。
```

## Bad Example

- 這個例子是壞的，因為題目沒編號、沒選項、沒影響，使用者無從作答。

```md
review 那邊怎麼處理？另外 tag 的事也要確認一下。
```

# Rule 3 - 有未解問題時 handoff 發 FAIL `#spec-gap` 並停止

- Level: `MUST`
- 寫完 `specs/<slug>/clarify/questions.md` 後，最終 handoff 的 Gate Verdict 發：
  `FAIL — 待使用者澄清，見 specs/<slug>/clarify/questions.md #spec-gap`，然後**停止**。
- flow 會回報使用者；使用者的回答由主對話寫入 `specs/<slug>/clarify/answers.md` 後重跑 spec stage。
- 不得一邊留著未解問題一邊發 PASS，也不得停止而不寫 handoff。

## Good Example

- 這個例子是好的，因為 FAIL 指向問題清單並乾淨停止。

```md
## Gate Verdict
FAIL — 待使用者澄清，見 specs/add-tag/clarify/questions.md #spec-gap
```

## Bad Example

- 這個例子是壞的，因為留著未解問題卻發 PASS 繼續往下。

```md
## Gate Verdict
PASS — 規格完成（另有兩題待確認，之後再說）
```

# Rule 4 - 開工先讀 answers.md，已答的不重問

- Level: `MUST`
- 進入 spec stage 時先檢查 `specs/<slug>/clarify/answers.md` 是否存在——存在就讀入，納為判準依據。
- 重跑時已答過的題目不得再問一次；只有新產生的未解問題才進新的 questions.md。

## Good Example

- 這個例子是好的，因為重跑時先消化既有答案。

```md
檢查 specs/add-tag/clarify/answers.md：存在。
Q1 已答「否」→ 直接採用，不重問；本輪無新問題，繼續產出規格。
```

## Bad Example

- 這個例子是壞的，因為重跑時無視既有答案、重複問同一題。

```md
重跑 spec stage。寫 questions.md：
Q1. Lightweight 模式是否跳過 review stage？（上一輪已在 answers.md 回答過）
```
