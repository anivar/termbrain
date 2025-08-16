#!/usr/bin/env bash
# Termbrain Release Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧠 Termbrain Release Script${NC}"
echo "=========================="
echo ""

# Check if we're in the right directory
if [[ ! -f "package.json" ]] || [[ ! -d "src" ]]; then
    echo -e "${RED}Error: Must run from Termbrain root directory${NC}"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(jq -r .version package.json)
echo "Current version: $CURRENT_VERSION"

# Get new version
echo ""
echo "Enter new version (or press Enter to auto-increment patch):"
read -r NEW_VERSION

if [[ -z "$NEW_VERSION" ]]; then
    # Auto-increment patch version
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR="${VERSION_PARTS[0]}"
    MINOR="${VERSION_PARTS[1]}"
    PATCH="${VERSION_PARTS[2]}"
    NEW_PATCH=$((PATCH + 1))
    NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"
fi

echo ""
echo -e "${YELLOW}Releasing version $NEW_VERSION${NC}"
echo ""

# Confirmation
echo -n "Continue? (y/N): "
read -r confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Release cancelled"
    exit 0
fi

# Run tests
echo ""
echo "🧪 Running tests..."
if ! ./tests/run_all_tests.sh; then
    echo -e "${RED}Tests failed! Fix them before releasing.${NC}"
    exit 1
fi

# Update version in package.json
echo ""
echo "📝 Updating package.json..."
jq ".version = \"$NEW_VERSION\"" package.json > package.json.tmp
mv package.json.tmp package.json

# Update CHANGELOG
echo ""
echo "📝 Updating CHANGELOG..."
echo "Please update CHANGELOG.md with changes for version $NEW_VERSION"
echo "Press Enter when done..."
read -r

# Git operations
echo ""
echo "🔀 Creating git commit and tag..."

git add -A
git commit -m "chore: release v$NEW_VERSION

- Updated version in package.json
- Updated CHANGELOG.md"

git tag -a "v$NEW_VERSION" -m "Release version $NEW_VERSION"

echo ""
echo -e "${GREEN}✅ Release prepared successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Review the changes: git show"
echo "2. Push to GitHub: git push origin main --tags"
echo "3. GitHub Actions will handle:"
echo "   - Creating GitHub release"
echo "   - Publishing to npm"
echo "   - Updating Homebrew formula"
echo ""
echo "To publish manually:"
echo "  npm publish"
echo ""

# Create release notes preview
echo "📋 Release notes preview:"
echo "========================"
awk "/## \[$NEW_VERSION\]/{flag=1; next} /## \[/{flag=0} flag" CHANGELOG.md || echo "No release notes found in CHANGELOG.md"