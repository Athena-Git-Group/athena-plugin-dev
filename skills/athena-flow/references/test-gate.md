# Test Gate（TDD 分類與紅綠契約）

**本檔是「哪些變更適用 TDD、`tdd` 模式怎麼跑測試」的唯一真源**：變更集分類函數、
weight 適用表、紅綠流程契約、缺失處置。其他 references／templates／agents 殼與
團隊 skill 對這些規則一律指標引用本檔，不得再抄規則全文
（遵循 `agent-handoff.md` 的「唯一來源」模式）。

## 變更集分類函數

**純函數**：輸入 = 檔案路徑清單，輸出 = `tdd` | `smoke-only`。
分類是檔案清單上的純函數，任何 agent 重算必得同一結果——這就是「可機械判定」。

### code 類副檔名表（plugin 預設）

`.sh .bash .py .js .mjs .cjs .ts .tsx .jsx .vue .svelte .rs .go .java .kt .kts .rb .php .c .h .cc .cpp .hpp .cs .swift .scala .sql`

### 判定規則

- 變更集中**任一**檔案的副檔名命中 code 類表 → `tdd`
- **否則**（純 markdown／文件／config／資料檔）→ `smoke-only`（降級，維持現行 smoke test）
- **混合變更優先序：code > doc**——混合變更整體判 `tdd`（fail-closed 朝 TDD）；
  紅綠流程只要求覆蓋 code 類檔案的行為，doc 部分照常跑 smoke 檢查
- **團隊覆寫**：team build skill 可在其 SKILL.md 宣告自己的 code 類表
  （宣告即**取代**預設表）；未宣告則用本檔預設表

### 判定時點與輸入來源（三個 weight 都有機械輸入）

| Weight | 判定者 | 輸入 |
|--------|--------|------|
| Full | plan agent（寫卡時） | phase card `Touches.files` glob 清單 |
| Minimal / Lightweight | build agent（開工列檔清單時） | 預計變更檔案清單 |
| verify（重算查核） | verify agent | `git diff --name-only <base>...HEAD` |

- verify 的重算結果與 build 宣稱不一致 → verify FAIL `#contract-violation`
- Minimal / Lightweight 的 build agent 實作中發現實際變更清單超出開工清單
  （例如多改了一個 code 類檔案）→ **必須重判分類**；Lightweight 重判升級為
  `tdd` 時依下方紅綠契約補做（Minimal 豁免不受重判影響，見 weight 適用表）

## Weight 適用表

| Weight | TDD 適用性 | 理由 |
|--------|-----------|------|
| Minimal（PASS-TRIVIAL） | **豁免**——維持現行 smoke + self-review，不分類、不紅綠 | 低 overhead 初衷；且 Minimal 無 verify stage，測試存在性無人獨立驗收，強制了也 enforce 不了 |
| Lightweight（PASS-DIRECT-BUILD / PASS-BUILD-WITH-VERIFY） | 分類為 `tdd` 時適用 | BUILD-WITH-VERIFY 由 verify 驗收；DIRECT-BUILD 由 review-ship 的 review 檢查測試存在（弱 enforce，記入 handoff Risks；查核內容明文見 `stage-contracts.md` review-ship 段） |
| Full（PASS-SPEC-FIRST） | 分類為 `tdd` 的 phase **強制** | phase card `Test Mode: tdd`，verify 獨立驗收 |

## 紅綠流程契約（`tdd` 模式下 build agent 的行為）

1. 實作前：先寫（或修改）測試，執行 Test Command，**記錄紅**（預期失敗的輸出摘要）
2. 實作到通過：重新執行**同一個** Test Command，**記錄綠**
3. 兩次執行結果都寫入 handoff／mini-handoff 的測試結果欄位——**欄位名沿用現行、
   不新開欄位**；red/green 行的具體格式見 `agent-handoff.md` mini-handoff 段的
   tdd 寫法
4. 紅步驟**初跑即綠**（測試沒失敗過）：**不自動 FAIL**，但必須在 handoff 記錄原因
   （例：既有行為已滿足、測試為回歸保護）；verify 對此類記錄做合理性查證
5. `tests_written` / `tests_passed` 數字放 `## Metrics` JSON（選填；key 定義見
   `run-trace-extensions.md` 已知 key 詞彙表）

> **紅記錄不是 FAIL verdict**：紅是 build 過程的中間狀態，不產生 handoff verdict；
> gate 判定只看最終 handoff（綠後）。與 flow 非協商規則「Gate 沒過不 commit」同向——
> 紅階段不觸發任何 commit、retry 或回報。

> **retry / repair 時**：repair agent 重跑**同一個** Test Command 並更新 green 記錄；
> 原 red 記錄保留（紅已發生過，不重演紅步驟）。retry 指令來源分流見 `verify-retry.md`。

## 缺失處置

- `Test Mode: tdd` 但 phase card 無 `Test Command` → phase agent 停止，
  mini-handoff 記 gate FAIL + 原因 `#plan-gap`（與 touches 越界同款處置）——
  **不**落入「無 smoke test → PASS 預設」條款（該條款僅適用 smoke-only，
  分流見 `phase-orchestration.md` Gate 判定表與 `rules/回報協議與read-back綁定.md`
  「未驗證標示」）
- `smoke-only`（或未標 `Test Mode` 的舊卡）→ 行為與現行完全相同

## Gate 判定層級（Metrics 不參與）

gate 與 verify 的判定依據是 handoff 的**測試結果文字欄位**（欄位名與格式見
`agent-handoff.md`）與 `## Gate Verdict`；`## Metrics` 僅為 trace 觀測，
缺失不影響任何判定（`run-trace-extensions.md` 非協商條款：metrics 不參與任何 gate 判定）。
