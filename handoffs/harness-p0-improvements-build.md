# Handoff: build (lightweight)

## Gate Verdict

PASS — three P0 items implemented; 10 functional smoke tests on the new hook all green; JSON manifests valid; bash syntax OK.

## Files Changed

- `.claude-plugin/plugin.json` (modified) — add `commands` / `hooks` entries
- `CLAUDE.md` (modified) — short-form command names, hook-enforced gate note
- `README.md` (modified) — new "Slash Commands" section + rewritten "強制規則" with hook scope / self-protection / escape hatch
- `commands/athena-flow.md` (new)
- `commands/athena-point.md` (new)
- `commands/athena-skill-audit.md` (new)
- `commands/athena-skill-eval.md` (new)
- `hooks/hooks.json` (new) — `PreToolUse` matcher `Edit|Write|MultiEdit|NotebookEdit`
- `hooks/require-point.sh` (new, executable) — gate enforcer with env-var + marker-file escape hatches and self-protection allowlist
- `skills/athena-flow/SKILL.md` (modified) — phase loop step 8-F.d/e rewritten for foreground vs background parallel modes; +2 non-negotiable rules
- `skills/athena-flow/references/phase-orchestration.md` (modified) — "平行 Phase 執行" now distinguishes foreground vs background, adds TaskCreate progress tracking and conflict-detection ordering caveat; +3 non-negotiable rules

## Smoke Test Result

- `python3 -m json.tool` on both JSON manifests: valid
- `bash -n hooks/require-point.sh`: OK
- Hook functional matrix (10/10 pass):
  1. Non-Edit tool → exit 0
  2. Non-Athena project → exit 0
  3. Athena project, no points → exit 2 (blocks, message correct)
  4. Athena project, with point report → exit 0
  5. `ATHENA_SKIP_POINT_GATE=1` env → exit 0
  6. `.athena/skip-point-gate` marker → exit 0
  7. Target inside `hooks/` (self-protection) → exit 0
  8. Target inside `points/` (self-protection) → exit 0
  9. Real plugin repo cwd (has points/) → exit 0
  10. Mocked empty points dir → exit 2

## Risks / Unresolved Issues

- Hook depends on `jq`; degrades to exit 0 if `jq` missing — silent bypass on stripped-down systems. Acceptable for v1 because Claude Code installs jq by default; document later if it becomes an issue.
- Self-protection list is path-prefix based on `$CWD`. If a user's plugin install path differs from their project path, the prefix match would mis-fire; not a real-world case since hook only runs in cwd.
- Background parallel phase mode is documented but the existing flow agent must actually start using `run_in_background=true`; flow SKILL.md now says so but no consumer team is exercising it yet — verify in real Full Weight run later.
