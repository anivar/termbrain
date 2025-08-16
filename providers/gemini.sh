#!/usr/bin/env bash
# Gemini AI Provider for Termbrain

tb::gemini_export() {
    local output_file="${1:-.gemini-context.md}"
    local query="${2:-general}"
    
    # Generate context using core tb::ai
    tb::ai "$query" "gemini"
    
    # Add Gemini-specific formatting
    {
        echo "## Gemini Context Instructions"
        echo ""
        echo "This context is optimized for Google Gemini AI."
        echo "Focus areas based on query: $query"
        echo ""
        cat "$output_file"
    } > "${output_file}.tmp"
    
    mv "${output_file}.tmp" "$output_file"
    
    echo "📝 Gemini context saved to $output_file"
}

# Register with Termbrain
tb::provider_register "gemini" "Google Gemini AI context generation"