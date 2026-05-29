# Naming Conventions

## File system

| What | Convention | Real example |
|------|-----------|--------------|
| Template files | `kebab-case.yml` describing the lifecycle | `ci-node.yml`, `release-electron.yml`, `deploy-pages.yml` |
| Action folders | `kebab-case/` | `actions/azure-keyvault/` |
| Action file | `action.yml` (lowercase) | — |
| Action docs | `README.md` next to `action.yml` | — |
| Workflow tests | `<workflow>-workflow.test.sh` | `ci-electron-workflow.test.sh`, `eas-publish-workflow.test.sh` |
| Sample consumers | `samples/<purpose>/<workflow>.yml` | — |
| Extended docs | `docs/<topic>.md` | `docs/templates.md`, `docs/azure-keyvault.md` |

## YAML identifiers

| What | Convention | Example |
|------|-----------|---------|
| Workflow `name:` | `Title Case` describing the workflow | `name: CI Node.js` |
| Job ids | `kebab-case` reflecting role | `jobs.build`, `jobs.notarize`, `jobs.publish-pages` |
| Input names | `kebab-case` | `node-version`, `package-manager`, `os-matrix` |
| Secret names | `UPPER_SNAKE_CASE` | `NPM_TOKEN`, `APPLE_API_KEY`, `EXPO_TOKEN` |
| Step ids | `kebab-case` | `id: install-deps`, `id: notarize` |
| Env vars (within a step) | `UPPER_SNAKE_CASE` | `NODE_VERSION`, `RUNNER_OS` |

## Consumer reference

Workflows are consumed via:
```yaml
uses: MeteorFactory/Orbit/.github/workflows/<workflow>.yml@<ref>
```

The `<ref>` should be `main` for the canonical version, or a release tag once
versioning is in place.

## Composite action invocation

```yaml
- uses: MeteorFactory/Orbit/actions/azure-keyvault@main
  with:
    vault-name: <required>
```
