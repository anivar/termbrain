#!/usr/bin/env bash
# Prediction Shell Hooks - Infrastructure layer for predictive features

source "${TERMBRAIN_LIB}/application/predictions/show_predictions.sh"
source "${TERMBRAIN_LIB}/application/commands/record_command.sh"

# Bash preexec with predictions
_termbrain_bash_predictive_preexec() {
    local command="$1"
    
    # Record command
    RecordCommand::start "$command"
    
    # Show predictions if enabled
    if [[ "${TERMBRAIN_PREDICTIVE:-0}" == "1" ]]; then
        ShowPredictions::before_command "$command" 2>/dev/null
    fi
}

# Bash precmd with predictions
_termbrain_bash_predictive_precmd() {
    local exit_code="$?"
    
    # Complete recording
    RecordCommand::complete "$exit_code"
    
    # Track directory changes
    if [[ "$PWD" != "${TERMBRAIN_LAST_PWD:-}" ]]; then
        export TERMBRAIN_LAST_PWD="$PWD"
        if [[ "${TERMBRAIN_PREDICTIVE:-0}" == "1" ]]; then
            ShowPredictions::on_directory_change "$PWD" 2>/dev/null
        fi
    fi
    
    # Suggest next command on success
    if [[ "${TERMBRAIN_PREDICTIVE:-0}" == "1" ]] && [[ "$exit_code" == "0" ]]; then
        ShowPredictions::suggest_next 2>/dev/null
    fi
}

# Zsh preexec with predictions
_termbrain_zsh_predictive_preexec() {
    local command="$1"
    
    # Record command
    RecordCommand::start "$command"
    
    # Show predictions if enabled
    if [[ "${TERMBRAIN_PREDICTIVE:-0}" == "1" ]]; then
        ShowPredictions::before_command "$command" 2>/dev/null
    fi
}

# Zsh precmd with predictions
_termbrain_zsh_predictive_precmd() {
    local exit_code="$?"
    
    # Complete recording
    RecordCommand::complete "$exit_code"
    
    # Suggest next command on success
    if [[ "${TERMBRAIN_PREDICTIVE:-0}" == "1" ]] && [[ "$exit_code" == "0" ]]; then
        ShowPredictions::suggest_next 2>/dev/null
    fi
}

# Zsh chpwd hook
_termbrain_zsh_chpwd() {
    if [[ "${TERMBRAIN_PREDICTIVE:-0}" == "1" ]]; then
        ShowPredictions::on_directory_change "$PWD" 2>/dev/null
    fi
}

# Initialize prediction hooks
PredictionHooks::init() {
    if [[ -n "$BASH_VERSION" ]]; then
        # Set up Bash hooks
        trap '_termbrain_bash_predictive_preexec "$BASH_COMMAND"' DEBUG
        
        if [[ -z "$PROMPT_COMMAND" ]]; then
            PROMPT_COMMAND="_termbrain_bash_predictive_precmd"
        else
            # Replace existing termbrain precmd if present
            if [[ "$PROMPT_COMMAND" =~ _termbrain.*precmd ]]; then
                PROMPT_COMMAND="${PROMPT_COMMAND//_termbrain*precmd/_termbrain_bash_predictive_precmd}"
            else
                PROMPT_COMMAND="$PROMPT_COMMAND; _termbrain_bash_predictive_precmd"
            fi
        fi
        
    elif [[ -n "$ZSH_VERSION" ]]; then
        # Load hook system
        autoload -U add-zsh-hook
        
        # Remove any existing termbrain hooks
        add-zsh-hook -d preexec _termbrain_preexec 2>/dev/null
        add-zsh-hook -d precmd _termbrain_precmd 2>/dev/null
        
        # Add predictive hooks
        add-zsh-hook preexec _termbrain_zsh_predictive_preexec
        add-zsh-hook precmd _termbrain_zsh_predictive_precmd
        add-zsh-hook chpwd _termbrain_zsh_chpwd
    fi
}

# Enable predictive mode
PredictionHooks::enable() {
    export TERMBRAIN_PREDICTIVE=1
    PredictionHooks::init
}

# Disable predictive mode
PredictionHooks::disable() {
    export TERMBRAIN_PREDICTIVE=0
}