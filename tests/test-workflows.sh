#!/usr/bin/env bash
# Workflow feature tests

echo "🧪 Testing Termbrain Workflow Features"
echo "===================================="

# Source termbrain
source ~/.termbrain/bin/termbrain
source ~/.termbrain/lib/workflows.sh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test function
test_workflow() {
    local name="$1"
    local description="$2"
    
    echo -e "\n📝 Testing: $description"
    
    # Create a simple workflow
    if tb::workflow_create "$name" "$description" "echo 'Step 1 complete'" "echo 'Step 2 complete'" "echo 'Workflow finished'"; then
        echo -e "${GREEN}✓${NC} Workflow created"
        
        # Show the workflow
        echo -e "\n📋 Workflow details:"
        tb::workflow_show "$name"
        
        # Run it
        echo -e "\n🚀 Running workflow:"
        tb::workflow_run "$name"
        
        # Check statistics
        local uses=$(sqlite3 "$TERMBRAIN_DB" "SELECT times_used FROM workflows WHERE name='$name';")
        if [[ "$uses" == "1" ]]; then
            echo -e "${GREEN}✓${NC} Statistics updated correctly"
        else
            echo -e "${RED}✗${NC} Statistics not updated"
        fi
        
        # Clean up
        tb::workflow_delete "$name"
        echo -e "${GREEN}✓${NC} Workflow deleted"
    else
        echo -e "${RED}✗${NC} Failed to create workflow"
    fi
}

# Test 1: Basic workflow
test_workflow "test-basic" "Basic three-step workflow"

# Test 2: Workflow with variables
echo -e "\n📝 Testing: Workflow with environment variables"
tb::workflow_create "test-vars" "Test with variables" \
    "export TEST_VAR='Hello from workflow'" \
    "echo \$TEST_VAR" \
    "echo \"Current directory: \$PWD\""

tb::workflow_run "test-vars"
tb::workflow_delete "test-vars"

# Test 3: Pattern detection
echo -e "\n📝 Testing: Pattern detection"
# Simulate some repeated commands
for i in {1..5}; do
    sqlite3 "$TERMBRAIN_DB" "INSERT INTO commands (command, directory, exit_code, session_id, semantic_type) 
                            VALUES ('npm install', '$PWD', 0, 'test-pattern', 'package_management');"
    sqlite3 "$TERMBRAIN_DB" "INSERT INTO commands (command, directory, exit_code, session_id, semantic_type) 
                            VALUES ('npm test', '$PWD', 0, 'test-pattern', 'testing');"
done

# Detect patterns
tb::detect_patterns 3
tb::workflow_suggest

# Test 4: Create workflow from detected pattern
echo -e "\n📝 Testing: Create workflow from pattern"
PATTERN_ID=$(sqlite3 "$TERMBRAIN_DB" "SELECT id FROM patterns WHERE pattern_type='sequence_2' LIMIT 1;")
if [[ -n "$PATTERN_ID" ]]; then
    tb::workflow_from_pattern "$PATTERN_ID" "npm-workflow" "NPM install and test workflow"
    tb::workflow_show "npm-workflow"
    tb::workflow_delete "npm-workflow"
    echo -e "${GREEN}✓${NC} Workflow from pattern created and deleted"
else
    echo -e "${RED}✗${NC} No patterns found"
fi

# Test 5: Enhanced learning
echo -e "\n📝 Testing: Enhanced learning features"
tb::learn_enhanced

# Final summary
echo -e "\n✅ Workflow testing complete!"
echo ""
echo "💡 Try these commands:"
echo "  tb workflow create <name> <desc> <cmd1> <cmd2>..."
echo "  tb workflow list"
echo "  tb workflow run <name>"
echo "  tb workflow suggest"
echo "  tb learn"