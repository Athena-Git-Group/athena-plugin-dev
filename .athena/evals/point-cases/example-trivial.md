---
target_skill: athena-point
case_name: example-trivial
description: |
  Reference eval case for athena-point. Sanity-checks that a clearly
  trivial request gets routed to PASS-TRIVIAL with total score ≤ 4
  and the point-report file lands at the expected path.

  This is intentionally a mechanical-heavy case so it can run cheaply
  without burning API budget on semantic grading.
---

# Eval Case: athena-point — example-trivial

## Input

A trivial requirement that should clearly land on PASS-TRIVIAL.

```
Request: 把 README 第一行的 typo "athena-dev-pluign" 改成 "athena-dev-plugin"。
```

## Expected Behaviour

The point skill should:

1. Read its scoring-rubric, knowledge-base-guidelines, gate-rules.
2. Score every dimension at 0 or 1 (typo fix is the textbook trivial case).
3. Output Route = Trivial, Gate verdict = `PASS-TRIVIAL`.
4. Write `points/<some-slug>.md` containing the required fields.

## Criteria

### [mechanical] writes-point-report

After the skill runs, exactly one new file under `points/*.md` must
exist whose path includes a slug derived from the request (e.g.
contains "typo" or "readme").

### [mechanical] gate-verdict-trivial

The written point-report must contain a line matching
`^- Gate verdict: .*PASS-TRIVIAL` (allowing for the backtick-wrapped
form `` `PASS-TRIVIAL` ``).

### [mechanical] total-score-low

The written point-report must contain a Total line whose numeric value
is ≤ 4. Pattern: `^- Total: [0-4]/30`.

### [mechanical] knowledge-base-no

`Knowledge base needed: no` must appear (no knowledge required for a
typo fix).

### [semantic] reasoning-sound (optional, deferred)

Skip during CI. When manually run, a judge sub-agent reads the Why /
Risks sections and confirms the reasoning is consistent with the
trivial nature of a typo fix.

## Notes

- Case format follows `skills/athena-skill-eval/references/case-spec.md`.
- Run via `/athena-dev-plugin:athena-skill-eval athena-point example-trivial`.
- CI runs static lint only (see `.github/workflows/lint.yml`); this
  semantic case is for local / nightly use.
