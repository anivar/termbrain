# TermBrain shell integration for Fish
# This file should be sourced in ~/.config/fish/config.fish or placed in ~/.config/fish/conf.d/

# Configuration
set -gx TERMBRAIN_ENABLED (test -n "$TERMBRAIN_ENABLED"; and echo $TERMBRAIN_ENABLED; or echo "1")
set -gx TERMBRAIN_AUTO_RECORD (test -n "$TERMBRAIN_AUTO_RECORD"; and echo $TERMBRAIN_AUTO_RECORD; or echo "1")
set -gx TERMBRAIN_SESSION_ID (test -n "$TERMBRAIN_SESSION_ID"; and echo $TERMBRAIN_SESSION_ID; or echo (date +%s)"-"(echo %self))

# Check if termbrain CLI is available
if not command -v tb >/dev/null 2>&1
    echo "Warning: termbrain CLI (tb) not found in PATH" >&2
    exit 1
end

# Function to record command execution
function _termbrain_record_command --on-event fish_postexec
    set -l exit_code $status
    set -l end_time (date +%s%3N)
    
    # Skip if termbrain is disabled
    test "$TERMBRAIN_ENABLED" != "1"; and return $exit_code
    test "$TERMBRAIN_AUTO_RECORD" != "1"; and return $exit_code
    
    # Get the command that was just executed
    set -l last_command $argv[1]
    
    # Skip empty commands or termbrain commands
    test -z "$last_command"; and return $exit_code
    string match -q "tb *" "$last_command"; and return $exit_code
    string match -q "termbrain *" "$last_command"; and return $exit_code
    
    # Calculate duration if start time is available
    set -l duration_ms ""
    if test -n "$TERMBRAIN_COMMAND_START_TIME"
        set duration_ms (math $end_time - $TERMBRAIN_COMMAND_START_TIME)
        set -e TERMBRAIN_COMMAND_START_TIME
    end
    
    # Record the command asynchronously
    begin
        if test -n "$duration_ms"
            tb record "$last_command" \
                --exit-code "$exit_code" \
                --directory "$PWD" \
                --duration "$duration_ms" \
                >/dev/null 2>&1 &
        else
            tb record "$last_command" \
                --exit-code "$exit_code" \
                --directory "$PWD" \
                >/dev/null 2>&1 &
        end
    end
    
    return $exit_code
end

# Function to record command start time
function _termbrain_pre_command --on-event fish_preexec
    test "$TERMBRAIN_ENABLED" = "1"; and set -gx TERMBRAIN_COMMAND_START_TIME (date +%s%3N)
end

# Utility functions for manual control
function termbrain_enable
    set -gx TERMBRAIN_ENABLED 1
    echo "TermBrain recording enabled"
end

function termbrain_disable
    set -gx TERMBRAIN_ENABLED 0
    echo "TermBrain recording disabled"
end

function termbrain_status
    echo "TermBrain Status:"
    echo "  Enabled: $TERMBRAIN_ENABLED"
    echo "  Auto-record: $TERMBRAIN_AUTO_RECORD"
    echo "  Session ID: $TERMBRAIN_SESSION_ID"
    echo "  Shell: $SHELL"
    echo "  PWD: $PWD"
    echo "  Fish Version: $FISH_VERSION"
end

# Aliases for convenience
alias tbs='termbrain_status'
alias tbe='termbrain_enable'
alias tbd='termbrain_disable'

# Tab completion for termbrain commands
if command -v tb >/dev/null 2>&1
    # Fish completion
    complete -c tb -n '__fish_use_subcommand' -x -a 'record' -d 'Record a command execution'
    complete -c tb -n '__fish_use_subcommand' -x -a 'search' -d 'Search command history'
    complete -c tb -n '__fish_use_subcommand' -x -a 'history' -d 'Show recent command history'
    complete -c tb -n '__fish_use_subcommand' -x -a 'statistics' -d 'Show usage statistics'
    complete -c tb -n '__fish_use_subcommand' -x -a 'patterns' -d 'Detect and show usage patterns'
    complete -c tb -n '__fish_use_subcommand' -x -a 'workflow' -d 'Manage workflows'
    complete -c tb -n '__fish_use_subcommand' -x -a 'export' -d 'Export command data'
    complete -c tb -n '__fish_use_subcommand' -x -a 'install' -d 'Setup shell integration'
    complete -c tb -n '__fish_use_subcommand' -x -a 'interactive' -d 'Start interactive session'
    complete -c tb -n '__fish_use_subcommand' -x -a 'status' -d 'Show system status'
    complete -c tb -n '__fish_use_subcommand' -x -a 'help' -d 'Show help information'
    
    # Common options
    complete -c tb -l verbose -d 'Enable verbose output'
    complete -c tb -l format -x -a 'table json csv plain' -d 'Output format'
end

echo "TermBrain shell integration loaded (Fish)"