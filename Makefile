# Termbrain Makefile

.PHONY: all install test lint clean help dev-install uninstall

# Default target
all: help

# Install termbrain
install:
	@echo "🧠 Installing Termbrain..."
	@./install.sh

# Uninstall termbrain
uninstall:
	@echo "🗑️  Uninstalling Termbrain..."
	@./uninstall.sh

# Run all tests
test: test-unit test-integration test-platform

# Run unit tests
test-unit:
	@echo "🧪 Running unit tests..."
	@bash tests/test_workflows.sh

# Run integration tests
test-integration:
	@echo "🧪 Running integration tests..."
	@if [ -f tests/test_integration.sh ]; then \
		bash tests/test_integration.sh; \
	else \
		echo "Integration tests not found"; \
	fi

# Run platform tests
test-platform:
	@echo "🧪 Running platform tests..."
	@bash tests/test_platform.sh

# Run linter
lint:
	@echo "🔍 Running shellcheck..."
	@find . -name "*.sh" -type f -not -path "./.git/*" | while read -r file; do \
		echo "Checking: $$file"; \
		shellcheck -x "$$file" || true; \
	done
	@find bin -type f -not -name ".*" -not -path "./.git/*" | while read -r file; do \
		echo "Checking: $$file"; \
		shellcheck -x "$$file" || true; \
	done

# Format code
format:
	@echo "🎨 Formatting code..."
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -w -i 4 -bn -ci -sr bin/* lib/**/*.sh src/*.sh tests/*.sh; \
		echo "✅ Code formatted"; \
	else \
		echo "❌ shfmt not found. Install with: brew install shfmt"; \
	fi

# Development install (symlink)
dev-install:
	@echo "🔗 Creating development symlinks..."
	@mkdir -p ~/.termbrain
	@ln -sf $(PWD)/lib ~/.termbrain/lib
	@ln -sf $(PWD)/bin ~/.termbrain/bin
	@ln -sf $(PWD)/src ~/.termbrain/src
	@echo "✅ Development environment ready"

# Clean temporary files
clean:
	@echo "🧹 Cleaning temporary files..."
	@rm -f /tmp/termbrain_test_*.db
	@rm -f /tmp/tb_*
	@rm -rf ~/.termbrain/cache/*
	@echo "✅ Cleaned"

# Check dependencies
check-deps:
	@echo "🔍 Checking dependencies..."
	@command -v sqlite3 >/dev/null 2>&1 || echo "❌ sqlite3 not found"
	@command -v jq >/dev/null 2>&1 || echo "❌ jq not found"
	@command -v bc >/dev/null 2>&1 || echo "⚠️  bc not found (optional)"
	@command -v fzf >/dev/null 2>&1 || echo "⚠️  fzf not found (optional for search)"
	@echo "✅ Dependency check complete"

# Run workflow tests specifically
test-workflows:
	@echo "🧪 Testing workflow features..."
	@bash tests/test_workflows.sh

# Test SQL escaping
test-sql:
	@echo "🧪 Testing SQL escaping..."
	@bash -c 'source ~/.termbrain/bin/termbrain && \
		tb workflow create "sql-test" "Test SQL" "echo '\''Hello World'\''" "echo \"It'\''s working\"" && \
		tb workflow run "sql-test" && \
		tb workflow delete "sql-test"'

# CI simulation
ci: lint test
	@echo "✅ CI checks passed"

# Generate documentation
docs:
	@echo "📚 Generating documentation..."
	@if command -v grip >/dev/null 2>&1; then \
		grip README.md --export README.html; \
		echo "✅ Documentation generated"; \
	else \
		echo "❌ grip not found. Install with: pip install grip"; \
	fi

# Show help
help:
	@echo "🧠 Termbrain Development Commands"
	@echo "================================"
	@echo "make install      - Install Termbrain"
	@echo "make uninstall    - Uninstall Termbrain"
	@echo "make test         - Run all tests"
	@echo "make test-unit    - Run unit tests"
	@echo "make test-platform - Run platform compatibility tests"
	@echo "make test-workflows - Test workflow features"
	@echo "make lint         - Run shellcheck linter"
	@echo "make format       - Format code with shfmt"
	@echo "make dev-install  - Set up development environment"
	@echo "make clean        - Clean temporary files"
	@echo "make check-deps   - Check dependencies"
	@echo "make ci           - Run CI checks locally"
	@echo "make help         - Show this help"

# Watch for changes (requires entr)
watch:
	@if command -v entr >/dev/null 2>&1; then \
		find . -name "*.sh" -o -name "termbrain*" | entr -c make test; \
	else \
		echo "❌ entr not found. Install with: brew install entr"; \
	fi