# Orbit — Agent Instructions

> Last refreshed: 2026-05-29. Full AI memory: `.claude/CLAUDE.md`.

Catalog of reusable GitHub Actions workflows and composite actions powering CI/CD across the Meteor Factory ecosystem. Historically named "Pipelines" — the README still uses that name.

## Stack

- GitHub Actions YAML (`workflow_call` reusable workflows)
- Bash (in-step scripts, regression tests, pre-commit hook)
- Azure CLI + jq (only inside the `azure-keyvault` composite action)
- No Node build, no `package.json`, no `Makefile`

## Key directories

- `templates/` — **source of truth** for reusable workflows
- `.github/workflows/` — **mirror** of `templates/` (GitHub requires reusable workflows to live here)
- `actions/azure-keyvault/` — composite action that fetches Key Vault secrets and exposes them as env vars or step outputs
- `samples/` — drop-in consumer examples per stack (node, electron, docker, worker, static-site, railway, swift, expo)
- `docs/` — `templates.md` (per-template reference), `azure-keyvault.md`, `getting-started.md`
- `tests/*.test.sh` — plain-bash regression tests run by `.githooks/pre-commit`
- `.githooks/pre-commit` — enable once via `git config core.hooksPath .githooks`

## Critical rules

1. **Edit `templates/` first, then mirror to `.github/workflows/`.** Anything else is invisible to GitHub. The regression tests catch drift — keep them green.
2. **No SemVer yet.** Consumers pin `@main`. Any merge to `main` ships globally; **adding optional inputs is safe, renaming/removing inputs breaks every downstream repo.** Coordinate before breaking changes.
3. **Update `docs/templates.md` and `README.md`** when inputs, secrets, or behaviour change.
4. **Pin third-party actions to major tags** (`actions/checkout@v5`, etc.) — never `@main` / `@latest`.
5. **Minimal `permissions:` block.** Only declare what the workflow actually needs.
6. **No hardcoded secrets.** Always pass via `secrets:` or fetch from a vault at runtime.
7. **`npm ci` / `pnpm install --frozen-lockfile`** — never `npm install` in CI.
8. **Never `git commit --no-verify`.** Fix failing tests at the source — they exist to stop template regressions reaching downstream consumers.

## Self-hosted runner quirks (don't regress)

- `corepack enable pnpm || true` (scoped + tolerate `EEXIST` on shared hosts).
- Remove stale pnpm symlink before `corepack enable`.
- `setup-node` `cache:` is disabled when `matrix.os == 'self-hosted'`.
- Keep the Electron binary cache between runs — wiping it caused socket failures under concurrency.
- Dependency install runs in a 3-attempt loop with 15 s backoff; `node_modules` is wiped between attempts.
- `release-electron.yml` `prepare-release` runs on `[self-hosted, linux]`.

## Conventions

- Template filenames: `kebab-case.yml`. Action directories: `kebab-case/`.
- Workflow `inputs:` — `kebab-case` names with sensible defaults; only mark `required: true` when truly required.
- `secrets:` — `UPPER_SNAKE_CASE` names.
- JSON arrays (e.g. OS matrices) — `type: string` with a JSON-stringified default; consumers use `fromJson(...)`.
- Booleans for feature toggles.
- Artifacts: `retention-days: 1`, `compression-level: 9` (workspace-wide standard).

## Consumer reference

```yaml
jobs:
  ci:
    uses: MeteorFactory/Orbit/.github/workflows/<name>.yml@main
    with:
      ...
    secrets:
      ...
```

Some samples/docs still use the legacy path `MeteorFactory/Pipelines/...` — confirm the canonical GitHub repo before publishing new examples.

## Quick commands

```bash
# Enable the regression-test pre-commit hook (once per clone)
git config core.hooksPath .githooks

# Run every regression test
for t in tests/*.test.sh; do bash "$t"; done

# Run a single test
bash tests/ci-electron-workflow.test.sh
```
