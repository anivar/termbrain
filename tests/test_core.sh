#!/usr/bin/env bash
# Test suite for Termbrain core functionality

set -e

# Test configuration
export TERMBRAIN_HOME="${TERMBRAIN_HOME:-$HOME/.termbrain}"
export TERMBRAIN_TEST_DB="$TERMBRAIN_HOME/data/test.db"
export TERMBRAIN_DB="$TERMBRAIN_TEST_DB"
export TERMBRAIN_PAUSED=1  # Prevent recording test commands

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
test_start() {
    echo -e "${YELLOW}Testing: $1${NC}"
    ((TESTS_RUN++))
}

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((TESTS_FAILED++))
}

assert_equals() {
    if [[ "$1" == "$2" ]]; then
        test_pass "$3"
    else
        test_fail "$3 (expected: '$2', got: '$1')"
    fi
}

assert_contains() {
    if [[ "$1" == *"$2"* ]]; then
        test_pass "$3"
    else
        test_fail "$3 (output did not contain: '$2')"
    fi
}

assert_exists() {
    if [[ -f "$1" ]]; then
        test_pass "$2"
    else
        test_fail "$2 (file not found: '$1')"
    fi
}

# Setup
setup() {
    echo "Setting up test environment..."
    rm -f "$TERMBRAIN_TEST_DB"
    source "$TERMBRAIN_HOME/bin/termbrain"
    tb::init_db
}

# Teardown
teardown() {
    echo "Cleaning up test environment..."
    rm -f "$TERMBRAIN_TEST_DB"
}

# ============================================
# TESTS
# ============================================

test_database_initialization() {
    test_start "Database initialization"
    
    assert_exists "$TERMBRAIN_TEST_DB" "Database file created"
    
    # Check tables exist
    local tables=$(sqlite3 "$TERMBRAIN_TEST_DB" ".tables")
    assert_contains "$tables" "commands" "Commands table exists"
    assert_contains "$tables" "errors" "Errors table exists"
    assert_contains "$tables" "patterns" "Patterns table exists"
    assert_contains "$tables" "workflows" "Workflows table exists"
    assert_contains "$tables" "contexts" "Contexts table exists"
}

test_command_capture() {
    test_start "Command capture"
    
    # Manually insert a test command
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO commands (command, directory, semantic_type)
        VALUES ('git status', '/tmp', 'version_control');
    "
    
    local count=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT COUNT(*) FROM commands;")
    assert_equals "$count" "1" "Command inserted successfully"
    
    local cmd=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT command FROM commands LIMIT 1;")
    assert_equals "$cmd" "git status" "Command text stored correctly"
}

test_semantic_analysis() {
    test_start "Semantic analysis"
    
    # Test semantic type detection
    local type=$(tb::analyze_semantic "git commit -m 'test'")
    assert_equals "$type" "version_control" "Git command recognized"
    
    type=$(tb::analyze_semantic "npm install")
    assert_equals "$type" "package_management" "NPM command recognized"
    
    type=$(tb::analyze_semantic "docker run ubuntu")
    assert_equals "$type" "containerization" "Docker command recognized"
    
    type=$(tb::analyze_semantic "pytest test_file.py")
    assert_equals "$type" "testing" "Test command recognized"
}

test_project_detection() {
    test_start "Project type detection"
    
    # Create temporary project directories
    local temp_dir=$(mktemp -d)
    
    # Test JavaScript project
    cd "$temp_dir"
    echo '{}' > package.json
    local project_type=$(tb::detect_project)
    assert_equals "$project_type" "javascript" "JavaScript project detected"
    
    # Test TypeScript project
    touch tsconfig.json
    project_type=$(tb::detect_project)
    assert_equals "$project_type" "typescript" "TypeScript project detected"
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
}

test_safety_checks() {
    test_start "Safety checks"
    
    # Test dangerous command detection
    local safe=$(tb::is_safe_to_record "echo hello")
    assert_equals "$?" "0" "Safe command allowed"
    
    tb::is_safe_to_record "rm -rf /"
    assert_equals "$?" "1" "Dangerous command blocked"
    
    # Test sensitive data detection
    local sensitive=$(tb::check_sensitive "normal command")
    assert_equals "$sensitive" "0" "Normal command not sensitive"
    
    sensitive=$(tb::check_sensitive "export API_KEY=secret")
    assert_equals "$sensitive" "1" "API key detected as sensitive"
}

test_error_tracking() {
    test_start "Error tracking"
    
    # Insert test command and error
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO commands (id, command) VALUES (1, 'failing command');
        INSERT INTO errors (command_id) VALUES (1);
    "
    
    local error_count=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT COUNT(*) FROM errors;")
    assert_equals "$error_count" "1" "Error recorded"
    
    # Test solution learning
    sqlite3 "$TERMBRAIN_TEST_DB" "
        UPDATE errors SET solution_commands = 'fixed command', solved = 1
        WHERE command_id = 1;
    "
    
    local solved=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT solved FROM errors WHERE command_id = 1;")
    assert_equals "$solved" "1" "Error marked as solved"
}

test_pattern_detection() {
    test_start "Pattern detection"
    
    # Insert pattern
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO patterns (pattern_type, frequency)
        VALUES ('git-commit-push', 5);
    "
    
    local pattern=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT pattern_type FROM patterns LIMIT 1;")
    assert_equals "$pattern" "git-commit-push" "Pattern stored"
}

test_help_command() {
    test_start "Help command"
    
    local output=$("$TERMBRAIN_HOME/bin/tb-wrapper" help 2>&1)
    assert_contains "$output" "Termbrain" "Help shows title"
    assert_contains "$output" "tb ai" "Help shows ai command"
    assert_contains "$output" "tb search" "Help shows search command"
}

test_privacy_controls() {
    test_start "Privacy controls"
    
    # Test SQL escaping
    local escaped=$(tb::escape_sql "test'string")
    assert_equals "$escaped" "test''string" "SQL escaping works"
    
    # Test sensitive directory detection
    cd /tmp
    tb::is_safe_to_record "test command"
    assert_equals "$?" "0" "Normal directory allowed"
}

# ============================================
# RUN TESTS
# ============================================

echo "🧠 Termbrain Test Suite"
echo "======================="
echo ""

# Setup
setup

# Run tests
test_database_initialization
test_command_capture
test_semantic_analysis
test_project_detection
test_safety_checks
test_error_tracking
test_pattern_detection
test_help_command
test_privacy_controls

# Teardown
teardown

# Summary
echo ""
echo "======================="
echo "Test Summary:"
echo "  Total:  $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✨ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi