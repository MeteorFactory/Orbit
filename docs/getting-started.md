# Getting Started

This guide walks you through choosing a template, creating your first workflow, and configuring secrets.

## Choosing the Right Template

| I want to... | Use this template |
|--------------|-------------------|
| Run CI for a Node.js project (lint, test, build) | [`ci-node.yml`](templates.md#ci-nodeyml) |
| Run CI for an Electron app on macOS + Windows | [`ci-electron.yml`](templates.md#ci-electronyml) |
| Build and release an Electron app with code signing | [`release-electron.yml`](templates.md#release-electronyml) |
| Deploy static files to GitHub Pages | [`deploy-pages.yml`](templates.md#deploy-pagesyml) |
| Build and push a Docker image to a registry | [`docker-build.yml`](templates.md#docker-buildyml) |
| Fetch secrets from Azure Key Vault | [azure-keyvault action](azure-keyvault.md) |

## Your First Workflow in 5 Minutes

### 1. Create the workflow file

In your project repository, create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  ci:
    uses: MeteorFactory/Pipelines/.github/workflows/ci-node.yml@main
```

That is it. This gives you lint, typecheck, test, and build jobs using Node.js 22 on Ubuntu.

### 2. Customize with inputs

Override defaults by adding a `with` block:

```yaml
jobs:
  ci:
    uses: MeteorFactory/Pipelines/.github/workflows/ci-node.yml@main
    with:
      node-version: "20"
      run-typecheck: false
      run-build: false
```

### 3. Push and verify

Commit, push, and check the **Actions** tab in your GitHub repository. You should see the workflow running.

## Configuring GitHub Secrets

Some templates require secrets (e.g., signing certificates, registry credentials). Here is how to set them up.

### Adding a secret

1. Go to your repository on GitHub.
2. Navigate to **Settings > Secrets and variables > Actions**.
3. Click **New repository secret**.
4. Enter the name and value, then click **Add secret**.

### Passing secrets to reusable workflows

Use the `secrets` key in your workflow call:

```yaml
jobs:
  release:
    uses: MeteorFactory/Pipelines/.github/workflows/release-electron.yml@main
    secrets:
      GH_TOKEN: ${{ secrets.GH_TOKEN }}
      MAC_CERTIFICATE: ${{ secrets.MAC_CERTIFICATE }}
      MAC_CERTIFICATE_PASSWORD: ${{ secrets.MAC_CERTIFICATE_PASSWORD }}
      APPLE_ID: ${{ secrets.APPLE_ID }}
      APPLE_APP_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
      APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
```

### Secrets by template

| Template | Required Secrets |
|----------|-----------------|
| `ci-node.yml` | None |
| `ci-electron.yml` | None |
| `release-electron.yml` | `GH_TOKEN`, `MAC_CERTIFICATE`, `MAC_CERTIFICATE_PASSWORD`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID` |
| `deploy-pages.yml` | None (uses `GITHUB_TOKEN` automatically) |
| `docker-build.yml` | `REGISTRY_USERNAME`, `REGISTRY_PASSWORD` |

## Customizing Inputs

### OS Matrix

Templates that support `os-matrix` accept a JSON array of GitHub runner labels:

```yaml
# Single OS
os-matrix: '["ubuntu-latest"]'

# Multiple OS
os-matrix: '["ubuntu-latest", "macos-latest", "windows-latest"]'
```

### Toggling Jobs

CI templates let you disable individual jobs:

```yaml
with:
  run-lint: true
  run-typecheck: true
  run-test: true
  run-build: false  # Skip build for faster feedback
```

### Node.js Version

All Node.js-based templates accept a `node-version` string input:

```yaml
with:
  node-version: "20"   # Use Node.js 20
```

## Expected npm Scripts

The CI templates run standard npm scripts. Your `package.json` must define the scripts that are enabled:

| Job | npm Script |
|-----|------------|
| lint | `npm run lint` |
| typecheck | `npm run typecheck` |
| test | `npm run test` |
| build | `npm run build` |

If a job is enabled but the script is missing from `package.json`, the workflow will fail at that step.

## Pinning to a Version

For stability, pin to a specific commit SHA or tag instead of `@main`:

```yaml
# Pin to a commit
uses: MeteorFactory/Pipelines/.github/workflows/ci-node.yml@abc1234

# Pin to a tag (when available)
uses: MeteorFactory/Pipelines/.github/workflows/ci-node.yml@v1.0.0
```

Using `@main` always picks up the latest version, which is convenient but may introduce breaking changes.

## Next Steps

- [Template Reference](templates.md) -- detailed inputs, secrets, and examples for every template
- [Azure Key Vault Guide](azure-keyvault.md) -- centralized secret management with Azure
