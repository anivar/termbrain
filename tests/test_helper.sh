#!/usr/bin/env bash
# Test helper functions for termbrain tests

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters - use global variables
declare -g TESTS_PASSED=0
declare -g TESTS_FAILED=0
declare -g CURRENT_TEST=""

# Project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test environment
export TEST_HOME="${TEST_HOME:-/tmp/termbrain-test-$$}"
export TEST_RC="${TEST_HOME}/.bashrc"
export TERMBRAIN_HOME="${TEST_HOME}/.termbrain"
export PATH="${TEST_HOME}/.local/bin:$PATH"

# Setup test environment
setup_test_env() {
    mkdir -p "$TEST_HOME/.local/bin"
    mkdir -p "$TEST_HOME/.termbrain"
    echo "# Test RC file" > "$TEST_RC"
}

# Cleanup test environment
cleanup_test_env() {
    if [[ -d "$TEST_HOME" ]]; then
        rm -rf "$TEST_HOME"
    fi
}

# Test suite functions
test_suite_start() {
    local suite_name="$1"
    echo -e "${YELLOW}Starting $suite_name${NC}"
    echo "======================================"
    setup_test_env
}

test_suite_end() {
    echo ""
    echo "======================================"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    
    cleanup_test_env
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Individual test functions
test_start() {
    CURRENT_TEST="$1"
    echo -n "Testing $CURRENT_TEST... "
}

test_pass() {
    echo -e "${GREEN}PASS${NC}"
    ((TESTS_PASSED++))
}

test_fail() {
    local message="$1"
    echo -e "${RED}FAIL${NC}"
    echo "  Error: $message"
    ((TESTS_FAILED++))
}

# Assertion functions
assert_equals() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Values should be equal}"
    
    if [[ "$actual" != "$expected" ]]; then
        test_fail "$message (expected: '$expected', got: '$actual')"
        return 1
    fi
}

assert_not_equals() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Values should not be equal}"
    
    if [[ "$actual" == "$expected" ]]; then
        test_fail "$message (both values: '$actual')"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Should contain substring}"
    
    if [[ ! "$haystack" =~ "$needle" ]]; then
        test_fail "$message (looking for: '$needle')"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Should not contain substring}"
    
    if [[ "$haystack" =~ "$needle" ]]; then
        test_fail "$message (found: '$needle')"
        return 1
    fi
}

assert_exists() {
    local path="$1"
    local message="${2:-File should exist}"
    
    if [[ ! -e "$path" ]]; then
        test_fail "$message (path: '$path')"
        return 1
    fi
}

assert_not_exists() {
    local path="$1"
    local message="${2:-File should not exist}"
    
    if [[ -e "$path" ]]; then
        test_fail "$message (path: '$path')"
        return 1
    fi
}

assert_greater_than() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Value should be greater}"
    
    if [[ ! "$actual" -gt "$expected" ]]; then
        test_fail "$message (expected > $expected, got: $actual)"
        return 1
    fi
}

assert_less_than() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Value should be less}"
    
    if [[ ! "$actual" -lt "$expected" ]]; then
        test_fail "$message (expected < $expected, got: $actual)"
        return 1
    fi
}

assert_empty() {
    local value="$1"
    local message="${2:-Value should be empty}"
    
    if [[ -n "$value" ]]; then
        test_fail "$message (got: '$value')"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"
    
    if [[ -z "$value" ]]; then
        test_fail "$message"
        return 1
    fi
}

# Mock command for testing
mock_command() {
    local command="$1"
    local mock_script="$2"
    
    cat > "$TEST_HOME/.local/bin/$command" <<EOF
#!/usr/bin/env bash
$mock_script
EOF
    chmod +x "$TEST_HOME/.local/bin/$command"
}

# Wait for condition with timeout
wait_for() {
    local condition="$1"
    local timeout="${2:-5}"
    local message="${3:-Condition not met}"
    
    local elapsed=0
    while ! eval "$condition"; do
        sleep 0.1
        elapsed=$((elapsed + 1))
        if [[ $elapsed -gt $((timeout * 10)) ]]; then
            test_fail "$message (timeout after ${timeout}s)"
            return 1
        fi
    done
}

# Export all functions
export -f test_suite_start test_suite_end test_start test_pass test_fail
export -f assert_equals assert_not_equals assert_contains assert_not_contains
export -f assert_exists assert_not_exists assert_greater_than assert_less_than
export -f assert_empty assert_not_empty mock_command wait_for