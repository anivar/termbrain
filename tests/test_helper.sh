#!/usr/bin/env bash
# Test Helper Functions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test database
export TEST_DB="/tmp/termbrain_test_$$.db"
export TERMBRAIN_DB="$TEST_DB"
export TERMBRAIN_HOME="${TERMBRAIN_HOME:-$HOME/.termbrain}"

# Setup test environment
setup_test_env() {
    rm -f "$TEST_DB"
    mkdir -p "$(dirname "$TEST_DB")"
}

# Cleanup test environment
cleanup_test_env() {
    rm -f "$TEST_DB"
}

# Assert functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    
    ((TESTS_RUN++))
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"
    
    ((TESTS_RUN++))
    
    if [[ "$unexpected" != "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Value: '$actual' should not equal '$unexpected'"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"
    
    ((TESTS_RUN++))
    
    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  String: '$haystack'"
        echo "  Should contain: '$needle'"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should not contain substring}"
    
    ((TESTS_RUN++))
    
    if [[ "$haystack" != *"$needle"* ]]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  String: '$haystack'"
        echo "  Should not contain: '$needle'"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_success() {
    local exit_code="$1"
    local message="${2:-Command should succeed}"
    
    assert_equals "0" "$exit_code" "$message"
}

assert_failure() {
    local exit_code="$1"
    local message="${2:-Command should fail}"
    
    assert_not_equals "0" "$exit_code" "$message"
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"
    
    ((TESTS_RUN++))
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  File not found: '$file'"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local message="${2:-File should not exist}"
    
    ((TESTS_RUN++))
    
    if [[ ! -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  File exists: '$file'"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Run a test function
run_test() {
    local test_name="$1"
    
    echo -e "\n${YELLOW}Running:${NC} $test_name"
    
    # Setup before each test
    setup_test_env
    
    # Run the test
    if declare -f "$test_name" > /dev/null; then
        "$test_name"
    else
        echo -e "${RED}✗${NC} Test function not found: $test_name"
        ((TESTS_FAILED++))
    fi
    
    # Cleanup after each test
    cleanup_test_env
}

# Print test summary
print_summary() {
    echo -e "\n=================================="
    echo "Test Summary:"
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"
    echo "Total:  $TESTS_RUN"
    echo "=================================="
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        return 1
    fi
}

# Mock function for testing
mock_function() {
    local function_name="$1"
    local mock_output="$2"
    
    eval "$function_name() { echo '$mock_output'; }"
}

# Capture output of a command
capture_output() {
    local output
    output=$("$@" 2>&1)
    echo "$output"
}

# Test SQL escaping
test_sql_escape() {
    local input="$1"
    local escaped="${input//\'/\'\'}"
    echo "$escaped"
}