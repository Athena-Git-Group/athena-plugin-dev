# Worktree Isolation

## 讀取時機

**事件驅動**（Full Weight）：worktree spawn 本身只需讀 `templates/worktree-injection.md`
（注入段全文在該檔）；本檔全檔只在下列事件發生時才讀——**PRE-FLIGHT MISMATCH 回報抵達**、
**fallback 降級**、**merge-back 收斂**、**crash 清理／phase loop 開工前 prune**。
序列 phase / 主樹模式與 verify-fix 修復不適用本檔（判準見 D-0 表）。
Phase loop 本體與 Conflict Detection 見 `phase-orchestration.md`；本檔只管「agent 被送進 worktree」的隔離協議。

---

## 隔離模式與適用範圍（D-0）

Full Weight 且可平行集合大小 **≥ 2** 時，flow spawn phase agent **一律**帶 Agent 工具的
`isolation: "worktree"` 選項——每個 phase agent 得到獨立 git worktree（物理隔離），
未變更的 worktree 由 harness 自動清除。序列 phase（平行集大小 1）**不用** worktree。

**D-0 判準**：**這個 agent 有沒有被送進 worktree**，**不是**它是第幾次被 spawn：

| 情境 | 是否套用 | 依據 |
|------|---------|------|
| 平行集 ≥ 2 的首次 spawn（原生 `isolation: "worktree"`／手動 worktree fallback 協議） | **套用** | agent 在 worktree 內，不符時可沿 fallback 鏈退 |
| **續作 spawn**：`phase-orchestration.md`「Phase Retry」的 worktree retry（`git worktree add … <既有分支>`）——**掛回既有分支的續作只有這一種** | **套用** | 同樣在 worktree 內；且這是**最脆弱**的建立方式（殘留路徑衝突／`add` 失敗都會讓 agent 留在主樹） |
| 序列 phase / 主樹模式，**以及 verify-fix 的 per-phase 修復**（它一律在主樹，見下方專段） | **不套用** | 沒有「跑錯 worktree」這個失效模式，且不符時無處可退 |

續作 spawn 的健檢比首次**更容易**判定，不存在「retry 時無法判定」：worktree 與分支都是
flow 自己掛的，分支名必然已知（= 上一輪 mini-handoff 的 `Worktree Branch:`）→ 續作
prompt **必須**同時注入 `Main Tree Branch:` 與 `Expected Branch:`（= 掛回的既有分支），
檢查 1 走「必須**等於**」加嚴路徑。

### verify-fix 的 per-phase 修復：一律在主樹（D-0 第 3 列，不套用本檔）

時序推出的唯一可行位置，四條理由各一句：

1. **原分支已不存在**——verify 只在 merge-back（`git merge --no-ff` + `git branch -d`）之後才跑，對已刪分支 `git worktree add` 必得 `fatal: invalid reference`。
2. **也不需要掛回**——`-d` 刪得掉的前提是已 merge，該 phase 的 commit 主樹全看得到。
3. **只有主樹看得到要修的東西**——verify 抓的是跨 phase 整合問題，只存在於全部合入後的 flow 分支上。
4. **多個 phase 同時修也不互撞**——`verify-retry.md` 要求按依賴順序逐一修復，同時只有一個修復 agent；**不得**為 verify-fix 開平行 worktree。

因此 verify-fix 修復 agent：**不注入** `Main Tree Branch:` / `Expected Branch:`、**不跑**
pre-flight（agent 殼據「沒收到基準 = 主樹模式」正確推論）、commit 由 flow 依既有
post-build（`triggering_stage: verify-fix-phase-<NN>`）執行——全部沿用 `verify-retry.md`。
（若未來要送它進 worktree：唯一正確做法是從 flow 分支 `-b` **新建**、照 merge-back 合回，
不是掛回既有 phase 分支——此時 `Expected Branch:` 仍必然已知，本檔照常套用。）

## 注入義務（flow 端）

只要 agent 被送進 worktree（首次或續作），flow 就**必須**注入比對基準；「沒收到
`Main Tree Branch`」對 agent 即正確地等於「主樹模式，本檔不套用」
（`agents/athena-stage-build.md` 的鏡射依賴此推論）。漏注入是 **flow 的缺陷**——
agent 照主樹模式執行即可，不自行補救。

