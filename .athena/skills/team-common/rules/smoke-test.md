# Rule 1 - （plan 時）phase 卡的 Smoke Test 必須是可機械判定的指令

- Level: `MUST`
- smoke test（冒煙測試）是改完後用來快速確認「沒有明顯壞掉」的最小檢查，phase 卡的 `Smoke Test` 欄是該 phase 的 gate 依據。
- 它必須是**可機械判定的指令**：跑了有明確的成功／失敗（exit code 或可 grep 的輸出）。
- 不得寫「人工檢查」「確認文件一致」這類無法判定的話當 smoke test。
- 本 repo 的 markdown prompt 契約沒有測試可跑——這類 phase 的 smoke test 必須寫成具體的一致性檢查指令（通常是跨檔 grep）。

## Good Example

- 這個例子是好的，因為跨檔一致性被寫成可機械判定的指令。

```bash
# 確認新 tag 在所有消費者都出現
grep -q 'rule-conflict' skills/athena-flow/references/run-trace.md \
  && grep -q 'rule-conflict' skills/athena-hill-climb/references/hill-climb.md
```

## Bad Example

- 這個例子是壞的，因為它無法機械判定，gate 等於沒有依據。

```md
Smoke Test: 人工檢查 run-trace.md 與 hill-climb.md 的 tag 清單是否一致。
```

# Rule 2 - （plan 時）依 phase 改動的檔案類型從對照表選 Smoke Test

- Level: `MUST`
- 規劃 phase 卡時，`Smoke Test` 依該 phase 改動的檔案類型從下表選：

| 改動類型 | Smoke Test |
|---------|-----------|
| 任何檔案（基本盤） | `bash scripts/lint-plugin.sh` |
| 只動 markdown prompt 契約 | `bash scripts/lint-plugin.sh` + 卡片指定的跨檔一致性 grep（見 Rule 1） |
| 動 `hooks/*.sh` | `bash scripts/lint-plugin.sh`（含 `bash -n` 與執行位檢查）+ 該 hook 的實跑冒煙 |
| 動 `scripts/*.py` 或 `validate_plan.py` | `bash scripts/lint-plugin.sh`（含 plan validator self-test）+ 該 script 對 `tests/fixtures/` 實跑 |
| 動 plan/trace schema | 上述 + `python3 skills/athena-specformula/scripts/validate_plan.py --require-touches tests/fixtures/plan-valid/` |

## Good Example

- 這個例子是好的，因為 hook 改動除了基本盤還安排了實跑冒煙。

```md
Smoke Test:
- bash scripts/lint-plugin.sh
- echo '{}' | bash hooks/require-point.sh  # 實跑冒煙：空輸入不得 crash
```

## Bad Example

- 這個例子是壞的，因為動了 hook 卻只排基本盤，漏掉表中要求的實跑冒煙。

```md
Smoke Test:
- bash scripts/lint-plugin.sh
```

# Rule 3 - （build 時）依改動類型逐類執行 smoke，任一失敗即 Gate FAIL

- Level: `MUST`
- 實作完成後，依本次改動的檔案類型從下表執行 smoke test：

| 改動類型 | 檢查指令 |
|----------|----------|
| bash（`.sh`） | `bash -n <file>` |
| python（`.py`） | `python3 -m py_compile <file>` |
| markdown / SKILL.md | frontmatter 可被解析（YAML 區塊完整、必填欄位存在）+ 檔內相對路徑引用的檔案實際存在（逐一 `ls` 查證） |
| Gherkin `.feature`（若任務涉及） | gherkin parser 可用則跑之；否則至少 grep 檢查 `Feature:` / `Scenario:` / `Given/When/Then` 關鍵字結構一致 |

- 多類型混合改動就**每類都跑**，不挑著跑。
- 任一檢查失敗 → Gate FAIL。
- Full path（有 phase 卡）時，另須執行卡片 `Smoke Test` 欄指定的指令（卡片指令依 Rule 2 的表規劃）；兩邊都要過。

## Good Example

- 這個例子是好的，因為混合改動每類都跑，並照實記錄結果。

```md
本次改了 hooks/require-point.sh 與 skills/athena-flow/SKILL.md：
$ bash -n hooks/require-point.sh         # exit 0
frontmatter 解析 OK；SKILL.md 引用的 references/run-trace.md 存在（ls 查證）。
Smoke Test Result：全數通過。
```

## Bad Example

- 這個例子是壞的，因為混合改動只跑了一類，markdown 那半沒檢查。

```md
本次改了 hooks/require-point.sh 與 skills/athena-flow/SKILL.md：
$ bash -n hooks/require-point.sh         # exit 0
Smoke Test Result：通過。
```

# Rule 4 - （verify 時）不採信 build 的 smoke 結果，依改動類型自己重跑

- Level: `MUST`
- verify 時不信 build handoff 記錄的 smoke 結果——依改動類型，照 Rule 3 的同一張表**自己重跑**：bash → `bash -n`；python → `python3 -m py_compile`；markdown/skill → frontmatter 可解析 + 相對路徑引用存在；feature 檔 → 關鍵字結構檢查。
- 重跑的指令與實際輸出記入 handoff 的 Checks Performed，作為判定依據。

## Good Example

- 這個例子是好的，因為 verify 自己重跑並以輸出為判定依據。

```md
## Checks Performed
- bash -n hooks/require-point.sh: exit 0（自跑）
- python3 -m py_compile scripts/emit_trace.py: exit 0（自跑）
```

## Bad Example

- 這個例子是壞的，因為 verify 直接轉抄 build 的結果。

```md
## Checks Performed
- smoke: PASS（依 build handoff 的 Smoke Test Result 段）
```
