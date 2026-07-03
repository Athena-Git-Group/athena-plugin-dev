# athena-dev-plugin 品質檢測報告

- 日期：2026-07-03
- 分支：`feature/main_feedback_channel_v1`（HEAD `cd754b8`）
- 方法：5 個 fresh-context agent 平行分維度審查（發布面 / hooks / flow 語意 / Loop 2b·3 / 文件·eval）＋ repo 自帶 `scripts/lint-plugin.sh`
- 性質：**只檢測、未修改任何檔案**

## 檢測範圍與極限（誠實條款）

- **實測到位**：`hooks/require-point.sh` 以 macOS bash 3.2 餵 6 組輸入實跑、看 exit code；`.athena/traces/` 的 dogfood JSON 實際 parse；lint 腳本實跑。這些 finding 信心最高。
- **靜態一致性審查**：flow / point / loop 的語意問題來自跨檔契約比對，agent **沒有真的端到端跑一次 flow**（需要 consumer 專案與真實任務）。這些 finding 是「照文件執行會斷」的推論，信心高但未經執行驗證，已逐條標注可驗證方式。
- **補不了的部分**：skill 指令的「品味級模糊」（好不好讀、抽象是否得當）只能點出最模糊的幾條，無法窮舉；需要人工或更強模型把關。

---

## 結論摘要

| 嚴重度 | 數量 | 一句話 |
|--------|------|--------|
| BLOCKER | 8 | 會讓對應路徑「實際跑斷」或安全閘門「實際可繞過」 |
| MAJOR | 15 | 會造成弱模型混亂、誤路由、或迴圈失控 |
| MINOR | 12+ | 一致性/漂移/死碼，不阻斷但累積成噪音 |

**最重要的三個系統性判斷：**

1. **`require-point` 是「軟提醒」不是「安全邊界」。** 三條旁路實測可繞過（路徑穿越、自鑄鑰匙、Bash 寫檔），且畸形輸入 fail-open。若團隊把它當強制閘門依賴，這是認知落差；建議重新定位為「提醒」，或補正規化＋內容驗證。
2. **README／文件已落後實作一個 feature branch。** feedback、codemap 等新功能存在但沒進表格，design doc 還寫「draft 尚未實作」但其實全落地了。「三處表格手動同步」的漂移風險已兌現——應納入 lint。
3. **eval 自我改進鏈是「規格漂亮、自家範例跑不動」。** 唯一 dogfood eval case 不符自家 spec、skill-eval 解析不到 plugin 內建 skill、hill-climb 的 watermark 會吃掉遲到回饋。三圈閉環的「學習臂」目前無法自我 dogfood。

---

## BLOCKER（8）

> 修復優先序建議：B4、B5 先修（最省力、直接讓 flow 主幹跑得動）→ B7、B8（讓 eval 能自測）→ B6（feedback 核心價值）→ B1–B3（安全閘門，需決定定位）。

### B1 · require-point 路徑穿越可繞過閘門 〔hooks · 已實測〕
`hooks/require-point.sh:65-75` — case glob 不做路徑正規化。實測 `Write $CWD/hooks/../src/main.py` → **exit 0（放行）**，因為字串命中 `"$CWD"/hooks/*`。任何 `保護目錄/../src/x` 都能繞過。
**修法**：比對前先 `realpath` 正規化，或直接拒絕含 `/../` 的路徑。

### B2 · 可自鑄 points 檔永久開鎖 〔hooks · 已實測〕
`hooks/require-point.sh:71` — `points/**` 在自我保護清單內。實測先 `Write points/fake.md`（exit 0），此後 gate 對整個專案放行。agent 可自己造一把鑰匙。
**修法**：`points/` 只允許 point subagent 寫入；或驗證檔案內容含合法 verdict 欄位才算數。

### B3 · Bash 寫檔完全不經 gate 〔hooks〕
`hooks/hooks.json:5` — PreToolUse matcher 只含 `Write|Edit`（+MultiEdit/NotebookEdit），**不含 Bash**。heredoc / `tee` / `sed -i` 寫 `src/` 完全不觸發閘門。
**修法**：至少在 README 強制規則章節明示此 gap；或加 Bash matcher 偵測寫入 pattern。