spawn 時在 Agent Prompt（模板見 `templates/prompt-phase-agent.md`）末尾附加
`templates/worktree-injection.md` 的注入段全文（逐字，含 pre-flight 三項健檢、
`PRE-FLIGHT MISMATCH` 固定回報格式、雙路徑規則、收尾 commit 義務；spawn 那一刻才讀該檔）。

## Pre-Flight 健檢（開工義務，agent 端判準）

一句動機：隔離假設破裂（agent 其實在主樹、錯分支、讀不到注入路徑）**不報錯**、
只在稍後顯現，所以開工第二步必查。三項判準（鏡射於 `agents/athena-stage-build.md`）：

| # | 檢查 | 指令 | 通過條件 |
|---|------|------|---------|
| 1 | **分支** | `git branch --show-current` | 輸出**非空** **且** ≠ flow 注入的 `Main Tree Branch`。flow 另注入 `Expected Branch` 時（**只要 flow 自己指定了分支名就會有**：手動協議下是 flow 用 `-b` 命名的新分支、phase retry 續作則是掛回的那個既有分支，兩者名稱都確切已知；原生模式下分支名由 harness 決定，沒有這一項）→ 加嚴為**必須等於**它。空輸出（detached HEAD）視為**不通過**——merge-back 協議依賴分支名，無分支則整條路徑失效 |
| 2 | **cwd** | `pwd` | 輸出 ≠ flow 注入的 `<main-repo-root>`（確認自己不在主樹） |
| 3 | **目標檔案存在** | Read 兩類路徑各至少一項 | (a) **主樹 artifact**：注入的 phase card 絕對路徑可讀；(b) **worktree code**：phase card `touches.files` 中已存在於基線的檔案任取一項可讀。該 phase 全為新建檔案時，此項自動視為通過並在自報中註明 `n/a (all-new)` |

檢查 1 通用條件是「≠ 主樹分支」而非「= 預期分支」，一句理由：原生模式分支名由
harness 決定、flow 不知道，通用條件只能建立在 flow 一定知道的自己分支（`branch_name`）上。
通過／不通過的處置（自報行、`PRE-FLIGHT MISMATCH` 固定格式、不得自己修復）見 `templates/worktree-injection.md` 注入段。

不寫 mini-handoff 的兩個機械理由各一句：(1) `hooks/auto-commit.sh` 沒 handoff 就
no-op，不可能誤 commit；(2) `scripts/render_status.py` 會把 FAIL verdict 染紅成
「這個 phase 做壞了」——語意誤報且不報錯。因此 final response 的 `PRE-FLIGHT MISMATCH`
行**本身**就是 flow 可機械分辨的**正向**訊號，不靠「mini-handoff 不存在」推論，
也不需要在 `agent-handoff.md` 新增欄位。

**續作情境的唯一處置差異**：續作 agent 的 mini-handoff 上一輪已在磁碟上——不符時
**也不得更新它**（原樣留著，它記的是上一輪真實結果），只回 `PRE-FLIGHT MISMATCH`；
flow 看到的仍是「舊 verdict + 新正向訊號」，與分辨表第 1 列一致。

## flow 收到訊號後的行為（mismatch 分辨表）

分辨主鍵是**正向訊號**（某字串出現了），**不是**「某檔案不存在」。**依序**比對，先命中者為準：

| # | 訊號（正向可偵測） | 判定 | 路徑 |
|---|------|------|------|
| 1 | final response **以上面那行固定格式回報 `PRE-FLIGHT MISMATCH` 並就此結束**——**不論 mini-handoff 是否存在** | **isolation-setup failure**（無新產出，**不是 gate 事件**） | 既有 **fallback 階梯**（見下方）：降級後重新 spawn |
| 2 | **沒有** `PRE-FLIGHT MISMATCH`，但**有** mini-handoff 且 `Gate Verdict: FAIL` | gate 失敗（有產出可修） | 既有 Phase Retry（`phase-orchestration.md`），最多 2 輪 |
| 3 | 兩者皆無（無 `PRE-FLIGHT MISMATCH`，且無 mini-handoff 或 mini-handoff 沒有 `## Gate Verdict`） | 狀態未知，**不得**逕自判定 | 走 `intervention-protocol.md` 的查證階梯；查不到就問使用者 |

- 第 1 列**不得**加「無 mini-handoff」條件，一句理由：mini-handoff 從不在重試之間被刪
  （續作與 verify-fix 都是「讀→更新」，唯一刪除點是 run 收尾 GC）——加了該條件，續作
  情境第 1 列永遠不命中，mismatch 被誤路由成 gate 失敗、燒掉 retry 額度、fallback 階梯
  成死碼。**缺席推論在 re-spawn 情境不可靠——一律以正向訊號為主鍵。**
