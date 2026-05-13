# Plugin self-evals

Eval cases for the plugin's own built-in skills. Mirrors what consumer
projects would put under their `.athena/evals/`.

## Why these aren't in the plugin install path

`.athena/` is consumer-project state (knowledge base, evals, escape
markers). When the plugin is installed, `.athena/` is **not** copied
into consumer projects — these files live here only because the plugin
repo eats its own dog food.

## Directory layout

```
.athena/evals/
└── point-cases/
    └── example-trivial.md     # reference case, mechanical-heavy
```

Future cases for `athena-pre-build`, `athena-post-build`, etc. should be
added under their own `<stage>-cases/` folder following the same case
spec.

## CI vs. local

| Layer | Where | Cost | Frequency |
|-------|-------|------|-----------|
| Static lint | `.github/workflows/lint.yml` → `scripts/lint-plugin.sh` | Free | Every PR |
| Mechanical eval cases | `.athena/evals/<stage>-cases/*.md` (mechanical criteria only) | Free | TODO — wire to CI when a CI-side runner exists |
| Semantic eval cases | Same files, `[semantic]` criteria | $$ (spawns sub-agent + LLM judge) | Manual or nightly |

The CI workflow today only runs the static lint. Semantic cases are kept
in the repo as living regression docs; promote them to CI when there's
a runner that can use a service Anthropic API key without leaking it
into PR contexts from forks.
