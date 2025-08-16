#!/usr/bin/env bash
# Complete workflow test for Termbrain

echo "🧠 Testing Complete Termbrain Workflow"
echo "====================================="

# 1. Set intention
echo -e "\n1️⃣ Setting intention..."
tb intend "test termbrain workflow"

# 2. Run some commands
echo -e "\n2️⃣ Running test commands..."
echo "Test command 1"
ls -la | head -5
git status 2>/dev/null || echo "Not a git repo"
echo "Test error" && false || echo "Error captured"

# 3. Check stats
echo -e "\n3️⃣ Checking statistics..."
tb stats | head -20

# 4. Document a decision
echo -e "\n4️⃣ Documenting architecture decision..."
tb arch "Test Decision" "Testing the architecture documentation feature"

# 5. Generate AI context
echo -e "\n5️⃣ Generating AI context..."
tb ai "test workflow" claude
ls -la .claude-context.md

# 6. Check learning
echo -e "\n6️⃣ Checking patterns..."
tb learn

# 7. Mark achievement
echo -e "\n7️⃣ Completing intention..."
echo "Learned how termbrain workflow works" | tb achieved

# 8. View growth
echo -e "\n8️⃣ Viewing growth..."
tb growth

echo -e "\n✅ Workflow test complete!"