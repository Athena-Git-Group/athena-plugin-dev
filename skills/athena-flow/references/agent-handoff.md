# Agent Handoff Contract

**本檔是所有 handoff 模板的唯一來源**：機械契約 + Base 模板 + Mini-handoff 模板 + 變體差異表。
其他 references 與 team skills 只放指標或標題級骨架，不得再抄模板全文。

原則：agent 之間不共享上下文，一切靠 handoff 檔案交接。

> **機械契約紅線（hooks/scripts 依賴，違反即壞 commit / 狀態渲染）**：
> `## Gate Verdict` 標題必須行首逐字；verdict 必須**緊貼標題下一行**（不可先空行）；
> H1 以 `# Handoff` 起頭時**檔案第 3 行**（H1 → 空行 → 一行摘要）被取為 commit desc；
> mini-handoff 的 H1 是 `# Phase Handoff:`，**刻意**不匹配 `^# Handoff`，勿「順手統一」。
> awk/grep 依賴細表見檔尾「附錄——機械契約細表（改模板時才讀）」。

## Handoff 路徑

`handoffs/<slug>-spec.md` / `-plan.md` / `-build.md` / `-verify.md` / `-review.md` /
`-ship.md` / `-review-ship.md`（Lightweight 合併）/ `-build-phase-<NN>.md`（Full build 內部）。

> **例外**：point stage 的輸出在 `points/<slug>.md`（由 plugin 內建的 athena-point 控制）。

## Base 模板（Standard 六欄）

```markdown
# Handoff: <stage-name>

<一行摘要——H1 後隔一空行的第 3 行，auto-commit.sh 取此行為 commit desc>

## Stage
<stage 名稱>

## Inputs Used
<讀取了哪些前置 artifact>

## Artifacts Produced
<產出的檔案路徑>

## Gate Verdict
<PASS / FAIL — 一句話原因 [#taxonomy-tag]>（本行緊貼標題，不可先空行）

## Risks / Unresolved Issues
<未解決的風險或問題；無則 None>

## Next Recommended Stage
<建議的下一個 stage>
```

## Gate Verdict 與 Failure Taxonomy

格式：`<PASS / FAIL> — <一句話原因> [#<taxonomy-tag>]`

- **PASS**：不帶 tag。
- **FAIL**：**必須**附一個 failure taxonomy tag（enum 見 `run-trace.md` 的 Failure Taxonomy 段），
  供 emit-trace 彙整進 Run Trace 的 `failures[]`。多個獨立問題列多筆 issue、各帶自己的 tag。
- **向後相容**：tag 是 additive——舊 handoff 缺 tag 時 emit-trace 以 `#unclassified` 補登，不打斷 run。

範例（Full verify FAIL，issue 帶 `verify-retry.md` 的 affected_phase 前綴）：

```markdown
## Gate Verdict
FAIL — frontend 呼叫 /api/approval 但後端是 /api/approvals (plural) #integration-mismatch

## Issues Found
1. **[Phase 06]** frontend calls `/api/approval` instead of `/api/approvals` #integration-mismatch
```

## 變體差異表

各變體 = Base 模板 + 下表增刪。`−` 為刪除欄位、`+` 為新增欄位；未列即同 base。

