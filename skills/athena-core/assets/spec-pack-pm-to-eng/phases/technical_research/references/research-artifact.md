# `research.md` 最小必要資訊判準

> `technical_research` phase 產 `specs/<slug>/technical_research/research.md` 時的判準。
> 本檔為本 repo 原創，判準借鑑自 CH3-SDD-workflow `skills/technical-research` 的同名 rules
> （未複製原檔，授權標註見 pack 根目錄 `VENDORED.md`）。
> 比例原則：研究問題少時決策區塊就少，**不為了湊篇幅發明題目**。

## 檔案骨架

```md
# 技術研究 — <slug>

- 研究範圍：<一句話，回指 spec.md 的哪些 NFR / 全域需求>
- 上游依據：`specs/<slug>/specify/spec.md`（STATUS: READY）
- 預設棧對照：pack 的 `frontend-stack-conventions.md`（預設棧）

## 決策 1 · <決策標題>

- **研究問題**：<要拍板什麼；回指 spec.md#NFR-002>
- **選項**：
  - A. <方案> — <trade-off>
  - B. <方案> — <trade-off>
- **判準**：<用哪條需求 / NFR / 既有專案事實來選>
- **決策**：<採納哪一個>　**狀態**：已定 ∣ 待定
- **依據來源**：`spec.md#NFR-002`、`package.json`、`frontend-stack-conventions.md`
- **風險**：<未驗證假設、殘留風險、需後續 spike 的項目>
```

決策編號 `決策 N`，標題可被 `techstack.md` 以 `研究來源：research.md#決策 N` 回指。

## 判準 1 · 每個決策五欄齊備（MUST）

一個決策區塊必須同時有 **研究問題 / 選項 / 判準 / 決策 / 風險** 五欄，
外加「狀態（已定 ∣ 待定）」與「依據來源」。

- 只有結論沒有判準 → 下游無法判斷這個決策還能不能改。
- 只有優缺點比較沒有決策 → 沒有拍板，等於沒研究。
- 風險欄沒有東西可寫時，寫 `無殘留風險 — <一句話理由>`，不留空。

✅ 好的（可被 review、可被推翻）

```md
- **研究問題**：照片縮圖存 DB BLOB 或檔案系統？（spec.md#NFR-003 保存年限 3 年）
- **選項**：A. MySQL BLOB — 備份一致但體積膨脹；B. 檔案系統 + 路徑欄 — 體積可控但需另備份
- **判準**：NFR-003 要求「單機部署、備份單一來源」
- **決策**：A（MySQL BLOB）　**狀態**：已定
- **依據來源**：`spec.md#NFR-003`
- **風險**：實際容量與備份時間未量測，需在 build stage 驗證
```

❌ 壞的（沒有判準、沒有替代方案、沒有風險）

```md
## 決策 1 · 縮圖儲存
- 用 BLOB。
```

## 判準 2 · 研究問題一律回推 `spec.md`（MUST）

每個決策都必須能回扣 `spec.md` 的需求、範圍、成功標準或邊界。
`research.md` 不是通用技術教學，也不是技術百科。

- 研究問題**不得**自行發明：找不到對應的 FR / NFR / 邊界 / 量級敘述，就不是本次的研究問題。
- 無法支撐下游 `data_model` / `screens` / `api` / `ui_contract` 判斷的段落，刪掉或縮成附註。

✅ 「研究主題：照片日期相簿整理 → 前端是否需要框架、圖片持久化方式、排序如何建模」
❌ 「研究主題：JavaScript 語言演進史 → ECMAScript 各版本整理」

## 判準 3 · 選項必須是真替代方案（SHOULD）

`選項` 要列在當前問題下**實際可選、且會導致不同 trade-off** 的方案，
一般 2–3 個；唯一合理替代方案只有 1 個時可只列 1 個，但仍須有比較價值。
未採納的方案簡短寫明不採納理由。

✅ 「`mysql2` 直接寫 SQL：依賴少，但 schema 演進可讀性差」／「`Knex`：接近 SQL，但型別整合弱」
❌ 「更好的做法」／「另一個差不多的方法」

## 判準 4 · 未驗證假設必須明示（SHOULD）

尚未量測的容量、效能、相容性或營運假設，一律寫進「風險」欄或把狀態標「待定」。
**不得**把推測寫成既定事實。

- 「待定」必須寫清楚**待定什麼**、**由誰在哪個 stage 決**（通常是 build stage 的 spike）。
- 數值一律標來源；沒有來源的數值不寫。

✅ 「**風險**：BLOB 在 >50GB 時的備份時間未量測，build stage 需 spike」
❌ 「**決策**：BLOB 一定能在所有部署情境提供最佳效能與最低成本」

## 判準 5 · 偏離預設棧必須寫理由（MUST，本 pack 特有）

本 pack 的預設棧是 Nuxt 4 + TypeScript strict。研究結論**偏離**預設棧時，
對應決策必須寫明「為什麼本專案要偏離」，並在 `handoffs/technical_research.md` 列為顯著風險。

- 沿用預設棧的項目也要**顯式**寫一行「沿用預設棧（`frontend-stack-conventions.md`）」，
  不留白——下游要能一眼看出這是被確認過的，不是漏寫。
- **不得**修改 `frontend-stack-conventions.md` 本身（vendored，零改動）。

✅ 「**決策**：沿用預設棧 Nuxt 4 + TypeScript strict　**依據來源**：`frontend-stack-conventions.md`」
❌ 靜默改棧：`techstack.md` 寫 React 而 `research.md` 沒有任何對應決策。
