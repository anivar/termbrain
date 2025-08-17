#!/usr/bin/env bash
# Command Router - Routes all termbrain commands to use cases

# Set up library path
export TERMBRAIN_LIB="${TERMBRAIN_LIB:-./lib}"

# Load all use cases
source "${TERMBRAIN_LIB}/application/commands/search_history.sh"
source "${TERMBRAIN_LIB}/application/commands/generate_stats.sh"
source "${TERMBRAIN_LIB}/application/workflows/create_workflow.sh"
source "${TERMBRAIN_LIB}/application/workflows/run_workflow.sh"

# Load infrastructure
source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_command_repository.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_workflow_repository.sh"
source "${TERMBRAIN_LIB}/infrastructure/shell/shell_hooks.sh"

# Initialize repositories
SqliteCommandRepository::init
SqliteWorkflowRepository::init

# Route search commands
CommandRouter::search() {
    local query="$1"
    local format="${2:-table}"
    
    SearchHistory::execute "$query" "$format"
}

# Route statistics commands
CommandRouter::stats() {
    local format="${1:-detailed}"
    
    GenerateStats::execute "$format"
}

# Route workflow commands (delegate to existing router)
CommandRouter::workflow() {
    # Load workflow router if not already loaded
    if ! command -v CLIRouter::workflow >/dev/null 2>&1; then
        source "${TERMBRAIN_LIB}/presentation/cli_router.sh"
    fi
    
    CLIRouter::workflow "$@"
}

# Show command history by type
CommandRouter::history() {
    local semantic_type="${1:-all}"
    local limit="${2:-20}"
    
    if [[ "$semantic_type" == "all" ]]; then
        SearchHistory::execute "" "table" "$limit"
    else
        SearchHistory::by_semantic_type "$semantic_type" "$limit"
    fi
}

# Show productivity metrics
CommandRouter::productivity() {
    GenerateStats::productivity
}

# Search commands by semantic type
CommandRouter::type() {
    local semantic_type="$1"
    
    if [[ -z "$semantic_type" ]]; then
        echo "Usage: tb type <semantic_type>"
        echo ""
        echo "Available types:"
        sqlite3 "$TERMBRAIN_DB" "SELECT DISTINCT semantic_type FROM commands WHERE is_sensitive = 0 ORDER BY semantic_type;"
        return 1
    fi
    
    SearchHistory::by_semantic_type "$semantic_type"
}

# Initialize termbrain
CommandRouter::init() {
    # Set up shell hooks
    ShellHooks::init
    
    # Show welcome message
    local total_commands=$(CommandRepository::count)
    echo "🧠 Termbrain active | $total_commands commands remembered | 'tb help' for info"
}

# Disable termbrain
CommandRouter::disable() {
    ShellHooks::disable
    echo "⏸️ Termbrain disabled"
}

# Enable termbrain
CommandRouter::enable() {
    ShellHooks::enable
    echo "▶️ Termbrain enabled"
}

# Status check
CommandRouter::status() {
    echo "🧠 Termbrain Status"
    echo "==================="
    
    if ShellHooks::is_active; then
        echo "Status: ✅ Active"
    else
        echo "Status: ❌ Inactive"
    fi
    
    local total_commands=$(CommandRepository::count)
    echo "Commands recorded: $total_commands"
    
    echo "Database: $TERMBRAIN_DB"
    echo "Shell: ${SHELL##*/}"
    
    if [[ -n "$BASH_VERSION" ]]; then
        echo "Shell version: Bash $BASH_VERSION"
    elif [[ -n "$ZSH_VERSION" ]]; then
        echo "Shell version: Zsh $ZSH_VERSION"
    fi
}

# Help command
CommandRouter::help() {
    cat << 'EOF'
🧠 Termbrain - The Terminal That Never Forgets

Core Commands:
  tb search [query]             Search command history
  tb stats [format]             View analytics (detailed|summary|json)
  tb workflow <action>          Manage workflows
  tb history [type] [limit]     Show command history
  tb type <semantic_type>       Show commands by type
  tb productivity               Show productivity metrics
  tb status                     Show termbrain status
  tb init                       Initialize/restart termbrain
  tb disable                    Disable command recording
  tb enable                     Enable command recording
  tb help                       Show this help

Workflow Commands:
  tb workflow create <name> <desc> <cmd1> <cmd2>...
  tb workflow list              Show all workflows
  tb workflow show <name>       Show workflow details
  tb workflow run <name>        Run a workflow
  tb workflow delete <name>     Delete a workflow
  tb workflow patterns          Find command patterns

Search Examples:
  tb search git                 Find all git commands
  tb search "npm install"       Find npm install commands
  tb type version_control       Show all git commands
  tb history building 10        Show last 10 build commands

Statistics Examples:
  tb stats                      Detailed analytics dashboard
  tb stats summary              Quick overview
  tb stats json                 JSON format for scripts
  tb productivity               Productivity metrics

More info: https://github.com/anivar/termbrain
EOF
}