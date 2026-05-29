# GitHub Actions Conventions

## File naming

- Templates: `kebab-case.yml` matching the consumed name (`ci-node.yml`).
- Composite folders: `kebab-case/`.
- `templates/<name>.yml` ↔ `.github/workflows/<name>.yml` MUST share the same basename.

## Template anatomy

```yaml
name: CI (Node)
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: "22"
    secrets:
      NPM_TOKEN: { required: false }

permissions: {}

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  ci:
    runs-on: ubuntu-24.04
    timeout-minutes: 20
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck && pnpm lint && pnpm test
```

## Rules

- Every job declares `runs-on` first, then `timeout-minutes`, then `permissions`, then `steps`.
- Prefer `npm ci` / `pnpm install --frozen-lockfile` / `yarn install --immutable`.
- Cache via the official cache key on the lockfile (`actions/setup-node` `cache: pnpm` handles this).
- `concurrency:` on every CI-style workflow to dedupe rapid pushes.
- Set `timeout-minutes:` on every job. Default 20 minutes; bump explicitly when justified.
- Use `matrix:` only for stable, additive inputs (Node versions, OSes). NEVER for tenant-specific values.