- 反向誤判防線：第 1 列認的是**固定格式回報行且 agent 就此結束**——mini-handoff 或
  final response 中**引述**該字串不算訊號；判不出是回報還是引述 → 落第 3 列走查證階梯，不得猜。
- pre-flight 不符**不是 gate 事件**：無 gate verdict、不進 `failures[]`、不給
  taxonomy tag、**不計入** phase retry 的 2 輪額度（兩條路徑各自獨立）。

## Fallback 階梯（降級）

**同一 fallback 層級最多重試 1 次**，仍回報 mismatch → 降下一級。兩種 spawn 的階梯終點不同：

| spawn 種類 | 降級階梯 | 最後一級的終止動作 |
|-----------|---------|------------------|
| **首次 spawn**（平行集 ≥ 2） | 原生 `isolation: "worktree"` → 手動 worktree 協議 → **shared-tree**（終點） | shared-tree 是**必然收斂**的終點：該級 flow 不注入比對基準 → 依 D-0 第 3 列 agent 不跑健檢 → **結構上不可能再回報 mismatch**。此時該平行集改以 **shared-tree 模式**執行——**仍是平行 spawn**（照舊寫 `parallel_phases`、依「執行模式」共同要求（`phase-orchestration.md`）於同一次回應送出全部可平行 phase），序列化的**只有 commit**（由 flow 層在全部收斂後依序執行）；touches 事前分區 + 兩層 conflict detection 照跑。定義見下方「Fallback 鏈」第 2 項，此處不另立語意。這是**降級成功、不是失敗**，phase loop 繼續 |
| **續作 spawn**（phase retry 掛回既有分支） | 手動 worktree 協議（**起點即此級**——續作本來就用它）→ **不再降級**（終點） | 同級重試 1 次仍回報 mismatch → **停止該 phase 的續作**，依 `intervention-protocol.md` C-4 把三項完整狀態交使用者拍板（其餘不受影響的 phase 照常繼續）。**不得降到 shared-tree**，理由見下 |

- 續作不得降到 shared-tree，一句理由：要接手的工作只在那個 latest gate = FAIL、絕不
  merge 也絕不自動刪的分支上，主樹沒有那些 commit——shared-tree 的 repair agent 看不到
  上一輪成果，只能重做或誤診（首次 spawn 無此問題：還沒有已完成工作要接手）。
- 續作命中第 1 列時，同級那 1 次重試重新 spawn 的是「**同一次續作**」——仍掛回既有分支、
  依 `intervention-protocol.md` C-7「已有 commit 代表已完成的工作，不重做」；
  該 phase 已用掉的 retry 輪數也不因此改變（pre-flight 不符不計入）。

## 收尾義務（phase agent 在 worktree 內）

1. **無論 gate 結果都要 commit 到 worktree 分支**——分支永遠承載最新狀態：
   - gate PASS → 正常 commit（git-conventions 格式、帶 phase 編號，同 post-build 的 per-phase commit 格式）
   - gate FAIL → **`wip:` 前綴** commit（如 `wip: phase-05 smoke test failing`），
     供 repair agent 掛回續作；**latest gate = FAIL 的分支絕不 merge**
2. mini-handoff 寫入選填欄位 `Worktree Branch:`——值**必須**是 `git branch --show-current`
   的實測輸出，**不准猜命名**（欄位定義見 `agent-handoff.md`）；mini-handoff 寫進**主樹**的 `handoffs/`

## 雙路徑規則（artifact 交接，非協商）

worktree 只隔離 **code**；`handoffs/`、`plans/`、`specs/`、`points/` 是 gitignored 的
runtime artifact，只帶 tracked 檔案的 worktree 裡不會出現它們，因此：

- flow spawn 時 prompt **必須注入主樹絕對路徑**（`<main-repo-root>`）
- **code 讀寫** → worktree cwd 的相對路徑；**artifact 讀寫** → 主樹絕對路徑
- mini-handoff（含 `Worktree Branch:`）直接寫進主樹 `handoffs/`——flow 照常讀，
  原生模式下 flow 因此**不需要**知道 worktree 的實際路徑

## 與 auto-commit hook 的互動（行為差異，明確寫死）

