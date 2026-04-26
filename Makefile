PREFIX ?= /usr/local
BIN_DIR := $(PREFIX)/bin
DEV_PREFIX ?= $(HOME)/.local
DEV_BIN_DIR := $(DEV_PREFIX)/bin
SRC_BIN := $(shell pwd)/bin/md2pdf
VERSION_FILE := $(shell pwd)/VERSION

.PHONY: install install-link install-dev uninstall uninstall-dev test check-deps install-prereqs release-tag release help

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

install-dev: ## Symlink dev build into DEV_PREFIX/bin (default ~/.local/bin) to shadow Homebrew
	@mkdir -p "$(DEV_BIN_DIR)"
	@ln -sf "$(SRC_BIN)" "$(DEV_BIN_DIR)/md2pdf"
	@echo "Installed: $(DEV_BIN_DIR)/md2pdf -> $(SRC_BIN)"
	@case ":$$PATH:" in \
		*":$(DEV_BIN_DIR):"*) \
			active="$$(command -v md2pdf)"; \
			if [ "$$active" = "$(DEV_BIN_DIR)/md2pdf" ]; then \
				echo "Active: $$active (dev shim wins)"; \
			else \
				echo "Warning: $$active is earlier in PATH than $(DEV_BIN_DIR); dev shim is shadowed."; \
			fi ;; \
		*) \
			echo "Warning: $(DEV_BIN_DIR) is not in PATH; add it to your shell rc to activate the dev shim." ;; \
	esac

uninstall: ## Remove md2pdf from PREFIX/bin
	@rm -f "$(BIN_DIR)/md2pdf"
	@echo "Removed: $(BIN_DIR)/md2pdf"

uninstall-dev: ## Remove dev shim from DEV_PREFIX/bin
	@rm -f "$(DEV_BIN_DIR)/md2pdf"
	@echo "Removed: $(DEV_BIN_DIR)/md2pdf"

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

release: ## Bump, commit, tag, and push origin master + tag (triggers Homebrew tap PR)
	@git fetch --quiet origin master
	@if [ "$$(git rev-parse HEAD)" != "$$(git rev-parse origin/master)" ]; then \
		echo "Refusing to release: HEAD is not at origin/master."; \
		echo "  HEAD:           $$(git rev-parse --short HEAD) ($$(git rev-parse --abbrev-ref HEAD))"; \
		echo "  origin/master:  $$(git rev-parse --short origin/master)"; \
		exit 1; \
	fi
	@$(MAKE) release-tag VERSION=$(VERSION)
	@git push origin HEAD:master
	@git push origin "v$(VERSION)"

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
