# Skill 根因確認閘門報告

## 任務資訊

- 處理路徑: `optimize`
- 目標 Skills: `skill-engineering`
- 使用者問題: 優化既有 skill 時，agent 直接提出編排方案，沒有先做根因分析，也不敢刪掉舊流程。

## 預期結果

- 先說清楚使用者真正期待的結果，再回推 skill 為何失敗。
- 在提出編排方案前，先給出可被確認的根因確認閘門分析。
- 若根因在控制平面，允許直接重寫 phase 與刪除舊模組，而不是只做局部修補。

## 現況重演

- 檢視既有 `SKILL.md` 後，發現流程在收斂需求後直接進入 SOP 重建與模組編排。
- 既有流程沒有要求回推問題、沒有強制對齊 expected vs actual，也沒有列出候選刪除項。
- 因此後續提案天然偏向「在既有結構上加東西」，而不是先判斷舊結構是否應被拆掉。

## 落差分析

- 預期流程需要先診斷、再提案；現況流程直接提案。
- 預期要能明確說出根因與改動層級；現況只說要怎麼改，沒有先證明為什麼這樣改。
- 預期要能列出刪除候選項；現況缺少刪除視角，容易疊床架屋。

## 根因

- 根因類型: `Control-Plane Gap`
- 改動範圍: `skill rewrite`
- 失敗原因: 既有 skill 把 optimize 與 create 混成同一條直線流程，缺少 optimize lane 的根因確認閘門，導致所有優化任務都被導向加法式編排。

## 影響範圍

- `skill-engineering/SKILL.md`
- 後續要新增的 RCA template 與 delete-friendly 規則
- 所有依賴 `skill-engineering` 進行既有 skill 優化的使用情境

## 候選刪除項

- 舊版直接從問題跳到編排提案的 phase
- 舊版沒有 delete candidates 欄位的提案格式
- 舊版只允許 derive、沒有 explicit delete 決策的 step 描述

## 確認閘門

請確認以上根因與落差分析是否成立；未收到確認前，停止後續編排提案與檔案修改。
