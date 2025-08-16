#!/usr/bin/env bash
# 🧠 Termbrain - The Terminal That Never Forgets
# Version: 1.0.0
# Author: Anivar Aravind
# License: MIT

# ============================================
# TERMBRAIN CORE
# ============================================

export TERMBRAIN_VERSION="1.0.0"
export TERMBRAIN_HOME="${TERMBRAIN_HOME:-$HOME/.termbrain}"
export TERMBRAIN_DB="$TERMBRAIN_HOME/data/termbrain.db"
export TERMBRAIN_SESSION_ID="session-$(date +%s)-$$"

# Create directory structure
[[ ! -d "$TERMBRAIN_HOME/data" ]] && mkdir -p "$TERMBRAIN_HOME"/{data,cache,exports,providers}

# ============================================
# DATABASE INITIALIZATION
# ============================================

tb::init_db() {
    sqlite3 "$TERMBRAIN_DB" <<'EOF'
-- Commands table: Core memory storage
CREATE TABLE IF NOT EXISTS commands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    command TEXT NOT NULL,
    directory TEXT,
    exit_code INTEGER,
    duration_ms INTEGER,
    git_branch TEXT,
    project_type TEXT,
    semantic_type TEXT,
    session_id TEXT,
    is_sensitive BOOLEAN DEFAULT FALSE
);

-- Errors table: Learn from mistakes
CREATE TABLE IF NOT EXISTS errors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    command_id INTEGER,
    error_output TEXT,
    solution_commands TEXT,
    solved BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (command_id) REFERENCES commands(id)
);

-- Patterns table: Detect workflows
CREATE TABLE IF NOT EXISTS patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern_type TEXT NOT NULL,
    pattern_data JSON,
    frequency INTEGER DEFAULT 1,
    last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(pattern_type)
);

-- Workflows table: Automation opportunities
CREATE TABLE IF NOT EXISTS workflows (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    description TEXT,
    command_sequence JSON,
    trigger_conditions JSON,
    success_rate REAL,
    times_used INTEGER DEFAULT 0
);

-- Context table: AI-ready contexts
CREATE TABLE IF NOT EXISTS contexts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    query TEXT,
    context_type TEXT,
    content TEXT,
    provider TEXT
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_commands_timestamp ON commands(timestamp);
CREATE INDEX IF NOT EXISTS idx_commands_semantic ON commands(semantic_type);
CREATE INDEX IF NOT EXISTS idx_commands_session ON commands(session_id);
CREATE INDEX IF NOT EXISTS idx_errors_solved ON errors(solved);
CREATE INDEX IF NOT EXISTS idx_patterns_type ON patterns(pattern_type);
EOF

    echo "✅ Termbrain database initialized"
}

# ============================================
# COMMAND CAPTURE SYSTEM
# ============================================

# Capture command before execution
tb::preexec() {
    local cmd="$1"
    
    # Safety check
    if tb::is_safe_to_record "$cmd"; then
        export TB_LAST_COMMAND="$cmd"
        export TB_COMMAND_START=$(date +%s%N)
        
        # Semantic analysis
        local semantic_type=$(tb::analyze_semantic "$cmd")
        local project_type=$(tb::detect_project)
        local is_sensitive=$(tb::check_sensitive "$cmd")
        
        # Store in database
        export TB_CURRENT_CMD_ID=$(sqlite3 "$TERMBRAIN_DB" "
            INSERT INTO commands (
                command, directory, git_branch, semantic_type, 
                project_type, session_id, is_sensitive
            )
            VALUES (
                '$(tb::escape_sql "$cmd")', 
                '$PWD', 
                '$(git branch --show-current 2>/dev/null || echo "")', 
                '$semantic_type', 
                '$project_type', 
                '$TERMBRAIN_SESSION_ID',
                $is_sensitive
            );
            SELECT last_insert_rowid();
        ")
        
        # Async pattern detection
        (tb::detect_patterns "$cmd" &)
    fi
}

# Capture result after execution
tb::precmd() {
    local exit_code=$?
    
    if [[ -n "$TB_CURRENT_CMD_ID" ]]; then
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - TB_COMMAND_START) / 1000000 ))
        
        # Update command record
        sqlite3 "$TERMBRAIN_DB" "
            UPDATE commands 
            SET exit_code = $exit_code, duration_ms = $duration 
            WHERE id = $TB_CURRENT_CMD_ID;
        "
        
        # Handle errors intelligently
        if [[ $exit_code -ne 0 ]]; then
            tb::capture_error $exit_code
        elif [[ -n "$TB_ERROR_MODE" ]]; then
            tb::learn_solution
        fi
        
        # Update live context
        (tb::update_live_context &)
    fi
}

