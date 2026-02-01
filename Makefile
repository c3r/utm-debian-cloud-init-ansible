# =========================
# Configuration
# =========================

ROOT_DIR := $(shell git rev-parse --show-toplevel)
ANSIBLE_PLAYBOOK := ansible-playbook
PLAYBOOK := $(ROOT_DIR)/scripts/generate-cloud-init.yml
SEED_SCRIPT := $(ROOT_DIR)/scripts/build-seed-isos.sh

# Colors
RESET  := \033[0m
BOLD   := \033[1m
CYAN   := \033[36m
GREEN  := \033[32m
YELLOW := \033[33m
RED    := \033[31m

.DEFAULT_GOAL := help

# =========================
# Help
# =========================
.PHONY: help
help: ## Show this help
	@echo ""
	@echo "$(BOLD)Available targets$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} \
	/^[a-zA-Z0-9_-]+:.*##/ { \
		printf "  $(CYAN)%-18s$(RESET) %s\n", $$1, $$2 \
	}' $(MAKEFILE_LIST)
	@echo ""

# =========================
# Validation
# =========================
.PHONY: validate
validate: ## Validate cloud-init configuration (no files written)
	@echo "$(YELLOW)==> Validating configuration$(RESET)"
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOK) --check

# =========================
# Apply / Generate
# =========================
.PHONY: apply
apply: ## Generate cloud-init files and seed ISOs
	@echo "$(GREEN)==> Generating cloud-init configs$(RESET)"
	$(ANSIBLE_PLAYBOOK) $(PLAYBOOK)
	@echo "$(GREEN)==> Building seed ISOs$(RESET)"
	$(SEED_SCRIPT)

# Alias
.PHONY: cloud-init
cloud-init: apply ## Alias for apply

# =========================
# Cleanup
# =========================
.PHONY: clean
clean: ## Remove generated cloud-init artifacts
	@echo "$(RED)==> Cleaning generated files$(RESET)"
	rm -rf build/

