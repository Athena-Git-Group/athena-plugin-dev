# Point Result

- Report path: `points/harness-p0-improvements.md`
- Summary: 對 athena-dev-plugin 本身做三項 harness 整合升級——P0-1 新增 `commands/` 真 slash command 入口、P0-2 新增 `PreToolUse` hook 強制執行 point gate、P0-3 把 phase loop 平行執行改為 background agent / TaskCreate 路線。範圍限定 plugin repo 自身設定、skill markdown、與一支 hook shell script。
- Knowledge base needed: no
- Knowledge sources checked: none（plugin repo 無 `.athena/knowledge/`；Harness 行為依據是 Claude Code 公開文件慣例）
- Route: Build With Verify
- Gate verdict: `PASS-BUILD-WITH-VERIFY`
- Allowed next commands: `/build`（完成後強制進 `/verify`）
- Required follow-up gates: 必須 verify hook 安裝後不會把使用者鎖死、commands 確實被 harness 認出、phase loop 改動不破壞既有 Full Weight 流程

## Scorecard

- Requirement clarity: 1/5
- Domain rule complexity: 1/5
- Impact radius: 3/5
- Contract/schema change: 2/5
- Regression risk: 4/5
- Knowledge dependency: 1/5
- Total: 12/30

## Why

- 需求明確：三項 P0 在前一輪 audit 已列出並由使用者確認，每項皆有具體 deliverable 清單與檔案路徑，沒有業務歧義
- 無 domain rule 複雜度：純 harness 工具改造，不涉及業務規則、權限、計費等
- Impact Radius 給 3：雖然 plugin repo 本身改動範圍小（~8 個檔案），但 hook 一旦發布，會影響**所有安裝此 plugin 的 consumer 專案**的每一次 Edit/Write 行為，從使用者視角是跨模組廣播
- Contract change 給 2：`plugin.json` 補欄位（`commands` / `hooks`）屬於 plugin manifest 對外契約微調；新增的 4 個 slash commands 是新的 user-facing surface
- Regression Risk 給 4：`PreToolUse` hook 若邏輯錯誤、escape hatch 失效，會把使用者自己的編輯動作全部 block（包含 fix hook 本身），是高風險變更，必須 verify
- 不必走 spec：前一輪 audit 已是事實 spec，使用者已對齊方案；spec stage 此處無新增資訊量
- 走 verify 不是 build-direct：hook 安裝後必須實際試跑「missing point-report 應 block」「有 point-report 應放行」「escape hatch 生效」三條路徑

## Risks

- **Hook 設計風險（最高優先）**：
  - 必須提供確定可用的 escape hatch（建議用 env var `ATHENA_SKIP_POINT_GATE=1` 同時支援 marker file `.athena/skip-point-gate`）
  - 必須限定 hook 觸發範圍（只有 Edit/Write、且 cwd 包含 plugin 標記時才檢查），不能跨專案誤傷
  - 必須有可逆退路：若 hook 自己壞了，使用者應能透過 `claude plugin disable` 或編輯 hook 檔案脫困——後者需要 hook 對 hooks/* 自身的編輯放行
- **Commands 命名衝突**：使用者已習慣短形式 `/athena-flow`，若 harness 同時存在 skill 觸發與 command 觸發，要確認沒有 ambiguous routing；建議 commands 內容明確 delegate 到 skill，避免邏輯分裂
- **Phase loop 改動**：`Agent(run_in_background)` 路線需要 flow agent 用 Monitor 跟事件，而非 sleep 輪詢；改寫時要確保依賴尚未滿足的 phase 不被誤啟動
- **README / docs drift**：commands 形式上線後，README 「方式 A / 方式 B」段落、強制規則段、所有範例都要同步——這是 verify 階段要捕捉的次要 regression
- **plugin.json 鏈結驗證**：補欄位後要實際 `claude plugin list` 確認 plugin 仍能載入，避免 schema typo 讓整個 plugin 失效