# ============================================
# SEMANTIC ANALYSIS
# ============================================

tb::analyze_semantic() {
    local cmd="$1"
    
    # Intelligent command categorization
    case "$cmd" in
        git*) echo "version_control" ;;
        npm*|yarn*|pnpm*|bun*) echo "package_management" ;;
        docker*|kubectl*|podman*) echo "containerization" ;;
        *test*|*spec*|jest*|pytest*|mocha*) echo "testing" ;;
        *lint*|*format*|prettier*|black*|rustfmt*) echo "code_quality" ;;
        make*|cargo\ build*|go\ build*|mvn*) echo "building" ;;
        curl*|wget*|http*|fetch*) echo "http_request" ;;
        ssh*|scp*|rsync*) echo "remote_access" ;;
        vim*|nvim*|emacs*|code*|subl*) echo "editing" ;;
        cd*|ls*|find*|grep*|rg*|fd*) echo "navigation" ;;
        psql*|mysql*|mongo*|redis-cli*) echo "database" ;;
        python*|node*|ruby*|go\ run*|cargo\ run*) echo "code_execution" ;;
        *) echo "general" ;;
    esac
}

tb::detect_project() {
    # Smart project type detection
    if [[ -f "package.json" ]]; then
        if [[ -f "tsconfig.json" ]]; then echo "typescript"
        else echo "javascript"; fi
    elif [[ -f "Cargo.toml" ]]; then echo "rust"
    elif [[ -f "go.mod" ]]; then echo "go"
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then echo "python"
    elif [[ -f "Gemfile" ]]; then echo "ruby"
    elif [[ -f "pom.xml" ]]; then echo "java_maven"
    elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then echo "java_gradle"
    elif [[ -f "CMakeLists.txt" ]]; then echo "cpp_cmake"
    elif [[ -f "Dockerfile" ]] || [[ -f "docker-compose.yml" ]]; then echo "docker"
    elif [[ -d ".git" ]]; then echo "git_project"
    else echo "unknown"; fi
}

# ============================================
# SAFETY & PRIVACY
# ============================================

