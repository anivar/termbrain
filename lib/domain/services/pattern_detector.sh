#!/usr/bin/env bash
# Pattern Detector Service - Detects patterns in command usage

# Pattern entity representation
Pattern::new() {
    local pattern_type="$1"
    local pattern_data="$2"
    local frequency="$3"
    
    echo "{\"type\":\"$pattern_type\",\"data\":$pattern_data,\"frequency\":$frequency}"
}

# Detect command sequence patterns
PatternDetector::detect_sequences() {
    local min_frequency="${1:-3}"
    local patterns=()
    
    # Find common 2-command sequences
    while IFS='|' read -r cmd1 cmd2 frequency; do
        local pattern_type="${cmd1}->${cmd2}"
        local pattern_data="{\"sequence\":[\"$cmd1\",\"$cmd2\"]}"
        patterns+=("$(Pattern::new "$pattern_type" "$pattern_data" "$frequency")")
    done < <(sqlite3 "$TERMBRAIN_DB" "
        SELECT 
            c1.semantic_type,
            c2.semantic_type,
            COUNT(*)
        FROM commands c1
        JOIN commands c2 ON c2.id = c1.id + 1
        WHERE c1.session_id = c2.session_id
        AND c1.exit_code = 0
        GROUP BY c1.semantic_type, c2.semantic_type
        HAVING COUNT(*) >= $min_frequency;
    ")
    
    printf '%s\n' "${patterns[@]}"
}

# Detect time-based patterns
PatternDetector::detect_time_patterns() {
    local min_frequency="${1:-5}"
    local days_back="${2:-30}"
    local patterns=()
    
    while IFS='|' read -r hour semantic_type frequency; do
        local pattern_type="time:${hour}:${semantic_type}"
        local pattern_data="{\"hour\":\"$hour\",\"type\":\"$semantic_type\"}"
        patterns+=("$(Pattern::new "$pattern_type" "$pattern_data" "$frequency")")
    done < <(sqlite3 "$TERMBRAIN_DB" "
        SELECT 
            strftime('%H', timestamp),
            semantic_type,
            COUNT(*)
        FROM commands
        WHERE timestamp > datetime('now', '-$days_back days')
        GROUP BY strftime('%H', timestamp), semantic_type
        HAVING COUNT(*) >= $min_frequency;
    ")
    
    printf '%s\n' "${patterns[@]}"
}

# Detect error-fix patterns
PatternDetector::detect_error_patterns() {
    local min_frequency="${1:-2}"
    local patterns=()
    
    while IFS='|' read -r error_type solution frequency; do
        local pattern_type="error-fix:${error_type}"
        local pattern_data="{\"error_type\":\"$error_type\",\"solution\":\"$solution\"}"
        patterns+=("$(Pattern::new "$pattern_type" "$pattern_data" "$frequency")")
    done < <(sqlite3 "$TERMBRAIN_DB" "
        SELECT 
            c.semantic_type,
            e.solution_commands,
            COUNT(*)
        FROM errors e
        JOIN commands c ON e.command_id = c.id
        WHERE e.solved = 1
        GROUP BY c.semantic_type, e.solution_commands
        HAVING COUNT(*) >= $min_frequency;
    ")
    
    printf '%s\n' "${patterns[@]}"
}

# Detect project-specific patterns
PatternDetector::detect_project_patterns() {
    local project_type="${1:-$(ProjectDetector::detect)}"
    local min_frequency="${2:-3}"
    local patterns=()
    
    while IFS='|' read -r semantic_type frequency; do
        local pattern_type="project:${project_type}:${semantic_type}"
        local pattern_data="{\"project\":\"$project_type\",\"command_type\":\"$semantic_type\"}"
        patterns+=("$(Pattern::new "$pattern_type" "$pattern_data" "$frequency")")
    done < <(sqlite3 "$TERMBRAIN_DB" "
        SELECT 
            semantic_type,
            COUNT(*)
        FROM commands
        WHERE project_type = '$project_type'
        GROUP BY semantic_type
        HAVING COUNT(*) >= $min_frequency
        ORDER BY COUNT(*) DESC;
    ")
    
    printf '%s\n' "${patterns[@]}"
}

# Detect workflow patterns (3+ command sequences)
PatternDetector::detect_workflow_patterns() {
    local min_frequency="${1:-2}"
    local patterns=()
    
    while IFS='|' read -r step1 step2 step3 frequency; do
        local pattern_type="workflow:${step1}-${step2}-${step3}"
        local pattern_data="{\"steps\":[\"$step1\",\"$step2\",\"$step3\"]}"
        patterns+=("$(Pattern::new "$pattern_type" "$pattern_data" "$frequency")")
    done < <(sqlite3 "$TERMBRAIN_DB" "
        SELECT 
            c1.semantic_type,
            c2.semantic_type,
            c3.semantic_type,
            COUNT(*)
        FROM commands c1
        JOIN commands c2 ON c2.id = c1.id + 1
        JOIN commands c3 ON c3.id = c2.id + 1
        WHERE c1.session_id = c2.session_id 
        AND c2.session_id = c3.session_id
        AND c1.exit_code = 0
        AND c2.exit_code = 0
        GROUP BY c1.semantic_type, c2.semantic_type, c3.semantic_type
        HAVING COUNT(*) >= $min_frequency;
    ")
    
    printf '%s\n' "${patterns[@]}"
}