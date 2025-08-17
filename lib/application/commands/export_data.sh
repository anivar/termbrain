#!/usr/bin/env bash
# Export Data Use Case - Export termbrain data in various formats

source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_command_repository.sh"
source "${TERMBRAIN_LIB}/presentation/formatters/json_formatter.sh"
source "${TERMBRAIN_LIB}/presentation/formatters/markdown_formatter.sh"

ExportData::execute() {
    local format="${1:-json}"
    local output="${2:-}"
    local query="${3:-}"
    
    # Generate default filename if not provided
    if [[ -z "$output" ]]; then
        output="$HOME/termbrain-export-$(date +%Y%m%d-%H%M%S).$format"
    fi
    
    case "$format" in
        json)
            ExportData::to_json "$output" "$query"
            ;;
        csv)
            ExportData::to_csv "$output" "$query"
            ;;
        markdown|md)
            ExportData::to_markdown "$output" "$query"
            ;;
        sql)
            ExportData::to_sql "$output" "$query"
            ;;
        *)
            echo "❌ Unknown format: $format"
            echo "Supported formats: json, csv, markdown, sql"
            return 1
            ;;
    esac
}

ExportData::to_json() {
    local output="$1"
    local query="$2"
    
    echo "📤 Exporting to JSON: $output"
    
    local where_clause=""
    if [[ -n "$query" ]]; then
        where_clause="AND (command LIKE '%$query%' OR semantic_type LIKE '%$query%')"
    fi
    
    sqlite3 "$TERMBRAIN_DB" -json "
        SELECT 
            command,
            directory,
            semantic_type,
            project_type,
            git_branch,
            timestamp,
            exit_code,
            duration_ms,
            session_id
        FROM commands
        WHERE is_sensitive = 0 $where_clause
        ORDER BY timestamp DESC;
    " > "$output"
    
    # Add metadata
    local total=$(wc -l < "$output" | tr -d ' ')
    echo "✅ Exported $total commands to $output"
}

ExportData::to_csv() {
    local output="$1"
    local query="$2"
    
    echo "📤 Exporting to CSV: $output"
    
    local where_clause=""
    if [[ -n "$query" ]]; then
        where_clause="AND (command LIKE '%$query%' OR semantic_type LIKE '%$query%')"
    fi
    
    # Write header
    echo "timestamp,command,directory,semantic_type,project_type,git_branch,exit_code,duration_ms" > "$output"
    
    # Export data
    sqlite3 "$TERMBRAIN_DB" -csv "
        SELECT 
            timestamp,
            command,
            directory,
            semantic_type,
            project_type,
            git_branch,
            exit_code,
            duration_ms
        FROM commands
        WHERE is_sensitive = 0 $where_clause
        ORDER BY timestamp DESC;
    " >> "$output"
    
    local total=$(($(wc -l < "$output" | tr -d ' ') - 1))
    echo "✅ Exported $total commands to $output"
}

ExportData::to_markdown() {
    local output="$1"
    local query="$2"
    
    echo "📤 Exporting to Markdown: $output"
    
    {
        echo "# Termbrain Command History Export"
        echo ""
        echo "Generated: $(date)"
        echo "Query: ${query:-all commands}"
        echo ""
        
        # Summary stats
        local total=$(sqlite3 "$TERMBRAIN_DB" "SELECT COUNT(*) FROM commands WHERE is_sensitive = 0;")
        local date_range=$(sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('%s to %s', 
                MIN(date(timestamp)), 
                MAX(date(timestamp)))
            FROM commands;
        ")
        
        echo "## Summary"
        echo "- Total Commands: $total"
        echo "- Date Range: $date_range"
        echo ""
        
        # Commands by type
        echo "## Commands by Type"
        echo ""
        echo "| Type | Count | Percentage |"
        echo "|------|-------|------------|"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('| %s | %d | %.1f%% |',
                semantic_type,
                COUNT(*),
                COUNT(*) * 100.0 / (SELECT COUNT(*) FROM commands WHERE is_sensitive = 0))
            FROM commands
            WHERE is_sensitive = 0
            GROUP BY semantic_type
            ORDER BY COUNT(*) DESC
            LIMIT 20;
        "
        echo ""
        
        # Recent commands
        echo "## Recent Commands"
        echo ""
        echo "| Time | Command | Type | Exit Code |"
        echo "|------|---------|------|-----------|"
        
        local where_clause=""
        if [[ -n "$query" ]]; then
            where_clause="AND (command LIKE '%$query%' OR semantic_type LIKE '%$query%')"
        fi
        
        sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('| %s | `%s` | %s | %d |',
                datetime(timestamp),
                CASE 
                    WHEN LENGTH(command) > 60 THEN SUBSTR(command, 1, 57) || '...'
                    ELSE command
                END,
                semantic_type,
                COALESCE(exit_code, 0))
            FROM commands
            WHERE is_sensitive = 0 $where_clause
            ORDER BY timestamp DESC
            LIMIT 100;
        "
    } > "$output"
    
    echo "✅ Exported to $output"
}

ExportData::to_sql() {
    local output="$1"
    local query="$2"
    
    echo "📤 Exporting to SQL: $output"
    
    {
        echo "-- Termbrain SQL Export"
        echo "-- Generated: $(date)"
        echo ""
        echo "-- Create commands table"
        sqlite3 "$TERMBRAIN_DB" ".schema commands"
        echo ""
        echo "-- Command data"
        
        local where_clause=""
        if [[ -n "$query" ]]; then
            where_clause="WHERE is_sensitive = 0 AND (command LIKE '%$query%' OR semantic_type LIKE '%$query%')"
        else
            where_clause="WHERE is_sensitive = 0"
        fi
        
        sqlite3 "$TERMBRAIN_DB" ".mode insert commands" "SELECT * FROM commands $where_clause ORDER BY timestamp DESC;"
    } > "$output"
    
    echo "✅ Exported to $output"
}

# Export workflows
ExportData::workflows() {
    local format="${1:-json}"
    local output="${2:-$HOME/termbrain-workflows-$(date +%Y%m%d-%H%M%S).$format}"
    
    echo "📤 Exporting workflows to: $output"
    
    case "$format" in
        json)
            sqlite3 "$TERMBRAIN_DB" -json "
                SELECT 
                    w.name,
                    w.description,
                    json_group_array(
                        json_object('position', wc.position, 'command', wc.command)
                    ) as commands
                FROM workflows w
                LEFT JOIN workflow_commands wc ON w.id = wc.workflow_id
                GROUP BY w.id
                ORDER BY w.name;
            " > "$output"
            ;;
        shell)
            {
                echo "#!/usr/bin/env bash"
                echo "# Termbrain Workflows Export"
                echo "# Generated: $(date)"
                echo ""
                
                sqlite3 "$TERMBRAIN_DB" -separator '|' "
                    SELECT w.name, w.description
                    FROM workflows w
                    ORDER BY w.name;
                " | while IFS='|' read -r name desc; do
                    echo "# Workflow: $name"
                    echo "# Description: $desc"
                    echo "tb_workflow_${name}() {"
                    
                    sqlite3 "$TERMBRAIN_DB" "
                        SELECT command
                        FROM workflow_commands
                        WHERE workflow_id = (SELECT id FROM workflows WHERE name = '$name')
                        ORDER BY position;
                    " | while read -r cmd; do
                        echo "    $cmd"
                    done
                    
                    echo "}"
                    echo ""
                done
            } > "$output"
            chmod +x "$output"
            ;;
    esac
    
    echo "✅ Workflows exported to $output"
}

# Convenience function
tb::export() {
    ExportData::execute "$@"
}