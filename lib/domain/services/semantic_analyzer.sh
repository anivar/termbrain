#!/usr/bin/env bash
# Semantic Analyzer Service - Analyzes command semantics

# Analyze command semantics
SemanticAnalyzer::analyze() {
    local command="$1"
    
    # Intelligent command categorization
    case "$command" in
        git*) echo "version_control" ;;
        npm*|yarn*|pnpm*|bun*) echo "package_management" ;;
        docker*|kubectl*|podman*) echo "containerization" ;;
        *test*|*spec*|jest*|pytest*|mocha*) echo "testing" ;;
        *lint*|*format*|prettier*|black*|rustfmt*) echo "code_quality" ;;
        make*|cargo\ build*|go\ build*|mvn*) echo "building" ;;
        curl*|wget*|http*|fetch*) echo "http_request" ;;
        ssh*|scp*|rsync*) echo "remote_access" ;;
        vim*|nvim*|emacs*|code*|subl*) echo "editing" ;;
        cd*|ls*|find*|grep*|rg*|fd*) echo "navigation" ;;
        psql*|mysql*|mongo*|redis-cli*) echo "database" ;;
        python*|node*|ruby*|go\ run*|cargo\ run*) echo "code_execution" ;;
        tb*|termbrain*) echo "termbrain" ;;
        *) echo "general" ;;
    esac
}

# Detect project type based on current directory
SemanticAnalyzer::detect_project() {
    local directory="${1:-$PWD}"
    
    # Check for project files in order of specificity
    if [[ -f "$directory/package.json" ]]; then
        if [[ -f "$directory/tsconfig.json" ]]; then 
            echo "typescript"
        else 
            echo "javascript"
        fi
    elif [[ -f "$directory/Cargo.toml" ]]; then 
        echo "rust"
    elif [[ -f "$directory/go.mod" ]]; then 
        echo "go"
    elif [[ -f "$directory/requirements.txt" ]] || [[ -f "$directory/pyproject.toml" ]]; then 
        echo "python"
    elif [[ -f "$directory/Gemfile" ]]; then 
        echo "ruby"
    elif [[ -f "$directory/pom.xml" ]]; then 
        echo "java_maven"
    elif [[ -f "$directory/build.gradle" ]] || [[ -f "$directory/build.gradle.kts" ]]; then 
        echo "java_gradle"
    elif [[ -f "$directory/CMakeLists.txt" ]]; then 
        echo "cpp_cmake"
    elif [[ -f "$directory/Dockerfile" ]] || [[ -f "$directory/docker-compose.yml" ]]; then 
        echo "docker"
    elif [[ -d "$directory/.git" ]]; then 
        echo "git_project"
    else 
        echo "unknown"
    fi
}

# Extract command intent
SemanticAnalyzer::extract_intent() {
    local command="$1"
    
    case "$command" in
        *install*|*add*) echo "install" ;;
        *remove*|*delete*|*uninstall*) echo "remove" ;;
        *build*|*compile*) echo "build" ;;
        *test*|*check*) echo "test" ;;
        *run*|*start*|*exec*) echo "execute" ;;
        *stop*|*kill*) echo "stop" ;;
        *list*|*ls*|*show*) echo "list" ;;
        *search*|*find*|*grep*) echo "search" ;;
        *edit*|*modify*|*change*) echo "edit" ;;
        *deploy*|*push*|*publish*) echo "deploy" ;;
        *) echo "unknown" ;;
    esac
}

# Get command complexity score (1-5)
SemanticAnalyzer::complexity_score() {
    local command="$1"
    
    local score=1
    
    # Add points for pipes
    local pipe_count=$(echo "$command" | grep -o "|" | wc -l)
    score=$((score + pipe_count))
    
    # Add points for redirections
    local redirect_count=$(echo "$command" | grep -oE "[><]+" | wc -l)
    score=$((score + redirect_count))
    
    # Add points for command substitution
    if [[ "$command" =~ \$\( ]]; then
        score=$((score + 1))
    fi
    
    # Add points for loops/conditionals
    if [[ "$command" =~ (for|while|if|case) ]]; then
        score=$((score + 2))
    fi
    
    # Cap at 5
    if [[ $score -gt 5 ]]; then
        score=5
    fi
    
    echo "$score"
}

# Extended semantic analysis with sub-categorization
SemanticAnalyzer::analyze_extended() {
    local cmd="$1"
    
    # Get basic semantic type
    local basic_type=$(SemanticAnalyzer::analyze "$cmd")
    
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
SemanticAnalyzer::detect_intent() {
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