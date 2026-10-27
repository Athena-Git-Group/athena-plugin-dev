# Rule 1 - 逐項列舉式引用必須同步；指標式引用不必

- Level: `MUST`
- 先定義兩個術語：
  - **逐項列舉式引用**：消費檔案把來源的 enum 值、欄位或規則**一條一條抄出來**（例如一張逐 tag 的對照表）。來源多了一項，這份清單就少一項——所以**必須**列為「需要同步」的消費者。
  - **指標式引用**：消費檔案只寫「詳見 X」「enum 見 X 的某段」，內容仍以來源為準。改了來源它自動跟上——**不需要**同步。
- 判定結果（同步／不同步＋理由）必須寫進 `contract-surface.md` 的消費者判定表。

## Good Example

- 這個例子是好的，因為它依引用形式分別判定，並寫明理由。

```md
| 檔案:行號 | 引用形式 | 需要同步？ | 理由 |
|-----------|---------|-----------|------|
| `skills/hill-climb/SKILL.md:84` | 逐項列舉（逐 tag 表列出全部 tag） | **是** | 新 tag 不加這列，統計得到卻沒有對應項 |
| `skills/team-build/SKILL.md:38` | 指標引用（「enum 見 run-trace.md」） | 否 | 指向來源，來源改了就跟著對 |
```

## Bad Example

- 這個例子是壞的，因為它把所有提到來源檔名的地方一律當成要同步（或一律當成不用同步），沒有看引用形式。

```md
grep 到 5 個檔案提到 run-trace.md，全部標「需要同步」，理由統一寫「有引用」。
```

# Rule 2 - 契約面盤點每列都要有真實 grep 輸出

- Level: `MUST`
- 消費者清單必須來自**實跑的 grep**：指令與實際輸出都貼進 `contract-surface.md`，不得省略、不得虛構。
- point-report 列的消費者清單是起點不是終點——必須自己再 grep 一次。
- 不得憑印象或記憶列消費者。

## Good Example

- 這個例子是好的，因為指令與輸出俱在，可被任何人重跑驗證。

````md
指令：
```bash
grep -rn "#integration-mismatch" skills/ agents/ hooks/ scripts/ .athena/skills/
```
實際輸出：
```
skills/athena-flow/references/run-trace.md:88:- #integration-mismatch — ...
.athena/skills/team-common/rules/fail-reporting.md:33:- ... #integration-mismatch ...
```
````

## Bad Example

- 這個例子是壞的，因為消費者清單是「想起來的」，沒有任何可驗證的輸出。

```md
消費者：大概就 run-trace.md 和 hill-climb 那邊，印象中沒有別的。
```

# Rule 3 - 跨語言消費者一律標「壞掉時會不會報錯」

- Level: `MUST`
- 跨語言消費者指 bash / python 等程式碼對契約內容的消費點（例如 `jq` 取欄位、awk 抓標題）。
- 每個跨語言消費點都要在盤點表標注「壞掉時會不會報錯」。
- **不報錯的是最高風險**（靜默行為錯誤），必須在 `acceptance.md` 有對應的機械驗收項。

## Good Example

- 這個例子是好的，因為它標出靜默失敗點並連到機械驗收。

```md
| 檔案:行號 | 語言 | 消費方式 | 壞掉時會不會報錯 |
|-----------|------|---------|-----------------|
| `hooks/auto-commit.sh:69` | bash | `jq -r '.parallel_phases // 0'` | **不會**——靜默行為錯誤 |

acceptance.md 機械驗收 #3：實跑 auto-commit.sh 冒煙，確認 commit message 含描述。
```

## Bad Example

- 這個例子是壞的，因為它列了跨語言消費點卻不評估失敗可見性。

```md
hooks/auto-commit.sh 也有用到這個欄位，應該沒事，先不管。
```

# Rule 4 - 「agent 實際會讀哪一份」優先於「文件寫在哪一份」

- Level: `MUST`
- 契約寫進 reference 檔，但 agent 執行時實際讀的殼（`agents/*.md`）沒鏡射，等於沒寫。
- 盤點時兩邊都要列：規則的文件位置＋agent 實際載入的檔案。

## Good Example

- 這個例子是好的，因為它同時盤出文件位置與 agent 實際讀取點。

```md
規則落點：skills/athena-flow/references/phase-orchestration.md（文件）
消費者：agents/athena-stage-build.md（build agent 實際讀的殼）→ 必須鏡射，列入同步清單。
```

## Bad Example

- 這個例子是壞的，因為它以為寫進 reference 就生效了。

```md
規則已寫進 phase-orchestration.md，build agent 自然會遵守，不用動 agents/。
```
