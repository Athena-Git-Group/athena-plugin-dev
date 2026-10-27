# 改動 A：mini-handoff 新增 Timing 區塊

## 現況
`skills/hxde-flow/references/agent-handoff.md:87`
> ## Notes for Next Phase
> [下一個 phase agent 需要的資訊，如實際 API path、schema 細節]

## 問題
phase 耗時無處記錄，hill-climb 無法分析 phase 粒度是否過粗；可追溯到 requirement.md 第 2 段「要能看出每個 phase 花多久」。

## 目標行為
build phase agent 開工第一步與寫 mini-handoff 前各取一次 UTC 時間，寫入 `## Timing` 的 Started At / Ended At 兩行；emit-trace 讀此區塊填入 `phases[].started_at/ended_at`，缺欄位時安靜降級不影響 gate。

## 落點
| 檔案 | 位置 | 動作 |
|------|------|------|
| `skills/hxde-flow/references/agent-handoff.md` | Mini-Handoff 模板 | 新增 |
| `agents/hxde-stage-build.md` | 收尾欄位清單 | 鏡射 |

## 不做什麼
不改 stage 級 handoff 的 Timing 行為；不動 emit-trace 的 schema 欄位名。

## 驗收條件
- [ ] `grep -c 'Started At' agents/hxde-stage-build.md` ≥ 1
- [ ] fresh reader 通讀 agent-handoff.md 與 hxde-stage-build.md，確認欄位清單一致
