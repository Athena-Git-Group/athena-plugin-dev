# Athena Dev Plugin

## Non-Negotiable Rules

1. **Any code change must go through `/athena-point` first.**
   Do NOT implement code changes directly based on your own complexity assessment.
   The point skill exists to objectively evaluate complexity and route the task —
   that is its job, not yours. Even if the task looks trivial, run point first.
   The flow has a Minimal path (PASS-TRIVIAL) for truly simple tasks, so overhead is low.

   This rule is enforced by a `PreToolUse` hook (`hooks/require-point.sh`):
   missing `points/*.md` will block `Edit` / `Write` / `MultiEdit`. See the
   README "強制規則" section for scope, self-protection paths, and escape hatches.

2. After point evaluation, follow the verdict:
   - `PASS-TRIVIAL` / `PASS-DIRECT-BUILD` / `PASS-BUILD-WITH-VERIFY` → `/athena-flow`
   - `PASS-SPEC-FIRST` → `/athena-flow`

3. The only exceptions where you may skip point:
   - User explicitly says "don't run point" or "just do it"
   - The change is purely non-code (documentation, comments, config formatting)
   - The change touches only self-protected paths (`hooks/`, `commands/`,
     `.claude-plugin/`, `points/`, `handoffs/`, `.claude/`, `.athena/`)
