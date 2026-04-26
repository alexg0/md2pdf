PREFIX ?= /usr/local
BIN_DIR := $(PREFIX)/bin
SRC_BIN := $(shell pwd)/bin/md2pdf
VERSION_FILE := $(shell pwd)/VERSION

.PHONY: install install-link uninstall test check-deps install-prereqs release-tag help

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
	@command -v bats >/dev/null 2>&1 || { echo "bats-core is required: run 'make install-prereqs' or 'brew install bats-core'"; exit 1; }
	bats tests/

check-deps: ## Check dependencies for all modes
	./bin/md2pdf --check-deps-all

release-tag: ## Bump VERSION (VERSION=X.Y.Z), update baked constant, commit, tag vX.Y.Z
	@if [ -z "$(VERSION)" ]; then echo "Usage: make release-tag VERSION=X.Y.Z"; exit 1; fi
	@if ! echo "$(VERSION)" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$'; then echo "VERSION must be semver X.Y.Z"; exit 1; fi
	@if [ -n "$$(git status --porcelain)" ]; then echo "Working tree not clean; commit or stash first."; exit 1; fi
	@if git rev-parse "v$(VERSION)" >/dev/null 2>&1; then echo "Tag v$(VERSION) already exists"; exit 1; fi
	@echo "$(VERSION)" > "$(VERSION_FILE)"
	@/usr/bin/sed -i.bak -E 's/^MD2PDF_VERSION = "[^"]+"/MD2PDF_VERSION = "$(VERSION)"/' "$(SRC_BIN)"
	@rm -f "$(SRC_BIN).bak"
	@git add VERSION bin/md2pdf
	@git commit -m "Release v$(VERSION)"
	@git tag -a "v$(VERSION)" -m "v$(VERSION)"
	@echo "Tagged v$(VERSION). Push with: git push origin master && git push origin v$(VERSION)"

install-prereqs: ## Install development prerequisites (bats-core)
	@if command -v bats >/dev/null 2>&1; then \
		echo "bats-core already installed: $$(bats --version)"; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install bats-core; \
	elif command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y bats; \
	else \
		echo "Cannot auto-install bats-core on this platform."; \
		echo "See https://bats-core.readthedocs.io/en/stable/installation.html"; \
		exit 1; \
	fi
