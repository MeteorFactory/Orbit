# Git Workflow

## Commit message format

```
type(scope): description (#F-XX)
```

- `type`: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`.
- `scope`: template or area (`ci-node`, `release-electron`, `azure-keyvault`,
  `tests`, `docs`, `ai`).
- `description`: lowercase, imperative, no period.
- `(#F-XX)`: kanban ticket reference when applicable.

Examples:
```
feat(ci-node): expose os-matrix input
fix(release-electron): restore Electron cache key on macOS arm64
docs(ai): refresh configuration
chore(deps): bump actions/checkout to v5
```

## No Co-Authored-By

Never add `Co-Authored-By: ...` trailers.

## Never bypass git hooks

`.githooks/pre-commit` runs `tests/*.test.sh`. Enable once per clone:

```bash
git config core.hooksPath .githooks
```

Once enabled:
- Never `--no-verify`, `HUSKY=0`, `GIT_SKIP_HOOKS=1`.
- If a test fails, the commit did NOT happen. Read the test output, fix the
  template (or update the test in the same commit if the invariant intentionally
  changed), re-stage, retry.
- Never `git commit --amend` after a hook failure.
- Never delete a test to make a commit pass — tests encode regressions.

## Branch naming

```
type/description
```

Examples: `feat/release-worker-multi-region`, `fix/ci-electron-cache-key`,
`docs/eas-publish-getting-started`.

## Worktree commits

When working inside `.singularity-worktrees/`:

- Stay on the worktree branch.
- Stage specific files (`templates/<x>.yml`, `.github/workflows/<x>.yml`,
  `tests/<x>.test.sh`, `docs/*.md`).
- The orchestration engine rebases the worktree back into the base branch on
  completion — never `git merge` manually.

## Backward-compatibility callouts

When a change affects the workflow input/secret surface, mention it in the
commit body so consumers can react:

```
feat(ci-node): expose os-matrix input

Adds optional `os-matrix` input defaulting to '["ubuntu-latest"]'. Existing
consumers continue to build on Ubuntu only. Pass a JSON array to opt into
multi-OS jobs.
```
