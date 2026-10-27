# Rule 1 - 工具邊界（spec stage shell 契約）

- Level: `MUST`
- Write **只能**寫 `specs/` 與 `handoffs/<slug>-spec.md`。
- Bash 唯讀（`grep` / `git` 查詢）；**不得**改檔、commit / push、跑會寫入的 script。
- 需要範圍外工具時：在 handoff 回報並停止，不繞道。

## Good Example

- 這個例子是好的，因為遇到需要寫入的動作時停下來回報。

```md
驗證 hook 需要實跑會寫檔的 script → 不跑。
在 handoff 的 Risks 記「機械驗收 #3 需於 build/verify 階段實跑」，繼續完成規格。
```

## Bad Example

- 這個例子是壞的，因為 spec agent 自己動手改了標的檔案。

```md
反正只是一行 typo，順手 Edit hooks/auto-commit.sh 修掉。
```

# Rule 2 - 範圍邊界：只寫契約規格，不越 stage

- Level: `MUST`
- **不產出** `data_model` / `class_diagram` / `db_table` / `screens` / `api` / `ui_contract`——那是 `pm-to-eng-spec` 的產物；本 skill 的標的沒有實體、資料表、畫面或 endpoint。
- **不做 phase 拆解**——那是 plan stage 的工作。
- **不寫實作程式碼**。

## Good Example

- 這個例子是好的，因為產出止於契約規格。

```md
specs/add-tag/ 下只有 source/、contract-surface.md、changes/、conflicts.md、acceptance.md。
沒有 data_model，沒有 phase 卡，changes/ 裡寫的是目標行為不是 diff。
```

## Bad Example

- 這個例子是壞的，因為規格裡混進了 plan 與實作。

```md
changes/A.md 附上建議的 Phase 1/2/3 拆解，以及改好的 bash 程式碼全文。
```

# Rule 3 - `source/requirement.md` 不可變

- Level: `MUST`
- 需求原文自 point-report 抄錄到 `specs/<slug>/source/requirement.md`：不改寫、不摘要、不「順一下語句」。
- Why：後面所有判斷都要能追溯回這份原文。

## Good Example

- 這個例子是好的，因為原文一字不動地抄錄。

```md
points/add-tag.md 的需求段共 12 行 → 原樣複製進 source/requirement.md。
```

## Bad Example

- 這個例子是壞的，因為抄錄時做了摘要。

```md
需求有點長，摘成三點重點寫進 source/requirement.md。
```

# Rule 4 - 現況帶檔案:行號原文引用；目標行為寫行為、不寫文案

- Level: `MUST`
- 每個 `changes/<ID>.md` 的「現況」必須**原文引用**並帶 `檔案:行號`，不得憑記憶描述現況。
- 「目標行為」寫的是**改完之後讀這份契約的 agent 會怎麼做**，不是要加什麼文字。寫文案的規格，build agent 會自由發揮；寫行為的才能做對。

## Good Example

- 這個例子是好的，因為現況可追溯、目標是可判定的行為。

```md
## 現況
`skills/athena-flow/SKILL.md:42`
> stage 交界時直接貼 handoff 全文給使用者

## 目標行為
stage 交界回報時，先給 2-4 句白話：發生什麼、卡在哪、要使用者決定什麼。
```

## Bad Example

- 這個例子是壞的，因為現況是印象、目標是文案。

```md
## 現況
記得 flow 那邊回報滿生硬的。

## 目標行為
加一段講白話摘要。
```

# Rule 5 - `conflicts.md` 不可省：每個改動項都要有結論，有衝突都要有解法

- Level: `MUST`
- 新規則可能跟**既有的非協商規則**互斥。本 repo 的規則散在多層：plugin 的 `skills/*/SKILL.md` 與 `references/*.md`、team 的 `.athena/skills/*/SKILL.md`、使用者的全域守則——每個改動項都要檢查並記錄結論（無衝突也要寫「無衝突」與搜尋過的來源）。
- 有衝突必須給解法，三選一：在新規則明文寫出例外與適用層級；改走對方規定的程序；修改對方規則（**需在 handoff 的 Risks 明列**，因為這擴大了 impact）。
- 已知的一條：taxonomy tag 須透過 hill-climb 提案擴充、不得私自發明（見 `.athena/skills/team-common/rules/fail-reporting.md` Rule 2）。任何動 `failures[].tag` enum 的改動都會撞到它，必須給出解法，不得沉默略過。
- **規則編號重排也是衝突的一種**：在「非協商規則」清單插入新條目會讓後續編號位移。動之前先 grep 是否有跨檔引用（如「見 flow 非協商規則第 N 條」）——有引用就一起改，沒有就記「已查證無跨檔引用」。

