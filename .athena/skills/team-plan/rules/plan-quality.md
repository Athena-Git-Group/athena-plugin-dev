# Rule 1 - Dependency Graph 以 YAML frontmatter 為準

- Level: `MUST`
- `plans/<slug>/plan.md` 頂部的 YAML frontmatter 是 Dependency Graph 的機械依據（`validate_plan.py` 只解析它）；內文的 markdown 表格與 ASCII 圖是人類視圖，必須與 frontmatter 一致，衝突時以 frontmatter 為準（validator 會比對）。
- `id` 是兩位數字字串（`"01"`）；`depends_on` 只准引用存在的 `id`；`status_source: folders` 是固定值——phase 狀態的唯一真相是卡片所在資料夾。
- 正文必須保留「機械真相聲明」與「防過度串鏈」兩段警語，原文照抄自 `skills/athena-specformula/assets/plan-template.md`。

## Good Example

- 這個例子是好的，因為 id 格式、依賴引用與固定值都符合 schema。

```yaml
---
plan: add-tag
phases:
  - id: "01"
    name: taxonomy-enum
    depends_on: []
    touches:
      files: ["skills/athena-flow/references/**"]
status_source: folders
---
```

## Bad Example

- 這個例子是壞的，因為 id 不是兩位字串、depends_on 引用了不存在的 phase，且 status_source 被改掉。

```yaml
---
plan: add-tag
phases:
  - id: 1
    name: taxonomy-enum
    depends_on: ["03"]
status_source: table
---
```

# Rule 2 - 卡片的 Touches 與 frontmatter 一字不差

- Level: `MUST`
- 每張 phase 卡的 `Touches` 欄位必須與 frontmatter 該 phase 的 `touches` 一字不差。
- Why：卡片是給 phase agent 看的邊界宣告，frontmatter 是給 validator 看的——兩邊漂移＝agent 越界而 validator 沒攔到。flow 會把 touches 邊界注入 phase agent 的 prompt，越界即 gate FAIL `#plan-gap`。

## Good Example

- 這個例子是好的，因為卡片照抄 frontmatter 的宣告。

```md
frontmatter: files: ["hooks/**"], resources: ["lint-plugin-checks"]
卡片:       - **Touches:** files: hooks/** / resources: lint-plugin-checks
```

## Bad Example

- 這個例子是壞的，因為卡片比 frontmatter 多宣告了一個目錄，agent 會照卡片越界。

```md
frontmatter: files: ["hooks/**"]
卡片:       - **Touches:** files: hooks/**, scripts/** / resources: —
```

# Rule 3 - 必須建立空的 doing/ 與 done/（各放 .gitkeep）

- Level: `MUST`
- 除了 `todo/`（寫卡片時自動產生），必須建立 `plans/<slug>/doing/.gitkeep` 與 `plans/<slug>/done/.gitkeep`。
- Why：flow 在 spawn phase agent 前執行 `mv todo/<NN>-*.md doing/`（位置即狀態、mv 即鎖）；目標資料夾不存在，`mv` 失敗、phase loop 起不來，而 validator 容忍這兩個資料夾不存在，不會幫你抓到這個錯。

## Good Example

- 這個例子是好的，因為三個狀態資料夾齊備。

```text
plans/add-tag/todo/01-taxonomy-enum.md
plans/add-tag/doing/.gitkeep
plans/add-tag/done/.gitkeep
```

## Bad Example

- 這個例子是壞的，因為缺 doing/ 與 done/，validator 會過但 phase loop 起不來。

```text
plans/add-tag/todo/01-taxonomy-enum.md
```

# Rule 4 - 必跑 validator、輸出貼進 handoff、非 0 即 FAIL 不放行

