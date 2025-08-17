#!/usr/bin/env bash
# Semantic analysis utilities for Termbrain

# Extended semantic analysis
tb::analyze_semantic_extended() {
    local cmd="$1"
    
    # Get basic semantic type
    local basic_type=$(tb::analyze_semantic "$cmd")
    
    # Add sub-categorization
    case "$cmd" in
        git\ add*) echo "${basic_type}:staging" ;;
        git\ commit*) echo "${basic_type}:committing" ;;
        git\ push*) echo "${basic_type}:publishing" ;;
        git\ pull*|git\ fetch*) echo "${basic_type}:syncing" ;;
        git\ checkout*|git\ switch*) echo "${basic_type}:branching" ;;
        git\ merge*|git\ rebase*) echo "${basic_type}:integrating" ;;
        
        npm\ install*|yarn\ add*) echo "${basic_type}:installing" ;;
        npm\ run*|yarn\ run*) echo "${basic_type}:running" ;;
        npm\ test*|yarn\ test*) echo "${basic_type}:testing" ;;
        
        docker\ build*) echo "${basic_type}:building" ;;
        docker\ run*) echo "${basic_type}:running" ;;
        docker\ compose*) echo "${basic_type}:orchestrating" ;;
        
        *) echo "$basic_type" ;;
    esac
}

# Detect command intent
tb::detect_intent() {
    local cmd="$1"
    
    case "$cmd" in
        *"--help"*|*"-h"*|man\ *) echo "learning" ;;
        *"--version"*|*"-v"*) echo "checking" ;;
        *install*|*setup*|*init*) echo "setting_up" ;;
        *test*|*spec*) echo "testing" ;;
        *build*|*compile*) echo "building" ;;
        *deploy*|*release*) echo "deploying" ;;
        *debug*|*log*) echo "debugging" ;;
        *clean*|*remove*|*delete*) echo "cleaning" ;;
        *) echo "working" ;;
    esac
}