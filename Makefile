PREFIX ?= /usr/local
BIN_DIR := $(PREFIX)/bin
SRC_BIN := $(shell pwd)/bin/md2pdf

.PHONY: install install-link uninstall test check-deps help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

install: ## Install md2pdf to PREFIX/bin (copy)
	@mkdir -p "$(BIN_DIR)"
	@cp "$(SRC_BIN)" "$(BIN_DIR)/md2pdf"
	@chmod +x "$(BIN_DIR)/md2pdf"
	@echo "Installed: $(BIN_DIR)/md2pdf"

install-link: ## Install md2pdf to PREFIX/bin (symlink)
	@mkdir -p "$(BIN_DIR)"
	@ln -sf "$(SRC_BIN)" "$(BIN_DIR)/md2pdf"
	@echo "Installed: $(BIN_DIR)/md2pdf -> $(SRC_BIN)"

uninstall: ## Remove md2pdf from PREFIX/bin
	@rm -f "$(BIN_DIR)/md2pdf"
	@echo "Removed: $(BIN_DIR)/md2pdf"

test: ## Run test suite (requires bats-core)
	@command -v bats >/dev/null 2>&1 || { echo "bats-core is required: brew install bats-core"; exit 1; }
	bats tests/

check-deps: ## Check dependencies for all modes
	./bin/md2pdf --check-deps-all