- Level: `MUST`
- 寫完 plan.md 與所有卡片後，必須跑 `python3 skills/athena-specformula/scripts/validate_plan.py --require-touches plans/<slug>/`。它檢查：環、懸空 `depends_on`、每個 phase 恰好一張卡、frontmatter 與正文表格一致、所有互不可達 pair 的 touches 交集。
- exit 0 是 gate PASS 的必要條件；非 0 不得手動判斷「這個 error 其實沒關係」——改 plan 直到過。validator 沒過就是 `FAIL`，tag 用 `#plan-gap`。
- 指令、exit code 與實際輸出全文（含 warning）必須貼進 handoff 的 `## Validator Result`。
- Gate 條件：`plan.md` 存在、Dependency Graph 完整、validator exit 0，三者齊備才 PASS。

## Good Example

- 這個例子是好的，因為 handoff 貼的是實跑輸出，且非 0 時回頭改 plan。

```md
## Validator Result
$ python3 skills/athena-specformula/scripts/validate_plan.py --require-touches plans/add-tag/
exit 0
OK: 3 phases, no cycle, touches disjoint (1 warning: phase 03 has no resources)
```

## Bad Example

- 這個例子是壞的，因為 validator 報 error 卻被人工放行。

```md
## Validator Result
exit 1（touches 重疊）——但那兩個 glob 實際上不相交，我判斷是誤判，直接記 PASS。
```

# Rule 5 - 跨檔契約面必須安排通讀驗收

- Level: `MUST`
- 任何 phase 改動 ≥ 2 個檔案的同一個契約面時，plan 必須安排 fresh-context 通讀驗收。兩種寫法擇一：
  - 寫進該 phase 的驗收條件：`- [ ] fresh-context reader 通讀本 phase 全部改動檔案，回報結構缺口（雞生蛋／缺失路徑／時序矛盾）`
  - 獨立一個驗證 phase：依賴所有契約面 phase，`touches` 只宣告 `resources: ["cross-file-readthrough"]`（不擁有任何檔案，避免與被驗 phase 交集）
- Verification Phase Dedup：若路由上有 verify stage 且最後一個 phase 是純驗證，flow 會跳過它（見 `phase-orchestration.md`）——獨立驗證 phase 只在「verify 不在路由上」或「驗證內容 verify skill 不覆蓋」時才值得開；不確定就寫進驗收條件。
- Why：本 repo 實證過機械 checklist 全過、fresh reader 通讀仍抓到 3 個結構缺口——這類「這條路走不通」的缺口 grep 與 lint 抓不到。

## Good Example

- 這個例子是好的，因為跨檔契約面 phase 把通讀寫進了驗收條件。

```md
### 驗收條件
- [ ] 新 tag 在 run-trace.md / hill-climb.md / agent-handoff.md 三處都出現（grep）
- [ ] fresh-context reader 通讀本 phase 全部改動檔案，回報結構缺口（雞生蛋／缺失路徑／時序矛盾）
```

## Bad Example

- 這個例子是壞的，因為改了同一契約面的 3 個檔案，驗收卻只有 grep，結構缺口沒人看。

```md
### 驗收條件
- [ ] 新 tag 在三處都出現（grep）
```

# Rule 6 - 只寫 plans/ 與 handoffs/，Bash 唯讀

- Level: `MUST`
- plan 階段只能寫 `plans/` 與 `handoffs/`；不得改動 `skills/`、`hooks/`、`scripts/` 或任何 src——那是 build 的工作。
- Bash 只用來跑 `validate_plan.py`、`git` 查詢與 `grep`，不用來改檔。

## Good Example

- 這個例子是好的，因為發現文件問題時記入 handoff 而不是動手改。

```md
發現 phase-orchestration.md 有一處筆誤，不在 plan 的寫入範圍——
記入 handoff 的 Risks / Unresolved Issues，留給 build。
```

## Bad Example

- 這個例子是壞的，因為 plan agent 順手改了 skills/ 下的檔案。

```md
順手用 sed 修掉 skills/athena-flow/SKILL.md 的筆誤，反正只是一行。
```
