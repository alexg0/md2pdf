PREFIX ?= /usr/local
SCRIPT_DIR := $(shell pwd)

.PHONY: install uninstall test check-deps lint help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

install: ## Install md2pdf to PREFIX/bin (default: /usr/local/bin)
	@mkdir -p "$(PREFIX)/bin"
	@ln -sf "$(SCRIPT_DIR)/md2pdf.sh" "$(PREFIX)/bin/md2pdf"
	@echo "Installed: $(PREFIX)/bin/md2pdf -> $(SCRIPT_DIR)/md2pdf.sh"

uninstall: ## Remove md2pdf from PREFIX/bin
	@rm -f "$(PREFIX)/bin/md2pdf"
	@echo "Removed: $(PREFIX)/bin/md2pdf"

test: ## Run test suite (requires bats-core)
	@command -v bats >/dev/null 2>&1 || { echo "bats-core is required: brew install bats-core"; exit 1; }
	bats tests/

check-deps: ## Check dependencies for all modes
	./md2pdf.sh --check-deps-all

lint: ## Run shellcheck on md2pdf.sh
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck is required: brew install shellcheck"; exit 1; }
	shellcheck md2pdf.sh
