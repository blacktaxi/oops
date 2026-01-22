ROCKSPEC := $(shell ls *.rockspec | head -n 1)
SRC := src
TESTS := tests
COVERAGE_THRESHOLD := 100

.PHONY: all
all: lint test check-coverage check-examples

.PHONY: deps
deps:
	@echo "📦 Installing development dependencies..."
	luarocks install --only-deps oops-scm-1.rockspec

.PHONY: test
test:
	@echo "🔍 Running tests with coverage..."
	@LUA_PATH="./src/?.lua;;" busted --coverage $(TESTS)

.PHONY: check-coverage
check-coverage:
	@echo "📊 Checking coverage threshold..."
	@if [ ! -f luacov.stats.out ]; then \
		echo "❌ No coverage data found. Run 'make test' first."; \
		exit 1; \
	fi
	@luacov > /dev/null
	@lua scripts/check_coverage.lua $(COVERAGE_THRESHOLD)

.PHONY: build-test
build-test:
	@echo "🏗️ Building and installing the local library..."
	luarocks make $(ROCKSPEC)
	@echo "🧪 Running tests with the installed library..."
	busted $(TESTS)

.PHONY: check-examples
check-examples:
	@echo "📦 Running example scripts..."
	@set -e; \
	for file in examples/*.lua; do \
	  echo "▶️  Running $$file..."; \
	  LUA_PATH="./src/?.lua;;" lua $$file > /dev/null; \
	done
	@echo "✅ All examples ran successfully."

.PHONY: format
format:
	@echo "🎨 Formatting with stylua..."
	stylua $(SRC) $(TESTS)

.PHONY: lint
lint:
	@echo "Checking rockspecs..."
	luarocks lint $(ROCKSPEC)
	luarocks lint oops-scm-1.rockspec
	@echo "🧼 Linting with luacheck..."
	luacheck $(SRC) $(TESTS)

.PHONY: perf
perf:
	@echo "🚀 Running performance test..."
	@cd perftest && LUA_PATH="../src/?.lua;;" lua all.lua

.PHONY: publish
publish: lint test check-examples build-test
	@echo "📦 Validating and uploading rockspec..."
	@luarocks lint $(ROCKSPEC)
	@luarocks upload $(ROCKSPEC) --api-key=${LUAROCKS_API_KEY}

.PHONY: clean
clean:
	@echo "🧹 Cleaning up..."
	find . -name "*.luac" -delete
	rm -f luacov.*.out
