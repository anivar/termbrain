#!/usr/bin/env bash
# Project Detector Service - Detects project type based on directory contents

# Detect project type based on current directory
ProjectDetector::detect() {
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

# Get project details
ProjectDetector::get_details() {
    local directory="${1:-$PWD}"
    local project_type=$(ProjectDetector::detect "$directory")
    
    case "$project_type" in
        javascript|typescript)
            local name=$(jq -r '.name // "unknown"' "$directory/package.json" 2>/dev/null)
            local version=$(jq -r '.version // "0.0.0"' "$directory/package.json" 2>/dev/null)
            echo "{\"type\":\"$project_type\",\"name\":\"$name\",\"version\":\"$version\"}"
            ;;
        rust)
            local name=$(grep -E '^name' "$directory/Cargo.toml" | cut -d'"' -f2 | head -1)
            local version=$(grep -E '^version' "$directory/Cargo.toml" | cut -d'"' -f2 | head -1)
            echo "{\"type\":\"$project_type\",\"name\":\"$name\",\"version\":\"$version\"}"
            ;;
        python)
            local name=$(basename "$directory")
            echo "{\"type\":\"$project_type\",\"name\":\"$name\"}"
            ;;
        *)
            echo "{\"type\":\"$project_type\",\"name\":\"$(basename "$directory")\"}"
            ;;
    esac
}

# Check if directory is a project root
ProjectDetector::is_project_root() {
    local directory="${1:-$PWD}"
    local project_type=$(ProjectDetector::detect "$directory")
    
    if [[ "$project_type" != "unknown" ]]; then
        echo "true"
        return 0
    else
        echo "false"
        return 1
    fi
}

# Find project root from current directory
ProjectDetector::find_root() {
    local current="$PWD"
    
    while [[ "$current" != "/" ]]; do
        if [[ $(ProjectDetector::is_project_root "$current") == "true" ]]; then
            echo "$current"
            return 0
        fi
        current=$(dirname "$current")
    done
    
    echo "$PWD"  # Default to current directory
}

# Backwards compatibility
tb::detect_project() {
    ProjectDetector::detect "$@"
}