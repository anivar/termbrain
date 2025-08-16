#!/usr/bin/env bash
# Test installation script for Termbrain

set -e

echo "🧪 Testing Termbrain Installation"
echo "================================="

# Test location
TEST_HOME="/tmp/termbrain-test-$$"
export TERMBRAIN_HOME="$TEST_HOME/.termbrain"

echo "📍 Test directory: $TEST_HOME"
mkdir -p "$TEST_HOME"
cd "$TEST_HOME"

# Copy source files
echo "📋 Copying source files..."
cp -r /Users/anivar/termbrain .

# Run installer
echo "🚀 Running installer..."
cd termbrain
./install.sh

# Source the initialization
echo "🔧 Sourcing init..."
source "$TERMBRAIN_HOME/init.sh"

# Test commands
echo -e "\n✅ Testing commands..."

echo "1️⃣ Testing tb help"
tb help > /dev/null && echo "✓ tb help works" || echo "✗ tb help failed"

echo "2️⃣ Testing tb stats"
tb stats > /dev/null && echo "✓ tb stats works" || echo "✗ tb stats failed"

echo "3️⃣ Testing tb ai"
tb ai "test" > /dev/null && echo "✓ tb ai works" || echo "✗ tb ai failed"

echo "4️⃣ Testing tb search (non-interactive)"
echo "test" | tb search > /dev/null 2>&1 && echo "✓ tb search works" || echo "✗ tb search failed"

echo "5️⃣ Testing enhanced commands"
tb why > /dev/null 2>&1 && echo "✓ tb why works" || echo "✗ tb why failed"

echo "6️⃣ Testing cognitive commands"
echo "test goal" | tb intend > /dev/null 2>&1 && echo "✓ tb intend works" || echo "✗ tb intend failed"

# Check database
echo -e "\n📊 Checking database..."
if [[ -f "$TERMBRAIN_HOME/data/termbrain.db" ]]; then
    echo "✓ Database created"
    tables=$(sqlite3 "$TERMBRAIN_HOME/data/termbrain.db" ".tables" | wc -w)
    echo "✓ Found $tables tables"
else
    echo "✗ Database not created"
fi

# Check shell integration
echo -e "\n🐚 Checking shell integration..."
if type tb::preexec &>/dev/null; then
    echo "✓ Shell hooks loaded"
else
    echo "✗ Shell hooks not loaded"
fi

# Cleanup
echo -e "\n🧹 Cleaning up test installation..."
rm -rf "$TEST_HOME"

echo -e "\n✨ Test complete!"