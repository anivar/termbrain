#!/usr/bin/env bash
set -e

# Termbrain Installer
TERMBRAIN_VERSION="1.0.0"
TERMBRAIN_HOME="${TERMBRAIN_HOME:-$HOME/.termbrain}"

echo ""
echo "🧠 Termbrain Installer v${TERMBRAIN_VERSION}"
echo "=================================="
echo ""

# Check OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     OS_TYPE=Linux;;
    Darwin*)    OS_TYPE=Mac;;
    *)          echo "❌ Unsupported OS: ${OS}"; exit 1;;
esac

echo "📍 Detected OS: ${OS_TYPE}"

# Check dependencies
echo ""
echo "📦 Checking dependencies..."

MISSING_DEPS=()

# Required commands
for cmd in sqlite3 jq; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_DEPS+=("$cmd")
    else
        echo "✅ $cmd"
    fi
done

# Optional but recommended
if command -v fzf &> /dev/null; then
    echo "✅ fzf (optional)"
else
    echo "⚠️  fzf not found (optional but recommended for search)"
fi

# Install missing dependencies
if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo ""
    echo "📦 Installing missing dependencies: ${MISSING_DEPS[*]}"
    
    if [[ "$OS_TYPE" == "Mac" ]]; then
        if command -v brew &> /dev/null; then
            brew install "${MISSING_DEPS[@]}"
        else
            echo "❌ Homebrew not found. Please install: https://brew.sh"
            exit 1
        fi
    else
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y "${MISSING_DEPS[@]}"
        elif command -v yum &> /dev/null; then
            sudo yum install -y "${MISSING_DEPS[@]}"
        else
            echo "❌ No supported package manager found"
            exit 1
        fi
    fi
fi

# Create directory structure
echo ""
echo "📁 Creating Termbrain directories..."
mkdir -p "$TERMBRAIN_HOME"/{bin,lib,data,providers,cache,exports}

# Copy core files
echo ""
echo "📥 Installing Termbrain..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy main script
cp "$SCRIPT_DIR/src/termbrain.sh" "$TERMBRAIN_HOME/bin/termbrain"
chmod +x "$TERMBRAIN_HOME/bin/termbrain"

# Copy enhanced versions
cp "$SCRIPT_DIR/src/termbrain-enhanced.sh" "$TERMBRAIN_HOME/lib/"
cp "$SCRIPT_DIR/src/termbrain-cognitive.sh" "$TERMBRAIN_HOME/lib/"

# Copy lib files
if [[ -d "$SCRIPT_DIR/lib" ]]; then
    cp "$SCRIPT_DIR/lib/"*.sh "$TERMBRAIN_HOME/lib/" 2>/dev/null || true
    chmod +x "$TERMBRAIN_HOME/lib/"*.sh 2>/dev/null || true
fi

# Copy provider files
if [[ -d "$SCRIPT_DIR/providers" ]]; then
    cp "$SCRIPT_DIR/providers/"*.sh "$TERMBRAIN_HOME/providers/" 2>/dev/null || true
    chmod +x "$TERMBRAIN_HOME/providers/"*.sh 2>/dev/null || true
fi

# Create symlinks
echo ""
echo "🔗 Creating command shortcuts..."
ln -sf "$TERMBRAIN_HOME/bin/tb-wrapper" "$TERMBRAIN_HOME/bin/tb"

# Add to PATH
mkdir -p "$HOME/.local/bin"
ln -sf "$TERMBRAIN_HOME/bin/termbrain" "$HOME/.local/bin/termbrain"
ln -sf "$TERMBRAIN_HOME/bin/tb" "$HOME/.local/bin/tb"

# Shell detection and setup
echo ""
echo "🐚 Setting up shell integration..."

SHELL_NAME=$(basename "$SHELL")
RC_FILE=""

case "$SHELL_NAME" in
    bash)
        RC_FILE="$HOME/.bashrc"
        ;;
    zsh)
        RC_FILE="$HOME/.zshrc"
        ;;
    *)
        echo "⚠️  Unknown shell: $SHELL_NAME"
        echo "   Please manually add to your shell config:"
        echo "   source $TERMBRAIN_HOME/init.sh"
        ;;
esac

if [[ -n "$RC_FILE" ]]; then
    # Add to shell config
    if ! grep -q "termbrain/init.sh" "$RC_FILE" 2>/dev/null; then
        echo "" >> "$RC_FILE"
        echo "# Termbrain - The terminal that never forgets" >> "$RC_FILE"
        echo "export TERMBRAIN_HOME=\"$TERMBRAIN_HOME\"" >> "$RC_FILE"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$RC_FILE"
        echo "source \"\$TERMBRAIN_HOME/init.sh\"" >> "$RC_FILE"
        echo "✅ Added to $RC_FILE"
    else
        echo "✅ Already configured in $RC_FILE"
    fi
fi

# Create init script
cat > "$TERMBRAIN_HOME/init.sh" << 'EOF'
#!/usr/bin/env bash
# Termbrain initialization

# Load main module
if [[ -f "$TERMBRAIN_HOME/bin/termbrain" ]]; then
    source "$TERMBRAIN_HOME/bin/termbrain"
fi

# Welcome message (only show once per session)
if [[ -z "$TERMBRAIN_WELCOMED" ]]; then
    export TERMBRAIN_WELCOMED=1
    echo "🧠 Termbrain active | 'tb help' for commands"
fi
EOF

# Create wrapper script for non-sourced execution
cat > "$TERMBRAIN_HOME/bin/tb-wrapper" << 'EOF'
#!/usr/bin/env bash
# Wrapper for termbrain commands
export TERMBRAIN_HOME="${TERMBRAIN_HOME:-$HOME/.termbrain}"
export TERMBRAIN_DB="$TERMBRAIN_HOME/data/termbrain.db"

# Source core
source "$TERMBRAIN_HOME/bin/termbrain"

# Initialize database if needed
[[ ! -f "$TERMBRAIN_DB" ]] && tb::init_db >/dev/null 2>&1

# Load enhanced features if available
if [[ -f "$TERMBRAIN_HOME/lib/termbrain-enhanced.sh" ]]; then
    source "$TERMBRAIN_HOME/lib/termbrain-enhanced.sh"
    tb::init_enhanced_db >/dev/null 2>&1
fi

# Load cognitive features if available
if [[ -f "$TERMBRAIN_HOME/lib/termbrain-cognitive.sh" ]]; then
    source "$TERMBRAIN_HOME/lib/termbrain-cognitive.sh"
    tb::init_cognitive >/dev/null 2>&1
fi

# Run command
tb::main "$@"
EOF
chmod +x "$TERMBRAIN_HOME/bin/tb-wrapper"

# Note: The main termbrain script already has the correct ending,
# so we don't need to modify it during installation

# Initialize database
echo ""
echo "🗄️  Initializing memory database..."
"$TERMBRAIN_HOME/bin/tb-wrapper" --init-db

# Success!
echo ""
echo "✨ Termbrain installed successfully!"
echo ""
echo "🚀 Next steps:"
echo "   1. Restart your terminal or run: source $RC_FILE"
echo "   2. Try these commands:"
echo "      tb help     - Show all commands"
echo "      tb ai       - Generate AI context"
echo "      tb search   - Search your memory"
echo "      tb stats    - View analytics"
echo ""
echo "📚 Full docs: https://github.com/anivar/termbrain"
echo ""