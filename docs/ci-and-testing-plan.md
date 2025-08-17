# Termbrain CI/CD and Testing Plan

## Current Issues to Address

### 1. SQL Escaping Problems
- **Issue**: Complex quotes in commands break SQL inserts
- **Root Cause**: JSON column type + shell quote escaping
- **Solutions**:
  - ✅ Use normalized tables (workflow_commands)
  - ✅ Base64 encoding for complex strings
  - ✅ Parameterized queries where possible
  - Use prepared statements (limited in bash/sqlite3)

### 2. Missing Test Infrastructure
- **Issue**: No automated tests
- **Impact**: Features break without notice
- **Solution**: Comprehensive test suite

### 3. Installation Issues
- **Issue**: Files not found after installation
- **Root Cause**: Hardcoded paths, missing files
- **Solution**: Proper installation testing

### 4. Cross-Platform Compatibility
- **Issue**: macOS-specific commands (e.g., `date` format)
- **Solution**: Platform detection and compatibility layer

## CI/CD Pipeline Design

### GitHub Actions Workflows

#### 1. `.github/workflows/test.yml` - Main Test Pipeline
```yaml
name: Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install shellcheck
        run: sudo apt-get install -y shellcheck
      - name: Lint shell scripts
        run: |
          find . -name "*.sh" -type f | xargs shellcheck -x
          find bin -type f | xargs shellcheck -x

  test-unit:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        shell: [bash, zsh]
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: |
          if [[ "${{ matrix.os }}" == "ubuntu-latest" ]]; then
            sudo apt-get update
            sudo apt-get install -y sqlite3 jq bc
          else
            brew install sqlite3 jq bc
          fi
      - name: Run unit tests
        run: |
          export TEST_SHELL="${{ matrix.shell }}"
          ./tests/run-unit-tests.sh

  test-integration:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: |
          if [[ "${{ matrix.os }}" == "ubuntu-latest" ]]; then
            sudo apt-get update
            sudo apt-get install -y sqlite3 jq bc expect
          else
            brew install sqlite3 jq bc expect
          fi
      - name: Run integration tests
        run: ./tests/run-integration-tests.sh

  test-installation:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        method: [curl, git]
    steps:
      - uses: actions/checkout@v3
      - name: Test installation
        run: |
          # Test installation method
          if [[ "${{ matrix.method }}" == "curl" ]]; then
            # Simulate curl installation
            bash -c "$(cat install.sh)"
          else
            # Simulate git installation
            ./install.sh
          fi
          
          # Verify installation
          source ~/.bashrc
          tb help
          tb workflow list

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run security scan
        run: |
          # Check for hardcoded secrets
          grep -r "password\|secret\|key\|token" --exclude-dir=.git . || true
          
          # Check for unsafe command execution
          grep -r "eval\|exec" --exclude-dir=.git . || true
```

#### 2. `.github/workflows/release.yml` - Release Pipeline
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run all tests
        run: make test
      
      - name: Build release artifacts
        run: |
          # Create tarball
          tar -czf termbrain-${GITHUB_REF##*/}.tar.gz \
            --exclude='.git' \
            --exclude='tests' \
            --exclude='docs' \
            .
          
          # Create checksums
          sha256sum termbrain-${GITHUB_REF##*/}.tar.gz > checksums.txt
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            termbrain-*.tar.gz
            checksums.txt
          body: |
            See [CHANGELOG.md](https://github.com/${{ github.repository }}/blob/main/CHANGELOG.md) for details.
```

## Test Suite Structure

### 1. Unit Tests
```bash
tests/
├── unit/
│   ├── test_helper.sh           # Common test functions
│   ├── domain/
│   │   ├── workflow_entity_test.sh
│   │   └── command_entity_test.sh
│   ├── application/
│   │   ├── create_workflow_test.sh
│   │   └── run_workflow_test.sh
│   └── infrastructure/
│       └── sqlite_repository_test.sh
```

### 2. Integration Tests
```bash
tests/
├── integration/
│   ├── workflow_integration_test.sh
│   ├── command_capture_test.sh
│   ├── pattern_detection_test.sh
│   └── ai_context_test.sh
```

### 3. End-to-End Tests
```bash
tests/
├── e2e/
│   ├── full_workflow_test.sh
│   ├── installation_test.sh
│   └── shell_integration_test.sh
```

## Test Implementation Examples

### Unit Test Example
```bash
#!/usr/bin/env bash
# tests/unit/domain/workflow_entity_test.sh

source tests/unit/test_helper.sh
source lib/domain/entities/workflow.sh

test_workflow_creation() {
    local workflow=$(Workflow::new "test" "Test workflow" "echo hello" "echo world")
    
    assert_equals "test" "$(Workflow::get "$workflow" "name")"
    assert_equals "Test workflow" "$(Workflow::get "$workflow" "description")"
    assert_equals "2" "$(Workflow::get "$workflow" "command_count")"
}

test_workflow_validation() {
    # Test invalid name
    local result=$(Workflow::new "test@123" "Test" "echo hello" 2>&1)
    assert_contains "$result" "ERROR"
    
    # Test empty commands
    result=$(Workflow::new "test" "Test" 2>&1)
    assert_contains "$result" "ERROR"
}

# Run tests
run_test test_workflow_creation
run_test test_workflow_validation
```

### Integration Test Example
```bash
#!/usr/bin/env bash
# tests/integration/workflow_integration_test.sh

source tests/unit/test_helper.sh

setup() {
    export TERMBRAIN_DB="/tmp/test_termbrain.db"
    rm -f "$TERMBRAIN_DB"
}

teardown() {
    rm -f "$TERMBRAIN_DB"
}

test_workflow_full_cycle() {
    # Create workflow
    ./bin/termbrain workflow create test "Test" "echo hello" "echo world"
    assert_equals "0" "$?"
    
    # List workflows
    local output=$(./bin/termbrain workflow list)
    assert_contains "$output" "test"
    
    # Run workflow
    output=$(./bin/termbrain workflow run test)
    assert_contains "$output" "hello"
    assert_contains "$output" "world"
    assert_contains "$output" "completed successfully"
    
    # Check stats updated
    output=$(./bin/termbrain workflow show test)
    assert_contains "$output" "Used 1 times"
    
    # Delete workflow
    ./bin/termbrain workflow delete test
    assert_equals "0" "$?"
}

# Run tests
run_test test_workflow_full_cycle
```

## Platform Compatibility Layer

### `lib/core/platform.sh`
```bash
#!/usr/bin/env bash
# Platform compatibility layer

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

# Date command compatibility
date_iso() {
    case "$(detect_platform)" in
        macos)  date -u +"%Y-%m-%dT%H:%M:%SZ" ;;
        linux)  date -u --iso-8601=seconds ;;
        *)      date ;;
    esac
}

