#!/bin/bash
# TermBrain Shell Integration Uninstaller

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SHELL_TYPE=""
AUTO_DETECT=true
DRY_RUN=false

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to detect current shell
detect_shell() {
    local shell_name=$(basename "$SHELL")
    case "$shell_name" in
        bash) echo "bash" ;;
        zsh) echo "zsh" ;;
        fish) echo "fish" ;;
        *) echo "unknown" ;;
    esac
}

# Function to get shell config file
get_shell_config() {
    local shell_type="$1"
    case "$shell_type" in
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            elif [[ -f "$HOME/.bash_profile" ]]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to remove shell integration
remove_integration() {
    local shell_type="$1"
    local config_file=$(get_shell_config "$shell_type")
    
    print_info "Removing TermBrain integration from $shell_type"
    
    if [[ ! -f "$config_file" ]]; then
        print_warning "Config file not found: $config_file"
        return 0
    fi
    
    # Check if integration is present
    if ! grep -q "termbrain" "$config_file" 2>/dev/null; then
        print_info "TermBrain integration not found in $config_file"
        return 0
    fi
    
    print_info "Removing integration lines from $config_file"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Lines that would be removed:"
        grep -n "termbrain\|TermBrain" "$config_file" 2>/dev/null || true
        return 0
    fi
    
    # Create backup
    local backup_file="${config_file}.termbrain.backup.$(date +%s)"
    cp "$config_file" "$backup_file"
    print_info "Created backup: $backup_file"
    
    # Remove lines containing termbrain (case insensitive)
    # This removes:
    # - Comment lines with "TermBrain"  
    # - Source lines with "termbrain"
    # - Empty lines that were part of the integration block
    local temp_file=$(mktemp)
    
    # More sophisticated removal - remove the entire integration block
    awk '
    BEGIN { in_termbrain_block = 0 }
    /# TermBrain shell integration/ { in_termbrain_block = 1; next }
    /termbrain/ { 
        if (in_termbrain_block) next
        # If standalone termbrain line (not in block), remove it
        if (/source.*termbrain/ || /^[[:space:]]*tb[[:space:]]/ || /TERMBRAIN_/) next
    }
    /^[[:space:]]*$/ && in_termbrain_block { next }
    { 
        in_termbrain_block = 0
        print 
    }
    ' "$config_file" > "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$config_file"
    
    print_success "Integration removed successfully"
    print_info "Backup saved as: $backup_file"
}

# Function to clean environment variables
clean_environment() {
    print_info "Cleaning TermBrain environment variables"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would unset:"
        env | grep "TERMBRAIN_" || print_info "  No TermBrain environment variables found"
        return 0
    fi
    
    # Unset TermBrain environment variables
    unset TERMBRAIN_ENABLED 2>/dev/null || true
    unset TERMBRAIN_AUTO_RECORD 2>/dev/null || true  
    unset TERMBRAIN_SESSION_ID 2>/dev/null || true
    unset TERMBRAIN_COMMAND_START_TIME 2>/dev/null || true
    
    print_success "Environment variables cleaned"
}

# Function to show usage
show_usage() {
    cat << EOF
TermBrain Shell Integration Uninstaller

Usage: $0 [OPTIONS]

Options:
    --shell SHELL       Specify shell type (bash, zsh, fish)
    --auto-detect       Auto-detect shell (default)
    --dry-run           Show what would be done without making changes
    --help              Show this help message

Examples:
    $0                  # Auto-detect and uninstall
    $0 --shell zsh      # Uninstall from zsh specifically
    $0 --dry-run        # Preview uninstallation

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --shell)
            SHELL_TYPE="$2"
            AUTO_DETECT=false
            shift 2
            ;;
        --auto-detect)
            AUTO_DETECT=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main uninstallation logic
main() {
    print_info "TermBrain Shell Integration Uninstaller"
    echo ""
    
    # Determine shell type
    if [[ "$AUTO_DETECT" == true ]]; then
        SHELL_TYPE=$(detect_shell)
        print_info "Auto-detected shell: $SHELL_TYPE"
    fi
    
    # Validate shell type
    case "$SHELL_TYPE" in
        bash|zsh|fish)
            print_info "Uninstalling from shell: $SHELL_TYPE"
            ;;
        unknown|"")
            print_error "Unsupported or unknown shell: $SHELL_TYPE"
            print_info "Supported shells: bash, zsh, fish"
            print_info "Use --shell to specify manually"
            exit 1
            ;;
        *)
            print_error "Invalid shell type: $SHELL_TYPE"
            print_info "Supported shells: bash, zsh, fish"
            exit 1
            ;;
    esac
    
    # Remove integration
    remove_integration "$SHELL_TYPE"
    
    # Clean environment
    clean_environment
    
    echo ""
    if [[ "$DRY_RUN" != true ]]; then
        print_success "Uninstallation complete!"
        print_info "To fully remove TermBrain integration:"
        print_info "  1. Restart your terminal, or"
        print_info "  2. Run: source $(get_shell_config "$SHELL_TYPE")"
        echo ""
        print_info "Note: TermBrain CLI itself is still installed"
        print_info "To remove it completely, run: cargo uninstall termbrain-cli"
    else
        print_info "Dry run complete. Use without --dry-run to actually uninstall."
    fi
}

# Run main function
main "$@"