#!/usr/bin/env bash
# Test clean architecture implementation

echo "🧪 Testing Clean Architecture Workflows"
echo "====================================="

# Use the new entry point
export TERMBRAIN_HOME="$HOME/.termbrain"
TB="./bin/termbrain-clean"

echo -e "\n1️⃣ Create workflow"
$TB workflow create test-clean "Clean architecture test" "echo 'Step 1'" "echo 'Step 2'"

echo -e "\n2️⃣ List workflows"
$TB workflow list

echo -e "\n3️⃣ Show workflow"
$TB workflow show test-clean

echo -e "\n4️⃣ Run workflow"
$TB workflow run test-clean

echo -e "\n5️⃣ Run again to test stats"
$TB workflow run test-clean

echo -e "\n6️⃣ Show updated stats"
$TB workflow show test-clean

echo -e "\n7️⃣ Delete workflow"
$TB workflow delete test-clean

echo -e "\n✅ Clean architecture test complete!"