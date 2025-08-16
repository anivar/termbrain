#!/usr/bin/env bash
# Termbrain Uninstaller

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "🧠 Termbrain Uninstaller"
echo "========================"
echo ""

# Confirm uninstallation
echo -e "${YELLOW}This will remove Termbrain from your system.${NC}"
echo -e "${YELLOW}Your command history database will be preserved unless you choose to delete it.${NC}"
echo ""
echo -n "Are you sure you want to uninstall Termbrain? (y/N): "
read -r confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

TERMBRAIN_HOME="${TERMBRAIN_HOME:-$HOME/.termbrain}"

# Remove from shell configuration
echo ""
echo "🔧 Removing shell integration..."

for rc_file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile"; do
    if [[ -f "$rc_file" ]]; then
        # Create backup
        cp "$rc_file" "${rc_file}.termbrain-backup"
        
        # Remove Termbrain lines
        sed -i.tmp '/# Termbrain/,/source.*termbrain.*init\.sh/d' "$rc_file"
        rm -f "${rc_file}.tmp"
        
        echo "✅ Cleaned $rc_file"
    fi
done

# Remove symlinks
echo ""
echo "🔗 Removing command symlinks..."

for link in "$HOME/.local/bin/termbrain" "$HOME/.local/bin/tb"; do
    if [[ -L "$link" ]]; then
        rm -f "$link"
        echo "✅ Removed $link"
    fi
done

# Handle database
echo ""
echo -e "${YELLOW}Your Termbrain database contains your command history.${NC}"
echo -n "Do you want to DELETE your database? (y/N): "
read -r delete_db

if [[ "$delete_db" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${RED}⚠️  This action cannot be undone!${NC}"
    echo -n "Type 'DELETE' to confirm database deletion: "
    read -r confirm_delete
    
    if [[ "$confirm_delete" == "DELETE" ]]; then
        rm -rf "$TERMBRAIN_HOME/data"
        echo "✅ Database deleted"
    else
        echo "Database deletion cancelled"
    fi
else
    echo ""
    echo "📁 Your database is preserved at: $TERMBRAIN_HOME/data/"
    echo "   To access it later, you can reinstall Termbrain"
fi

# Export option
if [[ -d "$TERMBRAIN_HOME/data" ]] && [[ -f "$TERMBRAIN_HOME/data/termbrain.db" ]]; then
    echo ""
    echo -n "Would you like to export your data before removing Termbrain? (y/N): "
    read -r export_data
    
    if [[ "$export_data" =~ ^[Yy]$ ]]; then
        export_file="$HOME/termbrain-export-$(date +%Y%m%d-%H%M%S).json"
        
        sqlite3 "$TERMBRAIN_HOME/data/termbrain.db" "
            SELECT json_group_array(json_object(
                'timestamp', timestamp,
                'command', CASE WHEN is_sensitive THEN '[REDACTED]' ELSE command END,
                'directory', directory,
                'semantic_type', semantic_type,
                'exit_code', exit_code
            )) FROM commands;
        " > "$export_file"
        
        echo "✅ Data exported to: $export_file"
    fi
fi

# Remove Termbrain directories (except data if preserved)
echo ""
echo "🗑️  Removing Termbrain files..."

if [[ -d "$TERMBRAIN_HOME" ]]; then
    # Remove everything except data directory if it exists
    find "$TERMBRAIN_HOME" -mindepth 1 -maxdepth 1 ! -name 'data' -exec rm -rf {} +
    
    # If data was deleted or doesn't exist, remove the whole directory
    if [[ ! -d "$TERMBRAIN_HOME/data" ]]; then
        rm -rf "$TERMBRAIN_HOME"
    fi
    
    echo "✅ Termbrain files removed"
fi

# Remove any leftover AI context files
echo ""
echo "🧹 Cleaning up context files..."
for file in .termbrain-context.md .claude.md .cursorrules .ai-context.md; do
    if [[ -f "$HOME/$file" ]]; then
        rm -f "$HOME/$file"
        echo "✅ Removed $file"
    fi
done

# Final message
echo ""
echo -e "${GREEN}✨ Termbrain has been uninstalled${NC}"
echo ""

if [[ -d "$TERMBRAIN_HOME/data" ]]; then
    echo "📁 Your database was preserved at: $TERMBRAIN_HOME/data/"
    echo "   Delete it manually if no longer needed: rm -rf $TERMBRAIN_HOME"
fi

echo ""
echo "To remove backup files created during uninstall:"
echo "  rm ~/.bashrc.termbrain-backup ~/.zshrc.termbrain-backup"
echo ""
echo "Thank you for trying Termbrain! 🧠"
echo "Feedback welcome at: https://github.com/anivar/termbrain/issues"

# Remind to restart shell
echo ""
echo -e "${YELLOW}Please restart your terminal or run: source ~/.bashrc (or ~/.zshrc)${NC}"