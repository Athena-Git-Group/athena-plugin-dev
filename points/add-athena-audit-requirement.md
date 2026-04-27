# Point Result

- Report path: `points/add-athena-audit-requirement.md`
- Summary: 新增兩個 plugin 內建 skill — `athena-audit-requirement-backend` 與 `athena-audit-requirement-frontend`，作為 PM 需求文件的「可譯性審計工具」。借用 specformula 的反向推導思想：能否從 PM 文件機械萃取出對應視角的工程原料（後端：entity / api.yml / BDD Examples；前端：activity / 畫面 / actor）。雙產出：(a) 對話中三段式建議報告，(b) 寫入 `requirement-feedback/<slug>-{frontend|backend}.md` 的 PM 澄清問題清單（clarify-loop 風格）。獨立於 /flow，可單獨觸發；不寫機器可解析 verdict。同步更新 README（表格 + 章節，仿 audit / eval 處理方式）。
- Knowledge base needed: no
- Knowledge sources consulted: none（`.athena/knowledge/` 不存在於本 plugin repo；任務純技術，不依賴業務規則）
- Route: Direct Build
- Gate verdict: `PASS-DIRECT-BUILD`
- Allowed next commands: `/build`
- Required follow-up gates: `/review` → `/ship`

## Scorecard

- Requirement clarity: 2/5
- Domain rule complexity: 1/5
- Impact radius: 2/5
- Contract/schema change: 1/5
- Regression risk: 1/5
- Knowledge dependency: 0/5
- Total: 7/30

## Why

- **Requirement clarity 2**：4 個關鍵設計決策已在前一輪 Q&A 對齊（plugin 內建 / 獨立 /audit-requirement / 寫 PM feedback doc / 拆 frontend+backend）。具象參考點明確（specformula 的 8 個 Phase 卡片作為「需要哪些原料」的權威清單，clarify-loop 作為「澄清問題清單格式」的權威風格，audit / eval 作為「三段式無 PASS/FAIL」的輸出風格）。仍有少量細節留給 build：(a) rubric 維度的具體分割（前後端各幾項）、(b) PM feedback doc 的精確 frontmatter 與 section schema、(c) slug 推斷規則（從 PM 文件檔名？標題？user 給定？）。這些可在 build 內部決策不影響開工，但比 skill-eval（1/5）多一層「兩個 skill 視角差異要寫清楚」的不確定，給 2/5。
- **Domain rule complexity 1**：plugin meta-tool，零業務規則 / 權限 / 計費 / 合規。需熟的「domain」是 specformula Phase 結構（已讀完）+ BDD 思想 + clarify-loop 風格 — 全部已成文於 plugin repo / 既有 skills 列表。
- **Impact radius 2**：兩個新 skill 目錄（每個含 SKILL.md + assets/ + references/，估 12-20 個新檔）+ README 兩處修改（表格新增兩列、新章節）+ 可能的 marketplace.json 微調（依 plugin source 是 `./` 應自動掃 `skills/`，預期不動）。不跨模組、不跨前後端、不動 athena-flow / athena-point / athena-core。屬單層多檔案，但檔案數約是 skill-eval（1/5）的兩倍。給 2/5。
- **Contract/schema change 1**：定義新的「PM feedback doc 格式」— 給下游 PM/RD 的新文件契約。但純文件契約，非 runtime；不動 stage-contracts.md / skill-metadata-spec.md / api / DB schema。
- **Regression risk 1**：兩個新 skill 皆無 `stage` 欄位 → 不被 flow Skill Discovery、不參與任何 standard stage / flow-inline stage 路由 → 對既有 flow / point / 其他 skill 零影響。純對話輸出 + 寫 feedback doc，無副作用。比 skill-eval（2/5）更低，因為不需要 spawn sub-agent（不依賴 unknown capability）、無 mock env / cwd 隔離風險。唯一殘餘風險：README 修改可能影響其他章節排版。
- **Knowledge dependency 0**：純技術任務，所需資訊全部在 plugin repo（已讀 specformula / point / flow / audit / eval 的 SKILL.md 與 references）+ Claude Code skill 撰寫慣例（已從本 repo 既有 skill 推導）可查。

**為什麼不用 spec**：總分 7/30 落 Direct Build 區間（0-7）；無 override 命中（所有維度 ≤ 2）；無 hard stop（無 schema/API/業務規則改動，無關鍵歧義 — 4 個設計問題已逐一定案）；scope 已在前一輪 Q&A 明確界定（含具象參考實作 audit / eval / clarify-loop / specformula）。雖然落點數 7 是區間上緣，但任務性質為「新增獨立 plugin 內建工具」，跟 add-athena-skill-eval（6/30）、add-athena-skill-audit 同質，後續走 review-ship 已足夠把關。直接進 build 合理。

## Risks

- **兩個 skill 視角區隔需明確區分，避免變成同一個 skill 換衣服**：後端 rubric 和前端 rubric 的具體題目要明顯不同（後端問 entity / api 邊界 / business rule，前端問 user flow / screen state / actor / 視覺驗收）。緩解：build 時第一步先把兩份 rubric 並列寫出來互相比對；引用 specformula Phase 02-04 vs Phase 01/06/07 的差異作為對照表。
- **PM feedback doc 不能被 PM 看懂則失去意義**：feedback doc 的 audience 是 PM 不是 RD，不能寫成 RD 內部術語（不要說「erm.dbml 推不出來」要說「沒有提到使用者資料要記什麼欄位」）。緩解：build 時為每個 rubric 維度寫「PM-facing 對應問題模板」；參考 clarify-loop 的逐題澄清格式。
- **Slug 推斷規則沒定**：feedback doc 寫到 `requirement-feedback/<slug>-{frontend|backend}.md`，slug 從哪推？build 時需決定（建議：使用者提供時給定，否則由 LLM 從 PM 文件標題推；缺省值 `untitled-<timestamp>`）。
- **與 athena-point 的 Requirement Clarity 維度功能重疊風險**：point 已有 Requirement Clarity 0-5 維度，新工具獨立評分可能讓使用者困惑「為什麼分兩次評」。緩解：在 README 章節 + 兩個 SKILL.md 的 description 中明確劃線 — point 是「對 RD 的工程分流」（低分 → spec），audit-requirement 是「對 PM 的需求驗收」（低分 → 退回 PM）。在新 skill 章節加比較表（仿 audit vs eval vs point 的處理方式）。
- **PM feedback doc 不應被誤用為機器可解析 gate**：跟 audit / eval 同樣風險。緩解：純對話輸出三段式（✅/🟡/💡）+ feedback doc 純自然語言問題清單，不輸出 verdict 或機器可讀分數欄位。
- **README 章節數量膨脹**：加完後 plugin README 的 skill 章節變多（已有 audit、eval，現在再加 audit-requirement-frontend / backend）。緩解：考慮把所有「輔導工具」歸成同一個大章節 H2（如「## 輔導工具」），底下分 H3 子章節，避免 README 平面化失去結構。build 時決策。
- **Plugin meta 場景下 .athena/skills/ 不存在於 plugin repo 自身**：與前兩次相同，flow 無法跑。處理方式：跳過 flow，直接 build（按 add-athena-skill-eval 同模式）。
