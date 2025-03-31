# Variables
ROCKSPEC := $(shell ls *.rockspec | head -n 1)
SRC := src/**/*.lua
TESTS := tests
PERF := perf/perf_test.lua

# Default target
.PHONY: all
all: lint format test

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
	lua $(PERF)

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
