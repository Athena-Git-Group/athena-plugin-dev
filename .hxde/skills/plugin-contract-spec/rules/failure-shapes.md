# Rule 1 - 契約改動的規格主工作是窮舉消費者

- Level: `MUST`
- 契約改動（改 LLM 讀的行為契約檔）不會「跑不起來」，它的失敗形狀是：
  - **一半生效**：改了來源檔，但另一個逐項列舉它的檔案沒同步（例：enum 加進 `run-trace.md`，但 `hill-climb.md` 的逐 tag 表沒加）。
  - **寫而未達**：規則寫進文件，但 agent 實際讀的檔案沒鏡射（例：規則進了 `phase-orchestration.md`，但 phase agent 讀的 `agents/hxde-stage-build.md` 沒改）。
  - **靜默壞**：跨語言消費點（bash / python）語意變了卻不報錯（例：flow-context 欄位改了語意，`hooks/auto-commit.sh` 的 `jq` 照舊跑）。
- 三種形狀共同點：**所有 gate 都顯示 PASS**。所以這份規格的主要工作不是描述想要什麼，而是**窮舉誰在消費這個契約**。

## Good Example

- 這個例子是好的，因為它把規格重心放在消費者窮舉，而不只是描述改動。

```md
改動項 A：在 run-trace.md 新增 tag。
消費者 grep：hill-climb.md:84（逐 tag 表，必須同步）、
team-build SKILL.md:83（指標引用，不必同步）、
scripts/emit_trace.py:40（python 消費，壞掉不報錯 → 列機械驗收）。
```

## Bad Example

- 這個例子是壞的，因為它只寫想要的結果，沒有盤任何消費者。

```md
改動項 A：在 run-trace.md 新增 tag，加上去就好，其他檔案應該不受影響。
```
