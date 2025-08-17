#!/usr/bin/env bash
# Analyze Project Use Case

source "${TERMBRAIN_LIB}/domain/services/project_detector.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_command_repository.sh"

AnalyzeProject::execute() {
    local project_root=$(ProjectDetector::find_root)
    local project_type=$(ProjectDetector::detect)
    
    echo "📊 Project Analysis: $(basename "$project_root")"
    echo "========================================="
    echo ""
    echo "Type: $project_type"
    echo "Root: $project_root"
    echo ""
    
    # Development patterns
    AnalyzeProject::dev_patterns "$project_root"
    echo ""
    
    # Common tasks
    AnalyzeProject::common_tasks "$project_root"
    echo ""
    
    # Time analysis
    AnalyzeProject::time_spent "$project_root"
}

AnalyzeProject::dev_patterns() {
    local root="$1"
    
    echo "## Development Patterns"
    
    # Most edited files
    echo "### Most Accessed Directories"
    sqlite3 "$TERMBRAIN_DB" "
        SELECT 
            printf('- %s (%d commands)',
                REPLACE(directory, '$root/', ''),
                COUNT(*))
        FROM commands
        WHERE directory LIKE '$root%'
        GROUP BY directory
        ORDER BY COUNT(*) DESC
        LIMIT 10;
    "
    
    # Development workflow
    echo ""
    echo "### Typical Workflow"
    sqlite3 "$TERMBRAIN_DB" "
        WITH Pairs AS (
            SELECT 
                c1.semantic_type as from_type,
                c2.semantic_type as to_type,
                COUNT(*) as transitions
            FROM commands c1
            JOIN commands c2 ON c2.id = c1.id + 1
            WHERE c1.session_id = c2.session_id
            AND c1.directory LIKE '$root%'
            GROUP BY from_type, to_type
            HAVING transitions > 2
            ORDER BY transitions DESC
            LIMIT 10
        )
        SELECT printf('- %s → %s (%d times)', from_type, to_type, transitions)
        FROM Pairs;
    "
}

AnalyzeProject::common_tasks() {
    local root="$1"
    
    echo "## Common Tasks"
    
    # Group by semantic type
    sqlite3 "$TERMBRAIN_DB" -column -header "
        SELECT 
            semantic_type as Task,
            COUNT(*) as Frequency,
            AVG(CASE WHEN exit_code = 0 THEN 100 ELSE 0 END) as 'Success %'
        FROM commands
        WHERE directory LIKE '$root%'
        GROUP BY semantic_type
        ORDER BY COUNT(*) DESC
        LIMIT 15;
    "
}

AnalyzeProject::time_spent() {
    local root="$1"
    
    echo "## Time Analysis"
    
    # Commands per day
    echo "### Daily Activity (Last 30 days)"
    sqlite3 "$TERMBRAIN_DB" "
        SELECT 
            printf('%s: %d commands',
                date(timestamp),
                COUNT(*))
        FROM commands
        WHERE directory LIKE '$root%'
        AND timestamp > datetime('now', '-30 days')
        GROUP BY date(timestamp)
        ORDER BY timestamp DESC
        LIMIT 7;
    "
    
    # Peak hours
    echo ""
    echo "### Peak Development Hours"
    sqlite3 "$TERMBRAIN_DB" "
        SELECT 
            printf('%s:00 - %d commands',
                strftime('%H', timestamp),
                COUNT(*))
        FROM commands
        WHERE directory LIKE '$root%'
        GROUP BY strftime('%H', timestamp)
        ORDER BY COUNT(*) DESC
        LIMIT 5;
    "
}

# Convenience function
tb::project() {
    AnalyzeProject::execute
}