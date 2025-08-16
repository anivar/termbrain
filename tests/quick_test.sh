#!/usr/bin/env bash
# Quick test of Termbrain functionality

echo "🧠 Termbrain Quick Test"
echo "======================="
echo ""

# Test 1: Check installation
echo "1. Testing installation..."
if [[ -f "$HOME/.termbrain/bin/termbrain" ]]; then
    echo "✓ Termbrain installed"
else
    echo "✗ Termbrain not found"
    exit 1
fi

# Test 2: Database initialization
echo "2. Testing database..."
if [[ -f "$HOME/.termbrain/data/termbrain.db" ]]; then
    echo "✓ Database exists"
    
    # Check tables
    tables=$(sqlite3 "$HOME/.termbrain/data/termbrain.db" ".tables" 2>/dev/null)
    if [[ "$tables" == *"commands"* ]]; then
        echo "✓ Database tables created"
    else
        echo "✗ Database tables missing"
    fi
else
    echo "✗ Database not found"
fi

# Test 3: Help command
echo "3. Testing help command..."
if $HOME/.termbrain/bin/tb-wrapper help | grep -q "Termbrain"; then
    echo "✓ Help command works"
else
    echo "✗ Help command failed"
fi

# Test 4: Semantic analysis
echo "4. Testing semantic analysis..."
source "$HOME/.termbrain/bin/termbrain"
result=$(tb::analyze_semantic "git commit -m test")
if [[ "$result" == "version_control" ]]; then
    echo "✓ Semantic analysis works"
else
    echo "✗ Semantic analysis failed (got: $result)"
fi

# Test 5: Project detection
echo "5. Testing project detection..."
cd /tmp
mkdir -p test-project && cd test-project
echo '{}' > package.json
result=$(tb::detect_project)
if [[ "$result" == "javascript" ]]; then
    echo "✓ Project detection works"
else
    echo "✗ Project detection failed (got: $result)"
fi
cd - > /dev/null
rm -rf test-project

# Test 6: AI context generation
echo "6. Testing AI context generation..."
$HOME/.termbrain/bin/tb-wrapper ai "test" > /dev/null 2>&1
if [[ -f ".ai-context.md" ]]; then
    echo "✓ AI context generation works"
    rm -f .ai-context.md
else
    echo "✗ AI context generation failed"
fi

echo ""
echo "✨ Quick test complete!"