| 變體 | H1 字樣 | 檔案 | 相對 base 增刪 |
|------|---------|------|----------------|
| Spec | `# Handoff: spec` | `<slug>-spec.md` | = base |
| Plan | `# Handoff: plan` | `<slug>-plan.md` | +`## Phase 列表`（Phase/Name/Depends On/Touches/可平行於 表）、+`## Validator Result`（指令、exit code、實際輸出）；Next = pre-build |
| Build 合成（Full；flow 寫，非 agent 寫） | `# Handoff: build` | `<slug>-build.md` | +`## Phase Summary`（Phase/Gate/Commit 表，置於 Inputs Used 後）；+`## Synthesis Note`（列來源 mini-handoff 清單＋「flow 彙整，未經獨立驗證」聲明；置於 Risks 前）；Artifacts = 合併各 mini-handoff 的 Files Changed；Risks = 合併各 phase 的 Spec Deviations 與 Notes |
| Compact build（Lightweight） | `# Handoff: build (lightweight)` | `<slug>-build.md` | −`## Stage`、−`## Inputs Used`、−`## Artifacts Produced`、−`## Next Recommended Stage`；+`## Files Changed`（new/modified 標注）、+`## Smoke Test Result`（command: result） |
| Minimal build（PASS-TRIVIAL） | `# Handoff: build (minimal)` | `<slug>-build.md` | 同 Compact build，另 +`## Self-Review`（Scope within point-report / New dependencies / Security concerns 三行） |
| Verify Full | `# Handoff: verify` | `<slug>-verify.md` | +`## Checks Performed`；FAIL 時必要：+`## Issues Found`（每條以 `**[Phase NN]**` 前綴標 affected phase）、+`## Affected Phases`（phase → issue 數彙整）；Next = review 或 re-build (targeted) |
| Verify Lightweight | `# Handoff: verify (lightweight)` | `<slug>-verify.md` | +`## Checks Performed`、+`## Issues Found`（**無** `[Phase NN]` 前綴）；**無** `## Affected Phases`；Next = review-ship |
| Review | `# Handoff: review` | `<slug>-review.md` | = base（審查意見寫本文與 Risks） |
| Review-ship（Lightweight 合併） | `# Handoff: review-ship` | `<slug>-review-ship.md` | 欄位序固定：`## Review Verdict` → `## Review Notes`（選）→ `## Ship Result`（Pushed / Merged / Merge commit）→ `## Commits Shipped`（Hash/Message 表）→ `## Gate Verdict`（置末）；base 六欄僅留 Gate Verdict |
| Ship（Full） | `# Handoff: ship` | `<slug>-ship.md` | −`## Artifacts Produced`；+`## Push Result`（Branch/Remote/Status）、+`## Merge Result`（Target/Method/Status/Merge commit）、+`## Commits Shipped`（Hash/Stage/Message 表）；Next = (end of flow) |

## Mini-Handoff（Build phase 之間，僅 Full Weight）

路徑：`handoffs/<slug>-build-phase-<NN>.md`（例：`approval-workflow-build-phase-05.md`）

```markdown
# Phase Handoff: Phase <NN> — <Phase Name>

## Phase
<phase 編號與名稱>

## Inputs Used
- plans/<slug>/doing/<NN>-<name>.md
- handoffs/<slug>-build-phase-<prev-NN>.md（若有）
- spec Section <X>, <Y>

## Files Changed
- src/api/approval.rs (new)

## Spec Deviations
[偏離 spec 時記錄內容與原因；無則寫「None」]

## Smoke Test Result
- <test command>: <result summary>

## Gate Verdict
<PASS / FAIL + 原因>

## Worktree Branch
- Worktree Branch: <選填，僅 worktree 隔離模式>

## Timing
- Started At: <ISO-8601 UTC，選填>
- Ended At: <ISO-8601 UTC，選填>

## Notes for Next Phase
[下一個 phase agent 需要的資訊，如實際 API path、schema 細節]
```

| 欄位 | 必要性 | 說明 |
|------|--------|------|
| Phase / Inputs Used / Files Changed | 必要 | 識別與可追溯性 |
| Spec Deviations | 必要 | 防止下游在錯誤基礎上繼續 |
| Smoke Test Result / Gate Verdict | 必要 | Gate 判定依據，flow 讀此決定是否繼續 |
| Worktree Branch | 選填 | 僅平行 worktree 隔離模式：phase agent 無論 gate 結果都 commit 到 worktree 分支（PASS 正常格式、FAIL 用 `wip:` 前綴）後回報所在分支，值 = `git branch --show-current` 實測（不准猜命名）；mini-handoff 本身寫在**主樹**的 `handoffs/`；flow merge-back（`git merge --no-ff`）讀此欄位且**只 merge latest gate = PASS 的分支**，協議見 `phase-orchestration.md`「Worktree 隔離」 |
| Timing | 選填 | 見下方 Timing 段 |
| Notes for Next Phase | 選填 | 跨 phase 的實作細節傳遞 |

所有 phase 完成後，flow 合成最終 `handoffs/<slug>-build.md`（見變體差異表「Build 合成」列）。

## Metrics 區塊（選填，所有 handoff 通用）

standard / compact / mini-handoff 皆可附至多一個 `## Metrics` 區塊——**單一 JSON 物件、
value 皆為數字**，emit-trace 解析後填入 trace 的 `stages[].metrics`（schema 見 `run-trace.md`）：

