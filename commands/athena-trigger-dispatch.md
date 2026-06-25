---
description: Athena 事件驅動觸發層（Loop 2b）— 輪詢 CI / PR review / cron / inbox，命中時製造 intake 呼叫 /athena-flow
argument-hint: "[once | 留空 = 持續監看]"
---

Invoke the `athena-trigger-dispatch` skill to run the event-driven trigger layer.

行為：讀 `.athena/triggers.yml`，唯讀探測各 source，命中時依 autonomy（預設 notify）製造 intake 並走 `/athena-flow`。內建 dedup、single-flight、cache-aware 排程與 handoff housekeeping。**事件層不繞過 point、不自己改 code。**

- 持續監看建議：`/loop /athena-trigger-dispatch`
- 純時間觸發（如 nightly retro）：用 `/schedule` 建 cron routine 呼叫

Mode / 參數：

$ARGUMENTS
