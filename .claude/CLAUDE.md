# Orbit — AI Memory

> Source of truth for AI assistants. Last refreshed: 2026-05-29.
>
> Note: Historically published under the name **Pipelines**. The folder/project is now **Orbit** in the Meteor Factory workspace; consumers still reference workflows by the GitHub repo path (see "Consumer reference" below). The README and some docs still use the legacy name.

## Identity

- **One-liner:** Curated catalog of reusable GitHub Actions workflows and composite actions powering CI/CD for the Meteor Factory ecosystem (Constellation, Meteor, Singularity, Horizon, Impacts, Flare, Stargate, EventHorizon, Neutron).
- **Stack:** GitHub Actions YAML (`workflow_call` triggers), Bash for in-step scripts, Azure CLI + jq inside the `azure-keyvault` composite action. No Node/TypeScript build — no `package.json`, no `Makefile`.
- **Public entry points** (what consumers pin to):
  - Reusable workflows at `MeteorFactory/Orbit/.github/workflows/<name>.yml@<ref>` (legacy repo name `MeteorFactory/Pipelines/...` also appears in some samples — verify the correct GitHub repo before publishing examples).
  - Composite action at `MeteorFactory/Orbit/actions/azure-keyvault@<ref>`.
  - Pin policy: consumers reference `@main` today. There is **no SemVer release flow yet** — be aware that any change to `.github/workflows/*.yml` immediately ships to every consumer.

## Folder map

```
Orbit/
  templates/                       # SOURCE OF TRUTH for reusable workflows
    ci-node.yml                    # Node CI (lint, typecheck, test, build) — multi-OS, npm/pnpm
    ci-electron.yml                # Electron CI (macOS + Windows) with self-hosted retry logic
    release-electron.yml           # Electron release: macOS sign+notarize, Win x64, Linux x64
    release-swift.yml              # Swift macOS app: universal binary, DMG, sign+notarize
    release-worker.yml             # Cloudflare Worker deploy + optional Newman integration tests
    deploy-pages.yml               # GitHub Pages deploy (same-repo)
    deploy-pages-external.yml      # GitHub Pages deploy to a different repo (cross-repo, App-auth)
    deploy-railway.yml             # Railway CLI deploy + optional health wait
    docker-build.yml               # Buildx + metadata-action + GHA cache, push on non-PR events
    eas-publish.yml                # Expo: `eas update`, `eas build`, or both
  .github/workflows/               # COPIES of templates/ (GitHub requires this location)
    ci-electron-test.yml           # internal test harness (small)
    <same files as templates/>
  actions/
    azure-keyvault/                # Composite action: fetch Key Vault secrets → env vars or outputs
      action.yml
      README.md
  samples/                         # Drop-in consumer examples per stack
    node-app/  electron-app/  docker-app/  worker-app/
    static-site/  static-site-external/  railway-app/  swift-app/  expo-app/
  docs/
    templates.md                   # Per-template reference (inputs, secrets, examples, gotchas)
    azure-keyvault.md              # SP setup, RBAC role, usage walkthrough
    getting-started.md             # Quick start + secrets bootstrap
  tests/                           # Plain-bash regression tests run by .githooks/pre-commit
    ci-electron-workflow.test.sh
    deploy-pages-external-workflow.test.sh
    eas-publish-workflow.test.sh
  .githooks/
    pre-commit                     # runs all tests/*.test.sh — enable via `git config core.hooksPath .githooks`
  .github/
    copilot-instructions.md
    instructions/
  README.md  CLAUDE.md  AGENTS.md  GEMINI.md
```

There is **no** `package.json`, **no** `Makefile`, **no** `scripts/` directory at the repo root. All automation lives in workflows + the `.githooks/pre-commit` hook + `tests/*.test.sh`.

## Canonical commands

Run from the repo root.

| Goal | Command |
|------|---------|
| Run every regression test | `for t in tests/*.test.sh; do bash "$t"; done` |
| Run a single test | `bash tests/ci-electron-workflow.test.sh` |
| Enable the pre-commit hook (once per clone) | `git config core.hooksPath .githooks` |
| Validate a workflow's YAML locally (optional) | `actionlint` (no config in repo — install separately) |
| Run a workflow locally (optional) | `act` — no `.actrc` in repo, so pass `-W .github/workflows/<file>.yml` |

There are **no** `lint`, `format`, `typecheck` or `build` scripts in this repo. The only enforced gate is `tests/*.test.sh` via the pre-commit hook.

## Glossary

### Templates (filenames map 1:1 to workflow callable names)

