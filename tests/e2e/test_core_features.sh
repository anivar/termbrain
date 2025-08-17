#!/usr/bin/env bash
# End-to-end tests for core features

set -euo pipefail

source "$(dirname "$0")/../test_helper.sh"

# Setup test environment
setup() {
    # Install termbrain
    cd "$PROJECT_ROOT"
    TERMBRAIN_HOME="$TEST_HOME/.termbrain" ./install.sh >/dev/null 2>&1 <<EOF
n
EOF
    
    # Set up test binary
    export TB="$TEST_HOME/.local/bin/tb"
    
    # Initialize with test data
    sqlite3 "$TEST_HOME/.termbrain/data/termbrain.db" <<EOF
DELETE FROM commands WHERE session_id = 'test';
INSERT INTO commands (command, directory, semantic_type, exit_code, session_id, timestamp)
VALUES 
    ('git status', '$PWD', 'version_control', 0, 'test', datetime('now', '-1 hour')),
    ('npm install', '$PWD', 'package_management', 0, 'test', datetime('now', '-30 minutes')),
    ('npm test', '$PWD', 'testing', 0, 'test', datetime('now', '-15 minutes')),
    ('git commit -m "test"', '$PWD', 'version_control', 0, 'test', datetime('now', '-10 minutes')),
    ('git push', '$PWD', 'version_control', 1, 'test', datetime('now', '-5 minutes')),
    ('git push --force', '$PWD', 'version_control', 0, 'test', datetime('now'));
EOF
}

# Test search functionality
test_search() {
    test_start "Search commands"
    
    # Search for git commands
    local result=$($TB search git 2>/dev/null | grep -c "git")
    assert_greater_than "$result" "2" "Found git commands"
    
    # Search for non-existent
    local empty=$($TB search "nonexistent" 2>/dev/null | grep -c "No commands found" || echo "0")
    assert_equals "$empty" "1" "No results for non-existent search"
    
    test_pass
}

# Test statistics
test_stats() {
    test_start "Statistics generation"
    
    local stats=$($TB stats 2>/dev/null)
    
    assert_contains "$stats" "Total Commands" "Stats show total"
    assert_contains "$stats" "version_control" "Stats show command types"
    assert_contains "$stats" "Success Rate" "Stats show success rate"
    
    test_pass
}

# Test workflow creation and execution
test_workflows() {
    test_start "Workflow management"
    
    # Create workflow
    $TB workflow create deploy "Deploy script" "echo 'Building...'" "echo 'Deploying...'" "echo 'Done!'" 2>/dev/null
    
    # List workflows
    local list=$($TB workflow list 2>/dev/null)
    assert_contains "$list" "deploy" "Workflow listed"
    
    # Show workflow
    local show=$($TB workflow show deploy 2>/dev/null)
    assert_contains "$show" "Building" "Workflow commands shown"
    
    # Run workflow
    local output=$($TB workflow run deploy 2>/dev/null)
    assert_contains "$output" "Building..." "First command executed"
    assert_contains "$output" "Deploying..." "Second command executed"
    assert_contains "$output" "Done!" "Third command executed"
    assert_contains "$output" "completed successfully" "Workflow completed"
    
    # Delete workflow
    $TB workflow delete deploy 2>/dev/null
    local deleted=$($TB workflow list 2>/dev/null | grep -c deploy || echo 0)
    assert_equals "$deleted" "0" "Workflow deleted"
    
    test_pass
}

# Test export functionality
test_export() {
    test_start "Export functionality"
    
    # Export to JSON
    local json_file="$TEST_HOME/test-export.json"
    $TB export json "$json_file" 2>/dev/null
    assert_exists "$json_file" "JSON export created"
    
    local json_count=$(jq length "$json_file")
    assert_equals "$json_count" "6" "All commands exported"
    
    # Export to CSV
    local csv_file="$TEST_HOME/test-export.csv"
    $TB export csv "$csv_file" 2>/dev/null
    assert_exists "$csv_file" "CSV export created"
    
    local csv_lines=$(wc -l < "$csv_file" | tr -d ' ')
    assert_equals "$csv_lines" "7" "CSV has header + 6 commands"
    
    # Export to Markdown
    local md_file="$TEST_HOME/test-export.md"
    $TB export md "$md_file" 2>/dev/null
    assert_exists "$md_file" "Markdown export created"
    assert_contains "$(cat "$md_file")" "# Termbrain Command History Export" "Markdown has title"
    
    test_pass
}

# Test predictive mode
test_predictive() {
    test_start "Predictive mode"
    
    # Enable predictive mode
    $TB predictive on 2>/dev/null
    assert_equals "$?" "0" "Predictive mode enabled"
    
    # Disable predictive mode
    $TB predictive off 2>/dev/null
    assert_equals "$?" "0" "Predictive mode disabled"
    
    # Toggle predictive mode
    $TB predictive 2>/dev/null
    assert_equals "$?" "0" "Predictive mode toggled"
    
    test_pass
}

# Test cognitive features
test_cognitive() {
    test_start "Cognitive features"
    
    # Set intention
    echo "Test termbrain features" | $TB intend 2>/dev/null
    assert_equals "$?" "0" "Intention set"
    
    # Track flow
    $TB flow start 2>/dev/null
    assert_equals "$?" "0" "Flow started"
    
    local status=$($TB flow status 2>/dev/null)
    assert_contains "$status" "In flow for" "Flow status shown"
    
    # End flow
    echo "8" | $TB flow end 2>/dev/null
    assert_equals "$?" "0" "Flow ended"
    
    test_pass
}

# Test enhanced features
test_enhanced() {
    test_start "Enhanced features"
    
    # Generate AI context
    $TB ai 2>/dev/null
    assert_exists ".termbrain-context.md" "AI context generated"
    
    # Project analysis
    local project=$($TB project 2>/dev/null)
    assert_contains "$project" "Project Analysis" "Project analysis shown"
    
    # Command explanation
    local why=$($TB why 5 2>/dev/null)
    assert_contains "$why" "Understanding Your Recent Commands" "Command explanation shown"
    
    test_pass
}

# Test error handling
test_error_handling() {
    test_start "Error handling"
    
    # Invalid command
    local error=$($TB invalid-command 2>&1)
    assert_contains "$error" "Unknown command" "Invalid command handled"
    
    # Invalid workflow
    local wf_error=$($TB workflow run nonexistent 2>&1)
    assert_contains "$wf_error" "not found" "Missing workflow handled"
    
    # Invalid export format
    local exp_error=$($TB export invalid 2>&1)
    assert_contains "$exp_error" "Unknown format" "Invalid format handled"
    
    test_pass
}

# Main test runner
main() {
    test_suite_start "Core Features E2E Tests"
    
    setup
    
    test_search
    test_stats
    test_workflows
    test_export
    test_predictive
    test_cognitive
    test_enhanced
    test_error_handling
    
    test_suite_end
}

main "$@"