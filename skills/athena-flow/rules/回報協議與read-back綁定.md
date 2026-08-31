# 回報協議與 read-back 綁定

> **啟動時必讀**（與 SKILL.md 同級的常駐控制面）。本檔是「怎麼對使用者講話」的
> 唯一細則來源；SKILL.md 只留控制資訊與讀取時機。向使用者回報是與 gate 串接
> 同級的職責，不是簿記的附屬品。

## 回報點（每個 stage / phase 交界恰好兩個）

| 回報點 | 時機 | 內容 |
|--------|------|------|
| **結束回報** | 讀 handoff、判 Gate Verdict 之後，**先於一切簿記**（post-build commit、mv doing→done、conflict detection 收尾、merge-back、emit trace、GC） | 兩層回報（見下） |
| **下一站預告** | 交界的**第一個動作**（先於 mv todo→doing 鎖卡、寫 marker、組 prompt、spawn） | 一行白話：接下來哪一站、大約要等多久、期間不需使用者行動 |

- subagent 執行中不新增進度回報——預告已交代預期等待。
- **run 收尾順序**：結束訊息（Minimal 的 ✅ Done、Full 的 ship 回報）**先輸出**，
  emit trace + Handoff GC 移到結束訊息之後執行（內部仍是先 emit 再 GC）。
- **交界回報不含當次 commit hash**——結束回報先於 post-build commit，該次 hash
  尚不存在；已有 commit 的時點（Minimal 結束輸出、ship 回報）如實引用。

## 兩層回報（結束回報的固定結構）

**第一層白話摘要在前**（2-4 句依序講：剛才發生什麼／現在狀態／需不需要使用者行動）、
**第二層機械欄位在後**，順序不可顛倒；只給機械欄位不合格。

### 第一層判準

| 判準 | 規則 |
|------|------|
| 長度／一句一意 | 2-4 句；每句只講一件事，不得用分號串句規避句數 |
| 術語 | 只用根目錄 `CONTEXT.md` 定義的詞（分支名、commit hash、slug 值可直用）；不轉述內部機制——只講狀況與是否需要使用者行動，機制細節使用者問起才展開 |
| 不重複／無 dump | 不得換句話重述機械欄位；不貼指令輸出、檔案內容、diff 或超過一行的引用 |

- 使用者表示看不懂或要求重講（re-pitch）時：停下重述——先補一句上下文，短句、
  一句一意，只用 `CONTEXT.md` 術語；重述只針對回報本身，不推進流程、不觸發
  gate/retry、不中止 agent。
- 請使用者拍板中止 agent 時順序固定：白話摘要 → 保全紀錄
  （`references/intervention-protocol.md` C-2 實際取到什麼）→ 機械欄位。

### 第二層機械欄位（原順序、原文字，不增不刪）

當前 stage／該 stage 的 skill 名稱與路徑（含是否 plugin 預設）／上一 stage 的
artifact 路徑／下一 stage／是否需要新 agent／Git context（branch_name、最近
commit hash 與 message）。

## read-back 欄位對映（成敗與數字的唯一事實來源）

回報中的**成敗字樣與一切數字必須機械複製自 handoff 欄位**。subagent 的 final
response 不得作為事實來源，只能觸發「去讀 handoff」。白話層只做包裝
（`CONTEXT.md` 術語翻譯），**不產生事實**。

| 回報內容 | 唯一來源 |
|----------|---------|
| 成敗字樣 | Gate Verdict 首行**原文照抄**為機械層第一欄；白話層的成敗表述由它翻譯 |
| 一切數字 | `## Metrics`／`## Smoke Test Result`／`## Files Changed` 條目——**handoff 沒有的數字不得出現在回報** |
| 「剛才發生什麼」 | handoff 一行摘要（H1 後第 3 行）＋ Artifacts Produced／Files Changed |
| 「現在狀態」 | Gate Verdict ＋ Risks / Unresolved Issues |
| 「需不需要使用者行動」 | flow 自身的路由決策（唯一由 orchestrator 產生的內容） |

## 未驗證標示

無 smoke test 定義時 gate 判定照舊（PASS 前綴保留、hook 照常 commit、流程語意不變），但：

- handoff／mini-handoff 的 **verdict 原因文字必須寫明「無 smoke test，未驗證」**
- **結束回報白話層必須含「未驗證」**——不得讓使用者把「沒有任何檢查」聽成「通過了」

## 合成 handoff 的如實聲明

flow 合成的 handoff（Full build 合成）必附 `## Synthesis Note`：列來源 mini-handoff
清單＋「flow 彙整，未經獨立驗證」聲明（additive，不動機械契約——欄位定義見
`references/agent-handoff.md` 變體差異表）。據合成 handoff 回報時，白話層必須
如實說明未經獨立驗證。

## 查證觸發義務（結論性回報前）

結論性回報的每個事實主張必須有 handoff 欄位佐證。無 handoff 可引用時，先走
查證階梯（artifact → git → harness，一次性查詢不輪詢；**階梯本體見
`references/intervention-protocol.md`**，此處只放觸發義務與指標）；查不到就照實
回報固定句式：「我無法查證 `<具體對象>` 的狀態；我查了 `<已執行的層>`，結果
`<實際輸出>`；請確認要不要 `<動作>`」。**不得猜一個狀態填進回報**。
