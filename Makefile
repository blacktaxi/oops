# Variables
ROCKSPEC := $(shell ls *.rockspec | head -n 1)
SRC := src/**/*.lua
TESTS := tests

# Default target
.PHONY: all
all: lint format test check-examples

# Install development dependencies
.PHONY: deps
deps:
	@echo "📦 Installing development dependencies..."
	luarocks install --only-deps oops-scm-1.rockspec

# Run tests using busted
.PHONY: test
test:
	@echo "🔍 Running tests..."
	@LUA_PATH="./lib/?.lua;;" busted $(TESTS)

# New target to install locally built library and run tests
.PHONY: build-test
build-test:
	@echo "🏗️ Building and installing the local library..."
	luarocks make oops-0.2-1.rockspec

	@echo "🧪 Running tests with the installed library..."
	busted $(TESTS)

.PHONY: check-examples
check-examples:
	@echo "📦 Running example scripts..."
	@set -e; \
	for file in examples/*.lua; do \
	  echo "▶️  Running $$file..."; \
	  LUA_PATH="./lib/?.lua;;" lua $$file > /dev/null; \
	done
	@echo "✅ All examples ran successfully."

# Run stylua formatter
.PHONY: format
format:
	@echo "🎨 Formatting with stylua..."
	stylua $(SRC) $(TESTS)

# Run luacheck linter
.PHONY: lint
lint:
	@echo "Checking rockspecs..."
	luarocks lint oops-0.2-1.rockspec
	luarocks lint oops-scm-1.rockspec
	@echo "🧼 Linting with luacheck..."
	luacheck $(SRC) $(TESTS)

# Run performance test
.PHONY: perf
perf:
	@echo "🚀 Running performance test..."
	@cd perftest && LUA_PATH="../lib/?.lua;;" lua all.lua

# Publish package to LuaRocks
.PHONY: publish
publish:
	@echo "📦 Validating and uploading rockspec..."
	luarocks lint $(ROCKSPEC)
	luarocks upload $(ROCKSPEC)

# Clean cache files (optional)
.PHONY: clean
clean:
	@echo "🧹 Cleaning up..."
	find . -name "*.luac" -delete