````markdown
## Metrics
```json
{"coverage": 0.82, "lint_warnings": 0}
```
````

沒有客觀數字就整段省略；非數字描述放 handoff 本文。解析失敗由 emit-trace 安靜降級，不影響 gate。

## Timing 區塊（選填，所有 handoff 通用）

```markdown
## Timing
- Started At: 2026-08-05T14:02:11Z
- Ended At: 2026-08-05T14:18:47Z
```

agent 開工第一步與寫 handoff 前各取一次 `date -u +%Y-%m-%dT%H:%M:%SZ`。emit-trace 填入
`stages[].started_at/ended_at`（stage handoff）或 `phases[].started_at/ended_at`（mini-handoff）。
選填、additive、缺就缺；解析失敗安靜降級。

## 各路由的 Handoff 檔案數量

| 路由 | Handoff 檔案 | 總數 |
|------|-------------|------|
| `PASS-TRIVIAL` | point + build(minimal) | **2** |
| `PASS-DIRECT-BUILD` | point + build + review-ship | **3** |
| `PASS-BUILD-WITH-VERIFY` | point + build + verify + review-ship | **4** |
| `PASS-SPEC-FIRST` | point + spec + plan + N × mini-handoff + build(合成) + verify + review + ship | **7+N** |

- **Minimal（PASS-TRIVIAL）**：不產出 review-ship handoff——build handoff 的 `## Self-Review`
  取代獨立 review，flow 在 build + commit 後直接結束。
- **Lightweight**：無 phase loop、無 mini-handoff，build agent 直接寫 build handoff；
  review + ship 由同一 agent 合併為 `<slug>-review-ship.md`。

## 非協商規則

1. **每個 stage 必須由全新的 agent 執行**——不得讓同一個 agent 處理多個 stage，避免 context window 過大與推理污染
2. **每個 build phase 必須由全新的 agent 執行**——phase 之間不共享 context（僅 Full Weight）
3. 下一個 agent 先讀 handoff artifact（或 mini-handoff），再開始工作
4. 不得從對話脈絡取得前一 stage 或前一 phase 的資訊——一切靠 artifact 檔案
5. 每個 stage 結束時必須寫入完整的 handoff artifact，不可省略
6. 每個 build phase 結束時必須寫入 mini-handoff，不可省略（僅 Full Weight）
7. **Lightweight 路由的 review-ship 可合併為一個 agent**——這是唯一允許同一 agent 處理多個 stage 的例外
8. **Minimal 路由不產出 review-ship handoff**——build handoff 的 self-review 段落取代獨立 review
9. **FAIL 的 gate verdict 必須帶 failure taxonomy tag**——enum 見 `run-trace.md`；缺 tag 時由 emit-trace 以 `#unclassified` 補登，不打斷流程

---

## 附錄——機械契約細表（改模板時才讀）

以下字面格式被兩個程式依賴——任何模板調整都不得破壞：

### `hooks/auto-commit.sh`

| 依賴 | 字面約定 |
|------|---------|
| verdict 存在檢查 | `grep -qE '^## Gate Verdict'`——標題必須是行首逐字 `## Gate Verdict` |
| verdict 萃取 | `awk '/^## Gate Verdict/{getline; print; exit}'`——**標題的下一行必須就是 verdict 本身**（中間不可有空行），以 `PASS` 開頭才 commit |
| commit desc 萃取 | `awk '/^# Handoff/{getline; getline; print; exit}'`——H1 以 `# Handoff` 起頭時，**H1 → 空行 → 一行摘要**（即檔案第 3 行）被取為 commit description（前 60 字元） |

> mini-handoff 的 H1 是 `# Phase Handoff:`，刻意不匹配 `^# Handoff`——desc 走 fallback
> （`<stage> changes`）。這是既有行為，勿「順手統一」H1 字樣。

### `scripts/render_status.py`

| 依賴 | 字面約定 |
|------|---------|
| 檔名 glob | `handoffs/<slug>-<stage>.md`（stage 名 = 檔名截去 `<slug>-` 前綴與 `.md`）；phase 級為 `handoffs/<slug>-build-phase-<NN>.md` |
| verdict 解析 | `## Gate Verdict` 標題後第一個非空行，以 PASS / FAIL 前綴判定（寬鬆解析，缺失顯示 unknown） |
