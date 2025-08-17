#!/usr/bin/env bash
# Create Workflow Use Case

source "${TERMBRAIN_LIB}/domain/entities/workflow.sh"
source "${TERMBRAIN_LIB}/domain/repositories/workflow_repository.sh"

CreateWorkflow::execute() {
    local name="$1"
    local description="$2"
    shift 2
    local commands=("$@")
    
    # Validate name
    if ! Workflow::validate_name "$name"; then
        return 1
    fi
    
    # Check if workflow already exists
    if WorkflowRepository::find_by_name "$name" >/dev/null 2>&1; then
        echo "ERROR: Workflow '$name' already exists" >&2
        return 1
    fi
    
    # Create workflow entity
    local workflow=$(Workflow::new "$name" "$description" "${commands[@]}")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Save to repository
    if WorkflowRepository::save "$workflow"; then
        echo "✅ Workflow '$name' created successfully"
        return 0
    else
        echo "❌ Failed to save workflow" >&2
        return 1
    fi
}