### B4 · point 報告模板缺 PASS-TRIVIAL，Minimal 路由不可達 〔flow〕
`skills/athena-point/assets/point-report-template.md:10-11` — Route/Gate verdict 枚舉沒有 `Trivial` / `PASS-TRIVIAL`，而 `agents/athena-point.md:60` 強制報告必須符合此模板。弱模型照抄模板 → 永遠發不出 PASS-TRIVIAL → Minimal 快速路徑形同不存在（諷刺的是這條路徑正是 repo CLAUDE.md 用來說服人「跑 point 開銷很低」的依據）。
**修法**：把 `Trivial | …` 與 `PASS-TRIVIAL` 加回模板兩行枚舉。
**可驗證**：對一個一行字修改跑 point，看能否產出 PASS-TRIVIAL。

### B5 · 步驟 10-L 要開的 review-ship 殼不存在 〔flow〕
`skills/athena-flow/SKILL.md:48,249` — 步驟 10-L 要開 review-ship 合併 agent，但 `agents/` 沒有 `athena-stage-review-ship.md`；而 :48 又指示一律用 `Agent(subagent_type: "athena-stage-<stage>")`。弱模型會拼出不存在的 subagent_type，或退回無 tool 邊界的 generic agent。
**修法**：新增 review-ship 殼；或 10-L 明寫「用 `athena-stage-ship` 殼並在 prompt 附 review skill」。

### B6 · hill-climb watermark 排除遲到回饋，掏空 feedback channel 〔Loop 3 · dogfood 已命中〕
`skills/athena-hill-climb/SKILL.md:42-46` — Collect 只取 watermark 之後的 run 再 JOIN feedback。但「retro 過後才到的回饋」（post-ship defect 最常見的時序）指向的是 pre-watermark 的舊 run，永遠不進視野。與 `athena-feedback/SKILL.md:78`「任何過去的 run 都能補回饋」直接矛盾。
**修法**：feedback 以自身 `ts` 另設 watermark；late feedback 把被指向的 run 拉回本輪窗口。

### B7 · 唯一 dogfood eval case 不符自家 case-spec 〔eval〕
`.athena/evals/point-cases/example-trivial.md` — 缺必填 frontmatter（`eval-case-version`、`target-stage`），段落結構是 Input/Expected Behaviour/Criteria 而非規定的 Setup/Task/Expected/Anti-patterns。依 `case-spec.md:132-140`，runner 必須「不執行、提示補齊」。且該檔 :64 自稱「format follows case-spec.md」為不實。（另注意：實際目錄是 `.athena/evals/point-cases/`，非某些文件寫的 `.athena/point-cases/`。）
**修法**：照 `assets/case-template.md` 重寫。

### B8 · skill-eval 解析不到 plugin 內建 skill，CONTRIBUTING 範例指令跑不動 〔eval〕
`skills/athena-skill-eval/SKILL.md:56-70` — 目標 skill 只從 `.athena/skills/<name>/` 解析、case 目錄由 frontmatter `stage` 推斷。但 `athena-point` 在 `skills/`（非 `.athena/skills/`）、無 `stage` 欄位、`point` 也不在 target-stage enum。`CONTRIBUTING.md:56` 的 `/athena-skill-eval athena-point example-trivial` 照 SKILL.md 走到第 2 步就卡死。
**修法**：SKILL.md 加 plugin-internal fallback 路徑；case-spec 增列 `point` stage。

---

## MAJOR（15）

### 發布面
- **M1 · marketplace repo URL 會 404**〔兩 agent 交叉確認〕 `.claude-plugin/marketplace.json:18` 寫 `athena-dev-plugin`，但 plugin.json:7、git remote、README:137 都是 `athena-plugin-dev.git`。→ 統一為 `athena-plugin-dev`。
- **M2 · README 表格漂移**〔兩 agent 交叉確認〕 Skills 表（README:41-54）漏 `athena-feedback`；Slash Commands 表（:56-66）漏 `/codemap`；內建參考 Skills 表（:365-369）漏 `athena-composition-analysis` / `athena-form-activity` / `athena-form-bdd-analysis` / `athena-form-feature-spec`。→ 補列，並把「表格同步」納入 `lint-plugin.sh`。

### hooks（require-point 定位問題群）
- **M3 · gate 語意過寬**〔已實測〕 `require-point.sh:78-83` — 實質是「專案史上存在過任一 `points/*.md`」，第一份報告之後永不再擋，遠寬於「本次變更有跑 point」。→ 改比對變更 slug，或明示這是設計上限。
- **M4 · fail-open**〔已實測〕 `require-point.sh:30` — `set -euo pipefail` 下 jq 對畸形輸入非零退出，腳本以 exit 5 收尾；harness 只把 exit 2 當 block，其餘=放行。→ 畸形輸入應明確 exit 0（或視安全需求 exit 2），並避免 pipefail 誤殺。
- **M5 · 自我保護清單三方不一致** `require-point.sh:65` vs `README:291` vs repo `CLAUDE.md` 例外清單 — 三處對「哪些路徑豁免」口徑不同（README 自承 agents/、scripts/ 未納入是 known gap）。→ 三方對齊。

