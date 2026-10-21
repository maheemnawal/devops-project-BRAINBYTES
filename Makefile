SRC_DIR := src
OUT_DIR := out
SOURCES := $(wildcard $(SRC_DIR)/*.md)
OUTPUTS := $(patsubst $(SRC_DIR)/%.md,$(OUT_DIR)/%.html,$(SOURCES))

.PHONY: all check build test clean ci help deps package

all: test ## Build and test everything

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

node_modules: package-lock.json
	npm ci
	@touch node_modules

deps: node_modules ## Install exactly what the lock file says

$(OUT_DIR)/%.html: $(SRC_DIR)/%.md package-lock.json | $(OUT_DIR) node_modules
	@echo "  BUILD $< -> $@"
	@npm run --silent build -- $< $@

check: ## Check that source files exist
	@if [ ! -d "$(SRC_DIR)" ]; then \
	    echo "ERROR: source directory $(SRC_DIR) is missing"; \
	    exit 1; \
	fi
	@if [ -z "$(SOURCES)" ]; then \
	    echo "ERROR: no .md files found in $(SRC_DIR)"; \
	    exit 1; \
	fi
	@echo "CHECK: found $(words $(SOURCES)) source files"

build: $(OUTPUTS) ## Build all outputs

test: build ## Run the test suite against what was built
	@npm test --silent

clean: ## Remove all generated files
	rm -rf $(OUT_DIR) *.tgz

ci: clean deps check test package ## The build server entry point

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*##' Makefile | awk 'BEGIN {FS = ":.*## "}; {printf "  %-10s %s\n", $$1, $$2}'

package: test ## Produce the versioned artifact
	npm pack
