#!/usr/bin/env bash
# Workflow Repository Interface - Domain layer contract

# Repository interface - must be implemented by infrastructure layer
# This defines what the domain needs, not how it's stored

# Save workflow
WorkflowRepository::save() {
    echo "ERROR: WorkflowRepository::save must be implemented" >&2
    return 1
}

# Find workflow by name
WorkflowRepository::find_by_name() {
    echo "ERROR: WorkflowRepository::find_by_name must be implemented" >&2
    return 1
}

# Get all workflows
WorkflowRepository::find_all() {
    echo "ERROR: WorkflowRepository::find_all must be implemented" >&2
    return 1
}

# Update workflow
WorkflowRepository::update() {
    echo "ERROR: WorkflowRepository::update must be implemented" >&2
    return 1
}

# Delete workflow by name
WorkflowRepository::delete() {
    echo "ERROR: WorkflowRepository::delete must be implemented" >&2
    return 1
}

# Get workflow commands
WorkflowRepository::get_commands() {
    echo "ERROR: WorkflowRepository::get_commands must be implemented" >&2
    return 1
}