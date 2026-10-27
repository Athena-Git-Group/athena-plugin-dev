# Handoff Contract（階段交接合約）

這條流水線的每個階段都是**全新的 agent**，彼此不共用對話脈絡。
唯一的溝通管道是 workspace 內的 artifact 檔案。本合約定義交接的最小規格。

## 1. 每階段必寫的 handoff 便條

路徑：`specs/<slug>/handoffs/<stage>.md`，建議結構：

```markdown
# <stage> handoff

- STATUS: DONE | BLOCKED
- 輸入 artifact: <path>
- 輸出 artifact: <path>

## 本階段做了什麼
- ...

## 關鍵決策（下一階段需知道的）
- ...

## 仍未決 / 假設（open questions / assumptions）
- ...
```

## 2. gate 標記（兩道閘各認一行）

### score 的 gate 標記

`score/score-report.md` 的**第一行**必須是 VERDICT，總控只認這一行：

```markdown
VERDICT: PASS-WITH-GAPS
```

- `BLOCKED` — 缺少必備維度，文件撐不起轉換；總控停止、把缺口清單退回 PM，不進 clarify。
- `PASS-WITH-GAPS` — 可開工，但 `<3` 的維度即缺口清單，交給 clarify 當提問議程。
- `PASS-CLEAN` — 原料齊備，clarify 只需最後確認。

### clarify 的 gate 標記

`clarify/clarified.md` 的**第一行**必須是狀態標記，總控只認這一行：

```markdown
STATUS: RESOLVED
```

- `RESOLVED` — 需求已釐清到可開始工程化轉換。
- `BLOCKED` — 仍有阻斷性缺口，總控應停止並回報缺口清單，不得進入 db_table。

## 3. 總控對每階段的驗收

- artifact 檔案存在且非空；
- handoff 的 STATUS = DONE；
- 才可派發下一階段的新 agent。

## 4. 給每個 stage agent 的固定指示模板

> 你是一個全新的 agent，只負責 `<stage>` 這一個階段。
> 1. Read `../<stage>/SKILL.md`，依其指示執行。
> 2. 你的輸入只有：`<input artifact path(s)>`。不要假設你知道對話前文。
> 3. 把產出寫到：`<output artifact path>`。
> 4. 最後寫一份 `handoffs/<stage>.md`（依本合約格式）。
> 5. 完成後回報 artifact 路徑與 STATUS。
