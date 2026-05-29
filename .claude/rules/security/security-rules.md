# Security Rules

GitHub Actions has subtle attack surfaces that bite hard. These rules are non-negotiable.

## Expression injection (THE #1 risk)

- NEVER interpolate `${{ github.event.* }}`, `${{ inputs.* }}`, or any user-controlled value directly inside a `run:` block. **Why:** `${{ }}` is substituted before the shell parses the script — a value containing `$(...)` or `;` executes.
- The fix: map to `env:` on the step, reference `$VAR` inside `run:`. Quote variable expansions (`"$VAR"`).

```yaml
- name: Print PR title (safe)
  env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: echo "$PR_TITLE"
```

## Secrets

- NEVER `echo` a secret. Mask via `::add-mask::` BEFORE the first use.
- NEVER log a registration token, App private key, or any short-lived credential.
- Wrap secret-handling blocks with `set +x` to disable shell tracing.
- Secrets are referenced by name only; never bake one into a template default.

## Action pinning

- Major tag for routine third-party actions (`actions/checkout@v5`).
- FULL commit SHA for high-trust workflows (release, deploy to prod, secrets at runtime). **Why:** a tag can be force-pushed; a SHA cannot.
- Never use `@main` or `@latest`. EVER.

## `pull_request_target`

- This trigger runs the BASE branch's workflow with secrets exposed. If it checks out the PR's HEAD, you've handed the repo to anyone with a fork.
- Use it only with an explicit author-membership gate (`if: github.event.pull_request.head.repo.full_name == github.repository`) and code-owner review.

## Permissions

- Start with `permissions: {}` at the workflow level.
- Grant the minimum at the job level. Common minimum for CI: `contents: read`.
