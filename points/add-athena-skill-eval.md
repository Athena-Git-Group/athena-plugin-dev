# Point Result

- Report path: `points/add-athena-skill-eval.md`
- Summary: 新增 athena-skill-eval plugin 內建 skill — L4 動態評估 runner（獨立於 audit）。給 skill 餵 case → spawn fresh general-purpose subagent 真實執行目標 skill（cwd = temp dir 隔離）→ mechanical/semantic 混合評分（mechanical 用 grep/Read 機械比對；semantic 用第二個 sub-agent LLM judging）→ 三段式對話輸出（✅/🟡/💡，無 PASS/FAIL）。Case 格式擴充 frontmatter 與 `[mechanical]`/`[semantic]` 前綴標記。第一版單 case 執行；批量、持久化、跨團隊 benchmark 留 v2。Phase 0 需先 spike 驗證 plugin skill 能透過 Agent tool spawn sub-agent。
- Knowledge base needed: no
- Knowledge sources consulted: none（`.athena/knowledge/` 不存在於本 plugin repo；任務純技術不依賴業務規則）
- Route: Direct Build
- Gate verdict: `PASS-DIRECT-BUILD`
- Allowed next commands: `/build`
- Required follow-up gates: `/review` → `/ship`

## Scorecard

- Requirement clarity: 1/5
- Domain rule complexity: 1/5
- Impact radius: 1/5
- Contract/schema change: 1/5
- Regression risk: 2/5
- Knowledge dependency: 0/5
- Total: 6/30

## Why

- **Requirement clarity 1**：經過 /plan-work + 三輪 Q&A 對齊（Q1=A spawn agent / Q2=B 獨立 skill / Q3=C 混合評分）+ 具象範例（typo-fix case）+ mechanical/semantic 區分驗證理解。Scope 邊界明確（單 case 執行、純對話輸出、不持久化）。少量細節（semantic rubric 具體 prompt、mechanical check 函式庫）留給 build，但不影響開工。
- **Domain rule complexity 1**：plugin meta-tool，無業務規則 / 權限 / 計費 / 合規。需熟悉的「domain」是 plugin 內既有契約（skill-metadata-spec、stage-contracts）+ Claude Code Agent tool 用法 — 後者屬技術文件，前者已成文於 plugin repo。
- **Impact radius 1**：8 個新檔（新 skill 目錄）+ 3 個小修改（audit SKILL.md 加 💡 引導句、audit mentoring-style.md 微調、README 加章節）+ 1 個刪除（audit 的 eval-case-example.md 搬遷）。屬單層多檔案，不跨模組、不跨前後端。
- **Contract/schema change 1**：定義新的「eval case file 格式」（frontmatter `eval-case-version: 1` + `[mechanical]`/`[semantic]` 標記）— 這是給下游團隊的新契約。但是純文件契約，不動 stage-contracts.md / skill-metadata-spec.md / API / schema。
- **Regression risk 2**：新 eval skill 無 `stage` 欄位、不被 flow discovery、獨立執行 — 對 flow / 既有 stage skill 零影響。次要風險來自：(a) audit SKILL.md 的小修改可能微調 audit 行為；(b) Phase 0 unknown（plugin skill 透過 Agent tool spawn sub-agent 是新 capability，不通則需重設計）；(c) sub-agent 執行行為面（timeout、檔案系統污染）為新風險面。
- **Knowledge dependency 0**：純技術任務，所需資訊全部在 plugin repo + Claude Code 工具文件可查。

**為什麼不用 spec**：總分 6/30 落 Direct Build 區間（0-7）；無 override（所有維度 ≤ 2）；無 hard stop（無 schema/API/業務規則改動）；scope 已在 /plan-work 階段明確界定（含三決策點 + 具象範例對齊）；新 case 格式雖是「契約」但是文件級別不是 runtime contract。直接進 build 合理。

## Risks

- **Phase 0 spike 不通**：若 plugin skill 不能透過 Agent tool spawn sub-agent，整個 v1 設計需改回 Q1-C（manual prompt 模式）。緩解：build 第 1 步先做 spike，失敗即停下重議。
- **Mock 環境污染目標 repo**：sub-agent 跑 build skill 真去 edit 檔案時，若 cwd 設定不確實，可能寫到使用者真實檔案。緩解：Executor prompt 強制 `cd <temp_dir>` + 警告 sub-agent 不可用 absolute path 寫入。
- **Sub-agent timeout / 失控**：build skill 執行可能很長。緩解：case 寫時建議加 `expected_max_steps`；Executor 設超時上限（如 5 分鐘）。
- **LLM 主觀評分不穩定**：semantic 評分可能跑兩次給不同結果。緩解：rubric prompt 提供具體判準（不是開放問題）；接受 ~80% 一致性作為 v1 目標。
- **Case 格式 v1 訂錯**：未來改格式破壞舊 case。緩解：frontmatter `eval-case-version: 1` + runner 認版本選 parser，留升級空間。
- **既有 audit 的 eval-case-example.md 已被使用者參考**：搬遷後舊路徑失效。緩解：在 README 與 audit SKILL.md 加 redirect 註記。
- **Build 階段觸到 plugin meta 場景的 flow 限制**：與上次 audit 一樣，`.athena/skills/` 不存在於 plugin repo，flow 無法跑。處理方式：跳過 flow，直接 build（按上次同模式）。
