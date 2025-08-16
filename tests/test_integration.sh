#!/usr/bin/env bash
# Integration tests for Termbrain

set -e

# Test configuration
export TERMBRAIN_HOME="${TERMBRAIN_HOME:-$HOME/.termbrain}"
export TERMBRAIN_TEST_DB="$TERMBRAIN_HOME/data/test-integration.db"
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

assert_success() {
    if [[ $? -eq 0 ]]; then
        test_pass "$1"
    else
        test_fail "$1"
    fi
}

assert_file_exists() {
    if [[ -f "$1" ]]; then
        test_pass "$2"
    else
        test_fail "$2 (file not found: $1)"
    fi
}

assert_file_contains() {
    if grep -q "$2" "$1" 2>/dev/null; then
        test_pass "$3"
    else
        test_fail "$3 (pattern not found in file)"
    fi
}

# Setup
setup() {
    echo "Setting up integration test environment..."
    rm -f "$TERMBRAIN_TEST_DB"
    rm -rf "$TERMBRAIN_HOME/cache/test-*"
    
    # Initialize all components
    "$TERMBRAIN_HOME/bin/tb-wrapper" --init-db
}

# Teardown
teardown() {
    echo "Cleaning up test environment..."
    rm -f "$TERMBRAIN_TEST_DB"
    rm -rf "$TERMBRAIN_HOME/cache/test-*"
    rm -f .ai-context.md .claude.md .cursorrules
}

# ============================================
# INTEGRATION TESTS
# ============================================

test_installation() {
    test_start "Installation verification"
    
    assert_file_exists "$TERMBRAIN_HOME/bin/termbrain" "Main script exists"
    assert_file_exists "$TERMBRAIN_HOME/bin/tb" "Symlink exists"
    assert_file_exists "$TERMBRAIN_HOME/init.sh" "Init script exists"
    
    # Check executable permissions
    [[ -x "$TERMBRAIN_HOME/bin/termbrain" ]]
    assert_success "Main script is executable"
}

test_command_execution() {
    test_start "Command execution"
    
    # Test help command
    "$TERMBRAIN_HOME/bin/tb-wrapper" help > /dev/null 2>&1
    assert_success "Help command executes"
    
    # Test stats command (should work even with empty db)
    "$TERMBRAIN_HOME/bin/tb-wrapper" stats > /dev/null 2>&1
    assert_success "Stats command executes"
}

test_ai_context_generation() {
    test_start "AI context generation"
    
    # Generate context
    "$TERMBRAIN_HOME/bin/tb-wrapper" ai "test query" > /dev/null 2>&1
    assert_success "AI context generation executes"
    
    # Check output file
    assert_file_exists ".ai-context.md" "AI context file created"
    assert_file_contains ".ai-context.md" "Termbrain Context" "Context has header"
    assert_file_contains ".ai-context.md" "test query" "Context contains query"
    
    # Cleanup
    rm -f .ai-context.md
}

test_provider_integration() {
    test_start "Provider-specific context files"
    
    # Test Claude provider
    TB_PROVIDER=claude "$TERMBRAIN_HOME/bin/tb-wrapper" ai "claude test" claude > /dev/null 2>&1
    assert_file_exists ".claude.md" "Claude context file created"
    
    # Test Cursor provider
    TB_PROVIDER=cursor "$TERMBRAIN_HOME/bin/tb-wrapper" ai "cursor test" cursor > /dev/null 2>&1
    assert_file_exists ".cursorrules" "Cursor context file created"
    
    # Cleanup
    rm -f .claude.md .cursorrules
}

test_database_operations() {
    test_start "Database operations"
    
    # Insert test data
    source "$TERMBRAIN_HOME/bin/termbrain"
    
    # Manually insert command
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO commands (command, directory, semantic_type, exit_code)
        VALUES ('echo test', '/tmp', 'general', 0);
    "
    assert_success "Command insertion"
    
    # Test pattern insertion
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO patterns (pattern_type, frequency)
        VALUES ('test-pattern', 3);
    "
    assert_success "Pattern insertion"
    
    # Verify data
    local cmd_count=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT COUNT(*) FROM commands;")
    [[ "$cmd_count" -gt 0 ]]
    assert_success "Commands stored in database"
}

