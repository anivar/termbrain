#!/usr/bin/env bash
# Command capture utilities for Termbrain

# Enhanced command capture with metadata
tb::capture_with_metadata() {
    local cmd="$1"
    local metadata="$2"
    
    # Capture additional context
    local env_vars=$(env | grep -E '^(NODE_ENV|RAILS_ENV|DEBUG|VERBOSE)=' | tr '\n' ',')
    local terminal_type="${TERM:-unknown}"
    local shell_level="${SHLVL:-1}"
    
    # Store with extended metadata
    sqlite3 "$TERMBRAIN_DB" "
        INSERT INTO commands (
            command, directory, git_branch, semantic_type, 
            project_type, session_id, is_sensitive, metadata
        )
        VALUES (
            '$(tb::escape_sql "$cmd")', 
            '$PWD', 
            '$(git branch --show-current 2>/dev/null || echo "")', 
            '$(tb::analyze_semantic "$cmd")', 
            '$(tb::detect_project)', 
            '$TERMBRAIN_SESSION_ID',
            $(tb::check_sensitive "$cmd"),
            '$(tb::escape_sql "$metadata,$env_vars,$terminal_type,$shell_level")'
        );
    "
}