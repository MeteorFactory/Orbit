# Pipelines

Catalog of reusable GitHub Actions workflows and custom composite actions for CI/CD automation. Targets Node.js, Electron, Docker, and Azure-integrated projects.

## Stack

- **GitHub Actions YAML** -- all templates use `workflow_call` trigger
- **Bash** -- shell scripts in composite actions and workflow steps
- **Azure CLI** -- used in the `azure-keyvault` composite action
- **jq** -- JSON processing in shell steps

## Project Structure

```
Pipelines/
  templates/                    # Source of truth for reusable workflows
    ci-node.yml                 # Node.js CI (lint, typecheck, test, build)
    ci-electron.yml             # Electron CI (multi-OS: macOS + Windows)
    release-electron.yml        # Electron release (signing, notarization, publish)
    deploy-pages.yml            # GitHub Pages deployment
    docker-build.yml            # Docker build & push with Buildx
  actions/                      # Custom composite GitHub Actions
    azure-keyvault/             # Fetches secrets from Azure Key Vault
      action.yml                # Action definition
      README.md                 # Action-specific docs
  .github/workflows/            # Copies of templates/ (required by GitHub for consumption)
  docs/                         # Extended documentation
    templates.md                # Detailed template reference
    azure-keyvault.md           # Azure Key Vault setup guide
    getting-started.md          # Quick start guide
  samples/                      # Usage examples (WIP)
```

### Important: templates/ vs .github/workflows/

GitHub requires reusable workflows to live in `.github/workflows/` of the source repo. The `templates/` directory is the canonical source. After editing a template, copy it to `.github/workflows/`.

Consumers reference workflows as:
```
uses: MeteorFactory/Pipelines/.github/workflows/<name>.yml@main
```

## Conventions

### File Naming
- Template files: `kebab-case.yml`
- Action directories: `kebab-case/`

### YAML Style
- Workflow inputs: `kebab-case` names
- Secrets: `UPPER_SNAKE_CASE` names
- Pin all third-party actions to major version tags (e.g., `actions/checkout@v4`)
- Use `workflow_call` trigger on all reusable templates
- Prefer `npm ci` over `npm install` for reproducible installs

### Template Anatomy
Every reusable workflow template follows this structure:
1. `name:` -- descriptive workflow name
2. `on: workflow_call:` -- with `inputs:` and optional `secrets:`
3. `permissions:` -- minimal required permissions (when needed)
4. `jobs:` -- one or more jobs

### Inputs Design
- Provide sensible defaults for all optional inputs
- Use `string` type for JSON arrays (e.g., OS matrix) since GitHub Actions does not support array inputs
- Use `boolean` type for feature toggles
- Mark only truly required inputs as `required: true`

## AI Agent Instructions

When modifying this project:

1. **Edit templates in `templates/` first** -- this is the source of truth. Then copy to `.github/workflows/`.
2. **Keep inputs backward-compatible** -- adding new optional inputs is safe; removing or renaming inputs is a breaking change.
3. **Update docs when changing templates** -- if inputs, secrets, or behavior change, update `docs/templates.md` and `README.md`.
4. **Test with act or a fork** -- use [act](https://github.com/nektos/act) for local testing or a fork repo for integration testing.
5. **Do not hardcode secrets** -- all sensitive values must be passed via `secrets:` or fetched from a vault at runtime.
6. **Pin action versions** -- always use `@v4` style tags, not `@main` or `@latest`, for third-party actions.
7. **Minimal permissions** -- only declare the permissions each workflow actually needs.
