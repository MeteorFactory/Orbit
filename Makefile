# ─── Pipelines Makefile ───────────────────────────────────────────────────────
# Provides setup, sync, validation, and testing targets for the reusable
# GitHub Actions workflow catalog.
# ──────────────────────────────────────────────────────────────────────────────

TEMPLATES_DIR := templates
WORKFLOWS_DIR := .github/workflows
ACTIONS_DIR   := actions

# ─── Setup ────────────────────────────────────────────────────────────────────

.PHONY: install clean dev setup

## Install validation tools (requires Homebrew on macOS)
install:
	@echo "Installing validation tools…"
	@command -v actionlint >/dev/null 2>&1 || brew install actionlint
	@command -v yamllint   >/dev/null 2>&1 || brew install yamllint
	@command -v shellcheck >/dev/null 2>&1 || brew install shellcheck
	@echo "All tools installed."

## Remove generated / cached files
clean:
	@echo "Cleaning…"
	@rm -rf .kanbai-session.lock
	@find . -name '.DS_Store' -delete 2>/dev/null || true
	@echo "Clean."

## Alias for working locally (install + sync)
dev: install sync
	@echo "Ready for development."

## Full setup: clean + install + sync
setup: clean install sync
	@echo "Setup complete."

# ─── Sync ─────────────────────────────────────────────────────────────────────

.PHONY: sync sync-check

## Copy templates/ → .github/workflows/ (source of truth → consumption dir)
sync:
	@echo "Syncing templates → workflows…"
	@cp $(TEMPLATES_DIR)/*.yml $(WORKFLOWS_DIR)/
	@echo "Synced."

## Verify templates/ and .github/workflows/ are in sync (CI-friendly)
sync-check:
	@echo "Checking templates ↔ workflows sync…"
	@diff_found=0; \
	for f in $(TEMPLATES_DIR)/*.yml; do \
		name=$$(basename "$$f"); \
		wf="$(WORKFLOWS_DIR)/$$name"; \
		if [ ! -f "$$wf" ]; then \
			echo "  MISSING  $$wf"; \
			diff_found=1; \
		elif ! diff -q "$$f" "$$wf" >/dev/null 2>&1; then \
			echo "  DIFFERS  $$name"; \
			diff_found=1; \
		fi; \
	done; \
	if [ "$$diff_found" -eq 1 ]; then \
		echo "Templates and workflows are out of sync. Run 'make sync'."; \
		exit 1; \
	fi
	@echo "All in sync."

# ─── Testing & Checks ────────────────────────────────────────────────────────

.PHONY: test lint actionlint shellcheck yamllint

## Run all checks
test: yamllint actionlint shellcheck sync-check
	@echo "All checks passed."

## YAML syntax validation
yamllint:
	@echo "Running yamllint…"
	@yamllint -d '{extends: default, rules: {line-length: {max: 200}, truthy: disable, document-start: disable}}' \
		$(TEMPLATES_DIR)/*.yml $(ACTIONS_DIR)/*/action.yml

## GitHub Actions-specific linting
actionlint:
	@echo "Running actionlint…"
	@actionlint $(TEMPLATES_DIR)/*.yml

## Lint shell scripts embedded in composite actions
shellcheck:
	@echo "Running shellcheck on composite actions…"
	@for action in $(ACTIONS_DIR)/*/action.yml; do \
		echo "  Checking $$action"; \
		grep -A 999 'shell: bash' "$$action" | \
		sed -n '/run: |/,/^[[:space:]]*- name:/{ /run: |/d; /^[[:space:]]*- name:/d; p; }' | \
		shellcheck -s bash - 2>/dev/null || true; \
	done
	@echo "Shellcheck done."

# ─── Help ─────────────────────────────────────────────────────────────────────

.PHONY: help

## Show this help
help:
	@echo "Available targets:"
	@echo ""
	@echo "  Setup:"
	@echo "    make install      Install validation tools (actionlint, yamllint, shellcheck)"
	@echo "    make clean        Remove generated/cached files"
	@echo "    make dev          Install tools + sync templates"
	@echo "    make setup        Clean + install + sync (full setup)"
	@echo ""
	@echo "  Sync:"
	@echo "    make sync         Copy templates/ → .github/workflows/"
	@echo "    make sync-check   Verify templates and workflows are in sync"
	@echo ""
	@echo "  Testing:"
	@echo "    make test         Run all checks (yamllint + actionlint + shellcheck + sync-check)"
	@echo "    make yamllint     YAML syntax validation"
	@echo "    make actionlint   GitHub Actions-specific linting"
	@echo "    make shellcheck   Lint shell in composite actions"
	@echo ""
	@echo "  Other:"
	@echo "    make help         Show this help"

.DEFAULT_GOAL := help