### flow 語意
- **M6 · Lightweight 路由漏 verify** `athena-flow/SKILL.md:183` — skill 檢查清單只列 build+review+ship，漏了 `PASS-BUILD-WITH-VERIFY` 必經的 verify；discovery 放行後會在 verify stage 中途斷。→ 拆成「DIRECT-BUILD: build+review+ship / BUILD-WITH-VERIFY: 再加 verify」。
- **M7 · 硬性 Gate 無目標 verdict** `athena-point/SKILL.md:124-132` — 只說「不得直接進 build」，未指定命中後發哪個 verdict；且 PASS-BUILD-WITH-VERIFY 本身也是直接進 build，字面自相矛盾；contract=3 分會命中 gate 但 override(≥4) 不觸發，總分 5-7 時路由懸空。→ 為五條 gate 各標目標 verdict。
- **M8 · review verdict 詞彙三套打架** `agents/athena-stage-review.md:35`（PASS/REQUEST-CHANGES，不用 FAIL）vs `agent-handoff.md:33-39`（只有 PASS/FAIL 且 FAIL 必附 taxonomy tag）vs `flow/SKILL.md:257`（FAIL(request-changes)）。emit-trace 的 `stages[].gate` 無法判定。→ 統一 FAIL＋`#tag`，request-changes 只當原因字串。

### Loop 2b（trigger-dispatch）
- **M9 · in_flight 無 TTL 永久封鎖** `event-triggers.md:117` — 靠「flow 完成通知」清除、無逾時；flow crash 後該 slug/branch 被 single-flight 永久鎖死。→ 加 `started` 逾時（如 24h）自動標 stale。
- **M10 · state.json 損壞行為未定義** `event-triggers.md:142` — 只定義「不存在=空」，半寫入/壞 JSON 未定義；遺失即全部事件當新事件，對 `auto-*` trigger 等於重派已處理事件。→ parse 失敗走備援副本或重建，並強制該輪全 registry 降級 `notify`。
- **M11 · dedup 換 id 重觸發＋auto-full 無界修復迴圈** `event-triggers.md:38` — dedup 鍵 `run-<databaseId>`，同根因換新 commit/rerun 即再觸發；`auto-full`（修→push→CI 又紅→再修）無嘗試上限。→ per-branch attempt cap + backoff + 失敗 fingerprint 級 dedup。
- **M12 · auto-full 對 hill-climb intake 語意錯誤** `trigger-dispatch/SKILL.md:55-56` vs `event-triggers.md:87` — `auto-full` 一律「呼叫 /athena-flow 跑完整流程」，但 hill-climb intake 應直呼 skill；`triggers.example.yml:32` 用「retro 不改 code」正當化 auto-full，若照 SKILL.md 走 flow 就可能真的改 code 並 push。→ 明定 `intake: hill-climb` 繞過 flow 直呼 skill。

### Loop 3（hill-climb）
- **M13 · re-point 覆寫 points/，違反唯讀宣稱** `hill-climb/SKILL.md:56`、`references/hill-climb.md:100` — 「拿歷史 intake 重新 point」會經 athena-point 寫 `points/<slug>.md`，同 slug 覆寫原始 report，違反規則 6「只寫 proposal/metrics/state/regression」。→ re-point 輸出到 `.athena/hill-climb/` 下的 re-score 檔或 dry-run。
- **M14 · 退步 gate 缺 baseline 欄位，不可執行** `references/hill-climb.md:150` vs `:180-192` — gate 要求「不低於上輪 baseline」，但 metrics.jsonl schema 只有 `regression_set_size`、無 `regression_pass_rate`，baseline 無處可讀。→ metrics.jsonl 增列 `regression_pass_rate`。
- **M15 · taxonomy×metric gap（dogfood 已命中）** `references/hill-climb.md:196-208` — `outcome=done`（非 shipped）的 run，其 post-ship-defect 回饋進 `by_kind` 卻因分母只算 shipped 而 rate=null。→ 分母擴為 `shipped ∪ done`，或對 done run 拒收該 kind。

---

## MINOR（精選）

