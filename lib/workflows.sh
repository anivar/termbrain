#!/usr/bin/env bash
# Termbrain Workflow Management - Simple and working

# Create workflow
tb::workflow_create() {
    local name="$1"
    local description="$2"
    shift 2
    local commands=("$@")
    
    if [[ -z "$name" ]] || [[ ${#commands[@]} -eq 0 ]]; then
        echo "Usage: tb workflow create <name> <description> <command1> [command2...]"
        return 1
    fi
    
    # Create workflow record first
    sqlite3 "$TERMBRAIN_DB" "INSERT OR REPLACE INTO workflows (name, description, command_sequence, success_rate, times_used) VALUES ('${name//\'/\'\'}', '${description//\'/\'\'}', '', 1.0, 0);"
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to create workflow"
        return 1
    fi
    
    # Get workflow ID
    local wf_id=$(sqlite3 "$TERMBRAIN_DB" "SELECT id FROM workflows WHERE name='${name//\'/\'\'}'")
    
    # Create separate table for commands if not exists
    sqlite3 "$TERMBRAIN_DB" <<EOF
CREATE TABLE IF NOT EXISTS workflow_commands (
    workflow_id INTEGER,
    position INTEGER,
    command TEXT,
    PRIMARY KEY (workflow_id, position),
    FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE
);
EOF
    
    # Delete old commands for this workflow
    sqlite3 "$TERMBRAIN_DB" "DELETE FROM workflow_commands WHERE workflow_id=$wf_id;"
    
    # Insert commands
    local pos=1
    for cmd in "${commands[@]}"; do
        sqlite3 "$TERMBRAIN_DB" "INSERT INTO workflow_commands (workflow_id, position, command) VALUES ($wf_id, $pos, '${cmd//\'/\'\'}');"
        ((pos++))
    done
    
    echo "✅ Workflow '$name' created with ${#commands[@]} commands"
}

# List workflows
tb::workflow_list() {
    echo "📋 Your Workflows"
    echo "================"
    
    sqlite3 "$TERMBRAIN_DB" -column -header <<EOF
SELECT 
    w.name,
    w.description,
    w.times_used as runs,
    COUNT(wc.position) as steps,
    CASE 
        WHEN w.success_rate >= 0.8 THEN '✅'
        WHEN w.success_rate >= 0.5 THEN '⚡'
        ELSE '⚠️'
    END as status
FROM workflows w
LEFT JOIN workflow_commands wc ON w.id = wc.workflow_id
GROUP BY w.id
ORDER BY w.times_used DESC, w.name;
EOF
}

# Show workflow
tb::workflow_show() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo "Usage: tb workflow show <name>"
        return 1
    fi
    
    # Get workflow info
    local info=$(sqlite3 "$TERMBRAIN_DB" -separator '|' "SELECT id, description, times_used, success_rate FROM workflows WHERE name='${name//\'/\'\'}'")
    
    if [[ -z "$info" ]]; then
        echo "❌ Workflow '$name' not found"
        return 1
    fi
    
    IFS='|' read -r wf_id desc uses rate <<< "$info"
    
    echo "📋 $name"
    echo "📝 $desc"
    echo "📊 Used $uses times ($(printf "%.0f%%" $(echo "$rate * 100" | bc))% success)"
    echo ""
    echo "Commands:"
    
    # Get commands
    sqlite3 "$TERMBRAIN_DB" <<EOF
SELECT printf('  [%d] %s', position, command)
FROM workflow_commands
WHERE workflow_id = $wf_id
ORDER BY position;
EOF
}

# Run workflow
tb::workflow_run() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo "Usage: tb workflow run <name>"
        return 1
    fi
    
    # Get workflow ID
    local wf_id=$(sqlite3 "$TERMBRAIN_DB" "SELECT id FROM workflows WHERE name='${name//\'/\'\'}'")
    
    if [[ -z "$wf_id" ]]; then
        echo "❌ Workflow '$name' not found"
        return 1
    fi
    
    echo "🚀 Running: $name"
    echo "=================="
    
    local success=true
    
    # Get and run commands
    while IFS='|' read -r pos cmd; do
        echo ""
        echo "[$pos] $cmd"
        
        if eval "$cmd"; then
            echo "✅ Success"
        else
            echo "❌ Failed"
            success=false
            break
        fi
    done < <(sqlite3 "$TERMBRAIN_DB" -separator '|' "SELECT position, command FROM workflow_commands WHERE workflow_id=$wf_id ORDER BY position")
    
    # Update stats
    if [[ "$success" == true ]]; then
        sqlite3 "$TERMBRAIN_DB" "UPDATE workflows SET times_used = times_used + 1, success_rate = (success_rate * times_used + 1.0) / (times_used + 1) WHERE id = $wf_id;"
        echo ""
        echo "✅ Workflow completed!"
    else
        sqlite3 "$TERMBRAIN_DB" "UPDATE workflows SET times_used = times_used + 1, success_rate = (success_rate * times_used) / (times_used + 1) WHERE id = $wf_id;"
        echo ""
        echo "❌ Workflow failed"
        return 1
    fi
}

# Delete workflow
tb::workflow_delete() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo "Usage: tb workflow delete <name>"
        return 1
    fi
    
    sqlite3 "$TERMBRAIN_DB" "DELETE FROM workflows WHERE name='${name//\'/\'\'}';"
    echo "🗑️  Deleted workflow: $name"
}

# Pattern detection
tb::detect_patterns() {
    echo "🔍 Looking for patterns in your command history..."
    
    sqlite3 "$TERMBRAIN_DB" -column -header <<EOF
SELECT 
    c1.command as "First Command",
    c2.command as "Then",
    COUNT(*) as "Times"
FROM commands c1
JOIN commands c2 ON c2.id = c1.id + 1
WHERE c1.session_id = c2.session_id
AND c1.exit_code = 0 
AND c2.exit_code = 0
GROUP BY c1.command, c2.command
HAVING COUNT(*) >= 3
ORDER BY COUNT(*) DESC
LIMIT 10;
EOF
    
    echo ""
    echo "💡 Create a workflow from any pattern you use often!"
}

# Main command
tb::workflow() {
    local cmd="${1:-list}"
    shift
    
    case "$cmd" in
        create)
            tb::workflow_create "$@"
            ;;
        list|ls)
            tb::workflow_list
            ;;
        show)
            tb::workflow_show "$@"
            ;;
        run)
            tb::workflow_run "$@"
            ;;
        delete|rm)
            tb::workflow_delete "$@"
            ;;
        patterns)
            tb::detect_patterns
            ;;
        help|*)
            echo "📋 Workflow Commands:"
            echo "  tb workflow create <name> <desc> <cmd1> <cmd2>..."
            echo "  tb workflow list                 # Show all workflows"
            echo "  tb workflow show <name>          # Show workflow details"  
            echo "  tb workflow run <name>           # Run a workflow"
            echo "  tb workflow delete <name>        # Delete a workflow"
            echo "  tb workflow patterns             # Find command patterns"
            ;;
    esac
}