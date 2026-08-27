# Output Templates（plugin-contract-spec 產出物模板）

SKILL.md 定義判定規則與 gate 條件；本檔承載五份產出物的完整模板。寫任何產出物前先讀對應段。

## 1. `source/requirement.md`

需求原文，自 point-report 抄錄。**不可變、不改寫、不摘要。** 後面所有判斷
都要能追溯到這份。

## 2. `contract-surface.md`（核心產出）

每一個改動項目，盤出它的契約面。**每一列都要有 grep 實據。**

````markdown
# 契約面盤點 — <slug>

## 改動項 <ID>：<一句話>

### 錨點（要改的地方）
- `<path>:<行號>` — <現況原文引用，1-3 行>

### 消費者搜尋
指令：
```bash
grep -rn "<搜尋字串>" skills/ agents/ commands/ hooks/ scripts/ .athena/skills/ docs/
```
實際輸出：
```
<貼上真實輸出，不得省略也不得虛構>
```

### 消費者判定
| 檔案:行號 | 引用形式 | 需要同步？ | 理由 |
|-----------|---------|-----------|------|
| `skills/x/y.md:84` | 逐項列舉 | **是** | 缺這列就統計得到卻沒有對應項 |
| `skills/a/b.md:38` | 指標引用（「見 run-trace.md」） | 否 | 指向來源，來源改了就跟著對 |

### 跨語言消費者
| 檔案:行號 | 語言 | 消費方式 | 壞掉時會不會報錯 |
|-----------|------|---------|-----------------|
| `hooks/auto-commit.sh:69` | bash | `jq -r '.parallel_phases // 0'` | **不會**——靜默行為錯誤 |
````

## 3. `changes/<ID>.md`（一項一檔）

```markdown
# 改動 <ID>：<標題>

## 現況
`<path>:<行號>`
> <原文引用>

## 問題
<現況為什麼不夠；一段，可追溯到 requirement.md>

## 目標行為
<改完之後，讀這份契約的 agent 會怎麼做；用行為描述，不是文字描述>

## 落點
| 檔案 | 位置 | 動作 |
|------|------|------|
| `<path>` | <段落名 / 規則編號> | 新增 / 修改 / 鏡射 |

## 不做什麼
<明確劃出範圍外，避免 build 階段擴張>

## 驗收條件
- [ ] <可判定；機械可查的寫成指令>
```

**`目標行為` 要寫行為，不要寫文案。** 「加一段講白話摘要」是文案；
「stage 交界回報時，先給 2-4 句白話講發生什麼、卡在哪、要使用者決定什麼」
是行為。build agent 照後者能做對，照前者會自由發揮。

## 4. `conflicts.md`（本 repo 特有，不可省）

新規則可能跟**既有的非協商規則**互斥。這個 repo 的規則散在多層：
plugin 的 `skills/*/SKILL.md`、`references/*.md`、team 的
`.athena/skills/*/SKILL.md`、以及使用者的全域守則。

每個改動項都要檢查，並在此記錄：

```markdown
# 規則衝突檢查 — <slug>

## 改動項 <ID>
搜尋過的規則來源：
- `skills/athena-flow/SKILL.md`「非協商規則」段
- `.athena/skills/*/SKILL.md`「非協商規則」段
- <其他>

結果：<無衝突 / 有衝突>

### 衝突（若有）
- **衝突對象**：`<path>:<行號>` — <原文引用>
- **衝突內容**：<為什麼兩條不能同時成立>
- **解法**：<三選一>
  - 在新規則明文寫出例外與適用層級
  - 改走對方規定的程序（例如提案而非直接改）
  - 修改對方規則（**需在 handoff 的 Risks 明列，因為這擴大了 impact**）
```

**已知的一條**：`.athena/skills/team-ship/SKILL.md`「失敗處理」段規定 taxonomy 要透過
hill-climb 提案擴充、不得私自發明 tag。任何動 `failures[].tag` enum 的改動
都會撞到它，必須在此段給出解法，不得沉默略過。

**規則編號重排是衝突的一種**：在「非協商規則」清單中插入新條目會讓後續編號
位移。動之前先 grep 是否有跨檔引用（例如「見 flow 非協商規則第 N 條」）。
有引用就一起改，沒有就在此記「已查證無跨檔引用」。

## 5. `acceptance.md`

驗收分兩類，兩類都要有。

```markdown
# 驗收條件 — <slug>

## 機械驗收（可判定的指令）
| # | 指令 | 期望 |
|---|------|------|
| 1 | `bash scripts/lint-plugin.sh` | exit 0 |
| 2 | `grep -c '<新字串>' <每個必須同步的檔案>` | 每個 ≥ 1 |
| 3 | <跨語言消費者的實跑冒煙> | <期望> |

## 通讀驗收（機械抓不到的）
- [ ] fresh-context reader 通讀 <檔案清單>，回報結構缺口：
      雞生蛋（A 需要 B 而 B 需要 A）、缺失路徑（規則沒說某情況怎麼辦）、
      時序矛盾（步驟順序不可能成立）
```

**通讀驗收不是可選的。** 本 repo 病史：worktree 隔離那次改動機械檢查全過，
fresh reader 通讀抓到 3 個結構缺口，全部是 grep 與 lint 抓不到的形狀。
任何改動涉及 ≥ 2 個檔案的同一個契約面，就必須有這一項。

## 6. Handoff（`handoffs/<slug>-spec.md`）

```markdown
# Spec Handoff — <slug>

## Stage
spec（plugin-contract-spec，經 team-spec-index 路由）

## Inputs Used
- points/<slug>.md
- specs/<slug>/route.md
- <每個實際讀過的標的檔案>

## Artifacts Produced
- specs/<slug>/source/requirement.md
- specs/<slug>/contract-surface.md
- specs/<slug>/changes/<ID>.md（逐一列出）
- specs/<slug>/conflicts.md
- specs/<slug>/acceptance.md

## 契約面摘要
| 改動項 | 錨點 | 必須同步的消費者 | 跨語言 |
|--------|------|-----------------|--------|
| A | `<path>` | <清單或「無」> | 無 |

## Gate Verdict
<PASS，或 FAIL — 原因 #tag>

## Risks
- <未解衝突、擴大的 impact、未查證的假設>

## Next Recommended Stage
plan
```
