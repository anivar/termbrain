#!/usr/bin/env bash
# Test runner for termbrain

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test types
RUN_UNIT=true
RUN_E2E=true
RUN_LINT=true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --unit-only)
            RUN_E2E=false
            RUN_LINT=false
            ;;
        --e2e-only)
            RUN_UNIT=false
            RUN_LINT=false
            ;;
        --lint-only)
            RUN_UNIT=false
            RUN_E2E=false
            ;;
        --no-lint)
            RUN_LINT=false
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--unit-only|--e2e-only|--lint-only|--no-lint]"
            exit 1
            ;;
    esac
    shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo -e "${YELLOW}Termbrain Test Suite${NC}"
echo "===================="
echo ""

TOTAL_FAILED=0

# Run shellcheck
if [[ "$RUN_LINT" == "true" ]]; then
    echo -e "${YELLOW}Running shellcheck...${NC}"
    if command -v shellcheck >/dev/null 2>&1; then
        if find . -name "*.sh" -not -path "./tests/test_*" -not -path "./.termbrain/*" | xargs shellcheck -x; then
            echo -e "${GREEN}✓ Shellcheck passed${NC}"
        else
            echo -e "${RED}✗ Shellcheck failed${NC}"
            ((TOTAL_FAILED++))
        fi
    else
        echo -e "${YELLOW}⚠ Shellcheck not installed, skipping${NC}"
    fi
    echo ""
fi

# Run unit tests
if [[ "$RUN_UNIT" == "true" ]]; then
    echo -e "${YELLOW}Running unit tests...${NC}"
    
    if [[ -d "$SCRIPT_DIR/unit" ]]; then
        for test_file in "$SCRIPT_DIR/unit"/test_*.sh; do
            if [[ -f "$test_file" ]]; then
                echo "Running $(basename "$test_file")..."
                bash "$test_file"
                exit_code=$?
                if [[ $exit_code -eq 0 ]]; then
                    echo -e "${GREEN}✓ $(basename "$test_file") passed${NC}"
                else
                    echo -e "${RED}✗ $(basename "$test_file") failed (exit code: $exit_code)${NC}"
                    ((TOTAL_FAILED++))
                fi
                echo ""
            fi
        done
    else
        echo "No unit tests found"
    fi
fi

# Run E2E tests
if [[ "$RUN_E2E" == "true" ]]; then
    echo -e "${YELLOW}Running E2E tests...${NC}"
    
    if [[ -d "$SCRIPT_DIR/e2e" ]]; then
        for test_file in "$SCRIPT_DIR/e2e"/test_*.sh; do
            if [[ -f "$test_file" ]]; then
                echo "Running $(basename "$test_file")..."
                bash "$test_file"
                exit_code=$?
                if [[ $exit_code -eq 0 ]]; then
                    echo -e "${GREEN}✓ $(basename "$test_file") passed${NC}"
                else
                    echo -e "${RED}✗ $(basename "$test_file") failed (exit code: $exit_code)${NC}"
                    ((TOTAL_FAILED++))
                fi
                echo ""
            fi
        done
    else
        echo "No E2E tests found"
    fi
fi

# Summary
echo ""
echo "===================="
if [[ $TOTAL_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$TOTAL_FAILED test suite(s) failed${NC}"
    exit 1
fi