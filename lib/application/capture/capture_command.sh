#!/usr/bin/env bash
# Capture Command Use Case

# Source dependencies
source "${TERMBRAIN_LIB}/domain/entities/command.sh"
source "${TERMBRAIN_LIB}/domain/services/semantic_analyzer.sh"
source "${TERMBRAIN_LIB}/domain/services/project_detector.sh"
source "${TERMBRAIN_LIB}/domain/services/safety_checker.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/command_repository.sh"

CaptureCommand::execute() {
    local cmd="$1"
    local metadata="$2"
    
    # Create command entity
    local command=$(Command::new \
        "$cmd" \
        "$PWD" \
        "$(git branch --show-current 2>/dev/null || echo '')" \
        "$(SemanticAnalyzer::analyze "$cmd")" \
        "$(ProjectDetector::detect)" \
        "$TERMBRAIN_SESSION_ID" \
        "$(SafetyChecker::is_sensitive "$cmd")"
    )
    
    # Enrich metadata
    local env_vars=$(env | grep -E '^(NODE_ENV|RAILS_ENV|DEBUG|VERBOSE)=' | tr '\n' ',')
    local terminal_type="${TERM:-unknown}"
    local shell_level="${SHLVL:-1}"
    local full_metadata="$metadata,$env_vars,$terminal_type,$shell_level"
    
    # Save to repository
    CommandRepository::save "$command" "$full_metadata"
}

# Convenience function for shell hooks
tb::capture_with_metadata() {
    CaptureCommand::execute "$@"
}