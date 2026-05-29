# Testing Standards

Templates are tested THREE ways. All three must be green before merge.

## 1. Local regression tests (`tests/`)

- Bash tests under `tests/` cover structural invariants of templates and composites (template/mirror byte-equality, required inputs declared, etc.).
- `.githooks/pre-commit` runs them. NEVER bypass with `--no-verify`.

## 2. Lint

- `actionlint` on every changed `.yml`. Install locally via Homebrew (`brew install actionlint`) — DO NOT vendor a binary.
- `shellcheck` on every inline `run: |` bash block. Treat warnings as errors.
- Use `shell: bash` explicitly on every composite step (don't rely on the default).

## 3. Live consumer run

- A template change is exercised against AT LEAST ONE consumer repo before merge. Link the live run URL in the PR.
- `samples/<kind>/` workflows are smoke runs. They run on push to `main` and on changes to the relevant template — keep that wiring intact.

## What NOT to do

- NO snapshot tests of YAML files.
- NO test that just runs `actionlint` — that's already in the hook.
- NO live test that requires real cloud credentials — use the `samples/<kind>/` workflows with mocked / dev creds.
