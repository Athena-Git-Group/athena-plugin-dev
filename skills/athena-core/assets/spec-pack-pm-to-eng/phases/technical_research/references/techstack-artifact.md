# `techstack.md` 最小必要資訊判準

> `technical_research` phase 產 `specs/<slug>/technical_research/techstack.md` 時的判準。
> 本檔為本 repo 原創，判準借鑑自 CH3-SDD-workflow `skills/technical-research` 的同名 rules
> （未複製原檔，授權標註見 pack 根目錄 `VENDORED.md`）。

## 這份檔在 pack 裡的角色（先讀這段）

`techstack.md` **存在**時，它就是下游結構層 / 契約層的**技術棧真源**——
`screens` / `ui_contract` / `api` 的棧慣例以它為準。
它**不存在**時（含 `technical_research` 略過的預設情況），下游一律沿用
`../../pm-to-eng-flow/references/frontend-stack-conventions.md` 的
**Nuxt 4 + TypeScript strict**（見 pack 根 `SKILL.md` 非協商規則 5）。

所以這份檔只有兩種合法狀態：**不存在**，或**五類都表態且每項有來源**。
「存在但寫得含糊」是最壞的狀態——下游會拿它覆蓋預設棧卻拿不到可執行的結論。

## 檔案骨架

```md
# 技術棧宣告 — <slug>

- 上游依據：`specs/<slug>/technical_research/research.md`
- 預設棧對照：pack 的 `frontend-stack-conventions.md`（預設棧）

## 技術堆疊總覽

### 前端框架

| 類別 | 採用技術 | 用途 | 來源 |
| --- | --- | --- | --- |
| 應用框架 | `Nuxt 4` | 檔案式路由與 SSR | 來源：research.md#決策 1（沿用預設棧） |

### 型別策略
### 後端分層
### 持久化
### 測試機制

## 本次開發不引入的技術

- <技術> — <為什麼本次不引入>
```

五類皆須出現；某類不適用時**保留標題**並寫 `N/A — <原因>`（例如純前端需求的「後端分層」）。

## 判準 1 · 只寫最終結果，不重寫研究過程（MUST）

`techstack.md` 的責任是「這次最後採用了哪些技術」。
詳細取捨、替代方案比較、長段理由一律留在 `research.md`。

✅ 好的（表格 + 一句用途）

```md
| 類別 | 採用技術 | 用途 | 來源 |
| --- | --- | --- | --- |
| HTTP 框架 | `Nitro`（Nuxt 內建） | API route 與伺服器處理 | 來源：research.md#決策 3 |
```

❌ 壞的（把 `research.md` 的理由整段搬進來）

```md
- `Nitro`：選它而不是 Express、Fastify、Hono，因為……（三段理由）
```

## 判準 2 · 固定五類 + 固定欄位（MUST）

- 必含 `## 技術堆疊總覽` 與 `## 本次開發不引入的技術` 兩節。
- 總覽下的五個分類固定為 **前端框架 / 型別策略 / 後端分層 / 持久化 / 測試機制**，
  每類一張表，欄位固定 `類別 ∣ 採用技術 ∣ 用途 ∣ 來源`。
- 分類不得自行增刪改名——下游與驗收都以這五類逐項比對。

✅ 五類皆在，不適用者 `N/A — 本需求無後端`
❌ 退化成裸清單：`- Vite`／`- Express`／`- Prisma`

## 判準 3 · 每一項都要有 `來源：research.md#<決策>`（MUST，本 pack 特有）

`來源` 欄不可空、不可寫「憑經驗」。合法寫法只有兩種：

1. `來源：research.md#決策 N` —— 對應 `research.md` 的決策區塊；
2. `來源：research.md#決策 N（沿用預設棧）` —— 決策結論是沿用
   `frontend-stack-conventions.md`，但**仍要有那個決策區塊**。

沒有對應決策區塊的技術**不得**出現在本檔——那代表它沒被研究過就被寫進棧。

✅ `| 型別策略 | `TypeScript strict`（禁 `any`） | 全專案型別契約 | 來源：research.md#決策 2（沿用預設棧） |`
❌ `| 型別策略 | `TypeScript` | 型別 | 來源：慣例 |`

## 判準 4 · 只列已拍板與明確排除（SHOULD）

- 總覽表只放**已拍板採用**的技術。`research.md` 裡標「待定」的決策，
  對應列寫 `待定 — 見 research.md#決策 N`，**不得**寫成已採用。
- 「本次開發不引入的技術」只放**明確決定不引入**的（含常見誤用的替代品），
  每項附一句理由；只是評估過而沒進入邊界的方案留在 `research.md` 的選項欄。

✅ 「`React` 或其他前端框架 — 本專案已定案 Nuxt 4，不並存第二套框架」
❌ 「| UI 技術 | `React?` / 原生 JS? | 還在考慮 |」

## 判準 5 · 粒度服務下游 handoff（SHOULD）

分類與列舉粒度以「下游 `screens` / `ui_contract` / `api` / build stage 最容易接手」為準：

- 一類只有一列但責任清楚 → 保留。
- 同一用途被切成多列 → 合併。
- **不要**把 `package.json` 的 dependency 原封不動 dump 成清單——目標是全局棧視圖。
