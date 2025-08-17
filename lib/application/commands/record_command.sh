#!/usr/bin/env bash
# Record Command Use Case

source "${TERMBRAIN_LIB}/domain/entities/command.sh"
source "${TERMBRAIN_LIB}/domain/entities/session.sh"
source "${TERMBRAIN_LIB}/domain/services/semantic_analyzer.sh"
source "${TERMBRAIN_LIB}/domain/repositories/command_repository.sh"

# Record command execution
RecordCommand::execute() {
    local command_text="$1"
    local exit_code="${2:-0}"
    local duration_ms="${3:-0}"
    
    # Create command entity
    local command=$(Command::new "$command_text" "$PWD" "$exit_code" "$duration_ms")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Validate command
    if ! Command::validate "$command"; then
        # Still return success - we just don't record unsafe commands
        return 0
    fi
    
    # Enhance with semantic analysis
    local semantic_type=$(SemanticAnalyzer::analyze "$command_text")
    local project_type=$(SemanticAnalyzer::detect_project)
    local intent=$(SemanticAnalyzer::extract_intent "$command_text")
    local complexity=$(SemanticAnalyzer::complexity_score "$command_text")
    
    # Add semantic information to command
    command="$command"$'\n'"semantic_type:$semantic_type"
    command="$command"$'\n'"project_type:$project_type"
    command="$command"$'\n'"intent:$intent"
    command="$command"$'\n'"complexity:$complexity"
    
    # Save to repository
    if CommandRepository::save "$command"; then
        return 0
    else
        echo "ERROR: Failed to save command" >&2
        return 1
    fi
}

# Record command start (preexec)
RecordCommand::start() {
    local command_text="$1"
    
    # Safety check
    if ! Command::is_safe_to_record "$command_text" "$PWD"; then
        return 0
    fi
    
    # Store command for completion
    export TB_LAST_COMMAND="$command_text"
    export TB_COMMAND_START=$(date +%s%N)
    
    # Create initial command record
    local command=$(Command::new "$command_text" "$PWD" "" "" "$(Session::current_id)")
    local semantic_type=$(SemanticAnalyzer::analyze "$command_text")
    local project_type=$(SemanticAnalyzer::detect_project)
    
    # Add semantic info
    command="$command"$'\n'"semantic_type:$semantic_type"
    command="$command"$'\n'"project_type:$project_type"
    
    # Save and store ID for completion
    local command_id=$(CommandRepository::save "$command")
    export TB_CURRENT_CMD_ID="$command_id"
    
    return 0
}

# Record command completion (precmd)
RecordCommand::complete() {
    local exit_code="${1:-$?}"
    
    if [[ -n "$TB_CURRENT_CMD_ID" && -n "$TB_COMMAND_START" ]]; then
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - TB_COMMAND_START) / 1000000 ))
        
        # Update command with completion data
        local command=$(CommandRepository::find_by_id "$TB_CURRENT_CMD_ID")
        if [[ -n "$command" ]]; then
            # Update exit code and duration
            command=$(echo "$command" | sed "s/^exit_code:.*/exit_code:$exit_code/")
            command=$(echo "$command" | sed "s/^duration_ms:.*/duration_ms:$duration/")
            
            CommandRepository::update "$command"
        fi
        
        # Clear tracking variables
        unset TB_CURRENT_CMD_ID TB_COMMAND_START TB_LAST_COMMAND
    fi
    
    return 0
}