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
	luarocks install --only-deps oops-0.0-0.rockspec

# Run tests using busted
.PHONY: test
test:
	@echo "🔍 Running tests..."
	@LUA_PATH="./lib/?.lua;;" busted $(TESTS)

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
