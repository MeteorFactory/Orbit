---
applyTo: "templates/**"
---

# Template Rules

- This is the source of truth — edit here first, then copy to `.github/workflows/`
- All templates use `workflow_call` trigger
- Pin third-party actions to major version tags (`@v4`)
- Use `kebab-case` for input names, `UPPER_SNAKE_CASE` for secrets
- Provide sensible defaults for optional inputs
- Use `string` type for JSON arrays, `boolean` for toggles
- Keep minimal required permissions
