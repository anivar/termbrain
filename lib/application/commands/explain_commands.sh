#!/usr/bin/env bash
# Explain Commands Use Case - Semantic understanding

source "${TERMBRAIN_LIB}/domain/services/semantic_analyzer.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_command_repository.sh"

ExplainCommands::why() {
    local limit="${1:-10}"
    
    echo "🤔 Understanding Your Recent Commands"
    echo "===================================="
    
    # Get recent commands with analysis
    sqlite3 "$TERMBRAIN_DB" -separator '|' "
        SELECT 
            command,
            semantic_type,
            directory,
            exit_code,
            timestamp
        FROM commands
        WHERE is_sensitive = 0
        ORDER BY timestamp DESC
        LIMIT $limit;
    " | while IFS='|' read -r cmd type dir exit_code timestamp; do
        echo ""
        echo "📍 Command: $cmd"
        echo "   Type: $type"
        echo "   Intent: $(SemanticAnalyzer::detect_intent "$cmd")"
        echo "   Directory: ${dir##*/}"
        
        if [[ "$exit_code" != "0" ]]; then
            echo "   ❌ Failed with exit code: $exit_code"
            ExplainCommands::suggest_fix "$cmd" "$exit_code"
        else
            echo "   ✅ Succeeded"
        fi
    done
}

ExplainCommands::suggest_fix() {
    local cmd="$1"
    local exit_code="$2"
    
    # Common error patterns
    case "$cmd" in
        git\ push*)
            if [[ "$exit_code" == "128" ]]; then
                echo "   💡 Try: git push --set-upstream origin <branch>"
            fi
            ;;
        npm\ install*)
            if [[ "$exit_code" != "0" ]]; then
                echo "   💡 Try: rm -rf node_modules package-lock.json && npm install"
            fi
            ;;
        docker*)
            if [[ "$exit_code" == "125" ]]; then
                echo "   💡 Docker daemon might not be running"
            fi
            ;;
    esac
}

ExplainCommands::architecture() {
    echo "🏗️ Project Architecture Analysis"
    echo "==============================="
    
    # Analyze command distribution
    echo ""
    echo "## Command Distribution by Type"
    sqlite3 "$TERMBRAIN_DB" -column -header "
        SELECT 
            semantic_type as 'Command Type',
            COUNT(*) as 'Count',
            printf('%.1f%%', COUNT(*) * 100.0 / (SELECT COUNT(*) FROM commands)) as 'Percentage'
        FROM commands
        WHERE directory LIKE '$PWD%'
        GROUP BY semantic_type
        ORDER BY COUNT(*) DESC
        LIMIT 10;
    "
    
    # Project structure insights
    echo ""
    echo "## Activity Heatmap"
    sqlite3 "$TERMBRAIN_DB" "
        SELECT 
            printf('- %s: %d commands', 
                REPLACE(directory, '$HOME', '~'), 
                COUNT(*))
        FROM commands
        WHERE directory LIKE '$PWD%'
        GROUP BY directory
        ORDER BY COUNT(*) DESC
        LIMIT 10;
    "
}

ExplainCommands::explore() {
    local pattern="${1:-}"
    
    echo "🔍 Exploring Command Patterns"
    echo "============================"
    
    if [[ -z "$pattern" ]]; then
        # Show command categories
        echo ""
        echo "## Command Categories"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT DISTINCT semantic_type
            FROM commands
            ORDER BY semantic_type;
        " | while read -r type; do
            local count=$(sqlite3 "$TERMBRAIN_DB" "SELECT COUNT(*) FROM commands WHERE semantic_type = '$type';")
            echo "- $type ($count commands)"
        done
    else
        # Explore specific pattern
        echo ""
        echo "## Commands matching: $pattern"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT 
                printf('[%s] %s', 
                    strftime('%Y-%m-%d %H:%M', timestamp),
                    command)
            FROM commands
            WHERE command LIKE '%$pattern%'
            AND is_sensitive = 0
            ORDER BY timestamp DESC
            LIMIT 20;
        "
    fi
}

# Convenience functions
tb::why() {
    ExplainCommands::why "$@"
}

tb::arch() {
    ExplainCommands::architecture
}

tb::explore() {
    ExplainCommands::explore "$@"
}