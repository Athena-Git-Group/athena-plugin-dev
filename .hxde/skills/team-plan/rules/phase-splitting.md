# Rule 1 - 以契約面切 phase，契約面不可切開

- Level: `MUST`
- 契約面＝一組必須同步變動才能保持一致的檔案。本 repo 的產物是三類：markdown prompt 契約（`skills/**/SKILL.md`、`references/*.md`、`agents/*.md`、`commands/*.md`，LLM 讀的行為契約，沒有測試可跑）、bash hook（`hooks/*.sh`）、python script（`scripts/*.py`、`validate_plan.py`）。
- 不套用 specformula 的 8-phase 模板（Backend TDD / Frontend Build / Frontend E2E / Integration）——那是 app 開發的圖。本 repo 一個契約面＝一個 phase。
- 一組必須同步的檔案必須屬於同一個 phase。切開就是製造「一半生效」的狀態，而 gate 會兩邊都 PASS——這是本 repo 最貴的錯誤形狀。
- 契約面的典型形狀（實例）：

| 契約面 | 同步範圍 |
|--------|---------|
| 一個 stage 的行為契約 | `skills/hxde-flow/references/stage-contracts.md` 該段 + 對應 `agents/hxde-stage-*.md` 殼 + `.hxde/skills/team-*/SKILL.md` |
| 一個 taxonomy / enum | `run-trace.md` 的 enum 表 + `hill-climb.md` 的「失敗模式 → 改進目標」逐 tag 表 + `agent-handoff.md` 的 tag 契約 |
| 一個 flow-context 欄位 | `flow-context.md` schema + `hooks/auto-commit.sh` 的 `jq` 消費點 + `scripts/render_status.py` 的 parser |
| 一個 phase loop 規則 | `phase-orchestration.md` + `hxde-flow/SKILL.md` 的非協商規則 + `agents/hxde-stage-build.md` 殼 |

## Good Example

- 這個例子是好的，因為同一個 enum 的三個消費檔被放進同一個 phase。

```md
Phase 02: 擴充 failure taxonomy
契約面清單：run-trace.md enum 表、hill-climb.md 逐 tag 表、agent-handoff.md tag 契約
```

## Bad Example

- 這個例子是壞的，因為同一個 enum 的消費者被切到兩個 phase，會出現「一半生效」而兩邊 gate 都 PASS。

```md
Phase 02: 改 run-trace.md 的 enum 表
Phase 05: 改 hill-climb.md 的逐 tag 表
```

# Rule 2 - 消費者用 grep 找，不用推測

- Level: `MUST`
- 動任何 enum、欄位名或規則編號之前，先跑
  `grep -rn "<那個字串>" skills/ agents/ hooks/ scripts/ commands/ .hxde/skills/`
  把所有消費者找出來，寫進該 phase 的契約面清單。
- 漏掉的消費者就是改完等於沒改——契約的機械真相在「agent 實際會讀的那份檔案」。
- Why：本 repo 吃過虧——enum 改了一處漏另一處、規則只寫編排文件而未鏡射 agent 殼，結果需求只解一半或規則等於不存在。

## Good Example

- 這個例子是好的，因為契約面清單是 grep 實據，不是印象。

```md
grep -rn "integration-mismatch" skills/ agents/ .hxde/skills/ 命中 3 檔：
run-trace.md、hill-climb.md、agent-handoff.md → 全部列入 Phase 02 契約面清單。
```

## Bad Example

- 這個例子是壞的，因為消費者是憑印象列的，少列的那份檔案不會被改到。

```md
這個 tag 應該只有 run-trace.md 在用，契約面清單就列它一個。
```

# Rule 3 - 一個檔案只有一個 owner

- Level: `MUST`
- 兩個 phase 都要改同一個檔案（即使是不同段落）→ 合併成一個 phase，或串成依賴。
- 不要賭 merge 不衝突。

## Good Example

- 這個例子是好的，因為同檔需求被收斂成單一 owner。

```md
Phase 03 與 Phase 04 都想改 hxde-flow/SKILL.md 的不同段 → 合併為一個 Phase 03。
```

## Bad Example

- 這個例子是壞的，因為兩個平行 phase 共享同一個檔案。

```md
Phase 03 touches: skills/hxde-flow/SKILL.md（非協商規則段）
Phase 04 touches: skills/hxde-flow/SKILL.md（SOP 段）
```

# Rule 4 - 依目錄切分，不依檔名切分

- Level: `MUST`
- validator 比對 touches 的 glob 時，只看每個 glob 在第一個 wildcard 之前的字面開頭。所以 `skills/a*.md` 與 `skills/b*.md` 都被當成「`skills` 目錄」而判為重疊。
- 想讓兩個 phase 平行，就讓一個 phase 擁有一個目錄，不要在同一目錄下用檔名 glob 分工。
- 覺得 validator 誤判（例如同目錄下其實不相交的 glob 被判重疊）時，正確做法是改成依目錄切分，不是繞過 validator。
- glob 比對的完整限制用 `python3 skills/hxde-specformula/scripts/validate_plan.py --help` 查，不憑印象。

## Good Example

- 這個例子是好的，因為兩個平行 phase 各自擁有一個目錄。

```yaml
- id: "02"
  touches: { files: ["skills/hxde-flow/**"] }
- id: "03"
  touches: { files: ["skills/hxde-point/**"] }
```

## Bad Example

- 這個例子是壞的，因為同目錄用檔名 glob 分工，validator 會判為重疊。

```yaml
- id: "02"
  touches: { files: ["skills/hxde-flow/a*.md"] }
- id: "03"
  touches: { files: ["skills/hxde-flow/b*.md"] }
```

# Rule 5 - 具名共享資源用 resources 宣告

- Level: `MUST`
- 不是檔案但會互相干擾的東西，用 `resources` 宣告：例如 `git-branch-namespace`、`plugin-manifest`、`trace-schema`、`lint-plugin-checks`。
- `resources` 是精確字串比對，比 glob 可靠，能表達 glob 表達不了的衝突。

## Good Example

- 這個例子是好的，因為兩個 phase 的隱性衝突被 resources 顯式化，validator 能攔到。

```yaml
- id: "04"
  touches: { files: ["hooks/**"], resources: ["lint-plugin-checks"] }
- id: "05"
  touches: { files: ["scripts/**"], resources: ["lint-plugin-checks"] }
```

## Bad Example

- 這個例子是壞的，因為兩個 phase 都會動到 lint 檢查項，卻沒宣告共享資源，validator 看不到衝突。

```yaml
- id: "04"
  touches: { files: ["hooks/**"] }
- id: "05"
  touches: { files: ["scripts/**"] }
```

# Rule 6 - 不人為串鏈，每條依賴邊要有一句話理由

- Level: `MUST`
- 兩個 phase 若 touches 無交集且無語意依賴，不得加 `depends_on` 邊。邊只表達真正的依賴——人為串鏈會抹掉可平行性，而可平行性是 flow 的主要加速來源。
- 每條 `depends_on` 邊在 phase 卡的 `Depends Why` 要能用一句話說出「為什麼 B 非得等 A」；說不出來的邊就是假邊，刪掉。

## Good Example

- 這個例子是好的，因為依賴方向有具體理由。

```md
- **Depends On:** 02
- **Depends Why:** 本 phase 的 grep 一致性檢查以 02 定稿的 tag 名為準。
```

## Bad Example

- 這個例子是壞的，因為邊沒有語意理由，只是把 phase 排成一條線。

```md
- **Depends On:** 02
- **Depends Why:** 照編號順序做比較保險。
```
