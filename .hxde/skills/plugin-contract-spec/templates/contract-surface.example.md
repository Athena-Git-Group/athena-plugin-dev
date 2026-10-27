# 契約面盤點 — add-timing-field

## 改動項 A：mini-handoff 新增 Timing 區塊

### 錨點（要改的地方）
- `skills/hxde-flow/references/agent-handoff.md:87` — mini-handoff 模板目前以 Notes for Next Phase 結尾，無 Timing 欄位

### 消費者搜尋
指令：
```bash
grep -rn "mini-handoff" skills/ agents/ commands/ hooks/ scripts/ .hxde/skills/ docs/
```
實際輸出：
```
skills/hxde-flow/references/phase-orchestration.md:52:每個 phase 結束寫 mini-handoff
agents/hxde-stage-build.md:18:收尾時依 mini-handoff 模板……
scripts/emit_trace.py:73:    # parse mini-handoff timing block
```

### 消費者判定
| 檔案:行號 | 引用形式 | 需要同步？ | 理由 |
|-----------|---------|-----------|------|
| `agents/hxde-stage-build.md:18` | 逐項列舉（抄了欄位清單） | **是** | 欄位清單缺 Timing，agent 不會寫這欄 |
| `skills/hxde-flow/references/phase-orchestration.md:52` | 指標引用（「模板見 agent-handoff.md」） | 否 | 指向來源，來源改了就跟著對 |

### 跨語言消費者
| 檔案:行號 | 語言 | 消費方式 | 壞掉時會不會報錯 |
|-----------|------|---------|-----------------|
| `scripts/emit_trace.py:73` | python | 解析 `## Timing` 下兩行 ISO-8601 | **不會**——解析失敗安靜降級 |