# Base64 compatibility
base64_encode() {
    case "$(detect_platform)" in
        macos)  base64 ;;
        linux)  base64 -w 0 ;;
        *)      base64 ;;
    esac
}

# Sed compatibility
sed_inplace() {
    case "$(detect_platform)" in
        macos)  sed -i '' "$@" ;;
        linux)  sed -i "$@" ;;
        *)      sed -i "$@" ;;
    esac
}
```

## Makefile for Development
```makefile
# Makefile

.PHONY: install test lint clean

install:
	./install.sh

test: test-unit test-integration test-e2e

test-unit:
	./tests/run-unit-tests.sh

test-integration:
	./tests/run-integration-tests.sh

test-e2e:
	./tests/run-e2e-tests.sh

lint:
	shellcheck -x bin/* lib/**/*.sh src/*.sh

format:
	shfmt -w -i 4 bin/* lib/**/*.sh src/*.sh

clean:
	rm -rf ~/.termbrain/data/test_*.db
	rm -f /tmp/tb_*

dev-install:
	ln -sf $(PWD)/bin/termbrain /usr/local/bin/tb-dev

coverage:
	bashcov ./tests/run-all-tests.sh
```

## SQL Best Practices

### 1. Use Transactions
```bash
sqlite3 "$DB" <<EOF
BEGIN TRANSACTION;
INSERT INTO workflows ...;
INSERT INTO workflow_commands ...;
COMMIT;
EOF
```

### 2. Prepared Statements (via temp files)
```bash
# Create SQL template
cat > /tmp/insert.sql <<EOF
INSERT INTO commands (command, timestamp) VALUES (?, ?);
EOF

# Use with parameters
echo "$command|$timestamp" | sqlite3 -separator '|' "$DB" ".import /dev/stdin commands"
```

### 3. Escape Functions
```bash
sql_escape() {
    echo "$1" | sed "s/'/''/g"
}
```

## Error Handling Standards

### 1. Function Template
```bash
function_name() {
    local param1="$1"
    
    # Validate inputs
    if [[ -z "$param1" ]]; then
        echo "ERROR: param1 is required" >&2
        return 1
    fi
    
    # Main logic with error handling
    if ! some_command; then
        echo "ERROR: Failed to execute some_command" >&2
        return 1
    fi
    
    return 0
}
```

### 2. Global Error Handler
```bash
set -euo pipefail
trap 'echo "Error on line $LINENO"' ERR
```

## Performance Monitoring

### 1. Execution Time Tracking
```bash
time_command() {
    local start=$(date +%s%N)
    "$@"
    local end=$(date +%s%N)
    local duration=$((($end - $start) / 1000000))
    echo "Execution time: ${duration}ms" >&2
}
```

### 2. Database Performance
```sql
-- Add indexes for common queries
CREATE INDEX IF NOT EXISTS idx_commands_timestamp ON commands(timestamp);
CREATE INDEX IF NOT EXISTS idx_commands_session ON commands(session_id);
CREATE INDEX IF NOT EXISTS idx_workflows_name ON workflows(name);
```

## Release Checklist

- [ ] All tests passing
- [ ] No shellcheck warnings
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in bin/termbrain
- [ ] Installation tested on macOS and Linux
- [ ] Performance benchmarks run
- [ ] Security scan clean

## Monitoring and Metrics

### 1. Usage Analytics (Privacy-Respecting)
```bash
# Track feature usage (local only)
track_usage() {
    local feature="$1"
    sqlite3 "$TERMBRAIN_DB" "INSERT INTO usage_stats (feature, timestamp) VALUES ('$feature', CURRENT_TIMESTAMP);"
}
```

### 2. Error Reporting
```bash
# Log errors for debugging
log_error() {
    local error="$1"
    local context="$2"
    echo "[$(date_iso)] ERROR: $error (Context: $context)" >> "$TERMBRAIN_HOME/logs/error.log"
}
```

This comprehensive plan addresses:
1. SQL escaping issues with proper solutions
2. Cross-platform compatibility
3. Comprehensive testing strategy
4. CI/CD pipeline
5. Error handling standards
6. Performance monitoring
7. Release process