#!/usr/bin/env bash
# Command Repository Interface - Domain layer contract

# Repository interface for command storage

# Save command
CommandRepository::save() {
    echo "ERROR: CommandRepository::save must be implemented" >&2
    return 1
}

# Find command by ID
CommandRepository::find_by_id() {
    echo "ERROR: CommandRepository::find_by_id must be implemented" >&2
    return 1
}

# Find commands by session
CommandRepository::find_by_session() {
    echo "ERROR: CommandRepository::find_by_session must be implemented" >&2
    return 1
}

# Search commands by text
CommandRepository::search() {
    echo "ERROR: CommandRepository::search must be implemented" >&2
    return 1
}

# Get recent commands
CommandRepository::get_recent() {
    echo "ERROR: CommandRepository::get_recent must be implemented" >&2
    return 1
}

# Get commands by semantic type
CommandRepository::find_by_semantic_type() {
    echo "ERROR: CommandRepository::find_by_semantic_type must be implemented" >&2
    return 1
}

# Get command statistics
CommandRepository::get_statistics() {
    echo "ERROR: CommandRepository::get_statistics must be implemented" >&2
    return 1
}

# Update command
CommandRepository::update() {
    echo "ERROR: CommandRepository::update must be implemented" >&2
    return 1
}

# Delete command
CommandRepository::delete() {
    echo "ERROR: CommandRepository::delete must be implemented" >&2
    return 1
}

# Count commands
CommandRepository::count() {
    echo "ERROR: CommandRepository::count must be implemented" >&2
    return 1
}