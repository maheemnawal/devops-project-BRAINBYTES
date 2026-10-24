
SRC_DIR := src
OUT_DIR := out

SOURCES := $(wildcard $(SRC_DIR)/*.md)
OUTPUTS := $(patsubst $(SRC_DIR)/%.md,$(OUT_DIR)/%.html,$(SOURCES))

.PHONY: all deps check build test clean ci

all: test

node_modules: package-lock.json
	npm ci
	@touch node_modules

deps: node_modules

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

$(OUT_DIR)/%.html: $(SRC_DIR)/%.md package-lock.json | $(OUT_DIR) node_modules
	@echo "  BUILD $< -> $@"
	@npm run --silent build -- $< $@

check:
	@if [ ! -d "$(SRC_DIR)" ]; then \
		echo "ERROR: source directory '$(SRC_DIR)' does not exist"; \
		exit 2; \
	elif [ -z "$(SOURCES)" ]; then \
		echo "ERROR: no .md files found in '$(SRC_DIR)'"; \
		exit 2; \
	else \
		echo "CHECK PASSED: $(words $(SOURCES)) source file(s) found"; \
	fi

build: $(OUTPUTS)

test: build
	@npm test --silent

clean:
	@rm -rf $(OUT_DIR)
	@echo "CLEAN: removed $(OUT_DIR)"

ci:
	@$(MAKE) clean
	@$(MAKE) check
	@$(MAKE) test


.PHONY: help package

help:
	@grep -E '^[a-zA-Z0-9_-]+:.*##' Makefile | awk 'BEGIN {FS = ":.*## "}; {printf "  %-10s %s\n", $$1, $$2}'

package: test
	npm pack