tb::is_safe_to_record() {
    local cmd="$1"
    
    # Don't record dangerous commands
    case "$cmd" in
        *"rm -rf /"*|*"dd if="*|*":(){ :|:& };:"*)
            return 1
            ;;
    esac
    
    # Don't record in sensitive directories
    case "$PWD" in
        */.ssh*|*/.gnupg*|*/private/*)
            return 1
            ;;
    esac
    
    return 0
}

tb::check_sensitive() {
    local cmd="$1"
    
    # Check for sensitive patterns
    if [[ "$cmd" =~ (password|token|secret|api_key|private) ]]; then
        echo "1"
    else
        echo "0"
    fi
}

tb::escape_sql() {
    echo "$1" | sed "s/'/''/g"
}

# ============================================
# ERROR LEARNING
# ============================================

tb::capture_error() {
    local exit_code=$1
    
    sqlite3 "$TERMBRAIN_DB" "
        INSERT INTO errors (command_id)
        VALUES ($TB_CURRENT_CMD_ID);
    "
    
    export TB_ERROR_MODE=1
    export TB_ERROR_CMD_ID=$TB_CURRENT_CMD_ID
    
    echo "🔴 Error detected. Watching for your solution..."
}

tb::learn_solution() {
    if [[ -n "$TB_ERROR_MODE" ]] && [[ -n "$TB_LAST_COMMAND" ]]; then
        sqlite3 "$TERMBRAIN_DB" "
            UPDATE errors 
            SET solution_commands = '$(tb::escape_sql "$TB_LAST_COMMAND")',
                solved = 1
            WHERE command_id = $TB_ERROR_CMD_ID
            AND solved = 0;
        "
        
        unset TB_ERROR_MODE TB_ERROR_CMD_ID
        echo "✅ Solution learned!"
    fi
}

# ============================================
# AI CONTEXT GENERATION
# ============================================

tb::ai() {
    local query="${1:-general help}"
    local provider="${2:-universal}"
    
    echo "🧠 Generating AI context for: $query"
    
    local context_file="$TERMBRAIN_HOME/cache/context-$(date +%s).md"
    
    {
        echo "# Termbrain Context"
        echo "Generated: $(date)"
        echo "Query: $query"
        echo ""
        
        echo "## Working Environment"
        echo "- Directory: $PWD"
        echo "- Project Type: $(tb::detect_project)"
        echo "- Git Branch: $(git branch --show-current 2>/dev/null || echo 'not a git repo')"
        echo ""
        
        echo "## Relevant Command History"
        sqlite3 "$TERMBRAIN_DB" -separator " | " "
            SELECT command, 
                   CASE WHEN exit_code = 0 THEN '✓' ELSE '✗' END as status,
                   semantic_type
            FROM commands 
            WHERE (command LIKE '%${query}%' OR semantic_type LIKE '%${query}%')
            AND is_sensitive = 0
            ORDER BY timestamp DESC 
            LIMIT 20;
        " | column -t -s "|"
        echo ""
        
        echo "## Learned Solutions"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('Problem: %s\nSolution: %s\n', 
                   c.command, e.solution_commands)
            FROM errors e
            JOIN commands c ON e.command_id = c.id
            WHERE e.solved = 1
            AND c.command LIKE '%${query}%'
            ORDER BY e.timestamp DESC
            LIMIT 5;
        "
        echo ""
        
        echo "## Your Patterns"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('- %s (used %d times)', 
                   pattern_type, frequency)
            FROM patterns 
            ORDER BY frequency DESC
            LIMIT 10;
        "
        echo ""
        
        echo "## Code Statistics"
        if command -v tokei &>/dev/null; then
            tokei . 2>/dev/null | tail -n +3 || echo "No code stats available"
        fi
        
    } > "$context_file"
    
    # Copy to provider location
    case "$provider" in
        claude)
            cp "$context_file" .claude.md
            echo "📝 Context saved to .claude.md"
            ;;
        cursor)
            cp "$context_file" .cursorrules
            echo "📝 Context saved to .cursorrules"
            ;;
        copilot)
            mkdir -p .github
            cp "$context_file" .github/copilot-instructions.md
            echo "📝 Context saved to .github/copilot-instructions.md"
            ;;
        *)
            cp "$context_file" .ai-context.md
            echo "📝 Context saved to .ai-context.md"
            ;;
    esac
    
    # Show preview
    echo ""
    head -30 "$context_file"
    echo -e "\n... (see full context in file)"
}

# ============================================
# INTERACTIVE COMMANDS
# ============================================

tb::search() {
    echo "🔍 Termbrain Search"
    echo "=================="
    
    local search_type=$(echo -e "Commands\nErrors\nPatterns\nSolutions" | fzf --height=10 --header="What to search?")
    
    case "$search_type" in
        Commands)
            sqlite3 "$TERMBRAIN_DB" -column -header "
                SELECT 
                    substr(command, 1, 50) as command,
                    datetime(timestamp, 'localtime') as time,
                    CASE WHEN exit_code = 0 THEN '✓' ELSE '✗' END as ok
                FROM commands 
                WHERE is_sensitive = 0
                ORDER BY timestamp DESC 
                LIMIT 100;
            " | fzf --header="Recent Commands"
            ;;
        Errors)
            sqlite3 "$TERMBRAIN_DB" "
                SELECT printf('%s | %s', c.command, e.solution_commands)
                FROM errors e
                JOIN commands c ON e.command_id = c.id
                WHERE e.solved = 1
                ORDER BY e.timestamp DESC;
            " | fzf --header="Errors & Solutions"
            ;;
        Patterns)
            sqlite3 "$TERMBRAIN_DB" -column -header "
                SELECT pattern_type, frequency, date(last_seen) as last_used
                FROM patterns
                ORDER BY frequency DESC;
            " | fzf --header="Your Patterns"
            ;;
    esac
}

tb::stats() {
    clear
    echo "📊 Termbrain Analytics"
    echo "====================="
    echo ""
    
    local total_commands=$(sqlite3 "$TERMBRAIN_DB" "SELECT COUNT(*) FROM commands;")
    local total_errors=$(sqlite3 "$TERMBRAIN_DB" "SELECT COUNT(*) FROM errors;")
    local solved_errors=$(sqlite3 "$TERMBRAIN_DB" "SELECT COUNT(*) FROM errors WHERE solved = 1;")
    
    echo "📈 Overview"
    echo "  Total Commands: $total_commands"
    echo "  Total Errors: $total_errors"
    echo "  Solutions Found: $solved_errors"
    echo ""
    
    echo "🏆 Top Command Types"
    sqlite3 "$TERMBRAIN_DB" -column -header "
        SELECT 
            semantic_type as type,
            COUNT(*) as count,
            printf('%.1f%%', 100.0 * COUNT(*) / $total_commands) as percent
        FROM commands
        GROUP BY semantic_type
        ORDER BY COUNT(*) DESC
        LIMIT 10;
    "
    echo ""
    
    echo "⚡ Performance Stats"
    sqlite3 "$TERMBRAIN_DB" -column -header "
        SELECT 
            semantic_type as type,
            printf('%.1fs', AVG(duration_ms/1000.0)) as avg_time,
            printf('%.1f%%', 100.0 * SUM(CASE WHEN exit_code != 0 THEN 1 ELSE 0 END) / COUNT(*)) as error_rate
        FROM commands
        WHERE duration_ms IS NOT NULL
        GROUP BY semantic_type
        HAVING COUNT(*) > 5
        ORDER BY AVG(duration_ms) DESC
        LIMIT 5;
    "
}

tb::learn() {
    echo "🤖 Learning your patterns..."
    
    # Find repeated command sequences
    local patterns=$(sqlite3 "$TERMBRAIN_DB" "
        WITH Sequences AS (
            SELECT 
                c1.command as cmd1,
                c2.command as cmd2,
                COUNT(*) as frequency
            FROM commands c1
            JOIN commands c2 ON c2.id = c1.id + 1
            WHERE c1.session_id = c2.session_id
            GROUP BY c1.command, c2.command
            HAVING COUNT(*) > 2
        )
        SELECT cmd1, cmd2, frequency FROM Sequences
        ORDER BY frequency DESC
        LIMIT 5;
    ")
    
    if [[ -n "$patterns" ]]; then
        echo "Found repeated patterns:"
        echo "$patterns" | column -t -s "|"
        echo ""
        echo "💡 Consider creating aliases for these workflows!"
    else
        echo "No significant patterns found yet. Keep using Termbrain!"
    fi
}

tb::help() {
    cat << 'EOF'
🧠 Termbrain - The Terminal That Never Forgets

Core Commands:
  tb ai [query] [provider]  Generate AI context (providers: claude, cursor, copilot)
  tb search                 Search through your command history
  tb stats                  View your terminal analytics
  tb learn                  Discover patterns in your workflow
  tb privacy                Manage privacy settings
  tb help                   Show this help message

Enhanced Commands (if enabled):
  tb why                    Explain why you ran the last command
  tb arch [title] [desc]    Document architectural decisions
  tb explore                Interactive memory explorer
  tb project [action]       Manage project contexts

Cognitive Commands (if enabled):
  tb intend [goal]          Set your current intention
  tb achieved               Mark intention complete and capture learnings
  tb flow [start|end|status] Track flow state and productivity
  tb growth                 View your learning journey

Examples:
  tb ai "docker help" claude     # Get Docker context for Claude
  tb intend "add user auth"      # Set intention
  tb why                         # Document reasoning
  tb flow start                  # Enter flow state

More info: https://github.com/anivar/termbrain
EOF
}

tb::privacy() {
    echo "🔒 Privacy Controls"
    echo "=================="
    
    local action=$(echo -e "Redact sensitive data\nExport my data\nClear all data\nPause recording" | fzf --height=10)
    
    case "$action" in
        "Redact sensitive data")
            sqlite3 "$TERMBRAIN_DB" "
                UPDATE commands 
                SET command = '[REDACTED]'
                WHERE is_sensitive = 1;
            "
            echo "✅ Sensitive commands redacted"
            ;;
        "Export my data")
            local export_file="$TERMBRAIN_HOME/exports/termbrain-export-$(date +%s).json"
            sqlite3 "$TERMBRAIN_DB" "
                SELECT json_group_array(json_object(
                    'timestamp', timestamp,
                    'command', CASE WHEN is_sensitive THEN '[REDACTED]' ELSE command END,
                    'semantic_type', semantic_type
                )) FROM commands;
            " > "$export_file"
            echo "📤 Exported to: $export_file"
            ;;
        "Clear all data")
            echo "⚠️  Are you sure? Type 'yes' to confirm:"
            read -r confirm
            if [[ "$confirm" == "yes" ]]; then
                rm -f "$TERMBRAIN_DB"
                tb::init_db
                echo "🧹 All data cleared"
            fi
            ;;
        "Pause recording")
            export TERMBRAIN_PAUSED=1
            echo "⏸️  Recording paused. Run 'unset TERMBRAIN_PAUSED' to resume"
            ;;
    esac
}

# ============================================
# SHELL INTEGRATION
# ============================================

tb::setup_hooks() {
    # Only set up if not paused
    if [[ -z "$TERMBRAIN_PAUSED" ]]; then
        if [[ -n "$BASH_VERSION" ]]; then
            # Bash integration
            trap 'tb::preexec "$BASH_COMMAND"' DEBUG
            PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}tb::precmd"
        elif [[ -n "$ZSH_VERSION" ]]; then
            # Zsh integration
            autoload -U add-zsh-hook
            add-zsh-hook preexec tb::preexec
            add-zsh-hook precmd tb::precmd
        fi
    fi
}

# ============================================
# MAIN ENTRY POINT
# ============================================

tb::main() {
    case "${1:-}" in
        --init-db)
            tb::init_db
            ;;
        ai)
            shift
            # Load provider if specified
            local query="${1:-general}"
            local provider="${2:-universal}"
            
            if [[ -f "$TERMBRAIN_HOME/providers/${provider}.sh" ]]; then
                source "$TERMBRAIN_HOME/providers/${provider}.sh"
                tb::${provider}_export ".${provider}-context.md" "$query"
            else
                tb::ai "$@"
            fi
            ;;
        search)
            tb::search
            ;;
        stats)
            tb::stats
            ;;
        learn)
            tb::learn
            ;;
        privacy)
            tb::privacy
            ;;
        help|--help|-h)
            tb::help
            ;;
        # Enhanced commands
        why)
            if command -v tb::why &>/dev/null; then
                tb::why
            else
                echo "Enhanced features not loaded. Source termbrain-enhanced.sh"
            fi
            ;;
        arch)
            if command -v tb::arch &>/dev/null; then
                shift
                tb::arch "$@"
            else
                echo "Enhanced features not loaded. Source termbrain-enhanced.sh"
            fi
            ;;
        explore)
            if command -v tb::explore &>/dev/null; then
                tb::explore
            else
                echo "Enhanced features not loaded. Source termbrain-enhanced.sh"
            fi
            ;;
        project)
            if command -v tb::project &>/dev/null; then
                shift
                tb::project "$@"
            else
                echo "Enhanced features not loaded. Source termbrain-enhanced.sh"
            fi
            ;;
        # Cognitive commands
        intend)
            if command -v tb::intend &>/dev/null; then
                shift
                tb::intend "$@"
            else
                echo "Cognitive features not loaded. Source termbrain-cognitive.sh"
            fi
            ;;
        achieved)
            if command -v tb::achieved &>/dev/null; then
                tb::achieved
            else
                echo "Cognitive features not loaded. Source termbrain-cognitive.sh"
            fi
            ;;
        flow)
            if command -v tb::flow &>/dev/null; then
                shift
                tb::flow "$@"
            else
                echo "Cognitive features not loaded. Source termbrain-cognitive.sh"
            fi
            ;;
        growth)
            if command -v tb::growth &>/dev/null; then
                tb::growth
            else
                echo "Cognitive features not loaded. Source termbrain-cognitive.sh"
            fi
            ;;
        "")
            # If sourced, set up hooks
            if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
                tb::setup_hooks
                
                # Create convenient aliases
                alias tb='tb'
                alias tb-ai='tb ai'
                alias tb-search='tb search'
                alias tb-stats='tb stats'
                alias tb-learn='tb learn'
                
                # Initialize database if needed
                [[ ! -f "$TERMBRAIN_DB" ]] && tb::init_db
                
                # Load enhanced features if available
                if [[ -f "$TERMBRAIN_HOME/lib/termbrain-enhanced.sh" ]]; then
                    source "$TERMBRAIN_HOME/lib/termbrain-enhanced.sh"
                fi
                
                # Load cognitive features if available
                if [[ -f "$TERMBRAIN_HOME/lib/termbrain-cognitive.sh" ]]; then
                    source "$TERMBRAIN_HOME/lib/termbrain-cognitive.sh"
                fi
                
                # Show session start
                local total_cmds=$(sqlite3 "$TERMBRAIN_DB" "SELECT COUNT(*) FROM commands;" 2>/dev/null || echo 0)
                echo "🧠 Termbrain active | $total_cmds commands remembered | 'tb help' for info"
            else
                tb::help
            fi
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run 'tb help' for usage"
            ;;
    esac
}

# If run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    tb::main "$@"
fi