# Forbidden Patterns

## YAML

| Forbidden | Replacement | Why |
|-----------|-------------|-----|
| `@main`, `@latest`, or a long SHA without context for third-party actions | `actions/<name>@v<major>` | Supply-chain hygiene + clear pinning |
| `permissions: write-all` | The minimum needed (`contents: read`, `id-token: write`, ...) | Least privilege |
| Hard-coded secrets in YAML | `secrets:` inputs or vault fetch at runtime | Secrets in git are credential compromise |
| Hard-coded paths to `~/runner` or `$HOME/...` | `${{ runner.temp }}`, `${{ github.workspace }}` | Cross-platform runners |
| `npm install` in CI | `npm ci` | Reproducibility |
| `pnpm install` without a frozen lockfile | `pnpm install --frozen-lockfile` | Reproducibility |
| Implicit dependency between jobs without `needs:` | Declare `needs:` explicitly | Graph correctness |

## Templates

| Forbidden | Replacement | Why |
|-----------|-------------|-----|
| Editing `.github/workflows/<file>.yml` directly without updating `templates/` | Edit `templates/<file>.yml` first, then copy | Templates is the source of truth |
| Removing or renaming an input | Add a new optional input or ship `<name>-v2.yml` | Breaks every consumer pinned at `@main` |
| Adding a new required secret silently | Document it in `docs/templates.md` and `README.md` | Consumers need an upgrade path |
| Changing a default value without a callout | Mention it explicitly in the PR description | Defaults are part of the API |

## Composite actions

| Forbidden | Replacement | Why |
|-----------|-------------|-----|
| Reading env vars inside the action without exposing them as `inputs:` | Add the input explicitly | Reusability, discoverability |
| Skipping `runs.using: composite` | Always declare it | Required for composites |

## Tests

| Forbidden | Replacement | Why |
|-----------|-------------|-----|
| Deleting a `tests/*.test.sh` to make a commit pass | Update the test to reflect the new invariant | Tests encode lessons-learned |
| Adding `set -e` without `-u -o pipefail` | Always `set -euo pipefail` | Catches unset vars and pipe failures |

## Git / process

- Never `--no-verify` once `git config core.hooksPath .githooks` is enabled.
- Never add a `Co-Authored-By` trailer.
- Never `git commit --amend` after a hook failure — create a new commit.
