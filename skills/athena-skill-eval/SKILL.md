---
name: athena-skill-eval
description: >
  L4 動態評估 runner — 給 skill 餵 eval case，spawn fresh sub-agent 真實執行目標 skill，
  混合 mechanical / semantic 評分，回報 ✅/🟡/💡 三段式對話結果。獨立於 audit 與 flow，
  team 主動觸發。當使用者說「跑 eval」、「測 skill 行為」、「skill regression test」、
  「eval my skill」、「run eval cases」、「動態檢查 skill」時觸發。
user-invocable: true
---

# Athena Skill Eval

L4 動態評估 runner — 對 skill 進行「行為測試」。

## 定位（非協商）

- **離線回歸測試工具**：給 skill 作者自己跑，不是 CI gate
- **獨立於 audit / flow**：不被 stage discovery，與其他 skill 解耦
- **唯讀目標**：絕不修改目標 skill 或下游團隊任何檔案；mock 操作全在 temp dir
- **無 PASS/FAIL**：沿用 audit 的輔導風格，輸出 ✅/🟡/💡

> 與 `athena-skill-audit` 的分工：audit 看 SKILL.md 寫得好不好（靜態 L1+L2），
> eval 看 skill 跑出來對不對（動態 L4）。兩者互補。

## 先讀哪些檔

每次執行前依序讀取：

1. `references/case-spec.md` — eval case 檔案格式契約
2. `references/executor-protocol.md` — sub-agent spawn 規範
3. `references/grader-protocol.md` — mechanical / semantic 評分機制
4. `references/mock-environment.md` — temp dir 隔離規範
5. `assets/eval-report-template.md` — 對話輸出模板

## 何時使用

- 你改了 skill 的 prompt，想確認行為沒退化（regression test）
- 新人接手 skill，想用 case 文件理解「該 skill 應有什麼行為」
- 比較同一 stage 兩個版本的 skill（A/B）
- 上線前 sanity check

## 輸入

```
/athena-dev-plugin:athena-skill-eval <target-skill> <case-name>
```

範例：

```
/athena-dev-plugin:athena-skill-eval crs-build-impl typo-fix
```

| 參數 | 說明 |
|------|------|
| `<target-skill>` | 要被測試的 skill 名稱（位於 `.athena/skills/<target-skill>/`） |
| `<case-name>` | case 檔名稱（不含 .md，位於 `.athena/evals/<stage>-cases/<case-name>.md`） |

`<stage>` 從目標 skill 的 frontmatter `stage` 欄位推斷（決定 case 從哪個目錄找）。

第一版只支援單 case 執行；批量、持久化結果、跨團隊 benchmark 留 v2。

## 執行流程

### 1. 載入規則
讀取上述 5 個 reference / asset 檔，掌握 protocol 與模板。

### 2. 解析輸入
- 從 `.athena/skills/<target-skill>/SKILL.md` 讀 frontmatter，取 `stage` 值
- 從 `.athena/evals/<stage>-cases/<case-name>.md` 讀 case 檔
- Case 檔不存在 → 輸出引導訊息（指向 `assets/case-template.md`）

### 3. 驗證 case 格式
依 `case-spec.md` 規則檢查：
- Frontmatter 完整（`eval-case-version`, `target-stage`）
- Setup / Task / Expected / Anti-patterns 段都在
- Expected / Anti-patterns 列表每條都有 `[mechanical]` 或 `[semantic]` 前綴

格式有問題 → 輸出 🟡 提示，**不執行 eval**。

### 4. Phase A：建立 mock 環境
依 `mock-environment.md`：
- `mktemp -d` 建立隔離 temp dir
- 把 case Setup 描述的 mock files 寫入 temp dir
- 記錄 temp dir 絕對路徑

### 5. Phase B：Executor — 執行目標 skill
依 `executor-protocol.md`：
- 用 Agent tool spawn fresh `general-purpose` sub-agent
- Prompt 含：目標 skill SKILL.md 絕對路徑、temp dir 絕對路徑、Task 指令、約束清單
- **強制使用絕對路徑**（不依賴 cwd state — Bash 跨 call 不持久，這是 Phase 0 spike 的關鍵啟示）
- 設 timeout 預設 5 分鐘
- 捕捉 sub-agent 最終輸出 + temp dir 內所有產出

### 6. Phase C：Grader — 評分
依 `grader-protocol.md`：
- 對每個 Expected / Anti-pattern criterion 看 `[mechanical]` / `[semantic]` 標記
- `[mechanical]`：用 Bash / Read / grep 在 temp dir 內機械比對（grader 主流程直接做）
- `[semantic]`：spawn 第二個 fresh sub-agent，給它 rubric + criterion + 實際輸出，回 ✓/✗/⚠️ + 一句理由

### 7. Phase D：清理
- `rm -rf <temp_dir>`
- 確認清理完成
- **例外**：sub-agent 違反隔離邊界時保留 temp dir 給人除錯（並在報告中提示）

### 8. Phase E：輸出報告
依 `eval-report-template.md` 格式輸出三段式對話。

## 輸出

純對話內容：
- Case 名稱與目標 skill
- ✅ 達成的 criterion（含 grading 依據）
- 🟡 部分達成（含 Why / What / How）
- 💡 進階建議（如「再加幾個邊界 case」）
- 結尾固定句

**不寫入任何檔案**。**無 PASS/FAIL**。**無數字總分**。

## 與其他 skill 的邊界

| 比較對象 | 差別 |
|---------|------|
| `athena-skill-audit` | audit 是「靜態」檢查 SKILL.md 寫得好不好；eval 是「動態」檢查 skill 跑出來對不對 |
| `athena-flow` | flow 編排執行 skill；eval 在隔離 temp dir 模擬執行 skill |
| `athena-point` | point 是進場閘門（評估需求要走哪條路）；eval 是離線回歸測試 |

## 非協商規則

1. **絕不修改目標 skill 或當前 repo**：所有 mock / 執行 / 產出都在 temp dir
2. **絕不出現 PASS/FAIL**：禁用詞清單參考 `../athena-skill-audit/references/mentoring-style.md`
3. **必須清 temp dir**：除非 sub-agent 違反邊界（保留供除錯），無論成功失敗都 `rm -rf`
4. **Sub-agent 必須用絕對路徑**：Bash `cd` 跨 call 不持久，executor prompt 必須強制此規則
5. **Sub-agent 不可寫入 temp dir 之外**：Executor prompt 強制聲明，違反時報告但不阻擋
6. **單 case 執行**：v1 不支援批量
7. **第一版不持久化結果**：每次跑就丟，無歷史檔案
8. **Anti-pattern verdict 邏輯反轉**：Anti-pattern 沒命中（grader = ✗）才是好事（✅）
