# Reusable Workflow Contracts

Every reusable workflow is a public contract. Consumers reference it as:

```yaml
uses: MeteorFactory/Pipelines/.github/workflows/ci-node.yml@main
```

## Rules

- Trigger MUST be `on: workflow_call:` with explicit `inputs:` and optional `secrets:`. NEVER `push`/`pull_request` on a template.
- Input names: `kebab-case`. Secret names: `UPPER_SNAKE_CASE`.
- Declare minimal `permissions:` at the workflow OR job level. Default to nothing; opt in (`contents: read`, `id-token: write`, etc.). **Why:** tokens with default `write-all` are an injection magnet.
- PIN all third-party actions to a major version tag (`actions/checkout@v5`). NEVER `@main`, NEVER `@latest`. **Why:** floating refs let supply-chain attacks become silent prod failures.
- Renaming or removing an existing input is a BREAKING change for every consumer. Add the new input as optional first; version the template (`ci-node-v2.yml`) if you must change semantics.
- Every input added to a template MUST be documented in `docs/templates.md` in the same commit.

## When to version vs evolve

- Backwards-compatible (new optional input, expand allowed values): edit in place, document the addition.
- Breaking (rename, remove, change default behavior): publish a new versioned file and deprecate the old one in `docs/templates.md` with a migration note.
