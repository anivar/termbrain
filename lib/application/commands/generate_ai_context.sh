#!/usr/bin/env bash
# Generate AI Context Use Case

source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_command_repository.sh"
source "${TERMBRAIN_LIB}/domain/services/project_detector.sh"

GenerateAIContext::execute() {
    local query="${1:-general}"
    local output="${2:-.termbrain-context.md}"
    
    {
        echo "# Termbrain AI Context"
        echo "Generated at: $(date)"
        echo ""
        
        # Project context
        GenerateAIContext::project_context
        echo ""
        
        # Recent activity
        GenerateAIContext::recent_activity "$query"
        echo ""
        
        # Command patterns
        GenerateAIContext::command_patterns "$query"
        echo ""
        
        # Common workflows
        GenerateAIContext::common_workflows "$query"
        echo ""
        
        # Error patterns
        GenerateAIContext::error_patterns
        
    } > "$output"
    
    echo "📄 AI context generated: $output"
    echo "💡 Use this with your AI assistant for better suggestions"
}

GenerateAIContext::project_context() {
    echo "## Project Context"
    
    local project_type=$(ProjectDetector::detect)
    local project_root=$(ProjectDetector::find_root)
    
    echo "- Project Type: $project_type"
    echo "- Project Root: $project_root"
    echo "- Current Directory: $PWD"
    
    # Git info
    if [[ -d ".git" ]]; then
        local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        local status=$(git status --porcelain | wc -l)
        echo "- Git Branch: $branch"
        echo "- Uncommitted Changes: $status files"
    fi
}

GenerateAIContext::recent_activity() {
    local query="$1"
    
    echo "## Recent Activity"
    
    # Last 20 commands with context
    sqlite3 "$TERMBRAIN_DB" -separator ' | ' "
        SELECT 
            strftime('%H:%M', timestamp) as time,
            command,
            directory,
            exit_code
        FROM commands
        WHERE is_sensitive = 0
        ${query:+AND command LIKE '%$query%'}
        ORDER BY timestamp DESC
        LIMIT 20;
    " | while IFS='|' read -r time cmd dir exit_code; do
        echo "- [$time] \`$cmd\` ${exit_code:-0} (in ${dir##*/})"
    done
}

GenerateAIContext::command_patterns() {
    local query="$1"
    
    echo "## Command Patterns"
    
    # Most used commands
    echo "### Most Used Commands"
    sqlite3 "$TERMBRAIN_DB" "
        SELECT 
            printf('- %s (%d times)', semantic_type, COUNT(*))
        FROM commands
        WHERE is_sensitive = 0
        ${query:+AND semantic_type LIKE '%$query%'}
        GROUP BY semantic_type
        ORDER BY COUNT(*) DESC
        LIMIT 10;
    "
    
    # Time-based patterns
    echo ""
    echo "### Peak Activity Hours"
    sqlite3 "$TERMBRAIN_DB" "
        SELECT 
            printf('- %s:00 - %d commands', 
                strftime('%H', timestamp), 
                COUNT(*))
        FROM commands
        WHERE timestamp > datetime('now', '-7 days')
        GROUP BY strftime('%H', timestamp)
        ORDER BY COUNT(*) DESC
        LIMIT 5;
    "
}

GenerateAIContext::common_workflows() {
    local query="$1"
    
    echo "## Common Workflows"
    
    # 3-command sequences
    sqlite3 "$TERMBRAIN_DB" "
        WITH Sequences AS (
            SELECT 
                c1.semantic_type as step1,
                c2.semantic_type as step2,
                c3.semantic_type as step3,
                COUNT(*) as frequency
            FROM commands c1
            JOIN commands c2 ON c2.id = c1.id + 1
            JOIN commands c3 ON c3.id = c2.id + 1
            WHERE c1.session_id = c2.session_id 
            AND c2.session_id = c3.session_id
            ${query:+AND (c1.semantic_type LIKE '%$query%' OR c2.semantic_type LIKE '%$query%' OR c3.semantic_type LIKE '%$query%')}
            GROUP BY step1, step2, step3
            HAVING frequency >= 2
            ORDER BY frequency DESC
            LIMIT 5
        )
        SELECT printf('- %s → %s → %s (%d times)', 
               step1, step2, step3, frequency)
        FROM Sequences;
    "
}

GenerateAIContext::error_patterns() {
    echo "## Error Patterns"
    
    # Recent errors
    sqlite3 "$TERMBRAIN_DB" "
        SELECT 
            printf('- %s: Exit code %d (%d times)',
                semantic_type,
                exit_code,
                COUNT(*))
        FROM commands
        WHERE exit_code != 0
        AND timestamp > datetime('now', '-7 days')
        GROUP BY semantic_type, exit_code
        ORDER BY COUNT(*) DESC
        LIMIT 10;
    "
}

# Convenience function
tb::ai() {
    GenerateAIContext::execute "$@"
}