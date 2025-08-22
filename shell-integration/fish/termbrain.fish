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

# Function to detect AI agents
function _termbrain_detect_ai_agent
    # Check if already wrapped by tb wrap
    if test -n "$TERMBRAIN_AI_WRAPPED"
        return 0
    end
    
    # Check for common AI agent environment variables
    if test -n "$AIDER_CHAT_ID"
        set -gx TERMBRAIN_AI_AGENT "aider"
        set -gx TERMBRAIN_AI_SESSION "$AIDER_CHAT_ID"
        return 0
    end
    
    if test -n "$CURSOR_SESSION_ID" -o -n "$CURSOR_CONTEXT"
        set -gx TERMBRAIN_AI_AGENT "cursor"
        set -gx TERMBRAIN_AI_SESSION (test -n "$CURSOR_SESSION_ID"; and echo "$CURSOR_SESSION_ID"; or echo "$CURSOR_CONTEXT")
        return 0
    end
    
    if test -n "$CONTINUE_SESSION" -o -n "$CONTINUE_CONTEXT_ID"
        set -gx TERMBRAIN_AI_AGENT "continue"
        set -gx TERMBRAIN_AI_SESSION (test -n "$CONTINUE_SESSION"; and echo "$CONTINUE_SESSION"; or echo "$CONTINUE_CONTEXT_ID")
        return 0
    end
    
    if test -n "$CODY_SESSION_ID" -o -n "$CODY_AGENT"
        set -gx TERMBRAIN_AI_AGENT "cody"
        set -gx TERMBRAIN_AI_SESSION (test -n "$CODY_SESSION_ID"; and echo "$CODY_SESSION_ID"; or echo "$CODY_AGENT")
        return 0
    end
    
    if test -n "$COPILOT_SESSION" -o -n "$GITHUB_COPILOT_CHAT"
        set -gx TERMBRAIN_AI_AGENT "copilot"
        set -gx TERMBRAIN_AI_SESSION (test -n "$COPILOT_SESSION"; and echo "$COPILOT_SESSION"; or echo "$GITHUB_COPILOT_CHAT")
        return 0
    end
    
    if test -n "$CLAUDE_SESSION_ID" -o -n "$ANTHROPIC_SESSION_ID" -o -n "$CLAUDE_CONVERSATION_ID"
        set -gx TERMBRAIN_AI_AGENT "claude"
        set -gx TERMBRAIN_AI_SESSION (test -n "$CLAUDE_SESSION_ID"; and echo "$CLAUDE_SESSION_ID"; or test -n "$ANTHROPIC_SESSION_ID"; and echo "$ANTHROPIC_SESSION_ID"; or echo "$CLAUDE_CONVERSATION_ID")
        return 0
    end
    
    if test -n "$GEMINI_SESSION_ID" -o -n "$GOOGLE_AI_SESSION" -o -n "$BARD_SESSION_ID"
        set -gx TERMBRAIN_AI_AGENT "gemini"
        set -gx TERMBRAIN_AI_SESSION (test -n "$GEMINI_SESSION_ID"; and echo "$GEMINI_SESSION_ID"; or test -n "$GOOGLE_AI_SESSION"; and echo "$GOOGLE_AI_SESSION"; or echo "$BARD_SESSION_ID")
        return 0
    end
    
    # Check process tree for AI agents - Fish implementation
    set -l current_pid %self
    set -l max_depth 10
    set -l depth 0
    
    while test $depth -lt $max_depth
        set current_pid (ps -o ppid= -p "$current_pid" 2>/dev/null | string trim)
        test -z "$current_pid" -o "$current_pid" = "1"; and break
        
        set -l process_name (ps -o comm= -p "$current_pid" 2>/dev/null | string trim)
        
        switch "$process_name"
            case "*aider*" "*Aider*"
                set -gx TERMBRAIN_AI_AGENT "aider"
                set -gx TERMBRAIN_AI_SESSION "pid-$current_pid"
                return 0
            case "*cursor*" "*Cursor*"
                set -gx TERMBRAIN_AI_AGENT "cursor"
                set -gx TERMBRAIN_AI_SESSION "pid-$current_pid"
                return 0
            case "*continue*" "*Continue*"
                set -gx TERMBRAIN_AI_AGENT "continue"
                set -gx TERMBRAIN_AI_SESSION "pid-$current_pid"
                return 0
            case "*cody*" "*Cody*"
                set -gx TERMBRAIN_AI_AGENT "cody"
                set -gx TERMBRAIN_AI_SESSION "pid-$current_pid"
                return 0
            case "*copilot*" "*Copilot*"
                set -gx TERMBRAIN_AI_AGENT "copilot"
                set -gx TERMBRAIN_AI_SESSION "pid-$current_pid"
                return 0
            case "*claude*" "*Claude*" "*anthropic*"
                set -gx TERMBRAIN_AI_AGENT "claude"
                set -gx TERMBRAIN_AI_SESSION "pid-$current_pid"
                return 0
            case "*gemini*" "*Gemini*" "*bard*" "*Bard*"
                set -gx TERMBRAIN_AI_AGENT "gemini"
                set -gx TERMBRAIN_AI_SESSION "pid-$current_pid"
                return 0
        end
        
        set depth (math $depth + 1)
    end
    
    return 1
end

# Function to record command execution
function _termbrain_record_command --on-event fish_postexec
    set -l exit_code $status
    set -l end_time (date +%s%3N)
    
    # Skip if termbrain is disabled
    test "$TERMBRAIN_ENABLED" != "1"; and return $exit_code
    test "$TERMBRAIN_AUTO_RECORD" != "1"; and return $exit_code
    
    # Detect AI agents if not already set
    _termbrain_detect_ai_agent
    
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
    # Use -- to prevent command injection and safely handle paths
    begin
        if test -n "$duration_ms"
            tb record -- "$last_command" \
                --exit-code "$exit_code" \
                --directory (realpath -- "$PWD" 2>/dev/null; or echo "$PWD") \
                --duration "$duration_ms" \
                >/dev/null 2>&1 &
        else
            tb record -- "$last_command" \
                --exit-code "$exit_code" \
                --directory (realpath -- "$PWD" 2>/dev/null; or echo "$PWD") \
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
    # Detect AI agent before showing status
    _termbrain_detect_ai_agent
    
    echo "TermBrain Status:"
    echo "  Enabled: $TERMBRAIN_ENABLED"
    echo "  Auto-record: $TERMBRAIN_AUTO_RECORD"
    echo "  Session ID: $TERMBRAIN_SESSION_ID"
    echo "  Shell: $SHELL"
    echo "  PWD: $PWD"
    echo "  Fish Version: $FISH_VERSION"
    
    # Show AI agent info if detected
    if test -n "$TERMBRAIN_AI_AGENT"
        echo "  AI Agent: $TERMBRAIN_AI_AGENT"
        echo "  AI Session: "(test -n "$TERMBRAIN_AI_SESSION"; and echo "$TERMBRAIN_AI_SESSION"; or echo "N/A")
        test -n "$TERMBRAIN_AI_CONTEXT"; and echo "  AI Context: $TERMBRAIN_AI_CONTEXT"
    end
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