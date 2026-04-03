# Pipelines — Agent Instructions

Catalog of reusable GitHub Actions workflows and custom composite actions for CI/CD automation. Targets Node.js, Electron, Docker, and Azure-integrated projects.

## Stack

- GitHub Actions YAML (all templates use `workflow_call` trigger)
- Bash (shell scripts in composite actions)
- Azure CLI (used in `azure-keyvault` composite action)
- jq (JSON processing in shell steps)

## Key Directories

- `templates/` — source of truth for reusable workflows
- `actions/` — custom composite GitHub Actions
- `.github/workflows/` — copies of templates (required by GitHub for consumption)
- `docs/` — extended documentation
- `samples/` — usage examples

## Critical Rules

1. **Edit `templates/` first**, then copy to `.github/workflows/` — templates is the source of truth
2. **Keep inputs backward-compatible** — adding optional inputs is safe; removing/renaming is breaking
3. **Update docs** when changing templates (`docs/templates.md` and `README.md`)
4. **Pin action versions** — use `@v4` style tags, never `@main` or `@latest`
5. **Minimal permissions** — only declare what each workflow needs
6. **No hardcoded secrets** — pass via `secrets:` or fetch from vault at runtime
7. **Prefer `npm ci`** over `npm install` for reproducible installs

## Conventions

- Template files: `kebab-case.yml`
- Action directories: `kebab-case/`
- Workflow inputs: `kebab-case` names
- Secrets: `UPPER_SNAKE_CASE` names
- Use `string` type for JSON arrays (GitHub Actions limitation)
- Use `boolean` type for feature toggles

## Template Anatomy

1. `name:` — descriptive workflow name
2. `on: workflow_call:` — with `inputs:` and optional `secrets:`
3. `permissions:` — minimal required
4. `jobs:` — one or more jobs

## Consumer Reference

```yaml
uses: MeteorFactory/Pipelines/.github/workflows/<name>.yml@main
```