| Template | Trigger | Notable inputs | Required secrets |
|----------|---------|----------------|------------------|
| `ci-node.yml` | `workflow_call` | `node-version` (def `22`), `package-manager` (`npm`\|`pnpm`), `pnpm-version` (def `10`), `os-matrix` (JSON string), `run-lint`/`run-typecheck`/`run-test`/`run-build` (booleans, all default `true`), `artifact-path`, `artifact-retention-days` (def `1`) | none |
| `ci-electron.yml` | `workflow_call` | same shape as `ci-node` but `os-matrix` defaults to `["macos-latest","windows-latest"]`; build job sets `NODE_OPTIONS=--max-old-space-size=4096` | none |
| `release-electron.yml` | `workflow_call` | `channel` (`latest`\|`alpha`), `notarize` (bool), `site-dispatch-repo`, `site-dispatch-event` | `MACOS_CERTIFICATE`, `MACOS_CERTIFICATE_PWD`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`, optional `SITE_APP_ID`/`SITE_APP_PRIVATE_KEY` |
| `release-swift.yml` | `workflow_call` | `app-name` (required), `info-plist-path`, `entitlements-path`, `xcode-version` (def `16.2`), `swift-build-flags`, `create-dmg`, `pre-build-script` | macOS signing + Apple notarization secrets (same set as electron release) |
| `release-worker.yml` | `workflow_call` | `worker-name` (required), `wrangler-env` (def `production`), `dry-run`, `pre-deploy-script`, `integration-test-collection`, `integration-test-url` | `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, optional `INTEGRATION_TEST_API_KEY` (mandatory when integration tests are configured — validated at runtime) |
| `deploy-pages.yml` | `workflow_call` | `path` (def `website`) | none (uses built-in `GITHUB_TOKEN` via `id-token: write`); concurrency group `pages` with `cancel-in-progress: false` |
| `deploy-pages-external.yml` | `workflow_call` | `path` (required), `target-repo` (required), `target-branch` (def `gh-pages`), `enable-tagging`, `site-name`, `build-command`, plus node/package-manager inputs | `APP_ID`, `APP_PRIVATE_KEY` (GitHub App with cross-repo write) |
| `deploy-railway.yml` | `workflow_call` | `railway-service`, `wait-for-deploy` (def `true`) | `RAILWAY_TOKEN` |
| `docker-build.yml` | `workflow_call` | `image-name` (required), `dockerfile` (def `Dockerfile`), `context` (def `.`), `registry` (def `ghcr.io`) | `REGISTRY_USERNAME`, `REGISTRY_PASSWORD` |
| `eas-publish.yml` | `workflow_call` | `command` (`update`\|`build`\|`both`), `update-branch`, `update-message`, `build-profile`, `build-platform` (`ios`\|`android`\|`all`), `build-wait`, `eas-cli-version` (def `latest`), `working-directory` | `EXPO_TOKEN` |

### Composite actions

- `actions/azure-keyvault` — inputs: `keyvault-name`, `secret-names` (comma list), `azure-credentials` (SP JSON: `clientId`/`clientSecret`/`tenantId`/`subscriptionId`), `export-as` (`env`\|`output`, def `env`), `mask-values` (def `true`). Output: `secrets-json` (only when `export-as=output`). Side effect: writes `<NAME>` (uppercased, dashes→underscores) to `$GITHUB_ENV` or `$GITHUB_OUTPUT`.

### Runner labels

- `ubuntu-latest`, `macos-latest`, `windows-latest` — used by most templates.
- `[self-hosted, linux]` — used by `release-electron.yml`'s `prepare-release` job. Self-hosted runners are provisioned by the **Neutron** project (AWS CDK).
- When `matrix.os == 'self-hosted'`, templates intentionally disable `setup-node`'s `cache:` input and the `package-manager-cache` (see Gotchas).

### Environments

- `github-pages` — used by `deploy-pages.yml` for the deployment URL output.
- `wrangler-env` input (`production`/`staging`) maps to wrangler's `--env` selector, **not** to a GitHub Environment.

## Gotchas

1. **`templates/` is the source of truth — `.github/workflows/` is a mirror.** GitHub only resolves `uses: owner/repo/.github/workflows/X.yml@ref`, so every change in `templates/` must be copied to `.github/workflows/`. The `tests/*.test.sh` files exist specifically to catch drift between the two.

2. **No SemVer / no version tags.** Consumers pin to `@main`. Any merge to `main` ships globally. Breaking input changes (rename/remove) WILL break every downstream repo — add new optional inputs instead, and if a breaking change is unavoidable, coordinate consumer updates first.

