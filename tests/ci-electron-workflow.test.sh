#!/usr/bin/env bash
#
# Regression test for templates/ci-electron.yml and its .github/workflows copy.
#
# Covers the "Release Alpha #255" failure
# (https://github.com/MeteorFactory/Singularity/actions/runs/26273075867):
# commit ca64cee added a blanket `rm -rf ~/Library/Caches/electron` to the
# "Clean workspace" step. That wiped the Electron binary cache, so every
# self-hosted run had to re-download Electron (~100 MB). When three jobs
# shared a runner host, the concurrent downloads exhausted the connection
# ("RequestError: socket hang up") and `pnpm install --frozen-lockfile`
# failed before any test/lint/e2e step could run.
#
# This test fails the commit if either of those guard-rails regresses:
#   1. the Electron binary cache is wiped during "Clean workspace", or
#   2. the dependency install is no longer wrapped in a retry loop.
# It also enforces that templates/ and .github/workflows/ stay in sync.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/templates/ci-electron.yml"
WORKFLOW="$REPO_ROOT/.github/workflows/ci-electron.yml"

fail=0
pass() { printf '  ok    %s\n' "$1"; }
err()  { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "ci-electron.yml regression checks"

# 1. Both copies must exist.
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

# 2. The template is the source of truth — the workflow copy must match it.
if diff -q "$TEMPLATE" "$WORKFLOW" >/dev/null; then
  pass "templates/ and .github/workflows/ copies are in sync"
else
  err "templates/ci-electron.yml and .github/workflows/ci-electron.yml differ — copy the template"
fi

# 3. The Electron binary cache must NOT be wiped. A leading `rm` that targets
#    the cache directory is the #255 regression; a comment mentioning the
#    path (starts with '#') is fine.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if grep -Eq '^[[:space:]]*rm[[:space:]].*(Library/Caches/electron|\.cache/electron)' "$f"; then
    err "$rel wipes the Electron binary cache — forces a re-download on every run"
  else
    pass "$rel keeps the Electron binary cache between runs"
  fi
done

# 4. Dependency install must retry, so a single transient network blip during
#    a native-module download does not fail the whole pipeline.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if grep -q 'for attempt in 1 2 3' "$f" \
     && grep -q 'pnpm install --frozen-lockfile && exit 0' "$f"; then
    pass "$rel retries dependency install on transient failure"
  else
    err "$rel does not wrap the dependency install in a retry loop"
  fi
done

# 5. The pnpm install retry must wipe node_modules between attempts.
#    Covers the "Release Alpha #266" failure
#    (https://github.com/MeteorFactory/Singularity/actions/runs/26300902505):
#    attempt 1's `electron` postinstall aborted mid binary-download on a
#    transient "socket hang up". pnpm does not re-run a dependency's
#    postinstall on a plain `pnpm install` retry — the package is already
#    linked into node_modules — so attempt 2 exited 0 with electron's
#    binary still missing, and every e2e suite then died at launch with
#    "Electron failed to install correctly". A clean retry must remove
#    node_modules so the reinstall re-runs every postinstall.
#
#    `rm -rf node_modules` must appear on its own line: the "Clean
#    workspace" step removes `node_modules dist out …` on one line, which
#    this anchored pattern deliberately does NOT match.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if grep -Eq '^[[:space:]]*rm -rf node_modules[[:space:]]*$' "$f"; then
    pass "$rel wipes node_modules between pnpm install retries"
  else
    err "$rel pnpm install retry does not wipe node_modules — a half-built dep (e.g. electron) survives the retry"
  fi
done

if [[ $fail -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "PASSED"
