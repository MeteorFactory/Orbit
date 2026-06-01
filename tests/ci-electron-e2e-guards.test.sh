#!/usr/bin/env bash
#
# Regression test for templates/ci-electron.yml and its .github/workflows copy.
#
# Covers the "Release Alpha #321" failure
# (https://github.com/MeteorFactory/Singularity/actions/runs/26649718419):
# the `Run e2e tests (macOS/Windows)` step was a raw `pnpm run test:e2e`
# invocation with no per-attempt timeout, no caffeinate wrap, no heartbeat
# and no retry loop. On self-hosted macOS Tart hosts hosting parallel CI
# jobs, the long silent phases of Playwright + Electron startup let the
# host enter idle/disk sleep; the runner agent then lost its WebSocket
# and the step ended in `failure` with `logId: null` / `result: in_progress`
# at 12m54s into the test — same signature as Release Alpha #281/#290 for
# electron-builder, for which release-alpha.yml had already grown four
# guard rails (caffeinate, gtimeout per-attempt cap, stdout heartbeat,
# diag dumps + retry loop). This test fails the commit if any of those
# guard rails regresses on the macOS e2e step.
#
# Windows hosted runners do not exhibit the App-Nap suspension failure
# mode, so the Windows step is intentionally left as a raw invocation.
#
# Linux DID need the guards: Release Alpha runs #337/#338/#339 all
# blocked on the Linux e2e step under `os-matrix: '["self-hosted"]'` —
# a Neutron-provisioned self-hosted Linux runner that shares the host
# with build-linux. The previous assumption ("Linux uses xvfb-run on
# hosted runners, no guards needed") missed that the self-hosted Linux
# path can hang Playwright/Electron startup and consume the whole
# 30-min budget with no retry. The Linux step now mirrors the macOS
# guards minus the macOS-only caffeinate wrap (Linux has no App Nap).

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/templates/ci-electron.yml"
WORKFLOW="$REPO_ROOT/.github/workflows/ci-electron.yml"

fail=0
pass() { printf '  ok    %s\n' "$1"; }
err()  { printf '  FAIL  %s\n' "$1"; fail=1; }

echo "ci-electron.yml macOS e2e guard-rail checks"

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

# 2. The macOS e2e step must wrap test:e2e in caffeinate to block macOS
#    idle-sleep, so the Tart VM hosting parallel CI jobs cannot be
#    suspended out from under the runner agent while Playwright/Electron
#    is silent.
#    The `caffeinate` invocation and the `run test:e2e` invocation live
#    on consecutive lines joined by a backslash continuation, so use a
#    multi-line `awk` pass instead of a single-line `grep`.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if awk '
      /caffeinate -i -m/ { saw_caffeinate = 1; next }
      saw_caffeinate && /run test:e2e/ { found = 1; exit }
      saw_caffeinate && !/\\[[:space:]]*$/ && !/^[[:space:]]*$/ { saw_caffeinate = 0 }
      END { exit found ? 0 : 1 }
    ' "$f"; then
    pass "$rel macOS e2e step wraps test:e2e in caffeinate -i -m"
  else
    err "$rel macOS e2e step is missing 'caffeinate -i -m ... run test:e2e' — Tart VM can sleep mid-test"
  fi
done

# 3. The macOS e2e step must cap each attempt with gtimeout/timeout so a
#    single hung Playwright invocation cannot burn the entire job budget
#    and starve the retry loop.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if grep -Eq '"\$TIMEOUT_BIN" --kill-after=30s [0-9]+m[[:space:]]+\\?$' "$f" \
     || grep -Eq '"\$TIMEOUT_BIN" --kill-after=30s [0-9]+m ' "$f"; then
    pass "$rel macOS e2e step caps each attempt with \$TIMEOUT_BIN --kill-after"
  else
    err "$rel macOS e2e step is missing a per-attempt \$TIMEOUT_BIN cap — hung Playwright will burn the whole job budget"
  fi
done

# 4. The macOS e2e step must run inside a retry loop so a single transient
#    runner-agent flake does not fail the whole pipeline.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if grep -Eq '^[[:space:]]*for attempt in 1 2[[:space:]]*;[[:space:]]*do[[:space:]]*$' "$f" \
     || grep -Eq '^[[:space:]]*for attempt in 1 2 3[[:space:]]*;[[:space:]]*do[[:space:]]*$' "$f"; then
    pass "$rel macOS e2e step runs inside a retry loop"
  else
    err "$rel macOS e2e step does not retry — a transient runner blip fails the whole pipeline"
  fi
done

# 5. The macOS e2e step must emit a stdout heartbeat so a future
#    runner-agent death pins down WHERE progress stopped instead of
#    vanishing into "step in_progress, job failure" with no log.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if grep -q 'start_heartbeat' "$f" && grep -q '\[heartbeat ' "$f"; then
    pass "$rel macOS e2e step emits a stdout heartbeat during silent phases"
  else
    err "$rel macOS e2e step is missing the stdout heartbeat — silent runner deaths will be opaque"
  fi
done

# 6. The macOS e2e step must dump diagnostics before/after each attempt
#    so the next runner death leaves actionable data instead of vanishing
#    into the runner-agent crash.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if grep -Eq 'diag[[:space:]]+"before-e2e"' "$f" \
     && grep -Eq 'diag[[:space:]]+"after-attempt-' "$f"; then
    pass "$rel macOS e2e step dumps runner state before/after attempts"
  else
    err "$rel macOS e2e step does not dump runner state — future failures will be opaque"
  fi
done

