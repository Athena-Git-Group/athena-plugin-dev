---
description: Athena 自我改進迴圈（Loop 3）— 讀 Run Trace 找系統性失敗模式，產出改進提案（✅/🟡/💡），人工 gate
argument-hint: "[留空 = 跑 retro]"
---

Invoke the `athena-hill-climb` skill to run a self-improvement retro over accumulated Run Traces.

行為：讀 `.athena/traces/runs.jsonl`，找**系統性**（重複出現）失敗模式，產出對 skill / point rubric / stage contract / team skill / memory 的改進提案，並用既有 `athena-skill-eval` / `athena-skill-audit` 規劃驗證。**一律人工 gate——只提案、絕不自動改 system**；採納的提案走 `/athena-flow`。追蹤 flow-health metrics 看趨勢。

前提：trace 需累積到足量（新 trace < 5 會停）。可由 `nightly-retro` cron trigger 或門檻自動觸發。

$ARGUMENTS
