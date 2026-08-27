# Plan Authoring 細節（team-plan 參考）

SKILL.md 是摘要與規則；本檔承載完整論述、模板與表格。由 team-plan SKILL.md 指引按需載入。

## 這個 repo 的產物是什麼（切分依據的前提）

這個 repo 不是 app。它的產物是三類：

1. **markdown prompt 契約** — `skills/**/SKILL.md`、`skills/**/references/*.md`、
   `agents/*.md`、`commands/*.md`。這些是 LLM 讀的行為契約，沒有測試可跑。
2. **bash hook** — `hooks/*.sh`。有 `bash -n` 語法檢查與執行位檢查。
3. **python script** — `scripts/render_status.py`、
   `skills/athena-specformula/scripts/validate_plan.py`。有 self-test。

所以**不要套用 specformula 的 8-phase 模板**（Backend TDD / Frontend Build /
Frontend E2E / Integration）。那是 app 開發的圖。這個 repo 的 phase 切分依據是
**契約面**：一組必須同步變動才能一致的檔案 = 一個 phase。

## 契約面的典型形狀（本 repo 實例）

| 契約面 | 同步範圍 |
|--------|---------|
| 一個 stage 的行為契約 | `skills/athena-flow/references/stage-contracts.md` 該段 + 對應 `agents/athena-stage-*.md` 殼 + `.athena/skills/team-*/SKILL.md` |
| 一個 taxonomy / enum | `run-trace.md` 的 enum 表 + `hill-climb.md` 的「失敗模式 → 改進目標」逐 tag 表 + `agent-handoff.md` 的 tag 契約 |
| 一個 flow-context 欄位 | `flow-context.md` schema + `hooks/auto-commit.sh` 的 `jq` 消費點 + `scripts/render_status.py` 的 parser |
| 一個 phase loop 規則 | `phase-orchestration.md` + `athena-flow/SKILL.md` 的非協商規則 + `agents/athena-stage-build.md` 殼 |

**找法是 grep，不是推測。** 動任何 enum、欄位名或規則編號之前，先
`grep -rn "<那個字串>" skills/ agents/ hooks/ scripts/ commands/ .athena/skills/`
把所有消費者找出來。漏掉的消費者就是改完等於沒改。

## 切分規則（第二步的完整版，依序檢查）

1. **契約面不可切開。** 一組必須同步的檔案必須屬於**同一個** phase。切開就是製造
   「一半生效」的狀態，而 gate 會兩邊都 PASS。這是本 repo 最貴的錯誤形狀。
2. **依目錄切，不依檔名切。** validator 的 glob 比對把每個 glob 截斷到第一個
   wildcard 前的字面前綴，再退回完整路徑段。所以 `skills/a*.md` 與
   `skills/b*.md` 會被判為重疊（前綴都是 `skills`）。同目錄下的不同檔案要平行，
   validator 攔不住也不放行——**改成一個 phase 擁有一個目錄**。
3. **同一個檔案只能有一個 owner。** 兩個 phase 都要改 `athena-flow/SKILL.md`
   的不同段落 → 合併成一個 phase，或串成依賴。不要賭 merge 不衝突。
4. **具名共享資源用 `resources`。** 不是檔案但會互相干擾的東西：
   `git-branch-namespace`、`plugin-manifest`、`trace-schema`、`lint-plugin-checks`。
   `resources` 是精確字串比對，比 glob 可靠，能表達 glob 表達不了的衝突。
5. **不要人為串鏈。** 兩個 phase 若 touches 無交集且**無語意依賴**，
   **不得**加 `depends_on` 邊。邊只表達真正的依賴。人為串鏈會抹掉可平行性，
   而可平行性是 flow 的主要加速來源。
6. **依賴要有方向理由。** 每條 `depends_on` 邊在 phase 卡裡要能用一句話說出
   「為什麼 B 非得等 A」。說不出來的邊就是第 5 條在講的那種假邊，刪掉。

`validate_plan.py` 的完整 touches 啟發式限制用
`python3 skills/athena-specformula/scripts/validate_plan.py --help` 查，**不要憑印象**——
它的 glob 比對是保守的字面前綴，會影響你怎麼切目錄。

## 機械自檢細節（第三步）

寫完 plan.md 與所有卡片後，**必須**跑：

```bash
python3 skills/athena-specformula/scripts/validate_plan.py --require-touches plans/<slug>/
```

它會檢查：環、懸空 `depends_on`、每個 phase 恰好一張卡、frontmatter 與正文
表格一致、以及**所有互不可達 pair 的 touches 交集**。

- **exit 0** → gate PASS 的必要條件成立
- **非 0** → **不要手動判斷「這個 error 其實沒關係」**。改 plan 直到它過。
  真的認為 validator 誤判（例如保守 glob 啟發式把同目錄的 disjoint glob 判為重疊），
  正確做法是**改成依目錄切分**，不是繞過 validator。

## plan.md frontmatter schema

frontmatter 是 Dependency Graph 的**唯一機械真相**，schema 固定：

```yaml
---
plan: <slug>
phases:
  - id: "01"
    name: <phase 名稱>
    depends_on: []
    touches:
      files: ["<glob>", ...]
      resources: ["<具名資源>", ...]
status_source: folders
---
```

