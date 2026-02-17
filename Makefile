PREFIX ?= /usr/local

BIN_DIR = $(PREFIX)/bin
SCRIPT  = bin/claw-drive

.PHONY: install uninstall lint test help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install claw-drive to $(PREFIX)/bin
	@echo "Installing claw-drive to $(BIN_DIR)..."
	@mkdir -p $(BIN_DIR)
	@ln -sf $(abspath $(SCRIPT)) $(BIN_DIR)/claw-drive
	@chmod +x $(SCRIPT)
	@echo "✅ Installed. Run: claw-drive help"

uninstall: ## Remove claw-drive from $(PREFIX)/bin
	@rm -f $(BIN_DIR)/claw-drive
	@echo "✅ Uninstalled."

lint: ## Run shellcheck on all scripts
	@echo "Running shellcheck..."
	@shellcheck bin/claw-drive lib/*.sh || true
	@echo "Done."

test: ## Run basic smoke tests
	@echo "Running smoke tests..."
	@bash bin/claw-drive version
	@bash bin/claw-drive help > /dev/null
	@echo "✅ All tests passed."
