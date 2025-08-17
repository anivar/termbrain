#!/usr/bin/env bash
# Save Patterns Use Case

source "${TERMBRAIN_LIB}/domain/services/pattern_detector.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/pattern_repository.sh"

SavePatterns::execute() {
    local pattern_type="${1:-all}"
    
    case "$pattern_type" in
        sequences)
            PatternDetector::detect_sequences | while read -r pattern; do
                PatternRepository::save "$pattern"
            done
            ;;
        time)
            PatternDetector::detect_time_patterns | while read -r pattern; do
                PatternRepository::save "$pattern"
            done
            ;;
        errors)
            PatternDetector::detect_error_patterns | while read -r pattern; do
                PatternRepository::save "$pattern"
            done
            ;;
        project)
            PatternDetector::detect_project_patterns | while read -r pattern; do
                PatternRepository::save "$pattern"
            done
            ;;
        workflows)
            PatternDetector::detect_workflow_patterns | while read -r pattern; do
                PatternRepository::save "$pattern"
            done
            ;;
        all)
            # Detect all pattern types
            SavePatterns::execute sequences
            SavePatterns::execute time
            SavePatterns::execute errors
            SavePatterns::execute project
            SavePatterns::execute workflows
            ;;
    esac
}

# Convenience functions for backwards compatibility
tb::detect_sequence_patterns() {
    SavePatterns::execute sequences
}

tb::detect_time_patterns() {
    SavePatterns::execute time
}

tb::detect_error_patterns() {
    SavePatterns::execute errors
}