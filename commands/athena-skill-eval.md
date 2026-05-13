---
description: Skill L4 動態評估 — 餵 eval case 給目標 skill，spawn fresh sub-agent 真實執行，混合 mechanical / semantic 評分
argument-hint: <target-skill> <case-name>
---

Invoke the `athena-skill-eval` skill. Load the named eval case from `.athena/evals/<stage>-cases/`, spawn a fresh sub-agent that executes the target skill, capture its output, grade per criterion, and report results in the three-tier advisory format.

Arguments (`<target-skill> <case-name>`):

$ARGUMENTS
