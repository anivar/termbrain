#!/usr/bin/env bash
# Generate Statistics Use Case

source "${TERMBRAIN_LIB}/domain/repositories/command_repository.sh"

# Generate comprehensive statistics
GenerateStats::execute() {
    local format="${1:-detailed}"
    
    case "$format" in
        summary)
            GenerateStats::summary
            ;;
        detailed)
            GenerateStats::detailed
            ;;
        json)
            GenerateStats::json
            ;;
        *)
            GenerateStats::detailed
            ;;
    esac
}

# Generate summary statistics
GenerateStats::summary() {
    local stats=$(CommandRepository::get_statistics)
    
    # Parse stats (assuming single row with pipe separator)
    IFS='|' read -r total successful failed types sessions avg_duration <<< "$stats"
    
    echo "📊 Termbrain Statistics Summary"
    echo "=============================="
    echo "Total Commands: $total"
    echo "Successful: $successful ($(( successful * 100 / total ))%)"
    echo "Failed: $failed ($(( failed * 100 / total ))%)"
    echo "Command Types: $types"
    echo "Sessions: $sessions"
    printf "Average Duration: %.1fms\n" "$avg_duration"
}

# Generate detailed statistics
GenerateStats::detailed() {
    clear
    echo "📊 Termbrain Analytics Dashboard"
    echo "==============================="
    echo ""
    
    # Overview
    GenerateStats::summary
    echo ""
    
    # Top command types
    echo "🏆 Top Command Types"
    echo "-------------------"
    sqlite3 "$TERMBRAIN_DB" -column -header <<EOF
SELECT 
    semantic_type as Type,
    COUNT(*) as Count,
    printf('%.1f%%', 100.0 * COUNT(*) / (SELECT COUNT(*) FROM commands)) as Percent,
    printf('%.1f%%', 100.0 * SUM(CASE WHEN exit_code = 0 THEN 1 ELSE 0 END) / COUNT(*)) as Success
FROM commands
WHERE is_sensitive = 0
GROUP BY semantic_type
ORDER BY COUNT(*) DESC
LIMIT 10;
EOF
    echo ""
    
    # Performance stats
    echo "⚡ Performance by Type"
    echo "--------------------"
    sqlite3 "$TERMBRAIN_DB" -column -header <<EOF
SELECT 
    semantic_type as Type,
    printf('%.1fms', AVG(duration_ms)) as AvgTime,
    printf('%.1fms', MAX(duration_ms)) as MaxTime,
    COUNT(*) as Count
FROM commands
WHERE duration_ms > 0 AND is_sensitive = 0
GROUP BY semantic_type
HAVING COUNT(*) > 5
ORDER BY AVG(duration_ms) DESC
LIMIT 10;
EOF
    echo ""
    
    # Daily activity
    echo "📅 Daily Activity (Last 7 Days)"
    echo "------------------------------"
    sqlite3 "$TERMBRAIN_DB" -column -header <<EOF
SELECT 
    date(timestamp) as Date,
    COUNT(*) as Commands,
    COUNT(DISTINCT session_id) as Sessions,
    printf('%.1f%%', 100.0 * SUM(CASE WHEN exit_code = 0 THEN 1 ELSE 0 END) / COUNT(*)) as Success
FROM commands
WHERE timestamp >= date('now', '-7 days')
AND is_sensitive = 0
GROUP BY date(timestamp)
ORDER BY Date DESC;
EOF
    echo ""
    
    # Project activity
    echo "📂 Project Activity"
    echo "------------------"
    sqlite3 "$TERMBRAIN_DB" -column -header <<EOF
SELECT 
    project_type as Project,
    COUNT(*) as Commands,
    COUNT(DISTINCT session_id) as Sessions
FROM commands
WHERE project_type != 'unknown' AND is_sensitive = 0
GROUP BY project_type
ORDER BY COUNT(*) DESC
LIMIT 10;
EOF
    echo ""
    
    # Error patterns
    echo "❌ Common Errors"
    echo "---------------"
    sqlite3 "$TERMBRAIN_DB" -column -header <<EOF
SELECT 
    semantic_type as Type,
    COUNT(*) as Errors,
    printf('%.1f%%', 100.0 * COUNT(*) / SUM(COUNT(*)) OVER()) as Percent
FROM commands
WHERE exit_code != 0 AND is_sensitive = 0
GROUP BY semantic_type
ORDER BY COUNT(*) DESC
LIMIT 5;
EOF
}

# Generate JSON statistics
GenerateStats::json() {
    local stats=$(CommandRepository::get_statistics)
    IFS='|' read -r total successful failed types sessions avg_duration <<< "$stats"
    
    # Basic stats
    echo "{"
    echo "  \"overview\": {"
    echo "    \"total_commands\": $total,"
    echo "    \"successful_commands\": $successful,"
    echo "    \"failed_commands\": $failed,"
    echo "    \"success_rate\": $(( successful * 100 / total )),"
    echo "    \"command_types\": $types,"
    echo "    \"sessions\": $sessions,"
    printf "    \"avg_duration_ms\": %.1f\n" "$avg_duration"
    echo "  },"
    
    # Command types
    echo "  \"command_types\": ["
    local first=true
    while IFS='|' read -r type count percent success_rate; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        printf '    {
      "type": "%s",
      "count": %s,
      "percentage": %s,
      "success_rate": %s
    }' "$type" "$count" "$percent" "$success_rate"
    done < <(sqlite3 "$TERMBRAIN_DB" -separator '|' "
        SELECT semantic_type, COUNT(*), 
               printf('%.1f', 100.0 * COUNT(*) / (SELECT COUNT(*) FROM commands)),
               printf('%.1f', 100.0 * SUM(CASE WHEN exit_code = 0 THEN 1 ELSE 0 END) / COUNT(*))
        FROM commands WHERE is_sensitive = 0
        GROUP BY semantic_type ORDER BY COUNT(*) DESC LIMIT 10")
    echo ""
    echo "  ]"
    echo "}"
}

# Get productivity metrics
GenerateStats::productivity() {
    echo "💪 Productivity Metrics"
    echo "======================"
    
    # Commands per session
    echo "Commands per session:"
    sqlite3 "$TERMBRAIN_DB" -column -header <<EOF
SELECT 
    AVG(commands_per_session) as AvgCommandsPerSession,
    MAX(commands_per_session) as MaxCommandsPerSession,
    MIN(commands_per_session) as MinCommandsPerSession
FROM (
    SELECT session_id, COUNT(*) as commands_per_session
    FROM commands
    WHERE is_sensitive = 0
    GROUP BY session_id
);
EOF
    echo ""
    
    # Most complex commands
    echo "Most complex commands:"
    sqlite3 "$TERMBRAIN_DB" -column -header <<EOF
SELECT 
    complexity as Level,
    COUNT(*) as Count,
    printf('%.1f%%', 100.0 * COUNT(*) / (SELECT COUNT(*) FROM commands)) as Percent
FROM commands
WHERE is_sensitive = 0
GROUP BY complexity
ORDER BY complexity DESC;
EOF
}