- **文件狀態漂移**〔兩 agent〕 `docs/design/loop-engineering-design.md:3` 仍寫「draft 尚未實作」，但 §8 改動清單 ①②③ 全落地。→ 改「已實作」附落點。
- **lint 死碼＋不可攜語法** `scripts/lint-plugin.sh:62-79` `check_frontmatter` 從未被呼叫且含壞插值；`:73-74` `${arr[@]@Q}` 是 bash 4.4+ 語法，macOS bash 3.2 會噴 error（CI 用 GNU bash 4+ 才無虞）。→ 刪死碼、換可攜寫法。
- **skill-audit 自我矛盾** `athena-skill-audit/references/l2-contract-checks.md:57` 把「flow-inline 提到 handoffs/」標為錯誤訊號🟡，但自家 `athena-post-build/SKILL.md:34-38` 合法讀 build handoff → plugin 自己的 skill 過不了自家 audit。→ 改成「**寫入** handoffs/ 才是錯誤訊號」。
- **auto-commit 守衛缺失** `hooks/auto-commit.sh:100,127` `git add -A` 未檢查 `.git/MERGE_HEAD` / detached HEAD，可能把 staged 外髒檔一併 commit。→ 加 in-progress-merge 與分支狀態守衛。
- **CLAUDE.md hook 敘述不準** repo `CLAUDE.md:12-13` 說 hook 只擋 Edit/Write/MultiEdit（實含 NotebookEdit），且指向不存在的「強制規則」章節（實名「Hooks 機制」README:270）。→ 修工具清單與章節名。
- **觸發詞互搶**〔發布面〕 `athena-audit-requirement-backend/frontend` 共用「PM 需求 audit」（未指定視角無消歧）；`athena-skill-audit`（「檢查 skill」）與 `athena-skill-eval`（「動態檢查 skill」）子字串碰撞；`athena-feedback` 觸發詞「回饋/feedback/覆蓋率太低」過寬。→ 加錨定詞消歧。
- **schema 必填欄位漏列** `athena-flow/SKILL.md:285-287` 步驟 12.a 欄位清單漏 `run_id`/`slug`/`ts`（run-trace.md:36-38 必填）。→ 補進列舉。
- **GC 歧義風險** `agent-handoff.md:244-247` 把 point-report 算進 handoff，GC 說「刪該 slug 所有 handoff」，弱模型可能連 `points/<slug>.md` 一起刪（觸發 require-point 誤鎖）。→ 明寫「只刪 handoffs/，points/ 永不刪」。
- **LICENSE 缺失** plugin.json:8 / marketplace.json:19 宣告 MIT 但無 LICENSE 檔。→ 補檔。
- **README 首句 pipeline 漏 verify**（README:3）；point 欄名 `consulted` vs `checked` 不一致（point/SKILL.md:144 vs 模板:6）；verify 殼「測試報告產物」無路徑約束（stage-verify.md:28）；四 manifest 入口只顯式宣告 2 個（plugin.json:8）。

---

## 亮點（值得保留，別在修 bug 時弄壞）

- **hook 與 README「強制規則」敘述罕見地誠實**：README:291 主動標注 agents/scripts 未保護是 known gap，沒有粉飾。
- **schema 三方對齊度高**：runs.jsonl / feedback.jsonl / hill-climb Collect 的 JOIN 鍵 `run_id` 型別一致、dogfood 資料實際 JOIN 得起來。
- **門檻數字全 repo 一致**：≥5 / 15–30 / 0.8 / ≥3 / 270s 等跨 SKILL.md·references·specs 無漂移。
- **retry/gate/GC 都有終止條件與非協商規則護欄**：phase retry 2 輪、verify↔rebuild 2 輪、ship 失敗即停交還使用者，無無界迴圈（trigger-dispatch 的 auto-full 例外，見 M11）。
- **hill-climb 人工 gate 夠硬**：「絕不自動改 system」大體守得住，只有 re-point 與 skill-eval 隔離兩條範圍外寫入的縫（M13）。

---

## 建議的修復批次（供派工參考）

1. **批次一「讓主幹跑得動」**（純文件、低風險）：B4、B5、M6、M7、M8、M15。改的是 SKILL.md/模板的枚舉與路由描述。
2. **批次二「讓 eval 能自測」**：B7、B8、M13、M14。修好後 plugin 能對自己跑 eval，後續改動有回歸保護。
3. **批次三「dispatcher 安全」**（開 auto-* autonomy 前必做）：M9、M10、M11、M12。
4. **批次四「閘門定位決策」**（需使用者拍板）：B1–B3、M3–M5。先決定 require-point 是「提醒」還是「安全邊界」，再決定投入多少。
5. **清潔批次**：M1、M2＋MINOR 群，並把「README 表格同步」與「command↔skill 對應」加進 lint。
