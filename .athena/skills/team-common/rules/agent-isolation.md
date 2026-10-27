# Rule 1 - 一切從檔案讀取，不假設記得任何事

- Level: `MUST`
- 你是 fresh agent（全新開啟的 agent，沒有前一個 stage 的對話脈絡）。
- 所有前置資訊必須從檔案讀取：`points/<slug>.md`、`handoffs/<slug>-*.md`、`specs/`、`plans/` 等由本 stage 契約指定的輸入檔。
- 不得假設自己「記得」前面 stage 做過什麼——沒讀到的就是不知道。
- 不得嘗試讀取或引用前 stage 的對話內容。

## Good Example

- 這個例子是好的，因為所有依據都來自檔案，且明確列出讀了哪些。

```md
讀取輸入：
1. points/add-tag.md — 需求原文與 Risks 段
2. handoffs/add-tag-spec.md — spec 產出清單
依上述兩檔展開工作，不引用任何「上一個 agent 說過」的內容。
```

## Bad Example

- 這個例子是壞的，因為它把不存在的對話脈絡當成依據。

```md
上一個 stage 的 agent 剛才提到這次只改兩個檔案，
所以我直接跳過讀 handoff，開始實作。
```

# Rule 2 - Gate 判定依據自己查證，不採信 handoff 的宣稱

- Level: `MUST`
- handoff（stage 之間的交接檔）是「指路」用的：告訴你產出在哪、風險是什麼。
- 但凡你要做 gate 判定（PASS / FAIL），依據必須是你自己查證的結果：實際 diff（`git diff` / `git show`）、自己重跑的指令輸出、檔案原文。
- 不得把上一 stage handoff 的宣稱（例如「smoke 已通過」「改動都在範圍內」）直接當成判定依據。

## Good Example

- 這個例子是好的，因為結論建立在自己重跑的指令上。

```md
build handoff 宣稱 bash -n 通過。我自己重跑：
$ bash -n hooks/require-point.sh
（exit 0）
判定：此項 PASS，依據是上述實跑輸出。
```

## Bad Example

- 這個例子是壞的，因為它直接抄 handoff 的宣稱當結論。

```md
build handoff 說 smoke 全過，所以 Smoke 重跑這項直接記 PASS，不用再跑。
```

# Rule 3 - 一個 stage 一個 agent，不開新 agent

- Level: `MUST`
- 你和你 DELEGATE 的子 skill（例如 team-spec-index 分流到的 plugin-contract-spec）在**同一個** agent 中執行。
- 不得嘗試開新 agent——stage shell 沒有 Agent 工具，嘗試只會失敗。
- DELEGATE 的意思是：在本 agent 內 Read 子 skill 的 SKILL.md 並照它執行。

## Good Example

- 這個例子是好的，因為 DELEGATE 在同一個 agent 內完成。

```md
路由判定為 plugin-contract-spec。
Read .athena/skills/plugin-contract-spec/SKILL.md，在本 agent 內依其步驟執行。
```

## Bad Example

- 這個例子是壞的，因為它嘗試開新 agent 執行子 skill。

```md
路由判定為 plugin-contract-spec，呼叫 Agent 工具 spawn 一個新 agent 去跑它。
```
