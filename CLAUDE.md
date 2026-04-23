# Athena Dev Plugin

## Non-Negotiable Rules

1. **Any code change must go through `/athena-dev-plugin:athena-point` first.**
   Do NOT implement code changes directly based on your own complexity assessment.
   The point skill exists to objectively evaluate complexity and route the task —
   that is its job, not yours. Even if the task looks trivial, run point first.
   The flow has a Minimal path (PASS-TRIVIAL) for truly simple tasks, so overhead is low.

2. After point evaluation, follow the verdict:
   - `PASS-TRIVIAL` / `PASS-DIRECT-BUILD` / `PASS-BUILD-WITH-VERIFY` → `/athena-dev-plugin:athena-flow`
   - `PASS-SPEC-FIRST` → `/athena-dev-plugin:athena-flow`

3. The only exceptions where you may skip point:
   - User explicitly says "don't run point" or "just do it"
   - The change is purely non-code (documentation, comments, config formatting)