# 7. The macOS-specific step must be gated by `runner.os == 'macOS'`, and
#    the Windows step must be gated by `runner.os == 'Windows'`. The
#    historical `runner.os != 'Linux'` collapsed both OSes into a single
#    step, which forced the macOS-only guard rails (caffeinate, vm_stat,
#    brew) onto Windows where they do not exist.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if grep -Eq "if:[[:space:]]+runner\.os[[:space:]]*==[[:space:]]*'macOS'" "$f" \
     && grep -Eq "if:[[:space:]]+runner\.os[[:space:]]*==[[:space:]]*'Windows'" "$f"; then
    pass "$rel splits macOS and Windows e2e steps by runner.os"
  else
    err "$rel does not split macOS and Windows e2e steps — macOS-only guards leak onto Windows"
  fi
done

# 8. The Linux e2e step must wrap test:e2e in a per-attempt timeout so a
#    single hung Playwright invocation cannot burn the whole 30-min job
#    budget on a self-hosted Linux runner (Release Alpha #337/#338/#339).
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if awk '
      /timeout --kill-after=30s [0-9]+m/ { saw_timeout = 1; next }
      saw_timeout && /xvfb-run/ && /run test:e2e/ { found = 1; exit }
      saw_timeout && !/\\[[:space:]]*$/ && !/^[[:space:]]*$/ { saw_timeout = 0 }
      END { exit found ? 0 : 1 }
    ' "$f"; then
    pass "$rel Linux e2e step caps each attempt with timeout --kill-after"
  else
    err "$rel Linux e2e step is missing a per-attempt timeout — hung Playwright will burn the whole job budget on self-hosted Linux"
  fi
done

# 9. The Linux e2e step must run inside a retry loop so a single transient
#    self-hosted runner blip does not fail the whole pipeline.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  # The Linux step uses `for attempt in 1 2`; the macOS step uses the same.
  # We already asserted the macOS retry loop above — assert there are at
  # LEAST two such loops in the file so the Linux one cannot regress to
  # a single invocation.
  count=$(grep -Ec '^[[:space:]]*for attempt in 1 2[[:space:]]*;[[:space:]]*do[[:space:]]*$' "$f" || true)
  if [[ "$count" -ge 2 ]]; then
    pass "$rel Linux + macOS e2e steps both run inside retry loops"
  else
    err "$rel only $count retry loop(s) for e2e — Linux must also retry on self-hosted runner blips"
  fi
done

# 10. The Linux e2e step must emit a stdout heartbeat AND diag dumps so a
#     silent runner death pins down where progress stopped. Same rationale
#     as the macOS step but on /proc/meminfo (Linux) instead of vm_stat.
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  if grep -q 'MemAvailable' "$f" && grep -q 'free -m' "$f"; then
    pass "$rel Linux e2e step emits heartbeat + diag (MemAvailable, free -m)"
  else
    err "$rel Linux e2e step is missing the /proc/meminfo heartbeat or free -m diag — silent runner deaths will be opaque"
  fi
done

# 11. The e2e per-attempt timeout must stay LARGE ENOUGH to leave Playwright
#     real runtime after the in-step `electron-vite build`. Covers the
#     "Release Alpha #346" failure
#     (https://github.com/MeteorFactory/Singularity/actions/runs/26739728330):
#     `test:e2e` is `electron-vite build && playwright test`, both run inside
#     the per-attempt `timeout`/`gtimeout`. With the old 12-min cap the ~3-4
#     min build left only ~8 min of Playwright runtime; the consumer's
#     Playwright `globalTimeout` had to be squeezed BELOW that to fire (and
#     reap leaked Electron trees) before the cap's SIGKILL — but on the
#     contended self-hosted Linux runner a healthy 39-suite serial run needs
#     MORE than that squeezed window, so Playwright self-aborted at its own
#     globalTimeout and the e2e step failed. Raising the cap to >= 18 min
#     gives Playwright >= ~14 min, room for both a healthy run AND a
#     globalTimeout that still reaps before SIGKILL. This guard fails the
#     commit if a future edit drops the cap back toward the 12-min squeeze.
#
#     The consumer side of this contract (Playwright `globalTimeout` <= the
#     Playwright slice of this cap, and >= a realistic healthy run) is pinned
#     in Singularity's tests/build/e2e-harness-timeouts.test.ts. Keep the two
#     in lock-step: if you change the cap here, update that guard's
#     CI_E2E_ATTEMPT_TIMEOUT_MS constant in the same change-set.
MIN_E2E_ATTEMPT_MINUTES=18
for f in "$TEMPLATE" "$WORKFLOW"; do
  rel="${f#"$REPO_ROOT"/}"
  # Pull every per-attempt e2e cap (Linux `timeout` + macOS `$TIMEOUT_BIN`)
  # and assert each is >= the floor. `--kill-after=30s` is the grace window,
  # not the cap, so anchor on the minute value that follows it.
  caps=$(grep -Eo -- '--kill-after=30s [0-9]+m' "$f" | grep -Eo '[0-9]+' || true)
  if [[ -z "$caps" ]]; then
    err "$rel has no per-attempt e2e timeout cap to check"
    continue
  fi
  step_ok=1
  for minutes in $caps; do
    if [[ "$minutes" -lt "$MIN_E2E_ATTEMPT_MINUTES" ]]; then
      err "$rel has an e2e per-attempt cap of ${minutes}m (< ${MIN_E2E_ATTEMPT_MINUTES}m) — the build squeezes Playwright runtime (Release Alpha #346)"
      step_ok=0
    fi
  done
  if [[ "$step_ok" -eq 1 ]]; then
    pass "$rel all e2e per-attempt caps are >= ${MIN_E2E_ATTEMPT_MINUTES}m (leaves Playwright real runtime after the build)"
  fi
done

if [[ $fail -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "PASSED"
