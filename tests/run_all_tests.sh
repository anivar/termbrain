#!/usr/bin/env bash
# Run all Termbrain tests

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🧠 Termbrain Complete Test Suite${NC}"
echo "======================================"
echo ""

# Track overall results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=()

# Run a test suite
run_test_suite() {
    local test_file="$1"
    local test_name="$2"
    
    ((TOTAL_SUITES++))
    
    echo -e "${YELLOW}Running $test_name...${NC}"
    echo "--------------------------------------"
    
    if bash "$test_file"; then
        ((PASSED_SUITES++))
        echo -e "${GREEN}✓ $test_name passed${NC}"
    else
        FAILED_SUITES+=("$test_name")
        echo -e "${RED}✗ $test_name failed${NC}"
    fi
    
    echo ""
}

# Make test files executable
chmod +x "$TEST_DIR"/*.sh

# Run all test suites
run_test_suite "$TEST_DIR/test_core.sh" "Core Tests"
run_test_suite "$TEST_DIR/test_enhanced.sh" "Enhanced Tests"
run_test_suite "$TEST_DIR/test_cognitive.sh" "Cognitive Tests"
run_test_suite "$TEST_DIR/test_integration.sh" "Integration Tests"

# Final summary
echo "======================================"
echo -e "${BLUE}Overall Test Summary${NC}"
echo "======================================"
echo "Total Test Suites: $TOTAL_SUITES"
echo -e "${GREEN}Passed: $PASSED_SUITES${NC}"
echo -e "${RED}Failed: ${#FAILED_SUITES[@]}${NC}"

if [[ ${#FAILED_SUITES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed suites:${NC}"
    for suite in "${FAILED_SUITES[@]}"; do
        echo "  - $suite"
    done
fi

echo ""

# Exit code
if [[ ${#FAILED_SUITES[@]} -eq 0 ]]; then
    echo -e "${GREEN}✨ All test suites passed! Termbrain is ready.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some test suites failed. Please check the output above.${NC}"
    exit 1
fi