# Termbrain Test Suite

## Overview

Comprehensive test suite for Termbrain covering core functionality, enhanced features, cognitive layer, and integration tests.

## Test Files

### 1. `test_core.sh`
Tests the fundamental Termbrain features:
- Database initialization and schema
- Command capture and storage
- Semantic analysis (git, npm, docker, etc.)
- Project type detection
- Safety checks and sensitive data detection
- Error tracking and solution learning
- Pattern detection
- Help command
- Privacy controls

### 2. `test_enhanced.sh`
Tests the enhanced memory features:
- Enhanced database schema (concepts, reasoning, projects)
- Concept capture and storage
- Reasoning documentation
- Project management
- Memory links between commands and concepts
- Enhanced context generation
- Auto-concept detection from commands

### 3. `test_cognitive.sh`
Tests the cognitive layer features:
- Cognitive database schema
- Intention tracking (goals and achievements)
- Knowledge extraction and storage
- Mental model creation
- Cognitive state and flow tracking
- Knowledge connections
- Focus area detection
- Flow interruption tracking

### 4. `test_integration.sh`
End-to-end integration tests:
- Installation verification
- Command execution
- AI context generation with different providers
- Database operations
- Error capture and solution workflow
- Privacy features (redaction)
- Export functionality
- Full workflow simulation

### 5. `quick_test.sh`
Quick verification test that checks:
- Installation paths
- Database existence
- Basic command functionality
- Semantic analysis
- Project detection
- AI context generation

## Running Tests

### Run all tests:
```bash
cd termbrain
./tests/run_all_tests.sh
```

### Run individual test suites:
```bash
./tests/test_core.sh        # Core functionality
./tests/test_enhanced.sh    # Enhanced features
./tests/test_cognitive.sh   # Cognitive layer
./tests/test_integration.sh # Integration tests
```

### Quick verification:
```bash
./tests/quick_test.sh       # Basic functionality check
```

## Test Structure

Each test file follows this pattern:
1. **Setup**: Initialize test database and environment
2. **Test Functions**: Individual test cases with assertions
3. **Teardown**: Clean up test artifacts
4. **Summary**: Report passed/failed tests

## Writing New Tests

Tests use these helper functions:
- `test_start "Test name"` - Begin a test
- `test_pass "Message"` - Mark test as passed
- `test_fail "Message"` - Mark test as failed
- `assert_equals "$actual" "$expected" "Test description"`
- `assert_contains "$haystack" "$needle" "Test description"`
- `assert_exists "$file" "Test description"`

Example test:
```bash
test_my_feature() {
    test_start "My feature test"
    
    # Test code
    local result=$(my_function)
    
    # Assertion
    assert_equals "$result" "expected" "My function returns expected value"
}
```

## Test Database

Tests use a separate database (`test.db`, `test-enhanced.db`, etc.) to avoid affecting the main Termbrain database. Each test suite creates and destroys its own test database.

## Environment Variables

- `TERMBRAIN_TEST_DB`: Path to test database
- `TERMBRAIN_PAUSED=1`: Prevents recording test commands
- `NO_COLOR=1`: Disable colored output (if needed)

## Current Test Coverage

✅ **Core**: 9 tests - Database, commands, analysis, safety, errors, patterns
✅ **Enhanced**: 7 tests - Concepts, reasoning, projects, memory links
✅ **Cognitive**: 8 tests - Intentions, knowledge, mental models, flow state
✅ **Integration**: 9 tests - Full workflows, providers, exports

Total: **33 test cases** covering all major functionality