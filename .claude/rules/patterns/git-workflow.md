# Git Workflow

## Commit message format

```
type(scope): description (#F-XX)
```

- `type`: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`.
- `scope`: template or area (`ci-node`, `release-electron`, `azure-keyvault`, `tests`, `docs`, `ai`).
- `description`: lowercase, imperative, no period.
- `(#F-XX)`: kanban ticket reference when applicable.

Examples:
```
feat(ci-node): expose os-matrix input
fix(release-electron): restore Electron cache key on macOS arm64
docs(ai): refresh configuration
chore(deps): bump actions/checkout to v5
```

## Hard rules

- NEVER `--no-verify`, `HUSKY=0`, `GIT_SKIP_HOOKS=1`. **Why:** `.githooks/pre-commit` runs the bash regression suite — bypassing it ships broken templates.
- NEVER add `Co-Authored-By` trailers. Commit message stays clean.
- Linear history. Rebase, never merge. `git pull --rebase` always.
- An edit to `templates/<x>.yml` MUST be paired with the SAME-COMMIT edit to `.github/workflows/<x>.yml`. The pre-commit test enforces this; do not split into two commits. **Why:** consumers always read the `.github/workflows/` copy; a one-commit-only update means a window where docs say one thing and prod runs another.
- A failed hook means the commit did NOT happen. NEVER `git commit --amend` after a hook failure — there was no previous commit to amend.
- NEVER delete a test to make a commit pass — tests encode regressions.
- PRs touching a template include the URL of a live consumer run that exercises the change.

## Enable hooks once per clone

```bash
git config core.hooksPath .githooks
```

## When the hook fails

- Mismatch between `templates/` and `.github/workflows/` → copy the file (the test tells you which).
- `actionlint` errors → fix the YAML; do not delete the test.
- A broken hook script → fix the script. NEVER delete `.githooks/`.

## Branch naming

```
type/description
```

Examples: `feat/release-worker-multi-region`, `fix/ci-electron-cache-key`, `docs/eas-publish-getting-started`.

## Worktree commits

When working inside `.singularity-worktrees/`:

- Stay on the worktree branch.
- Stage specific files (`templates/<x>.yml`, `.github/workflows/<x>.yml`, `tests/<x>.test.sh`, `docs/*.md`).
- The orchestration engine rebases the worktree back into the base branch on completion — never `git merge` manually.

## Backward-compatibility callouts

When a change affects the workflow input/secret surface, mention it in the commit body so consumers can react:

```
feat(ci-node): expose os-matrix input

Adds optional `os-matrix` input defaulting to '["ubuntu-latest"]'. Existing
consumers continue to build on Ubuntu only. Pass a JSON array to opt into
multi-OS jobs.
```
