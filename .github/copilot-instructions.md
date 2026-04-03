# Pipelines — Copilot Instructions

Catalog of reusable GitHub Actions workflows and custom composite actions for CI/CD automation.

## Critical Rules

1. **Edit `templates/` first**, then copy to `.github/workflows/` — templates is the source of truth
2. **Keep inputs backward-compatible** — removing/renaming inputs is a breaking change
3. **Update docs** when changing templates (`docs/templates.md` and `README.md`)
4. **Pin action versions** — use `@v4` style tags, never `@main` or `@latest`
5. **Minimal permissions** — only declare what each workflow needs
6. **No hardcoded secrets** — pass via `secrets:` or fetch from vault at runtime
7. **Prefer `npm ci`** over `npm install`

## Conventions

- Template files: `kebab-case.yml`
- Action directories: `kebab-case/`
- Workflow inputs: `kebab-case` names
- Secrets: `UPPER_SNAKE_CASE` names

## Consumer Reference

```yaml
uses: MeteorFactory/Pipelines/.github/workflows/<name>.yml@main
```
