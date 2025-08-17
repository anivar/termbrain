#!/usr/bin/env bash
# CLI Router - Maps commands to use cases

# Library path should be set by entry point

# Load use cases
source "${TERMBRAIN_LIB}/application/workflows/create_workflow.sh"
source "${TERMBRAIN_LIB}/application/workflows/run_workflow.sh"

# Load infrastructure
source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_workflow_repository.sh"

# Initialize
SqliteWorkflowRepository::init

# Route workflow commands
CLIRouter::workflow() {
    local subcommand="${1:-help}"
    shift
    
    case "$subcommand" in
        create)
            CreateWorkflow::execute "$@"
            ;;
        run)
            RunWorkflow::execute "$@"
            ;;
        list)
            _workflow_list
            ;;
        show)
            _workflow_show "$@"
            ;;
        delete)
            _workflow_delete "$@"
            ;;
        export)
            source "${TERMBRAIN_LIB}/application/commands/export_data.sh"
            ExportData::workflows "$@"
            ;;
        help|*)
            _workflow_help
            ;;
    esac
}

# List workflows (presentation logic)
_workflow_list() {
    echo "📋 Your Workflows"
    echo "================"
    
    local workflows=$(WorkflowRepository::find_all)
    if [[ -z "$workflows" ]]; then
        echo "No workflows found. Create one with: tb workflow create"
        return
    fi
    
    printf "%-20s %-30s %6s %8s\n" "Name" "Description" "Runs" "Success"
    printf "%-20s %-30s %6s %8s\n" "----" "-----------" "----" "-------"
    
    while IFS='|' read -r name desc rate used; do
        local success_pct=$(printf "%.0f%%" $(echo "$rate * 100" | bc))
        printf "%-20s %-30s %6s %8s\n" "$name" "${desc:0:30}" "$used" "$success_pct"
    done <<< "$workflows"
}

# Show workflow details
_workflow_show() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo "Usage: tb workflow show <name>"
        return 1
    fi
    
    local workflow=$(WorkflowRepository::find_by_name "$name")
    if [[ $? -ne 0 ]]; then
        echo "❌ Workflow '$name' not found"
        return 1
    fi
    
    # Parse workflow
    local desc=$(echo "$workflow" | grep "^description:" | cut -d: -f2-)
    local rate=$(echo "$workflow" | grep "^success_rate:" | cut -d: -f2-)
    local used=$(echo "$workflow" | grep "^times_used:" | cut -d: -f2-)
    
    echo "📋 $name"
    echo "📝 $desc"
    echo "📊 Used $used times ($(printf "%.0f%%" $(echo "$rate * 100" | bc)) success)"
    echo ""
    echo "Commands:"
    
    # Get and display commands
    local commands=$(WorkflowRepository::get_commands "$name")
    while IFS='|' read -r pos cmd; do
        echo "  [$pos] $cmd"
    done <<< "$commands"
}

# Delete workflow
_workflow_delete() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo "Usage: tb workflow delete <name>"
        return 1
    fi
    
    if WorkflowRepository::delete "$name"; then
        echo "🗑️  Deleted workflow: $name"
    else
        echo "❌ Failed to delete workflow '$name'"
        return 1
    fi
}

# Help
_workflow_help() {
    echo "📋 Workflow Commands:"
    echo "  tb workflow create <name> <desc> <cmd1> <cmd2>..."
    echo "  tb workflow list                 # Show all workflows"
    echo "  tb workflow show <name>          # Show workflow details"
    echo "  tb workflow run <name>           # Run a workflow"
    echo "  tb workflow delete <name>        # Delete a workflow"
}