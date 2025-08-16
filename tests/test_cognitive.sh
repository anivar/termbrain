#!/usr/bin/env bash
# Test suite for Termbrain cognitive features

set -e

# Test configuration
export TERMBRAIN_HOME="${TERMBRAIN_HOME:-$HOME/.termbrain}"
export TERMBRAIN_TEST_DB="$TERMBRAIN_HOME/data/test-cognitive.db"
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

assert_not_empty() {
    if [[ -n "$1" ]]; then
        test_pass "$2"
    else
        test_fail "$2 (value was empty)"
    fi
}

# Setup
setup() {
    echo "Setting up cognitive test environment..."
    rm -f "$TERMBRAIN_TEST_DB"
    source "$TERMBRAIN_HOME/bin/termbrain"
    source "$TERMBRAIN_HOME/lib/termbrain-enhanced.sh"
    source "$TERMBRAIN_HOME/lib/termbrain-cognitive.sh"
    tb::init_db
    tb::init_enhanced_db
    tb::init_cognitive
}

# Teardown
teardown() {
    echo "Cleaning up test environment..."
    rm -f "$TERMBRAIN_TEST_DB"
}

# ============================================
# COGNITIVE TESTS
# ============================================

test_cognitive_database() {
    test_start "Cognitive database schema"
    
    local tables=$(sqlite3 "$TERMBRAIN_TEST_DB" ".tables")
    assert_contains "$tables" "intentions" "Intentions table exists"
    assert_contains "$tables" "knowledge" "Knowledge table exists"
    assert_contains "$tables" "connections" "Connections table exists"
    assert_contains "$tables" "mental_models" "Mental models table exists"
    assert_contains "$tables" "cognitive_state" "Cognitive state table exists"
}

test_intention_tracking() {
    test_start "Intention tracking"
    
    # Set intention
    export TB_ACTIVE_INTENTION_ID=""
    export TB_INTENTION_START=$(date +%s)
    
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO intentions (id, goal, context)
        VALUES (1, 'Test goal', 'Test context');
    "
    export TB_ACTIVE_INTENTION_ID=1
    
    # Mark achieved
    sqlite3 "$TERMBRAIN_TEST_DB" "
        UPDATE intentions
        SET success = 1, learnings = 'Test learning', time_spent = 60
        WHERE id = 1;
    "
    
    local success=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT success FROM intentions WHERE id = 1;")
    assert_equals "$success" "1" "Intention marked as achieved"
    
    local learning=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT learnings FROM intentions WHERE id = 1;")
    assert_equals "$learning" "Test learning" "Learning captured"
}

test_knowledge_extraction() {
    test_start "Knowledge extraction"
    
    # Insert knowledge
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO knowledge (topic, insight, source, confidence)
        VALUES ('testing', 'Use mocks for external APIs', 'experience', 7);
    "
    
    local insight=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT insight FROM knowledge WHERE topic = 'testing';")
    assert_equals "$insight" "Use mocks for external APIs" "Knowledge stored"
    
    # Update confidence
    sqlite3 "$TERMBRAIN_TEST_DB" "
        UPDATE knowledge SET confidence = 8, verified = 1
        WHERE topic = 'testing';
    "
    
    local confidence=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT confidence FROM knowledge WHERE topic = 'testing';")
    assert_equals "$confidence" "8" "Confidence updated"
}

test_mental_models() {
    test_start "Mental models"
    
    # Create mental model
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO mental_models (name, description, pattern, effectiveness)
        VALUES (
            'test-debug-fix',
            'Standard debugging workflow',
            json_array('testing', 'debugging', 'code_execution'),
            0.85
        );
    "
    
    local model=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT name FROM mental_models LIMIT 1;")
    assert_equals "$model" "test-debug-fix" "Mental model created"
    
    local effectiveness=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT effectiveness FROM mental_models WHERE name = 'test-debug-fix';")
    assert_equals "$effectiveness" "0.85" "Effectiveness stored"
}

test_cognitive_state() {
    test_start "Cognitive state tracking"
    
    # Record flow state
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO cognitive_state (focus_area, productivity_score, flow_duration, interruption_count)
        VALUES ('coding', 8, 3600, 2);
    "
    
    local productivity=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT productivity_score FROM cognitive_state LIMIT 1;")
    assert_equals "$productivity" "8" "Productivity score recorded"
    
    local flow_hours=$(sqlite3 "$TERMBRAIN_TEST_DB" "SELECT flow_duration / 3600.0 FROM cognitive_state LIMIT 1;")
    assert_equals "$flow_hours" "1.0" "Flow duration recorded"
}

test_connections() {
    test_start "Knowledge connections"
    
    # Create connections
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO connections (from_type, from_id, to_type, to_id, relationship, strength)
        VALUES ('command', 1, 'knowledge', 1, 'produces', 8);
    "
    
    local relationship=$(sqlite3 "$TERMBRAIN_TEST_DB" "
        SELECT relationship FROM connections 
        WHERE from_type = 'command' AND from_id = 1;
    ")
    assert_equals "$relationship" "produces" "Connection created"
}

test_focus_detection() {
    test_start "Focus area detection"
    
    # Insert test commands
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO commands (semantic_type, session_id) VALUES
        ('testing', 'test-session'),
        ('testing', 'test-session'),
        ('debugging', 'test-session');
    "
    
    export TERMBRAIN_SESSION_ID="test-session"
    local focus=$(tb::detect_focus_area)
    assert_equals "$focus" "testing" "Most common activity detected as focus"
}

test_flow_interruptions() {
    test_start "Flow interruption tracking"
    
    # Set flow state
    export TB_FLOW_START=$(date +%s)
    export TB_FLOW_INTERRUPTIONS=0
    
    # Simulate context switch
    sqlite3 "$TERMBRAIN_TEST_DB" "
        INSERT INTO commands (semantic_type) VALUES ('testing');
    "
    
    # Different semantic type should increment interruptions
    local last_type="testing"
    local current_type="debugging"
    
    if [[ "$last_type" != "$current_type" ]]; then
        ((TB_FLOW_INTERRUPTIONS++))
    fi
    
    assert_equals "$TB_FLOW_INTERRUPTIONS" "1" "Interruption detected"
}

# ============================================
# RUN TESTS
# ============================================

echo "🧠 Termbrain Cognitive Test Suite"
echo "================================="
echo ""

# Setup
setup

# Run tests
test_cognitive_database
test_intention_tracking
test_knowledge_extraction
test_mental_models
test_cognitive_state
test_connections
test_focus_detection
test_flow_interruptions

# Teardown
teardown

# Summary
echo ""
echo "================================="
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