- `id` 是兩位數字字串（`"01"`），`depends_on` 只准引用存在的 `id`
- `status_source: folders` 是固定值——phase 狀態的唯一真相是卡片所在資料夾
- 正文的 markdown 表格與 ASCII 圖**只是人類視圖**，必須與 frontmatter 一致
  （validator 會比對），衝突時以 frontmatter 為準
- 正文必須保留 plan-template 的「機械真相聲明」與「防過度串鏈」兩段警語

## Phase 卡模板（`plans/<slug>/todo/<NN>-<name>.md`）

每張卡必須有這些欄位——**flow 的 phase agent 只讀卡片，讀不到你的推理過程**：

```markdown
## Phase <NN>: <name>

- **Depends On:** <NN, NN 或 —>
- **Depends Why:** <一句話講為什麼非得等這些 phase；無依賴寫「無前置」>
- **Spec Sections:** <只列這個 phase 需要的 section 編號或標題>
- **Touches:** files: <glob 清單> / resources: <清單或 —>
- **Smoke Test:** <指令；見下方「Smoke Test 表」>

### 目標
<這個 phase 要達成什麼，一段>

### 契約面清單（本 phase 擁有、必須同步變動的檔案）
- `<path>` — <為什麼它屬於這個契約面>
- ...

### 驗收條件
- [ ] <可判定的條件，不是「做好」這種話>
```

> **`Touches` 欄位要與 frontmatter 一字不差。** 卡片是給 agent 看的邊界宣告，
> frontmatter 是給 validator 看的。兩邊漂移 = agent 越界而 validator 沒攔到。
> flow 會把 touches 邊界注入 phase agent 的 prompt，越界即 gate FAIL `#plan-gap`。

## 資料夾骨架

`todo/` 由你建立（寫卡片時自動產生）。另外**必須**建立空的 `doing/` 與 `done/`：

```
plans/<slug>/doing/.gitkeep
plans/<slug>/done/.gitkeep
```

理由：flow 在 spawn phase agent 前執行 `mv todo/<NN>-*.md doing/`（位置即狀態、
mv 即鎖）。目標資料夾不存在，`mv` 會失敗，phase loop 起不來。
validator 容忍這兩個資料夾不存在，所以**它不會幫你抓到這個錯**。

## Smoke Test 表

phase 卡的 `Smoke Test` 是該 phase 的 gate 依據。依 phase 改動的檔案類型選：

| 改動類型 | Smoke Test |
|---------|-----------|
| 任何檔案（基本盤） | `bash scripts/lint-plugin.sh` |
| 只動 markdown prompt 契約 | `bash scripts/lint-plugin.sh` + 卡片指定的跨檔一致性 grep（見下） |
| 動 `hooks/*.sh` | `bash scripts/lint-plugin.sh`（含 `bash -n` 與執行位檢查）+ 該 hook 的實跑冒煙 |
| 動 `scripts/*.py` 或 `validate_plan.py` | `bash scripts/lint-plugin.sh`（含 plan validator self-test）+ 該 script 對 `tests/fixtures/` 實跑 |
| 動 plan/trace schema | 上述 + `python3 skills/athena-specformula/scripts/validate_plan.py --require-touches tests/fixtures/plan-valid/` |

**markdown 契約沒有測試可跑。** 這類 phase 的 smoke test 必須是**可機械判定的
一致性檢查**，寫成具體指令，例如：

```bash
# 確認新 tag 在所有消費者都出現
grep -q 'rule-conflict' skills/athena-flow/references/run-trace.md \
  && grep -q 'rule-conflict' skills/athena-hill-climb/references/hill-climb.md
```

不要寫「人工檢查文件一致」這種無法判定的話當 smoke test。

## 跨檔契約 → 通讀驗收（完整論述）

**本 repo 的驗收教訓（非協商）**：worktree 隔離那次改動，機械 checklist 全過，
但 fresh reader 通讀抓到 3 個結構缺口（雞生蛋、retry 路徑缺失、時序矛盾）。
這類缺口 **grep 與 lint 抓不到**——它們不是「某個字串漏了」，是「這條路走不通」。

所以：**任何 phase 改動 ≥ 2 個檔案的同一個契約面時**，plan 必須安排通讀驗收。
兩種寫法，選一種：

- **寫進該 phase 的驗收條件**：`- [ ] fresh-context reader 通讀本 phase 全部改動檔案，回報結構缺口（雞生蛋／缺失路徑／時序矛盾）`
- **獨立一個驗證 phase**：依賴所有契約面 phase，`touches` 只宣告
  `resources: ["cross-file-readthrough"]`（不擁有任何檔案，避免與被驗的 phase 交集）

> **注意 Verification Phase Dedup**：若路由上有 verify stage，而你的最後一個 phase
> 是純驗證，flow 會跳過該 phase（見 `phase-orchestration.md`）。所以獨立驗證 phase
> 只在「verify stage 不在路由上」或「驗證內容 verify skill 不覆蓋」時才值得開。
> 不確定就用第一種寫法，把通讀寫進驗收條件。
