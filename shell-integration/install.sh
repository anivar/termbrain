#!/bin/bash
# TermBrain Shell Integration Installer

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
FORCE_INSTALL=false
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

# Function to install shell integration
install_integration() {
    local shell_type="$1"
    local config_file=$(get_shell_config "$shell_type")
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local integration_file="$script_dir/$shell_type/termbrain.$shell_type"
    
    print_info "Installing TermBrain integration for $shell_type"
    
    # Check if integration file exists
    if [[ ! -f "$integration_file" ]]; then
        print_error "Integration file not found: $integration_file"
        return 1
    fi
    
    # Create config directory if it doesn't exist (for fish)
    if [[ "$shell_type" == "fish" ]]; then
        mkdir -p "$(dirname "$config_file")"
    fi
    
    # Check if already installed
    local source_line="source \"$integration_file\""
    if [[ "$shell_type" == "fish" ]]; then
        source_line="source \"$integration_file\""
    fi
    
    if [[ -f "$config_file" ]] && grep -q "termbrain" "$config_file" 2>/dev/null; then
        if [[ "$FORCE_INSTALL" != true ]]; then
            print_warning "TermBrain integration appears to already be installed in $config_file"
            print_info "Use --force to reinstall"
            return 0
        else
            print_info "Force installing - removing existing integration"
            # Remove existing lines (basic cleanup)
            if [[ "$DRY_RUN" != true ]]; then
                grep -v "termbrain" "$config_file" > "$config_file.tmp" 2>/dev/null || true
                mv "$config_file.tmp" "$config_file" 2>/dev/null || true
            fi
        fi
    fi
    
    print_info "Adding integration to $config_file"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Would add: $source_line"
        return 0
    fi
    
    # Add the source line
    {
        echo ""
        echo "# TermBrain shell integration"
        echo "$source_line"
    } >> "$config_file"
    
    print_success "Integration installed successfully"
    print_info "Restart your shell or run: source $config_file"
}

# Function to show usage
show_usage() {
    cat << EOF
TermBrain Shell Integration Installer

Usage: $0 [OPTIONS]

Options:
    --shell SHELL       Specify shell type (bash, zsh, fish)
    --auto-detect       Auto-detect shell (default)
    --force             Force reinstall even if already installed
    --dry-run           Show what would be done without making changes
    --help              Show this help message

Examples:
    $0                  # Auto-detect and install
    $0 --shell zsh      # Install for zsh specifically
    $0 --force          # Force reinstall
    $0 --dry-run        # Preview installation

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
        --force)
            FORCE_INSTALL=true
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

# Main installation logic
main() {
    print_info "TermBrain Shell Integration Installer"
    echo ""
    
    # Check if tb command is available
    if ! command -v tb >/dev/null 2>&1; then
        print_error "TermBrain CLI 'tb' not found in PATH"
        print_info "Please install TermBrain first or add it to your PATH"
        exit 1
    fi
    
    print_success "TermBrain CLI found: $(which tb)"
    
    # Determine shell type
    if [[ "$AUTO_DETECT" == true ]]; then
        SHELL_TYPE=$(detect_shell)
        print_info "Auto-detected shell: $SHELL_TYPE"
    fi
    
    # Validate shell type
    case "$SHELL_TYPE" in
        bash|zsh|fish)
            print_info "Installing for shell: $SHELL_TYPE"
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
    
    # Install integration
    install_integration "$SHELL_TYPE"
    
    echo ""
    print_success "Installation complete!"
    print_info "To activate TermBrain integration:"
    print_info "  1. Restart your terminal, or"
    print_info "  2. Run: source $(get_shell_config "$SHELL_TYPE")"
    echo ""
    print_info "Test the integration with: tb status"
    print_info "Control recording with: tbe (enable), tbd (disable), tbs (status)"
}

# Run main function
main "$@"