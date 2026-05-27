# Flow Context Marker File

Athena flow agent 在每次啟動 standard stage subagent **之前**，會把該次調用的
context 寫到 `<cwd>/.athena/.flow-context.json`。SubagentStop hook
（`hooks/auto-commit.sh`）依此 marker 決定要不要替剛結束的 subagent 自動 commit。

## 設計目標

| 目標 | 達成方式 |
|------|---------|
| Hook 知道剛結束的 agent 是哪個 stage | `triggering_stage` 欄位 |
| Hook 找得到對應 handoff | `slug` + `phase_number` 組合路徑 |
| 不被 stale marker 誤觸發 | `expires_at` 過期就直接 no-op |
| 不重複 commit 同一個 stop event | hook 成功 commit 後 `rm` marker |
| Flow 仍能選擇用 inline skill | marker 不存在或 `mode: inline` 時 hook no-op |

## Schema

```json
{
  "mode": "hook",
  "triggering_stage": "build-phase-05",
  "slug": "harness-p3-improvements",
  "branch_name": "feature/main_hap3621_harness_p3",
  "ticket": "3621",
  "phase_number": "05",
  "expires_at": "2026-05-13T15:00:00Z"
}
```

| 欄位 | 必要性 | 說明 |
|------|--------|------|
| `mode` | 必要 | `"hook"` 觸發 SubagentStop hook；`"inline"` 走傳統 flow-inline skill 路徑（hook no-op） |
| `triggering_stage` | 必要 | 與 `athena-post-build` 的 triggering_stage 對照表一致 |
| `slug` | 必要 | 用來找對應 handoff artifact |
| `branch_name` | 必要 | 由 pre-build inline skill 寫入 |
| `ticket` | 可空 | 從分支名稱推斷出來的 HAP ticket |
| `phase_number` | 條件必要 | 僅當 triggering_stage 為 `build-phase-NN` / `verify-fix-phase-NN` 時必要 |
| `expires_at` | 必要 | ISO-8601 UTC；建議設定為「subagent 啟動時間 + 預估執行 + 10 分鐘 buffer」 |

## Life cycle

```
flow agent: 即將 spawn build phase 05 subagent
    │
    ├─ 寫入 .athena/.flow-context.json（mode=hook, stage=build-phase-05, slug=…）
    │
    ├─ Agent(prompt=phase-05-skill-instructions, …)
    │
    └─ subagent 結束 → harness 發 SubagentStop → hook 觸發
        │
        ├─ jq 讀 marker → mode=hook → 驗 expires_at → 找 handoff
        │
        ├─ Gate Verdict = PASS？是 → git add -A && git commit
        │
        └─ rm marker（消費掉，避免重複觸發）
```

## Mode 選擇建議

| 情境 | 建議 mode |
|------|----------|
| 預設 / 不確定 | `inline`（與舊行為一致） |
| 想要 commit 與 subagent stop 嚴格同步 | `hook` |
| Full Weight phase loop 平行執行 | `hook`（每個 phase 自己的 marker） |
| Debug 或 CI（不希望意外 commit） | `inline` 或直接不寫 marker |

## 並行 phase 注意事項

Full Weight 中可平行的 phase 各自需要獨立 marker，避免相互覆寫。
實作建議：把 marker 檔名加上 phase 編號 `.athena/.flow-context-phase-NN.json`
並由 flow 在每個 Agent 啟動前寫對應 marker、hook 依照 stop event 中的
subagent identifier 找對應 marker。

> v1 hook 目前讀取單一 `.flow-context.json`；多 phase 平行使用 hook 模式
> 是 known limitation，要落地時需要擴充 schema 與 hook 邏輯。