3. **Self-hosted runner quirks (codified across many recent commits):**
   - `corepack enable` is invoked as `corepack enable pnpm || true` (scoped + tolerate `EEXIST` on shared hosts).
   - Any stale `pnpm`/`pnpx` symlink is removed before `corepack enable` (`rm -f "$(command -v pnpm)" ...`).
   - `setup-node`'s `cache:` input is disabled on `self-hosted` (`cache: ${{ matrix.os != 'self-hosted' && inputs.package-manager || '' }}`).
   - The Electron binary cache (`~/Library/Caches/electron`, `~/.cache/electron`) is **kept** between runs — wiping it caused concurrent re-downloads to drop sockets on shared hosts.
   - Dependency install (`npm ci` / `pnpm install --frozen-lockfile`) runs in a 3-attempt loop with 15 s backoff, and `node_modules` is wiped between attempts.
   - The Electron CI test step carries a step-level timeout.

4. **Permissions blocks are minimal — keep them that way.** `deploy-pages.yml` needs `pages: write` + `id-token: write`; `release-electron.yml` and `release-swift.yml` need `contents: write` to create tags/releases; `docker-build.yml` needs `packages: write`. Do not broaden without reason.

5. **Concurrency.** `deploy-pages.yml` uses `group: pages, cancel-in-progress: false` so deploys queue instead of cancelling. When adding concurrency to other workflows, prefer the same pattern for release workflows (don't cancel an in-progress release).

6. **Cross-repo Pages deploy uses a GitHub App, not PAT.** `deploy-pages-external.yml` needs `APP_ID` + `APP_PRIVATE_KEY` of an App installed on the target repo with `contents: write`. Recent commit `d1d8931` added retries on transient git push failures — keep that retry loop intact.

7. **Worker integration-test secret is fail-fast.** `release-worker.yml` validates `INTEGRATION_TEST_API_KEY` at runtime when `integration-test-collection` is set, and prints an `::error::` message — do not silently skip.

8. **`release-worker.yml` exposes Cloudflare creds to the pre-deploy step** (`pre-deploy-script` receives `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID`) so consumers can `wrangler r2 bucket create` / KV provisioning before `wrangler deploy`. Documented in `docs/templates.md`.

9. **Artifact policy:** `retention-days: 1`, `compression-level: 9` was applied workspace-wide (commit `0c10036`). Honour it on any new `upload-artifact` step unless there is a strong reason.

10. **Third-party action pinning:** all upgrades go through major tags — `actions/checkout@v5`, `actions/setup-node@v5`, `actions/upload-artifact@v5`, `actions/upload-pages-artifact@v3`, `actions/deploy-pages@v4`. Never use `@main` or `@latest`.

11. **Versioning logic in `release-electron.yml`** reads `major.minor` from `package.json`, scans tags `v{major}.{minor}.*` (or `v{major}.{minor}.*-alpha.*` for alpha channel), and increments. Pushing a tag manually that does not match the pattern can desync the auto-increment.

12. **`sed` delimiter for tag manipulation** uses `|` (pipe), not `/`, because tag prefixes can contain slashes (commit `1452f2f` regressed and was re-fixed). Keep `|` when editing those sed expressions.

13. **No CI on the Orbit repo itself.** There is no meta-workflow that validates templates on PR — the only gate is the local `.githooks/pre-commit`. Encourage contributors to enable it.

## Hooks & CI

- `.githooks/pre-commit` runs `bash` on every `tests/*.test.sh`. Enable per-clone via `git config core.hooksPath .githooks`.
- **Never bypass the hook** with `--no-verify` (workspace-wide rule). If a test fails, fix the template OR fix the test if the workflow change is intentional and backward-compatible.
- No `.husky/`, no `lint-staged`, no `actionlint` config, no GitHub-side meta-workflow. The pre-commit hook is the only safety net.

## Naming & style

- Template filenames: `kebab-case.yml`. Action directories: `kebab-case/`.
- Workflow `inputs:`: `kebab-case`.
- `secrets:`: `UPPER_SNAKE_CASE`.
- Prefer `npm ci` / `pnpm install --frozen-lockfile`. Never `npm install` in CI.
- JSON-array inputs (matrices) MUST be `type: string` with a JSON-stringified default (GitHub Actions has no array input type) — consumers and `fromJson(...)` handle decoding.

## Consumer reference

```yaml
jobs:
  ci:
    uses: MeteorFactory/Orbit/.github/workflows/ci-node.yml@main
    with:
      node-version: "22"
      package-manager: "pnpm"
```

(Some sample files and the README still use the legacy repo name `MeteorFactory/Pipelines/...`. Confirm the canonical GitHub repo name before publishing new examples.)
