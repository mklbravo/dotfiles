.DEFAULT_GOAL := help
ARGS ?=

.PHONY: help
help: ## Display available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: plan check link packages casks repositories update-repositories install restore
plan: ## Show the installation plan without making changes
	@./scripts/dotfiles plan $(ARGS)

check: ## Check managed symbolic links without making changes
	@./scripts/dotfiles check $(ARGS)

link: ## Create symbolic links; ARGS=--backup permits replacing conflicts
	@./scripts/dotfiles link $(ARGS)

packages: ## Install CLI packages using brew, apt or pacman
	@./scripts/dotfiles packages $(ARGS)

casks: ## Install optional macOS applications
	@./scripts/dotfiles casks $(ARGS)

repositories: ## Clone missing dependencies without updating existing checkouts
	@./scripts/dotfiles repositories $(ARGS)

update-repositories: ## Fast-forward clean dependency repositories
	@./scripts/dotfiles update-repositories $(ARGS)

install: ## Install links, CLI packages and Git dependencies
	@./scripts/dotfiles install $(ARGS)

restore: install ## Compatibility alias for install; Mackup is no longer used
