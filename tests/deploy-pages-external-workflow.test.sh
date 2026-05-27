#!/usr/bin/env bash
#
# Regression test for templates/deploy-pages-external.yml and its
# .github/workflows copy.
#
# Covers the "Deploy Flare Site #17" failure
# (https://github.com/MeteorFactory/Impacts/actions/runs/26509873277)
# and the simultaneous failures of "Deploy Meteor Factory Site #26"
# and "Deploy Singularity Pages #61": all three runs failed during a
# `git push` (one on the branch push to the target repo, two on the
# tag push back to origin) with the transient GitHub server-side
# error `remote: fatal error in commit_refs`. A single push attempt
# offers no resilience to that class of failure, so every concurrent
# deploy on a single commit died.
#
# The fix wraps each `git push` in a 3-attempt retry loop with
# exponential-ish backoff (15s, 30s, 45s). This test fails the commit
# if either push regresses to a single non-retried call.
# It also enforces that templates/ and .github/workflows/ stay in sync.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/templates/deploy-pages-external.yml"
WORKFLOW="$REPO_ROOT/.github/workflows/deploy-pages-external.yml"

fail=0
pass() { printf '  ok    %s\n' "$1"; }
err()  { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "deploy-pages-external.yml regression checks"

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
  err "templates/deploy-pages-external.yml and .github/workflows/deploy-pages-external.yml differ — copy the template"
fi

# 3. The branch push (Deploy to external repo) must be retried so a
#    transient "fatal error in commit_refs" does not kill the deploy.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  # Find lines doing the external repo push and confirm a retry loop
  # surrounds them (`for attempt in 1 2 3` followed by an `if git push`).
  if grep -q 'for attempt in 1 2 3' "$f" \
     && grep -q 'if git push --force "https://x-access-token:' "$f"; then
    pass "$rel retries the external repo push on transient failure"
  else
    err "$rel does not wrap the external repo push in a retry loop"
  fi
done

# 4. The tag push (Create deploy tag) must also be retried — runs #26
#    and #61 both succeeded at the branch push and then died on the
#    tag push with the same transient error.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  # Count `for attempt in 1 2 3` occurrences — must be at least 2
  # (one wrapping the branch push, one wrapping the tag push).
  count=$(grep -c 'for attempt in 1 2 3' "$f" || true)
  if [[ "$count" -ge 2 ]] && grep -q 'if git push origin' "$f"; then
    pass "$rel retries the deploy tag push on transient failure"
  else
    err "$rel does not wrap the deploy tag push in a retry loop"
  fi
done

# 5. A bare `git push` without a surrounding retry would silently
#    regress the fix. Reject any push line that is not preceded by an
#    `if` (the retry guard) or `||` (intentional failure handling).
#    Comments and the `for attempt` line itself are skipped.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  bare=0
  while IFS= read -r line; do
    # Trim leading whitespace.
    trimmed="${line#"${line%%[![:space:]]*}"}"
    case "$trimmed" in
      '#'*) continue ;;                 # comment
      'if git push'*) continue ;;       # retry-guarded
      '|| '*) continue ;;               # fallback chain
      'git push '*|'git push&&'*)
        bare=$((bare + 1))
        ;;
    esac
  done < "$f"
  if [[ $bare -eq 0 ]]; then
    pass "$rel has no bare (un-retried) git push"
  else
    err "$rel contains $bare bare git push call(s) — every push must be inside a retry loop"
  fi
done

if [[ $fail -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "PASSED"
