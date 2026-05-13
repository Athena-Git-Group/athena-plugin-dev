---
description: Athena 單一入口流程編排器 — 依 point → spec → plan → build → verify → review → ship 自動串接
argument-hint: <需求敘述 或 ticket 摘要>
---

Invoke the `athena-flow` skill to orchestrate the Athena pipeline for the following request. Each stage must run in a fresh agent and hand off via artifact files; do not skip the skill and execute the pipeline inline.

Request:

$ARGUMENTS
