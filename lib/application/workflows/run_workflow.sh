#!/usr/bin/env bash
# Run Workflow Use Case

source "${TERMBRAIN_LIB}/domain/entities/workflow.sh"
source "${TERMBRAIN_LIB}/domain/repositories/workflow_repository.sh"

RunWorkflow::execute() {
    local name="$1"
    local dry_run="${2:-false}"
    
    # Get workflow from repository
    local workflow=$(WorkflowRepository::find_by_name "$name")
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Workflow '$name' not found" >&2
        return 1
    fi
    
    # Get commands
    local commands=$(WorkflowRepository::get_commands "$name")
    if [[ -z "$commands" ]]; then
        echo "ERROR: No commands found for workflow '$name'" >&2
        return 1
    fi
    
    echo "🚀 Running workflow: $name"
    echo "===================="
    
    local success=true
    local cmd_num=0
    
    # Execute each command
    while IFS='|' read -r position command; do
        ((cmd_num++))
        echo ""
        echo "[$cmd_num] $command"
        
        if [[ "$dry_run" == "true" ]]; then
            echo "   [DRY RUN - not executed]"
        else
            if eval "$command"; then
                echo "✅ Success"
            else
                echo "❌ Failed"
                success=false
                break
            fi
        fi
    done <<< "$commands"
    
    # Update statistics if not dry run
    if [[ "$dry_run" != "true" ]]; then
        local updated_workflow=$(Workflow::update_stats "$workflow" "$success")
        WorkflowRepository::update "$updated_workflow"
        
        if [[ "$success" == "true" ]]; then
            echo ""
            echo "✅ Workflow completed successfully!"
        else
            echo ""
            echo "❌ Workflow failed"
            return 1
        fi
    fi
    
    return 0
}