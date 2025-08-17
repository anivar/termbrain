#!/usr/bin/env bash
# Smoke test for termbrain

echo "Running Termbrain smoke test..."

# Check if main script exists
if [[ ! -f "bin/termbrain" ]]; then
    echo "✗ Main script not found"
    exit 1
fi
echo "✓ Main script exists"

# Check if libraries exist
if [[ ! -d "lib" ]]; then
    echo "✗ Library directory not found"
    exit 1
fi
echo "✓ Library directory exists"

# Check if installer exists
if [[ ! -f "install.sh" ]]; then
    echo "✗ Installer not found"
    exit 1
fi
echo "✓ Installer exists"

# Check if uninstaller exists
if [[ ! -f "uninstall.sh" ]]; then
    echo "✗ Uninstaller not found"
    exit 1
fi
echo "✓ Uninstaller exists"

# Check library structure
for dir in domain application infrastructure presentation; do
    if [[ ! -d "lib/$dir" ]]; then
        echo "✗ Missing lib/$dir"
        exit 1
    fi
    echo "✓ lib/$dir exists"
done

# Check critical files
critical_files=(
    "lib/presentation/command_router.sh"
    "lib/infrastructure/database/migrations.sh"
    "lib/domain/services/command_classifier.sh"
    "lib/application/commands/search_commands.sh"
)

for file in "${critical_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "✗ Missing $file"
        exit 1
    fi
    echo "✓ $file exists"
done

# Test sourcing main script
if source bin/termbrain >/dev/null 2>&1; then
    echo "✓ Main script can be sourced"
else
    echo "✗ Failed to source main script"
    exit 1
fi

echo ""
echo "All smoke tests passed!"