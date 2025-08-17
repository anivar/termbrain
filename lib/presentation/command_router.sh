#!/usr/bin/env bash
# Command Router - Routes all termbrain commands to use cases

# Set up library path
export TERMBRAIN_LIB="${TERMBRAIN_LIB:-./lib}"

# Load all use cases
source "${TERMBRAIN_LIB}/application/commands/search_history.sh"
source "${TERMBRAIN_LIB}/application/commands/generate_stats.sh"
source "${TERMBRAIN_LIB}/application/workflows/create_workflow.sh"
source "${TERMBRAIN_LIB}/application/workflows/run_workflow.sh"

# Load cognitive features
source "${TERMBRAIN_LIB}/application/ai/track_intention.sh"
source "${TERMBRAIN_LIB}/application/ai/extract_knowledge.sh"
source "${TERMBRAIN_LIB}/application/ai/track_flow.sh"
source "${TERMBRAIN_LIB}/application/ai/show_growth.sh"
source "${TERMBRAIN_LIB}/application/ai/suggest_actions.sh"
source "${TERMBRAIN_LIB}/application/ai/generate_context.sh"

# Load enhanced features
source "${TERMBRAIN_LIB}/application/commands/generate_ai_context.sh"
source "${TERMBRAIN_LIB}/application/commands/explain_commands.sh"
source "${TERMBRAIN_LIB}/application/commands/analyze_project.sh"
source "${TERMBRAIN_LIB}/application/commands/export_data.sh"

# Load infrastructure
source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_command_repository.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_workflow_repository.sh"
source "${TERMBRAIN_LIB}/infrastructure/shell/shell_hooks.sh"
source "${TERMBRAIN_LIB}/infrastructure/database/cognitive_schema.sh"
source "${TERMBRAIN_LIB}/infrastructure/database/migration_runner.sh"

# Initialize repositories
SqliteCommandRepository::init
SqliteWorkflowRepository::init
CognitiveSchema::ensure

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

# Cognitive commands
CommandRouter::intend() {
    TrackIntention::start "$@"
}

CommandRouter::achieved() {
    TrackIntention::complete
}

CommandRouter::flow() {
    TrackFlow::main "$@"
}

CommandRouter::growth() {
    ShowGrowth::display
}

CommandRouter::suggest() {
    SuggestActions::display
}

CommandRouter::context() {
    GenerateContext::cognitive "$@"
}

# Enhanced commands
CommandRouter::ai() {
    GenerateAIContext::execute "$@"
}

CommandRouter::why() {
    ExplainCommands::why "$@"
}

CommandRouter::arch() {
    ExplainCommands::architecture
}

CommandRouter::explore() {
    ExplainCommands::explore "$@"
}

CommandRouter::project() {
    AnalyzeProject::execute
}

CommandRouter::export() {
    ExportData::execute "$@"
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

# Toggle predictive mode
CommandRouter::predictive() {
    local action="${1:-toggle}"
    
    source "${TERMBRAIN_LIB}/infrastructure/shell/prediction_hooks.sh"
    
    case "$action" in
        on|enable)
            PredictionHooks::enable
            echo "🤖 Predictive mode enabled"
            ;;
        off|disable)
            PredictionHooks::disable
            echo "🤖 Predictive mode disabled"
            ;;
        toggle)
            if [[ "${TERMBRAIN_PREDICTIVE:-0}" == "1" ]]; then
                PredictionHooks::disable
                echo "🤖 Predictive mode disabled"
            else
                PredictionHooks::enable
                echo "🤖 Predictive mode enabled"
            fi
            ;;
        *)
            echo "Usage: tb predictive [on|off|toggle]"
            return 1
            ;;
    esac
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

Cognitive Commands:
  tb intend [goal]              Set an intention/goal
  tb achieved                   Mark intention complete
  tb flow [start|end|status]    Track flow state
  tb growth                     View learning analytics
  tb suggest                    Get personalized suggestions
  tb context [query]            Generate cognitive context

Enhanced Commands:
  tb ai [query]                 Generate AI assistant context
  tb why [limit]                Explain recent commands
  tb arch                       Analyze project architecture
  tb explore [pattern]          Explore command patterns
  tb project                    Analyze current project
  tb export [format] [file]     Export command history (json|csv|md|sql)
  tb predictive [on|off]        Toggle predictive suggestions

Export Examples:
  tb export                     Export all to JSON (default)
  tb export csv                 Export to CSV format
  tb export md report.md        Export to markdown file
  tb export json - git          Export git commands to JSON
  tb workflow export            Export workflows

Predictive Mode:
  tb predictive on              Enable smart suggestions
  tb predictive off             Disable suggestions
  tb predictive                 Toggle on/off
EOF
}