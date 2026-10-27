# 驗收條件 — add-timing-field

## 機械驗收（可判定的指令）
| # | 指令 | 期望 |
|---|------|------|
| 1 | `bash scripts/lint-plugin.sh` | exit 0 |
| 2 | `grep -c 'Started At' agents/hxde-stage-build.md` | ≥ 1 |
| 3 | 以含 Timing 區塊的 fixture 實跑 `python3 scripts/emit_trace.py`（唯讀冒煙） | trace 的 `phases[].started_at` 有值 |

## 通讀驗收（機械抓不到的）
- [ ] fresh-context reader 通讀 `skills/hxde-flow/references/agent-handoff.md`、
      `agents/hxde-stage-build.md`，回報結構缺口：
      雞生蛋（A 需要 B 而 B 需要 A）、缺失路徑（規則沒說某情況怎麼辦）、
      時序矛盾（步驟順序不可能成立）
