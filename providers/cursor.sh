#!/usr/bin/env bash
# Cursor AI provider for Termbrain

tb::cursor_export() {
    local context_file="${1:-.cursorrules}"
    local query="${2:-general}"
    
    {
        echo "# Cursor Rules"
        echo ""
        echo "You are helping with a project that has the following context:"
        echo ""
        
        # Project info
        echo "## Project Type"
        echo "- Type: $(tb::detect_project)"
        echo "- Directory: $PWD"
        echo "- Git Branch: $(git branch --show-current 2>/dev/null || echo 'not a git repo')"
        echo ""
        
        # Include relevant context
        tb::ai "$query" > /tmp/tb-cursor-temp.md
        tail -n +5 /tmp/tb-cursor-temp.md  # Skip header
        rm -f /tmp/tb-cursor-temp.md
        
        echo ""
        echo "## Cursor-Specific Guidelines"
        echo ""
        echo "- Follow the coding patterns shown in recent commands"
        echo "- Use the same libraries and frameworks I've been using"
        echo "- Be consistent with my error handling approaches"
        
    } > "$context_file"
    
    echo "📝 Cursor rules saved to $context_file"
}