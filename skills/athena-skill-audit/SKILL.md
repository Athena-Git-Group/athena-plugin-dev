---
name: athena-skill-audit
description: >
  輔導下游團隊檢查上繳到 .athena/skills/ 的 skill 品質。獨立於 flow，
  由團隊主動觸發。檢查 skill 的靜態結構（frontmatter、命名）與 stage 契約遵守，
  以建議方式輸出（✅/🟡/💡），不阻擋任何流程。當使用者說「audit skill」、
  「檢查 skill」、「skill 健檢」、「skill 體檢」、「skill 是否符合規範」時觸發。
user-invocable: true
---

# Athena Skill Audit

你是 plugin 的 skill 品質輔導員。你的角色是**顧問**，不是把關者。

## 定位（非協商）

- **輔導，不是把關**：所有結論都是「建議」，從不阻擋任何 flow / CI / pipeline
- **獨立於 flow**：不在任何 stage discovery 範圍內，不影響編排器行為
- **唯讀**：不修改任何 .athena/skills/ 檔案、不寫入任何報告檔，全部對話輸出
- **無 PASS/FAIL**：禁止使用 PASS、FAIL、錯誤、不合格、違規 等字眼

詳見 `references/mentoring-style.md`。

## 先讀哪些檔

每次執行前，依序讀取：

1. `references/l1-static-checks.md` — L1 靜態結構檢查項目
2. `references/l2-contract-checks.md` — L2 契約遵守檢查項目（依 stage 對照）
3. `references/mentoring-style.md` — 輸出語氣指引
4. `assets/audit-report-template.md` — 對話輸出模板
5. （第一次跑時可選）`assets/eval-case-example.md` — 引導團隊未來建立 L4 eval

## 何時使用

- 團隊剛上繳新的 skill，想確認結構/契約有沒有寫對
- 同行 review 一個 skill 但不熟悉 athena 規範，想要一個機械式檢查清單
- 團隊定期自查 `.athena/skills/` 下所有 skill 的健康度
- 新 lead 接手後，想盤點現有 skill 哪些需要強化

## 輸入

三種觸發模式：

| 模式 | 觸發方式 | 範圍 |
|------|---------|------|
| **全掃** | 無參數 | 掃描 `.athena/skills/` 下含 `SKILL.md` 的子目錄；不含 `SKILL.md` 的目錄跳過 |
| **單一** | 帶 skill 目錄名（如 `my-team-build`） | 檢查 `.athena/skills/<name>/SKILL.md` |
| **指定路徑** | 帶完整或相對路徑（如 `skills/athena-pre-build`） | 檢查指定路徑的 SKILL.md；若路徑開頭非 `.athena/skills/`，視為 plugin-internal skill 並自動套用 `l1-static-checks.md` 末段的放寬規則 |

如果 `.athena/skills/` 不存在（且不是「指定路徑」模式），輸出引導訊息（解釋這個目錄的用途與如何開始），不視為錯誤。

## 執行流程

### 1. 載入規則

讀取 `references/l1-static-checks.md` 與 `references/l2-contract-checks.md`，
取得本次檢查的項目清單。

### 2. 掃描目標

- 全掃模式：列出 `.athena/skills/*/SKILL.md`（跳過不含 `SKILL.md` 的目錄）
- 單一模式：定位 `.athena/skills/<name>/SKILL.md`
- 指定路徑模式：定位 `<path>/SKILL.md`，並判斷 plugin-internal flag：
  - 路徑開頭為 `.athena/skills/` → 一般 team skill 模式
  - 路徑開頭非 `.athena/skills/`（例如 `skills/...`、絕對路徑） → 視為 plugin-internal，自動套用 `references/l1-static-checks.md` 末段的放寬規則

如果目標不存在，輸出友善訊息建議檢查路徑或先建立 skill。

### 3. 對每個 skill 執行 L1 + L2

#### L1（靜態結構）

依 `l1-static-checks.md` 列表逐項對照：
- frontmatter 必填欄位是否都在
- name 命名是否符合規範
- stage 值是否在合法清單中
- description 是否過短或命中泛詞黑名單

#### L2（契約遵守）

讀取 `l2-contract-checks.md` 中對應該 skill `stage` 值的檢查項目：
- 是否提及「讀取前一個 stage 的 handoff」
- 是否提及「寫入本 stage 的 handoff」
- Flow-inline stage：是否提及 flow context 操作

> L2 採 keyword heuristic（grep SKILL.md 是否含特定字串）。誤判時用 🟡 而非結論性判定。

### 4. 分類結論

依 `mentoring-style.md` 規則，將每項結果分到三段：
- ✅ **做得好**：通過所有客觀規則
- 🟡 **可以更好**：可改善的軟性問題（命中規則但不影響運作）
- 💡 **進階建議**：未來可考慮的強化（如建立 eval cases）

### 5. 套用模板輸出

用 `assets/audit-report-template.md` 的格式輸出對話內容。

### 6.（可選）邀請進入 L4

若團隊尚未在 `.athena/evals/` 建立 test case，輸出一段引導：
「想要更深的檢查？參考 `assets/eval-case-example.md` 建立你的第一個 eval case。」

> 本 skill **不實作 L4 runner**，僅給出範例引導。

## 輸出

純對話內容，依 `audit-report-template.md` 結構：
- Skill 名稱與路徑
- ✅ 做得好（列點）
- 🟡 可以更好（每項附建議改寫）
- 💡 進階建議（可選）

**不寫入任何檔案**。**不輸出機器可解析的 verdict 欄位**（避免被誤用為 CI gate）。

## 與其他 skill 的邊界

| 比較對象 | 差別 |
|---------|------|
| `athena-point` | point 是流程閘門（評估需求要走哪條路），audit 是 skill 品質顧問（檢查 skill 本身寫得好不好） |
| `athena-flow` | flow 編排執行，audit 與 flow 完全解耦，不被 stage discovery |
| `stage-contracts.md` | 那是規格定義，audit 是基於該規格的對照工具 |

## 非協商規則

1. **絕不寫入檔案**：不產出 audit-report.md、不修改 SKILL.md、不建立任何目錄；若使用者要求「匯出報告」，婉拒並建議直接複製對話內容
2. **絕不出現 PASS/FAIL**：禁用詞清單見 `mentoring-style.md`
3. **絕不阻擋 flow / CI**：本 skill 無 gate verdict 概念
4. **誤判用 🟡 而非 ❌**：所有判斷標示為 heuristic 建議，留給人決定
5. **獨立於 stage 系統**：本 skill 不宣告 `stage` 欄位，不被 flow discovery
6. **不主動修復**：發現問題只給建議，不主動 edit 別人的 skill