## Good Example

- 這個例子是好的，因為衝突被點名且給了解法。

```md
## 改動項 A
結果：有衝突
- 衝突對象：.athena/skills/team-common/rules/fail-reporting.md Rule 2 — 不得私自發明 tag
- 解法：改走對方規定的程序——本改動以 hill-climb 提案形式擴充 taxonomy，不直接加 tag。
```

## Bad Example

- 這個例子是壞的，因為明知撞規則卻沉默略過。

```md
## 改動項 A
新 tag 直接加進 enum。（conflicts.md 未提 taxonomy 擴充程序）
```

# Rule 6 - 驗收兩類都要；涉及 ≥ 2 檔同一契約面必須有通讀驗收項

- Level: `MUST`
- `acceptance.md` 分兩類，兩類都要有：**機械驗收**（可判定的指令＋期望）與**通讀驗收**（fresh-context reader 通讀相關檔案，回報機械抓不到的結構缺口：雞生蛋、缺失路徑、時序矛盾）。
- 任何改動涉及 ≥ 2 個檔案的同一個契約面，就必須有通讀驗收項——不是可選。
- Why：本 repo 病史——worktree 隔離那次改動機械檢查全過，fresh reader 通讀抓到 3 個 grep 與 lint 抓不到的結構缺口。
- 跨語言且壞掉不報錯的消費點，必須有對應的機械驗收（實跑冒煙）。

## Good Example

- 這個例子是好的，因為兩類驗收俱備且通讀有明確範圍。

```md
## 機械驗收
| 1 | grep -c '#new-tag' skills/hill-climb/SKILL.md | ≥ 1 |

## 通讀驗收
- [ ] fresh-context reader 通讀 run-trace.md + hill-climb SKILL.md，回報結構缺口
```

## Bad Example

- 這個例子是壞的，因為改動跨 3 個檔案卻只有機械驗收。

```md
## 機械驗收
| 1 | bash scripts/lint-plugin.sh | exit 0 |

（沒有通讀驗收——「lint 過了應該就沒問題」）
```

# Rule 7 - Gate 條件：PASS 須全部成立，否則 FAIL 帶 tag

- Level: `MUST`
- `PASS` 需要**全部**成立：
  - 每個改動項都有 `changes/<ID>.md` 且含現況原文引用（帶檔案:行號）
  - `contract-surface.md` 每個改動項都有真實 grep 輸出
  - `conflicts.md` 每個改動項都有結論，且有衝突的都有解法
  - `acceptance.md` 機械與通讀兩類都有
  - 沒有未解的 clarify 問題
- 任一不成立 → `FAIL` 帶 tag：

| 情況 | Verdict |
|------|---------|
| 有未解澄清問題 | `FAIL — 待澄清 #spec-gap` |
| 契約面盤點缺 grep 實據 | `FAIL — 盤點無實據 #spec-gap` |
| 規則衝突無解法 | `FAIL — 規則衝突未解 #rule-conflict`（原因文字需列出互斥兩條規則的來源，見 run-trace.md Failure Taxonomy 段） |
| 需求本身矛盾或無法工程化 | `FAIL — 需求不可譯 #spec-gap` |

- FAIL 的書寫格式與 taxonomy enum 限制，見 `.athena/skills/team-common/rules/fail-reporting.md`。

## Good Example

- 這個例子是好的，因為缺實據時誠實發對應的 FAIL。

```md
改動項 B 的消費者清單沒有 grep 輸出（當時憑印象列的）。
## Gate Verdict
FAIL — 盤點無實據 #spec-gap
```

## Bad Example

- 這個例子是壞的，因為條件沒全部成立仍發 PASS。

```md
conflicts.md 的改動項 B 還沒有結論，不過大致沒問題。
## Gate Verdict
PASS
```