test_error_workflow() {
    test_start "Error capture and solution workflow"
    
    source "$TERMBRAIN_HOME/bin/termbrain"
    
    # Simulate command with error
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO commands (id, command, exit_code) VALUES (99, 'failing-cmd', 1);
        INSERT INTO errors (command_id) VALUES (99);
    "
    
    # Simulate solution
    sqlite3 "$TERMBRAIN_TEST_DB" "
        UPDATE errors 
        SET solution_commands = 'working-cmd', solved = 1
        WHERE command_id = 99;
    "
    
    # Verify solution stored
    local solution=$(sqlite3 "$TERMBRAIN_TEST_DB" "
        SELECT solution_commands FROM errors WHERE command_id = 99;
    ")
    [[ "$solution" == "working-cmd" ]]
    assert_success "Error solution workflow"
}

test_privacy_features() {
    test_start "Privacy features"
    
    source "$TERMBRAIN_HOME/bin/termbrain"
    
    # Test sensitive command detection
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO commands (command, is_sensitive)
        VALUES ('export PASSWORD=secret', 1);
    "
    
    # Test redaction
    sqlite3 "$TERMBRAIN_TEST_DB" "
        UPDATE commands SET command = '[REDACTED]' WHERE is_sensitive = 1;
    "
    
    local redacted=$(sqlite3 "$TERMBRAIN_TEST_DB" "
        SELECT command FROM commands WHERE is_sensitive = 1;
    ")
    [[ "$redacted" == "[REDACTED]" ]]
    assert_success "Sensitive data redaction"
}

test_export_functionality() {
    test_start "Export functionality"
    
    source "$TERMBRAIN_HOME/bin/termbrain"
    
    # Insert test data
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO commands (command, semantic_type)
        VALUES ('test export', 'general');
    "
    
    # Create export
    local export_file="$TERMBRAIN_HOME/exports/test-export.json"
    sqlite3 "$TERMBRAIN_TEST_DB" "
        SELECT json_group_array(json_object(
            'command', command,
            'semantic_type', semantic_type
        )) FROM commands;
    " > "$export_file"
    
    assert_file_exists "$export_file" "Export file created"
    assert_file_contains "$export_file" "test export" "Export contains data"
    
    # Cleanup
    rm -f "$export_file"
}

test_full_workflow() {
    test_start "Full workflow simulation"
    
    source "$TERMBRAIN_HOME/bin/termbrain"
    
    # 1. Capture command
    export TB_LAST_COMMAND="git status"
    export TB_COMMAND_START=$(date +%s%N)
    local semantic_type=$(tb::analyze_semantic "$TB_LAST_COMMAND")
    
    [[ "$semantic_type" == "version_control" ]]
    assert_success "Semantic analysis in workflow"
    
    # 2. Store command
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO commands (command, semantic_type)
        VALUES ('$TB_LAST_COMMAND', '$semantic_type');
    "
    
    # 3. Generate AI context
    "$TERMBRAIN_HOME/bin/tb-wrapper" ai "git help" > /dev/null 2>&1
    assert_file_exists ".ai-context.md" "Workflow generates context"
    
    # Cleanup
    rm -f .ai-context.md
}

# ============================================
# RUN TESTS
# ============================================

echo "🧠 Termbrain Integration Test Suite"
echo "==================================="
echo ""

# Setup
setup

# Run tests
test_installation
test_command_execution
test_ai_context_generation
test_provider_integration
test_database_operations
test_error_workflow
test_privacy_features
test_export_functionality
test_full_workflow

# Teardown
teardown

# Summary
echo ""
echo "==================================="
echo "Test Summary:"
echo "  Total:  $TESTS_RUN"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✨ All integration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some integration tests failed${NC}"
    exit 1
fi