#!/usr/bin/env bash
# GitHub Copilot provider for Termbrain

tb::copilot_export() {
    local context_dir="${1:-.github}"
    local context_file="$context_dir/copilot-instructions.md"
    local query="${2:-general}"
    
    # Create .github directory if needed
    mkdir -p "$context_dir"
    
    {
        echo "# GitHub Copilot Instructions"
        echo ""
        echo "## Project Context"
        echo ""
        
        # Project info
        echo "- Project Type: $(tb::detect_project)"
        echo "- Primary Language: $(tb::detect_primary_language)"
        echo ""
        
        # Include context
        tb::ai "$query" > /tmp/tb-copilot-temp.md
        
        # Extract key patterns
        echo "## Code Patterns to Follow"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('- %s (used %d times)', 
                   pattern_type, frequency)
            FROM patterns 
            ORDER BY frequency DESC
            LIMIT 5;
        "
        echo ""
        
        cat /tmp/tb-copilot-temp.md | tail -n +5
        rm -f /tmp/tb-copilot-temp.md
        
        echo ""
        echo "## Copilot Guidelines"
        echo ""
        echo "- Suggest completions that match my coding style"
        echo "- Use the same naming conventions I've been using"
        echo "- Follow the error handling patterns shown above"
        
    } > "$context_file"
    
    echo "📝 Copilot instructions saved to $context_file"
}

tb::detect_primary_language() {
    # Simple heuristic based on file extensions
    local lang_count=$(find . -type f -name "*.js" -o -name "*.ts" 2>/dev/null | wc -l)
    [[ $lang_count -gt 0 ]] && echo "JavaScript/TypeScript" && return
    
    lang_count=$(find . -type f -name "*.py" 2>/dev/null | wc -l)
    [[ $lang_count -gt 0 ]] && echo "Python" && return
    
    lang_count=$(find . -type f -name "*.rs" 2>/dev/null | wc -l)
    [[ $lang_count -gt 0 ]] && echo "Rust" && return
    
    echo "Mixed"
}