#!/usr/bin/env bash
set -e

# Termbrain Uninstaller
TERMBRAIN_HOME="${TERMBRAIN_HOME:-$HOME/.termbrain}"

echo ""
echo "🧠 Termbrain Uninstaller"
echo "======================="
echo ""

# Confirmation
echo "This will remove Termbrain and all its data."
echo "Location: $TERMBRAIN_HOME"
echo ""
read -p "Are you sure? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Uninstall cancelled."
    exit 0
fi

echo ""
echo "🗑️  Removing Termbrain..."

# Remove from shell configs
SHELL_NAME=$(basename "$SHELL")
RC_FILE=""

case "$SHELL_NAME" in
    bash)
        RC_FILE="$HOME/.bashrc"
        ;;
    zsh)
        RC_FILE="$HOME/.zshrc"
        ;;
esac

if [[ -n "$RC_FILE" ]] && [[ -f "$RC_FILE" ]]; then
    echo "📝 Removing from $RC_FILE..."
    # Create backup
    cp "$RC_FILE" "$RC_FILE.termbrain-backup"
    
    # Remove termbrain lines
    sed -i.tmp '/# Termbrain - The terminal that never forgets/,/source.*termbrain.*init.sh/d' "$RC_FILE"
    rm -f "$RC_FILE.tmp"
    
    echo "✅ Shell config cleaned (backup: $RC_FILE.termbrain-backup)"
fi

# Remove symlinks
echo "🔗 Removing command links..."
rm -f "$HOME/.local/bin/termbrain"
rm -f "$HOME/.local/bin/tb"

# Optionally export data before removal
if [[ -f "$TERMBRAIN_HOME/data/termbrain.db" ]]; then
    echo ""
    read -p "Export command history before removal? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        EXPORT_FILE="$HOME/termbrain-export-$(date +%Y%m%d-%H%M%S).json"
        echo "📤 Exporting to $EXPORT_FILE..."
        
        sqlite3 "$TERMBRAIN_HOME/data/termbrain.db" -json "
            SELECT 
                command,
                directory,
                semantic_type,
                timestamp,
                exit_code
            FROM commands
            WHERE is_sensitive = 0
            ORDER BY timestamp DESC;
        " > "$EXPORT_FILE"
        
        echo "✅ Data exported to $EXPORT_FILE"
    fi
fi

# Remove termbrain directory
echo "🗑️  Removing $TERMBRAIN_HOME..."
rm -rf "$TERMBRAIN_HOME"

# Clean up any remaining files
rm -f .termbrain-context.md
rm -f cognitive-context.md

echo ""
echo "✅ Termbrain has been uninstalled."
echo ""
echo "To complete the uninstall:"
echo "1. Restart your terminal or run: source $RC_FILE"
echo "2. Remove any exported data files if no longer needed"
echo ""
echo "Thank you for using Termbrain\! 👋"
echo ""
