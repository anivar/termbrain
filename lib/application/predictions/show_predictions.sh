#!/usr/bin/env bash
# Show Predictions Use Case

source "${TERMBRAIN_LIB}/domain/services/prediction_engine.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_command_repository.sh"

ShowPredictions::before_command() {
    local command="$1"
    
    # Get context
    local context=$(ShowPredictions::build_context)
    
    # Assess risk
    local risk_assessment=$(PredictionEngine::assess_risk "$command" "$context")
    local risk_level=$(echo "$risk_assessment" | jq -r '.risk_level')
    
    if [[ "$risk_level" != "low" ]]; then
        ShowPredictions::display_risk_warning "$risk_assessment"
    fi
    
    # Check preconditions
    local preconditions=$(PredictionEngine::check_preconditions "$command" "$context")
    local required_checks=$(echo "$preconditions" | jq -r '.required_checks[]')
    
    if [[ -n "$required_checks" ]]; then
        ShowPredictions::check_and_display_preconditions "$command" "$required_checks"
    fi
}

ShowPredictions::on_directory_change() {
    local new_directory="$1"
    
    # Get command history for this directory
    local history=$(CommandRepository::find_by_directory "$new_directory" 10)
    
    # Get suggestions
    local suggestions=$(PredictionEngine::suggest_for_directory "$new_directory" "$history")
    
    # Get commonly used commands
    local common_commands=$(ShowPredictions::get_common_commands "$new_directory")
    
    if [[ -n "$common_commands" ]] || [[ $(echo "$suggestions" | jq '.suggestions | length') -gt 0 ]]; then
        ShowPredictions::display_directory_info "$new_directory" "$common_commands" "$suggestions"
    fi
}

ShowPredictions::suggest_next() {
    local context=$(ShowPredictions::build_context)
    local predictions=$(PredictionEngine::predict_next "$context")
    
    if [[ $(echo "$predictions" | jq '.predictions | length') -gt 0 ]]; then
        ShowPredictions::display_next_suggestions "$predictions"
    fi
}

# Helper functions

ShowPredictions::build_context() {
    # Get recent commands
    local recent_commands=$(sqlite3 "$TERMBRAIN_DB" -json "
        SELECT semantic_type, command, exit_code
        FROM commands
        WHERE session_id = '$TERMBRAIN_SESSION_ID'
        ORDER BY timestamp DESC
        LIMIT 5;
    ")
    
    jq -n \
        --arg dir "$PWD" \
        --argjson commands "${recent_commands:-[]}" \
        '{
            directory: $dir,
            recent_commands: $commands,
            recent_types: ($commands | map(.semantic_type))
        }'
}

ShowPredictions::display_risk_warning() {
    local risk_assessment="$1"
    local level=$(echo "$risk_assessment" | jq -r '.risk_level')
    local warnings=$(echo "$risk_assessment" | jq -r '.warnings[]')
    
    case "$level" in
        critical)
            echo "🚨 CRITICAL RISK DETECTED!"
            ;;
        high)
            echo "⚠️  High risk command detected"
            ;;
        medium)
            echo "⚡ Medium risk command"
            ;;
    esac
    
    echo "$warnings" | while read -r warning; do
        echo "   • $warning"
    done
}

ShowPredictions::check_and_display_preconditions() {
    local command="$1"
    local checks="$2"
    
    local failed_checks=()
    
    echo "$checks" | while read -r check; do
        case "$check" in
            tests_run_recently)
                if ! ShowPredictions::were_tests_run_recently; then
                    echo "⚠️  TB: No tests run recently. Consider running tests before pushing."
                fi
                ;;
            version_bumped)
                if ! ShowPredictions::was_version_bumped; then
                    echo "⚠️  TB: Version not bumped. Did you forget to update package.json?"
                fi
                ;;
        esac
    done
}

ShowPredictions::were_tests_run_recently() {
    local test_count=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT COUNT(*)
        FROM commands
        WHERE directory = '$PWD'
        AND semantic_type = 'testing'
        AND exit_code = 0
        AND timestamp > datetime('now', '-30 minutes');
    ")
    
    [[ "$test_count" -gt 0 ]]
}

ShowPredictions::was_version_bumped() {
    # Check if version files were modified
    git diff HEAD~1 HEAD --name-only 2>/dev/null | grep -qE "(package.json|Cargo.toml|VERSION|version)"
}

ShowPredictions::get_common_commands() {
    local directory="$1"
    
    sqlite3 "$TERMBRAIN_DB" "
        SELECT command, COUNT(*) as frequency
        FROM commands
        WHERE directory = '$directory'
        AND is_sensitive = 0
        AND exit_code = 0
        GROUP BY command
        ORDER BY frequency DESC
        LIMIT 3;
    "
}

ShowPredictions::display_directory_info() {
    local directory="$1"
    local common_commands="$2"
    local suggestions="$3"
    
    echo "🤖 TB: Entering $(basename "$directory")"
    
    if [[ -n "$common_commands" ]]; then
        echo "     Common commands here:"
        echo "$common_commands" | while IFS='|' read -r cmd freq; do
            echo "     • $cmd ($freq times)"
        done
    fi
    
    local suggested=$(echo "$suggestions" | jq -r '.suggestions[]')
    if [[ -n "$suggested" ]]; then
        echo "     Suggestions:"
        echo "$suggested" | while read -r sugg; do
            echo "     → $sugg"
        done
    fi
}