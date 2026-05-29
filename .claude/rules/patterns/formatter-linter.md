# Formatter & Linter

Orbit is a catalog of reusable GitHub Actions workflows + composite actions.
It is **YAML + bash**, not application code, so the tooling is unusual:

| Concern | Tool |
|---------|------|
| YAML schema validation | None automated — rely on `actionlint` locally if installed |
| Bash style | Hand-reviewed; prefer `set -euo pipefail` in every script |
| Tests | Bash test files in `tests/*.test.sh` (regression catch on real workflow text) |
| Pre-commit | `.githooks/pre-commit` runs every `tests/*.test.sh` |

There is **no Biome, no ESLint, no Prettier** in Orbit. Do not introduce them
without an explicit ticket — the project intentionally has no Node.js codebase.

## Pre-commit hook

`.githooks/pre-commit` is not enabled by default — each clone must opt in:

```bash
git config core.hooksPath .githooks
```

The hook iterates over `tests/*.test.sh` and aborts the commit on any failure.
**Never** `--no-verify`, `HUSKY=0`, `GIT_SKIP_HOOKS=1`.

## Tests are regression catchers

Existing tests (e.g. `ci-electron-workflow.test.sh`,
`eas-publish-workflow.test.sh`) grep the live YAML for invariants that previously
broke production (Electron cache busting, EAS auth wiring, …). When you change a
template, run the matching test by hand:

```bash
bash tests/ci-electron-workflow.test.sh
```

If you change a template in a way that intentionally breaks an invariant, **update
the test in the same commit**. Don't disable it.

## Adding a new test

Each test file:
- Lives in `tests/<workflow>-<concern>.test.sh`.
- Starts with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Greps `templates/<file>.yml` (and the mirror under `.github/workflows/`) for the
  invariant.
- Exits non-zero on failure with a descriptive `echo` to stderr.

## YAML style guidelines

- 2-space indent, no tabs.
- `kebab-case` input names, `UPPER_SNAKE_CASE` secrets.
- Pin every third-party action to a major version tag (`actions/checkout@v5`),
  never `@main` / `@latest` / a floating SHA.
- Top-level `permissions:` clause stating the minimum needed.
- Job ids in `kebab-case` matching their purpose (`build`, `notarize`,
  `publish-pages`).

## Bash style guidelines

- `set -euo pipefail` at the top of every script.
- Quote every variable: `"$VAR"`, not `$VAR`.
- Use `${VAR:-default}` for optional inputs.
- Echo human-readable progress lines so the GitHub Actions log is debuggable.
- Use `jq` for JSON, never hand-rolled greps.
