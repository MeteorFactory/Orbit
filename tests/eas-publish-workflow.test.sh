#!/usr/bin/env bash
#
# Regression test for templates/eas-publish.yml and its .github/workflows copy.
#
# Guarantees:
#   1. Both files exist and stay in sync (the template is the source of truth).
#   2. The workflow keeps the `EXPO_TOKEN` secret wired through to `eas` —
#      removing it silently breaks every consumer that authenticates via a
#      token (GitHub Actions cannot run an interactive `eas login`).
#   3. The workflow installs `eas-cli` globally before invoking it, otherwise
#      the `eas update` / `eas build` steps fail with "command not found".

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/templates/eas-publish.yml"
WORKFLOW="$REPO_ROOT/.github/workflows/eas-publish.yml"

fail=0
pass() { printf '  ok    %s\n' "$1"; }
err()  { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "eas-publish.yml regression checks"

for f in "$TEMPLATE" "$WORKFLOW"; do
  if [[ -f "$f" ]]; then
    pass "exists: ${f#"$REPO_ROOT"/}"
  else
    err "missing: ${f#"$REPO_ROOT"/}"
  fi
done
if [[ $fail -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi

if diff -q "$TEMPLATE" "$WORKFLOW" >/dev/null; then
  pass "templates/ and .github/workflows/ copies are in sync"
else
  err "templates/eas-publish.yml and .github/workflows/eas-publish.yml differ — copy the template"
fi

for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if grep -q 'EXPO_TOKEN:' "$f" && grep -q 'EXPO_TOKEN: \${{ secrets.EXPO_TOKEN }}' "$f"; then
    pass "$rel forwards EXPO_TOKEN to the runner env"
  else
    err "$rel does not wire EXPO_TOKEN through — eas commands will prompt and fail"
  fi
done

for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if grep -q 'npm install --global eas-cli' "$f"; then
    pass "$rel installs eas-cli before invoking it"
  else
    err "$rel never installs eas-cli — \`eas\` will not be on PATH"
  fi
done

if [[ $fail -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "PASSED"