- 主樹的 `.athena/.flow-context.json` marker **照寫** `parallel_phases`（保險——不給 hook 任何在主樹誤 commit 的機會）
- worktree 內**沒有**該 marker（untracked 檔案不跟隨 worktree），hook 在 worktree 內自然
  no-op——**phase commit 由 phase agent 自己做**（契約見 `flow-context.md`「並行 phase 行為」）

## Merge-back 協議（flow 在主樹執行）

全部平行 phase gate PASS **且**兩層 conflict detection（見 `phase-orchestration.md`）通過後：

1. 按拓撲序對各 mini-handoff 回報的 `Worktree Branch:` 執行 `git merge --no-ff <branch>`
   ——**僅限 latest gate = PASS 的分支**；latest gate = FAIL 的分支絕不 merge
2. touches 互斥下文字衝突**理應不發生**——若出現 merge conflict，這是**第三層安全網**：
   立即停止、**不嘗試自動解衝突**、交給使用者（依情況歸類 `#ownership` 或 `#plan-gap`）
3. 每個分支 merge 成功後 `git branch -d <branch>`（**`-d` 不是 `-D`**——git 保證已 merge 才刪得掉）

worktree 模式下，per-phase commit 已由 phase agent 在 worktree 分支完成；主樹的整合點
是 merge commit——flow **不再**對這些平行 phase 執行 post-build commit。

**三層安全網（層次定位）**：

| 層 | 檢查 | 執行點 |
|----|------|--------|
| 第一層 | Ownership Violation（對照各 phase 自己的 touches 宣告） | Conflict Detection（`phase-orchestration.md`） |
| 第二層 | 跨 Phase Files Changed 重疊比對 | Conflict Detection（`phase-orchestration.md`） |
| 第三層 | merge conflict（物理層，git 自己驗） | Merge-back（本檔） |

## Fallback 鏈（隔離手段不可用時）

1. **`isolation: "worktree"` 選項不可用** → 手動協議：flow 對每個平行 phase 執行
   `git worktree add .athena/worktrees/<slug>-<NN> -b athena/phase/<slug>-<NN>`，
   phase agent prompt 指明工作目錄為該 worktree 路徑，並照樣注入主樹絕對路徑
   （雙路徑規則不變）；其餘義務（worktree 分支 commit、`Worktree Branch:` 回報、
   merge-back）同上。收尾時 flow 對每個已 merge 的 worktree 執行
   `git worktree remove <path>` + `git worktree prune`。
2. **連 worktree 都不可用**（非 git 環境或其他限制）→ 現行 **shared-tree 模式**：
   touches 事前分區 + 兩層 conflict detection，並照舊寫 `parallel_phases` 進
   flow-context；commit 由 flow 層在全部收斂後依序執行（即 `phase-orchestration.md` 描述的原行為）。

## Crash 安全（非協商）

- flow 進入 phase loop **前**先執行 `git worktree prune`（清掉 crash 殘留的 worktree 註冊）
- GC 只刪**已 merge** 的 `athena/phase/` 分支（`git branch -d` 天然保證）
- **絕不自動刪未 merge 的分支**——殘留的未 merge 分支列給使用者決定去留

## 非協商規則（worktree 專屬）

1. **平行集 ≥ 2 一律 worktree 隔離** — spawn 帶 `isolation: "worktree"`；不可用時依序 fallback：手動 worktree 協議（`.athena/worktrees/` + `athena/phase/` 分支）→ shared-tree。序列 phase（平行集大小 1）不用 worktree
2. **Merge conflict 是第三層安全網** — merge-back（`git merge --no-ff`）遇衝突立即停止、不自動解衝突、交給使用者（`#ownership` 或 `#plan-gap`）
3. **只用 `git branch -d`，不用 `-D`** — 只刪已 merge 的 `athena/phase/` 分支；**絕不自動刪未 merge 的分支**，殘留分支列給使用者決定
4. **phase loop 開始前 `git worktree prune`** — 先清 crash 殘留的 worktree 註冊再開工
5. **Worktree 分支無論 gate 結果都 commit** — PASS 用正常格式、FAIL 用 `wip:` 前綴，分支永遠承載最新狀態；**latest gate = FAIL 的分支絕不 merge**
6. **Artifact 一律走主樹絕對路徑** — worktree 只隔離 code；`handoffs/`、`plans/`、`specs/`、`points/` 的讀寫用 flow 注入的 `<main-repo-root>` 絕對路徑（雙路徑規則）
7. **Worktree 模式下游不提早觸發** — 下游 phase 等所屬上游平行集全部 merge-back 完成後才 spawn，不做 partial merge
