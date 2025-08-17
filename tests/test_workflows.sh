#!/usr/bin/env bash
# Workflow Tests

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test helper
source "$SCRIPT_DIR/test_helper.sh"

# Source termbrain
export TERMBRAIN_HOME="${TERMBRAIN_HOME:-$HOME/.termbrain}"
source "$TERMBRAIN_HOME/bin/termbrain" || {
    echo "Error: Could not source termbrain. Is it installed?"
    exit 1
}

# Load workflow library
source "$TERMBRAIN_HOME/lib/workflows.sh" || {
    echo "Error: Could not load workflows library"
    exit 1
}

# Test workflow creation
test_workflow_create_basic() {
    tb::workflow_create "test-basic" "Basic test" "echo hello" "echo world"
    assert_success "$?" "Should create basic workflow"
    
    # Verify in database
    local count=$(sqlite3 "$TERMBRAIN_DB" "SELECT COUNT(*) FROM workflows WHERE name='test-basic';")
    assert_equals "1" "$count" "Workflow should exist in database"
}

# Test workflow with quotes
test_workflow_create_with_quotes() {
    tb::workflow_create "test-quotes" "Test quotes" "echo 'Hello World'" "echo \"It's working\""
    assert_success "$?" "Should create workflow with quotes"
    
    # Run the workflow
    local output=$(tb::workflow_run "test-quotes" 2>&1)
    assert_contains "$output" "Hello World" "Should output Hello World"
    assert_contains "$output" "It's working" "Should output It's working"
}

# Test workflow with special characters
test_workflow_special_chars() {
    tb::workflow_create "test-special" "Special chars" "echo \$HOME" "echo \$(date +%Y)"
    assert_success "$?" "Should create workflow with special characters"
    
    # Run and check output contains expected patterns
    local output=$(tb::workflow_run "test-special" 2>&1)
    assert_contains "$output" "$HOME" "Should expand HOME variable"
    assert_contains "$output" "$(date +%Y)" "Should execute date command"
}

# Test workflow deletion
test_workflow_delete() {
    # Create and delete
    tb::workflow_create "test-delete" "To be deleted" "echo test"
    tb::workflow_delete "test-delete"
    assert_success "$?" "Should delete workflow"
    
    # Verify deletion
    local count=$(sqlite3 "$TERMBRAIN_DB" "SELECT COUNT(*) FROM workflows WHERE name='test-delete';")
    assert_equals "0" "$count" "Workflow should be deleted from database"
}

# Test workflow statistics
test_workflow_statistics() {
    # Create workflow
    tb::workflow_create "test-stats" "Test statistics" "echo success"
    
    # Run it twice
    tb::workflow_run "test-stats" >/dev/null 2>&1
    tb::workflow_run "test-stats" >/dev/null 2>&1
    
    # Check statistics
    local stats=$(sqlite3 "$TERMBRAIN_DB" "SELECT times_used, success_rate FROM workflows WHERE name='test-stats';")
    assert_contains "$stats" "2|1" "Should have 2 runs with 100% success"
}

# Test workflow failure handling
test_workflow_failure() {
    # Create workflow with failing command
    tb::workflow_create "test-fail" "Test failure" "echo start" "false" "echo never_reached"
    
    # Run and expect failure
    tb::workflow_run "test-fail" >/dev/null 2>&1
    assert_failure "$?" "Workflow should fail"
    
    # Check that success rate decreased
    local rate=$(sqlite3 "$TERMBRAIN_DB" "SELECT success_rate FROM workflows WHERE name='test-fail';")
    assert_not_equals "1.0" "$rate" "Success rate should be less than 100%"
}

# Test pattern detection
test_pattern_detection() {
    # Insert test commands
    local session="test-session-$$"
    for i in {1..5}; do
        sqlite3 "$TERMBRAIN_DB" "INSERT INTO commands (command, directory, exit_code, session_id, semantic_type) 
                                VALUES ('git status', '$(pwd)', 0, '$session', 'version_control');"
        sqlite3 "$TERMBRAIN_DB" "INSERT INTO commands (command, directory, exit_code, session_id, semantic_type) 
                                VALUES ('git add .', '$(pwd)', 0, '$session', 'version_control');"
    done
    
    # Run pattern detection
    local output=$(tb::detect_patterns 2>&1)
    assert_contains "$output" "git status" "Should detect git status pattern"
    assert_contains "$output" "git add" "Should detect git add pattern"
}

# Test SQL injection protection
test_sql_injection_protection() {
    # Try to create workflow with SQL injection attempt
    tb::workflow_create "test'; DROP TABLE workflows; --" "Injection test" "echo safe"
    
    # Check that workflows table still exists
    local table_exists=$(sqlite3 "$TERMBRAIN_DB" "SELECT name FROM sqlite_master WHERE type='table' AND name='workflows';")
    assert_equals "workflows" "$table_exists" "Workflows table should still exist"
}

# Test empty workflow
test_empty_workflow() {
    # Try to create workflow without commands
    tb::workflow_create "test-empty" "Empty workflow" 2>&1
    assert_failure "$?" "Should fail to create empty workflow"
}

# Test duplicate workflow
test_duplicate_workflow() {
    # Create first workflow
    tb::workflow_create "test-dup" "First" "echo first"
    assert_success "$?" "Should create first workflow"
    
    # Try to create duplicate
    tb::workflow_create "test-dup" "Second" "echo second"
    assert_success "$?" "Should handle duplicate by replacing"
}

# Run all tests
echo "🧪 Running Workflow Tests"
echo "========================"

run_test test_workflow_create_basic
run_test test_workflow_create_with_quotes
run_test test_workflow_special_chars
run_test test_workflow_delete
run_test test_workflow_statistics
run_test test_workflow_failure
run_test test_pattern_detection
run_test test_sql_injection_protection
run_test test_empty_workflow
run_test test_duplicate_workflow

# Print summary
print_summary