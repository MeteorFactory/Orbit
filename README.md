# Pipelines - Reusable Workflow Templates

A curated catalog of reusable GitHub Actions workflows and custom actions for CI/CD automation. Built for Node.js, Electron, Docker, and Azure-integrated projects.

## Quick Start

Using a reusable workflow from this repository takes 3 steps:

**1. Choose a template** from the table below.

**2. Create a workflow file** in your repo at `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  ci:
    uses: MeteorFactory/Pipelines/.github/workflows/ci-node.yml@main
    with:
      node-version: "22"
```

**3. Commit and push.** GitHub Actions picks up the workflow automatically.

> **Important:** GitHub requires reusable workflows to live in `.github/workflows/` of the source repository. The `templates/` directory is the source of truth; files are copied to `.github/workflows/` for consumption. Consumers reference them as:
> ```
> uses: MeteorFactory/Pipelines/.github/workflows/<template>.yml@main
> ```

## Available Templates

| Template | Description | Docs |
|----------|-------------|------|
| [`ci-node.yml`](templates/ci-node.yml) | Node.js CI with lint, typecheck, test, build (toggleable jobs, multi-OS) | [Details](docs/templates.md#ci-nodeyml) |
| [`ci-electron.yml`](templates/ci-electron.yml) | Electron CI on macOS + Windows with lint, typecheck, test, build | [Details](docs/templates.md#ci-electronyml) |
| [`release-electron.yml`](templates/release-electron.yml) | Electron release with macOS code signing/notarization + Windows builds | [Details](docs/templates.md#release-electronyml) |
| [`deploy-pages.yml`](templates/deploy-pages.yml) | Deploy static files to GitHub Pages | [Details](docs/templates.md#deploy-pagesyml) |
| [`docker-build.yml`](templates/docker-build.yml) | Docker build and push with Buildx, metadata tagging, and GHA caching | [Details](docs/templates.md#docker-buildyml) |

## Custom Actions

| Action | Description | Docs |
|--------|-------------|------|
| [`azure-keyvault`](actions/azure-keyvault/) | Fetch secrets from Azure Key Vault and expose as env vars or step outputs | [Guide](docs/azure-keyvault.md) |

## Secrets Management

Several templates require secrets (signing certificates, registry credentials, Azure credentials). See the [Getting Started guide](docs/getting-started.md#configuring-github-secrets) for setup instructions.

### Azure Key Vault Integration

For projects using Azure Key Vault to manage secrets centrally, the `azure-keyvault` custom action provides seamless integration. Prerequisites:

- An Azure subscription with a Key Vault provisioned
- A Service Principal with the `Key Vault Secrets User` RBAC role
- The SP credentials stored as a GitHub secret (`AZURE_CREDENTIALS`)

Full setup walkthrough: [Azure Key Vault Guide](docs/azure-keyvault.md).

## Repository Structure

```
Pipelines/
  templates/               # Source of truth for reusable workflows
    ci-node.yml            # Node.js CI
    ci-electron.yml        # Electron CI (multi-OS)
    release-electron.yml   # Electron release (signing + publish)
    deploy-pages.yml       # GitHub Pages deployment
    docker-build.yml       # Docker build & push
  actions/                 # Custom composite actions
    azure-keyvault/        # Azure Key Vault secret fetcher
      action.yml
      README.md
  .github/workflows/       # Copies of templates (required by GitHub for consumption)
  docs/                    # Extended documentation
    templates.md           # Detailed template reference
    azure-keyvault.md      # Azure Key Vault setup guide
    getting-started.md     # Quick start guide
  samples/                 # Usage examples (WIP)
```

## Contributing

1. Edit templates in `templates/` (this is the source of truth).
2. Copy updated files to `.github/workflows/` so consumers can reference them.
3. Update documentation in `docs/` if inputs, secrets, or behavior change.
4. Test changes in a fork before merging to `main`.

### Conventions

- Template filenames: `kebab-case.yml`
- Input names: `kebab-case`
- Secret names: `UPPER_SNAKE_CASE`
- All templates use `workflow_call` trigger for reusability
- Pin action versions to major tags (e.g., `actions/checkout@v4`)

## License

MIT
