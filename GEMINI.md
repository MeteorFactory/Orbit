# Pipelines — Gemini Instructions

Catalog of reusable GitHub Actions workflows and custom composite actions for CI/CD automation. Targets Node.js, Electron, Docker, and Azure-integrated projects.

## Stack

- GitHub Actions YAML (all templates use `workflow_call` trigger)
- Bash (shell scripts in composite actions)
- Azure CLI (used in `azure-keyvault` composite action)
- jq (JSON processing in shell steps)

## Key Directories

| Directory | Purpose |
|-----------|---------|
| `templates/` | Source of truth for reusable workflows |
| `actions/` | Custom composite GitHub Actions |
| `.github/workflows/` | Copies of templates (required by GitHub) |
| `docs/` | Extended documentation |
| `samples/` | Usage examples |

## Critical Rules

1. **Edit `templates/` first**, then copy to `.github/workflows/`
2. **Keep inputs backward-compatible** — removing/renaming is a breaking change
3. **Update docs** when changing templates
4. **Pin action versions** — use `@v4` style tags, never `@main`
5. **Minimal permissions** — only declare what each workflow needs
6. **No hardcoded secrets** — pass via `secrets:` or fetch from vault
7. **Prefer `npm ci`** over `npm install`

## Conventions

- File naming: `kebab-case.yml` (templates), `kebab-case/` (actions)
- Inputs: `kebab-case` names
- Secrets: `UPPER_SNAKE_CASE` names
- Use `string` type for JSON arrays, `boolean` for feature toggles

## Consumer Reference

```yaml
uses: MeteorFactory/Pipelines/.github/workflows/<name>.yml@main
```
