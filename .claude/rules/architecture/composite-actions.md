# Composite Actions

Composite actions live at `actions/<name>/`. The reference implementation is `actions/azure-keyvault/`.

## Shape

```
actions/<name>/
  action.yml      # The composite definition
  README.md       # Public-facing docs
```

## Rules

- `action.yml` declares typed `inputs:` (with `description`, `required`, `default`).
- Validate inputs in an EARLY step (fail fast). See `azure-keyvault/action.yml` for the pattern.
- Map every secret-bearing input into `env:` ON THE STEP that uses it, then reference `$VAR` inside `run:`. **NEVER** interpolate `${{ inputs.token }}` directly into `run:` — that's shell command injection. **Why:** `${{ }}` substitution happens before the shell parses the script; a value containing `$(rm -rf /)` will execute.
- Mask secrets immediately: `echo "::add-mask::$VAR"`.
- Cleanup steps run with `if: always()` to revoke tokens / log out even on failure (see `azure-keyvault`).
- One side effect per step. Compose; don't sprawl.

## Anti-patterns to refuse

- `run: az login --service-principal -u ${{ inputs.client_id }} -p ${{ inputs.client_secret }}` — values interpolated; secret leaks into logs and step-injection becomes possible.
- `run: echo "${{ github.event.head_commit.message }}"` — commit message is attacker-controlled.
- Using `pull_request_target` to call a composite that checks out untrusted code — runs untrusted code with secrets.
