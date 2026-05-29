# Architectural Invariants

Orbit (a.k.a. "Pipelines") is a catalog of reusable GitHub Actions workflows + composite actions.

## Layout

```
templates/                  # SOURCE OF TRUTH for reusable workflows
.github/workflows/          # MIRROR of templates/ (required by GitHub for `uses:`)
actions/<name>/             # Composite actions (action.yml + README.md)
samples/<kind>/             # Reference consumer workflows
docs/                       # templates.md, getting-started.md, per-action docs
tests/                      # Bash regression tests, run by .githooks/pre-commit
```

## Hard rules

- `templates/` is the source of truth. **EVERY** template edit MUST also update its mirror in `.github/workflows/<same-name>.yml` in the SAME commit. **Why:** consumers reference `.github/workflows/` via `uses:` — `templates/` is never consumed.
- The two MUST stay byte-identical. `.githooks/pre-commit` checks this; if you see a mismatch, copy the template file.
- Composite actions live at `actions/<name>/action.yml`. One composite = one folder. Public-facing docs go next to the action in `actions/<name>/README.md`.
- Samples are reference-only. Do not put consumer-specific values in `templates/` — accept them as `inputs:`.
- New template or action: also add a `samples/<kind>/` workflow exercising it AND a bash test under `tests/` covering the inputs.

## Adding a template

1. Author it in `templates/<name>.yml`.
2. Copy to `.github/workflows/<name>.yml` (identical content).
3. Add or update a sample under `samples/<kind>/`.
4. Document the inputs in `docs/templates.md`.
5. Add a `tests/<name>.bats` (or equivalent) regression check.
