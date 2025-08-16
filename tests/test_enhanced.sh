#!/usr/bin/env bash
# Test suite for Termbrain enhanced features

set -e

# Test configuration
export TERMBRAIN_HOME="${TERMBRAIN_HOME:-$HOME/.termbrain}"
export TERMBRAIN_TEST_DB="$TERMBRAIN_HOME/data/test-enhanced.db"
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

# Setup
setup() {
    echo "Setting up enhanced test environment..."
    rm -f "$TERMBRAIN_TEST_DB"
    source "$TERMBRAIN_HOME/bin/termbrain"
    source "$TERMBRAIN_HOME/lib/termbrain-enhanced.sh"
    tb::init_db
    tb::init_enhanced_db
}

# Teardown
teardown() {
    echo "Cleaning up test environment..."
    rm -f "$TERMBRAIN_TEST_DB"
}

# ============================================
# ENHANCED TESTS
# ============================================

test_enhanced_database() {
    test_start "Enhanced database schema"
    
    local tables=$(sqlite3 "$TERMBRAIN_TEST_DB" ".tables")
    assert_contains "$tables" "concepts" "Concepts table exists"
    assert_contains "$tables" "reasoning" "Reasoning table exists"
    assert_contains "$tables" "projects" "Projects table exists"
    assert_contains "$tables" "memory_links" "Memory links table exists"
}

test_concept_capture() {
    test_start "Concept capture"
    
    # Capture a concept
    tb::capture_concept "architecture" "Test Architecture" "This is a test concept"
    
    local count=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT COUNT(*) FROM concepts;")
    assert_equals "$count" "1" "Concept captured"
    
    local title=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT title FROM concepts LIMIT 1;")
    assert_equals "$title" "Test Architecture" "Concept title stored"
}

test_reasoning_capture() {
    test_start "Reasoning capture"
    
    # Insert reasoning
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO reasoning (decision, why)
        VALUES ('use docker', 'for consistent environments');
    "
    
    local reason=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT why FROM reasoning LIMIT 1;")
    assert_equals "$reason" "for consistent environments" "Reasoning stored"
}

test_project_management() {
    test_start "Project management"
    
    # Initialize project
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO projects (name, description, tech_stack)
        VALUES ('test-project', 'Test Description', json_array('node', 'typescript'));
    "
    
    local project=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT name FROM projects LIMIT 1;")
    assert_equals "$project" "test-project" "Project created"
    
    local tech=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT json_extract(tech_stack, '$[0]') FROM projects LIMIT 1;")
    assert_equals "$tech" "node" "Tech stack stored as JSON"
}

test_memory_links() {
    test_start "Memory links"
    
    # Create command and concept
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO commands (id, command) VALUES (1, 'docker build');
        INSERT INTO concepts (id, concept_type, title) VALUES (1, 'architecture', 'Containerization');
        INSERT INTO memory_links (command_id, concept_id, link_type)
        VALUES (1, 1, 'implements');
    "
    
    local link_type=$(sqlite3 "$TERMBRAIN_TEST_DB" "
        SELECT link_type FROM memory_links 
        WHERE command_id = 1 AND concept_id = 1;
    ")
    assert_equals "$link_type" "implements" "Memory link created"
}

test_context_generation() {
    test_start "Enhanced context generation"
    
    # Insert test data
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO concepts (concept_type, title, description, importance)
        VALUES ('architecture', 'API Design', 'RESTful API structure', 8);
    "
    
    # Generate context (would write to file)
    local temp_cache="$TERMBRAIN_HOME/cache"
    mkdir -p "$temp_cache"
    
    # Test that context generation doesn't error
    (tb::ai_enhanced "test" > /dev/null 2>&1 && test_pass "Context generation runs") || \
        test_fail "Context generation failed"
}

test_auto_concept_detection() {
    test_start "Auto concept detection"
    
    # Test concept hints
    export TB_LAST_COMMAND="git checkout -b feature/new-feature"
    tb::preexec_enhanced "$TB_LAST_COMMAND"
    
    assert_equals "$TB_CONCEPT_HINT" "feature_start" "Feature start detected"
    
    export TB_LAST_COMMAND="mkdir components"
    tb::preexec_enhanced "$TB_LAST_COMMAND"
    
    assert_equals "$TB_CONCEPT_HINT" "creating" "Creation detected"
}

# ============================================
# RUN TESTS
# ============================================

echo "🧠 Termbrain Enhanced Test Suite"
echo "================================"
echo ""

# Setup
setup

# Run tests
test_enhanced_database
test_concept_capture
test_reasoning_capture
test_project_management
test_memory_links
test_context_generation
test_auto_concept_detection

# Teardown
teardown

# Summary
echo ""
echo "================================"
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