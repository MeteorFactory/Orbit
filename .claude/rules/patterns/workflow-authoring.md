# Workflow Authoring

## Source of truth: `templates/`

GitHub requires reusable workflows to live in `.github/workflows/` of the source
repo. Orbit therefore **duplicates** every template into `.github/workflows/`.

**`templates/` is the canonical source.** Always edit there first, then copy the
file to `.github/workflows/` byte-for-byte. The duplication is checked by humans
during review — there is no automated guard yet.

```bash
cp templates/ci-node.yml .github/workflows/ci-node.yml
```

## Template anatomy

Every reusable workflow follows this skeleton:

```yaml
name: <Descriptive Name>

on:
  workflow_call:
    inputs:
      <kebab-case-input>:
        description: "..."
        type: <string|boolean|number>
        default: <sensible default>
        required: false
    secrets:
      <UPPER_SNAKE_CASE_SECRET>:
        required: true

permissions:
  contents: read   # minimum needed; expand only when justified

jobs:
  <job-id>:
    runs-on: ${{ fromJSON(inputs.os-matrix) }}
    steps:
      - uses: actions/checkout@v5
      ...
```

## Input contract — backward compatibility is mandatory

Consumers reference Orbit workflows by tag:
```yaml
uses: MeteorFactory/Orbit/.github/workflows/ci-node.yml@main
```

This means **any change to `inputs:` is a public API change**:

| Change | Safe? |
|--------|-------|
| Add a new optional input (with default) | ✅ Safe |
| Add a new required input | ❌ Breaking — every consumer must update |
| Rename an input | ❌ Breaking |
| Remove an input | ❌ Breaking |
| Change a default value | ⚠️ Behaviour change — call it out in the PR |
| Change a `type` (e.g. `string` -> `boolean`) | ❌ Breaking |

When a breaking change is unavoidable, ship a new template file (`ci-node-v2.yml`)
rather than rewriting the existing one.

## Limitations to remember

- **No array inputs.** GitHub Actions inputs accept only `string`, `boolean`,
  `number`. Pass arrays as JSON strings (`'["ubuntu-latest", "macos-latest"]'`)
  and parse with `fromJSON(inputs.os-matrix)`.
- **No `if:` on `inputs`.** Use `if: ${{ inputs.run-lint }}` at the job level.
- **`secrets: inherit` only forwards SECRETS, not the calling repo's GITHUB_TOKEN
  scopes.** Declare `permissions:` explicitly in the called workflow.

## Composite actions

Composite actions live under `actions/<name>/action.yml`. Today there is one
(`azure-keyvault`). When adding more:

- One folder per action with `action.yml` + `README.md`.
- Use `runs.using: composite`.
- All `inputs:` go through `${{ inputs.x }}` — do not read from env unless wrapped.
- Document required permissions on the calling workflow side.

## After every change

1. Edit `templates/<name>.yml` first.
2. Copy to `.github/workflows/<name>.yml`.
3. Update `docs/templates.md` if the input/secret surface changed.
4. Run the matching regression test (`bash tests/<name>-workflow.test.sh`).
5. If new behaviour, add a new test alongside.
6. Reference the affected templates in the commit message scope.
