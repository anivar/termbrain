#!/usr/bin/env bash
# Pattern detection utilities for Termbrain

# Detect command sequences
tb::detect_sequence_patterns() {
    # Find common 2-command sequences
    sqlite3 "$TERMBRAIN_DB" "
        WITH Sequences AS (
            SELECT 
                c1.semantic_type as cmd1,
                c2.semantic_type as cmd2,
                COUNT(*) as frequency
            FROM commands c1
            JOIN commands c2 ON c2.id = c1.id + 1
            WHERE c1.session_id = c2.session_id
            AND c1.exit_code = 0
            GROUP BY cmd1, cmd2
            HAVING frequency >= 3
        )
        INSERT OR REPLACE INTO patterns (pattern_type, pattern_data, frequency)
        SELECT 
            cmd1 || '->' || cmd2,
            json_object('sequence', json_array(cmd1, cmd2)),
            frequency
        FROM Sequences;
    "
}

# Detect time-based patterns
tb::detect_time_patterns() {
    # Find commands frequently run at certain times
    sqlite3 "$TERMBRAIN_DB" "
        WITH TimePatterns AS (
            SELECT 
                strftime('%H', timestamp) as hour,
                semantic_type,
                COUNT(*) as frequency
            FROM commands
            WHERE timestamp > datetime('now', '-30 days')
            GROUP BY hour, semantic_type
            HAVING frequency >= 5
        )
        INSERT OR REPLACE INTO patterns (pattern_type, pattern_data, frequency)
        SELECT 
            'time:' || hour || ':' || semantic_type,
            json_object('hour', hour, 'type', semantic_type),
            frequency
        FROM TimePatterns;
    "
}

# Detect error-fix patterns
tb::detect_error_patterns() {
    sqlite3 "$TERMBRAIN_DB" "
        WITH ErrorPatterns AS (
            SELECT 
                c.semantic_type as error_type,
                e.solution_commands,
                COUNT(*) as frequency
            FROM errors e
            JOIN commands c ON e.command_id = c.id
            WHERE e.solved = 1
            GROUP BY error_type, solution_commands
            HAVING frequency >= 2
        )
        INSERT OR REPLACE INTO patterns (pattern_type, pattern_data, frequency)
        SELECT 
            'error-fix:' || error_type,
            json_object('error_type', error_type, 'solution', solution_commands),
            frequency
        FROM ErrorPatterns;
    "
}