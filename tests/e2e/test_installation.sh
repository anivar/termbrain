#!/usr/bin/env bash
# End-to-end installation tests

set -euo pipefail

# Test helpers
source "$(dirname "$0")/../test_helper.sh"

# Test installation process
test_fresh_install() {
    test_start "Fresh installation"
    
    # Clean any existing installation
    rm -rf "$TEST_HOME/.termbrain"
    rm -f "$TEST_HOME/.local/bin/tb"
    rm -f "$TEST_HOME/.local/bin/termbrain"
    
    # Remove from shell rc
    sed -i.bak '/termbrain/d' "$TEST_RC" 2>/dev/null || true
    
    # Run installer
    cd "$PROJECT_ROOT"
    TERMBRAIN_HOME="$TEST_HOME/.termbrain" ./install.sh <<EOF
n
EOF
    
    # Verify installation
    assert_exists "$TEST_HOME/.termbrain/bin/termbrain" "Main binary installed"
    assert_exists "$TEST_HOME/.termbrain/lib" "Library directory created"
    assert_exists "$TEST_HOME/.termbrain/data/termbrain.db" "Database initialized"
    assert_exists "$TEST_HOME/.local/bin/tb" "tb symlink created"
    
    # Check shell integration
    assert_contains "$TEST_RC" "termbrain/init.sh" "Shell integration added"
    
    test_pass
}

# Test upgrade from existing installation
test_upgrade_install() {
    test_start "Upgrade installation"
    
    # Simulate old version
    mkdir -p "$TEST_HOME/.termbrain"
    echo "0.9.0" > "$TEST_HOME/.termbrain/VERSION"
    
    # Add some data
    sqlite3 "$TEST_HOME/.termbrain/data/termbrain.db" <<EOF
CREATE TABLE IF NOT EXISTS commands (
    id INTEGER PRIMARY KEY,
    command TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO commands (command) VALUES ('test command');
EOF
    
    # Run installer
    cd "$PROJECT_ROOT"
    TERMBRAIN_HOME="$TEST_HOME/.termbrain" ./install.sh <<EOF
n
EOF
    
    # Verify upgrade
    local version=$(cat "$TEST_HOME/.termbrain/VERSION")
    assert_equals "$version" "1.0.1" "Version updated"
    
    # Check data preserved
    local count=$(sqlite3 "$TEST_HOME/.termbrain/data/termbrain.db" "SELECT COUNT(*) FROM commands;")
    assert_equals "$count" "1" "Existing data preserved"
    
    test_pass
}

# Test uninstaller
test_uninstall() {
    test_start "Uninstallation"
    
    # First install
    test_fresh_install
    
    # Add some data
    "$TEST_HOME/.local/bin/tb" workflow create test "Test workflow" "echo test"
    
    # Run uninstaller without export
    cd "$PROJECT_ROOT"
    ./uninstall.sh <<EOF
y
n
EOF
    
    # Verify removal
    assert_not_exists "$TEST_HOME/.termbrain" "Termbrain directory removed"
    assert_not_exists "$TEST_HOME/.local/bin/tb" "tb symlink removed"
    assert_not_contains "$TEST_RC" "termbrain" "Shell integration removed"
    
    test_pass
}

# Test uninstall with export
test_uninstall_with_export() {
    test_start "Uninstallation with export"
    
    # First install
    test_fresh_install
    
    # Add some data
    sqlite3 "$TEST_HOME/.termbrain/data/termbrain.db" <<EOF
INSERT INTO commands (command, directory, semantic_type)
VALUES ('git status', '$PWD', 'version_control');
EOF
    
    # Run uninstaller with export
    cd "$PROJECT_ROOT"
    ./uninstall.sh <<EOF
y
y
EOF
    
    # Check export file created
    local export_file=$(ls $TEST_HOME/termbrain-export-*.json 2>/dev/null | head -1)
    assert_not_empty "$export_file" "Export file created"
    
    # Verify export content
    local exported_commands=$(jq length "$export_file")
    assert_equals "$exported_commands" "1" "Commands exported"
    
    test_pass
}

# Run all tests
main() {
    test_suite_start "Installation E2E Tests"
    
    test_fresh_install
    test_upgrade_install
    test_uninstall
    test_uninstall_with_export
    
    test_suite_end
}

main "$@"