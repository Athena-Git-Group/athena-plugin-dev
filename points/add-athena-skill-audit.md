# Point Result

- Report path: `points/add-athena-skill-audit.md`
- Summary: 新增 athena-skill-audit plugin 內建 skill — 輔導下游團隊檢查上繳到 .athena/skills/ 的 skill 品質。獨立於 flow（無 stage 欄位，不被 auto-discovery），團隊主動透過 slash command 觸發。第一版實作 L1 靜態結構檢查 + L2 契約遵守檢查，L4 動態 eval 僅放範例引導不實作 runner。輸出為輔導風格對話建議（✅/🟡/💡），不出現 PASS/FAIL 字樣。
- Knowledge base needed: no
- Knowledge sources checked: none（`.athena/knowledge/` 不存在於本 plugin repo，且任務純技術不依賴業務規則）
- Route: Direct Build
- Gate verdict: `PASS-DIRECT-BUILD`
- Allowed next commands: `/build`
- Required follow-up gates: `/review` → `/ship`

## Scorecard

- Requirement clarity: 1/5
- Domain rule complexity: 1/5
- Impact radius: 1/5
- Contract/schema change: 0/5
- Regression risk: 1/5
- Knowledge dependency: 0/5
- Total: 4/30

## Why

- **Requirement clarity 1**：前置 /plan-work 已完成需求釐清與確認，scope 邊界明確（L1+L2 做、L4 只放範例、純對話輸出無檔案產出）。少量細節留給 build 決定（如 description 黑名單具體詞彙）但不影響開工。
- **Domain rule complexity 1**：plugin meta-tool，無業務規則、權限、計費、合規。需熟悉的「domain」是 plugin 自身的 stage contract 規則，已成文於 `skills/athena-flow/references/stage-contracts.md` 與 `skills/athena-core/references/skill-metadata-spec.md`，屬單一可查證來源。
- **Impact radius 1**：新增 1 個 skill 目錄（6 個檔案）+ 修改 1 個 README.md。純加法 + 一處文件，屬單層多檔案，不跨模組。不影響任何現有 skill 執行路徑。
- **Contract/schema change 0**：不新增/修改任何 API、SKILL.md frontmatter spec、stage-contracts.md。
- **Regression risk 1**：新 skill 無 stage 欄位，flow 不會 auto-discovery，無法污染 pipeline。不寫入任何檔案、不修改 `.athena/skills/`。唯一風險是 audit 本身誤判（功能性而非回歸性）。
- **Knowledge dependency 0**：純技術任務，所需資訊全部在 plugin repo 內可查，不依賴外部 PM ticket / 產品規格 / 業務文件。

**為什麼不用 spec**：分數 4/30 遠低於 Spec First 門檻（15）；無 override rule 命中（所有維度 ≤ 1）；scope 已在 /plan-work 階段明確界定，無模糊需求；無新業務規則或 schema 變更需要規格化；已有完整工作分解與檔案清單。直接進 build 是合理的。

## Risks

- L2 契約檢查使用 keyword heuristic（檢查 SKILL.md 是否提及 `handoffs/<slug>-<prev>.md` / `handoffs/<slug>-<stage>.md`），對非標準寫法可能誤判。緩解：誤判時用 🟡 而非 ❌，輸出明示為 heuristic。
- 團隊可能誤把 audit 當 CI gate 用。緩解：SKILL.md 首段、報告 header、所有結論都用「建議」語言；不輸出可機器解析的 verdict 欄位。
- description 品質的客觀規則（字數下限、泛詞黑名單）可能太鬆或太嚴，需 dogfooding 後微調 — 留作 build 階段的 smoke test 觀察點。
- Build 階段需對 plugin 自身內建 skill 跑 audit（dogfooding），若內建 skill 也未通過，要決定是修 audit 規則還是修自家 skill — 這個取捨可能需 build agent 停下確認。
