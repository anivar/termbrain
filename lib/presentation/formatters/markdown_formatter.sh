#!/usr/bin/env bash
# Markdown Formatter - Formats output as Markdown

MarkdownFormatter::format() {
    local data="$1"
    local title="${2:-Output}"
    
    echo "# $title"
    echo ""
    echo "$data"
}

MarkdownFormatter::format_commands() {
    local json_data="$1"
    
    echo "## Command History"
    echo ""
    echo "| Time | Command | Type | Exit Code |"
    echo "|------|---------|------|-----------|"
    
    echo "$json_data" | jq -r '.[] | 
        "| \(.timestamp) | `\(.command)` | \(.semantic_type) | \(.exit_code // 0) |"'
}

MarkdownFormatter::format_stats() {
    local json_data="$1"
    
    echo "## Terminal Statistics"
    echo ""
    
    echo "$json_data" | jq -r '
        "**Total Commands**: \(.total_commands)",
        "**Time Range**: \(.time_range)",
        "",
        "### Top Command Types",
        "",
        "| Type | Count | Percentage |",
        "|------|-------|------------|",
        (.top_types[] | "| \(.type) | \(.count) | \(.percentage)% |"),
        "",
        "### Activity by Hour",
        "",
        (.hourly_activity | to_entries | .[] | "- **\(.key):00**: \(.value) commands")
    '
}

MarkdownFormatter::format_workflows() {
    local json_data="$1"
    
    echo "## Workflows"
    echo ""
    
    echo "$json_data" | jq -r '.[] | 
        "### \(.name)",
        "",
        "**Description**: \(.description)",
        "",
        "**Commands**:",
        (.commands[] | "```bash", ., "```"),
        ""
    '
}

MarkdownFormatter::format_cognitive_context() {
    local data="$1"
    
    echo "# Cognitive Context"
    echo ""
    echo "Generated: $(date)"
    echo ""
    echo "$data"
}