#!/usr/bin/env bash
# Platform Compatibility Tests

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test helper
source "$SCRIPT_DIR/test_helper.sh"

# Test date command compatibility
test_date_formats() {
    # Test ISO date format
    local date_output=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        assert_contains "$date_output" "T" "Date should contain T separator"
        assert_contains "$date_output" "Z" "Date should end with Z"
    else
        echo "Skipping date format test on this platform"
    fi
}

# Test base64 command
test_base64_encoding() {
    local test_string="Hello 'World' with \"quotes\""
    local encoded=$(echo -n "$test_string" | base64 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        # Decode and verify
        local decoded=$(echo -n "$encoded" | base64 -d 2>/dev/null || echo -n "$encoded" | base64 -D 2>/dev/null)
        assert_equals "$test_string" "$decoded" "Base64 encode/decode should work"
    else
        echo "Skipping base64 test on this platform"
    fi
}

# Test sed in-place editing
test_sed_inplace() {
    local test_file="/tmp/termbrain_sed_test_$$"
    echo "original" > "$test_file"
    
    # Try GNU sed syntax first
    if sed -i 's/original/modified/' "$test_file" 2>/dev/null; then
        local content=$(cat "$test_file")
        assert_equals "modified" "$content" "GNU sed should work"
    # Try BSD/macOS sed syntax
    elif sed -i '' 's/original/modified/' "$test_file" 2>/dev/null; then
        local content=$(cat "$test_file")
        assert_equals "modified" "$content" "BSD sed should work"
    else
        echo "Skipping sed in-place test"
    fi
    
    rm -f "$test_file" "$test_file.bak"
}

# Test shell detection
test_shell_detection() {
    # Check if we're in bash
    if [[ -n "$BASH_VERSION" ]]; then
        assert_success "0" "Bash detected: $BASH_VERSION"
    # Check if we're in zsh
    elif [[ -n "$ZSH_VERSION" ]]; then
        assert_success "0" "Zsh detected: $ZSH_VERSION"
    else
        assert_failure "1" "Unknown shell: $SHELL"
    fi
}

# Test SQLite version
test_sqlite_version() {
    local sqlite_version=$(sqlite3 --version 2>/dev/null | cut -d' ' -f1)
    
    if [[ -n "$sqlite_version" ]]; then
        # Check for minimum version (3.7.0 for JSON support)
        local major=$(echo "$sqlite_version" | cut -d. -f1)
        local minor=$(echo "$sqlite_version" | cut -d. -f2)
        
        if [[ $major -gt 3 ]] || ([[ $major -eq 3 ]] && [[ $minor -ge 7 ]]); then
            assert_success "0" "SQLite version is sufficient ($sqlite_version)"
        else
            assert_failure "1" "SQLite version too old ($sqlite_version)"
        fi
    else
        assert_failure "1" "SQLite not found"
    fi
}

# Test jq availability
test_jq_availability() {
    if command -v jq >/dev/null 2>&1; then
        # Test basic JSON parsing
        local result=$(echo '{"test": "value"}' | jq -r .test 2>/dev/null)
        assert_equals "value" "$result" "jq should parse JSON correctly"
    else
        assert_failure "1" "jq is required but not found"
    fi
}

# Test bc for arithmetic
test_bc_availability() {
    if command -v bc >/dev/null 2>&1; then
        local result=$(echo "scale=2; 3.14 * 2" | bc 2>/dev/null)
        assert_equals "6.28" "$result" "bc should calculate correctly"
    else
        echo "Warning: bc not found, some features may not work"
    fi
}

# Test special characters in filenames
test_special_filenames() {
    local test_dir="/tmp/termbrain test $$/dir with spaces"
    mkdir -p "$test_dir" 2>/dev/null
    
    if [[ -d "$test_dir" ]]; then
        touch "$test_dir/file with 'quotes'.txt"
        assert_file_exists "$test_dir/file with 'quotes'.txt" "Should handle files with quotes"
        rm -rf "$test_dir"
    else
        echo "Skipping special filename test"
    fi
}

# Test command substitution
test_command_substitution() {
    # Test $() syntax (POSIX)
    local result=$(echo "test")
    assert_equals "test" "$result" "Command substitution with \$() should work"
    
    # Test backticks (legacy)
    local result2=`echo "test"`
    assert_equals "test" "$result2" "Command substitution with backticks should work"
}

# Test array support
test_array_support() {
    # Test indexed arrays
    local arr=("one" "two" "three")
    assert_equals "one" "${arr[0]}" "Indexed arrays should work"
    assert_equals "3" "${#arr[@]}" "Array length should work"
}

# Run all tests
echo "🧪 Running Platform Compatibility Tests"
echo "====================================="
echo "Platform: $(uname -s)"
echo "Shell: ${SHELL##*/} (${BASH_VERSION:-${ZSH_VERSION:-unknown version}})"
echo ""

run_test test_date_formats
run_test test_base64_encoding
run_test test_sed_inplace
run_test test_shell_detection
run_test test_sqlite_version
run_test test_jq_availability
run_test test_bc_availability
run_test test_special_filenames
run_test test_command_substitution
run_test test_array_support

# Print summary
print_summary