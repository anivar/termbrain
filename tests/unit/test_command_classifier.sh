#!/usr/bin/env bash
# Unit tests for command classifier

source "$(dirname "$0")/../test_helper.sh"
source "$PROJECT_ROOT/lib/domain/services/command_classifier.sh"

test_git_commands() {
    test_start "Git command classification"
    
    local type=$(CommandClassifier::classify "git status")
    assert_equals "$type" "version_control" "git status classified"
    
    type=$(CommandClassifier::classify "git commit -m 'test'")
    assert_equals "$type" "version_control" "git commit classified"
    
    type=$(CommandClassifier::classify "git push origin main")
    assert_equals "$type" "version_control" "git push classified"
    
    test_pass
}

test_file_operations() {
    test_start "File operation classification"
    
    local type=$(CommandClassifier::classify "ls -la")
    assert_equals "$type" "navigation" "ls classified"
    
    type=$(CommandClassifier::classify "rm -rf test.txt")
    assert_equals "$type" "file_operation" "rm classified"
    
    type=$(CommandClassifier::classify "mv old.txt new.txt")
    assert_equals "$type" "file_operation" "mv classified"
    
    type=$(CommandClassifier::classify "cp source.txt dest.txt")
    assert_equals "$type" "file_operation" "cp classified"
    
    test_pass
}

test_package_management() {
    test_start "Package management classification"
    
    local type=$(CommandClassifier::classify "npm install")
    assert_equals "$type" "package_management" "npm install classified"
    
    type=$(CommandClassifier::classify "pip install requests")
    assert_equals "$type" "package_management" "pip install classified"
    
    type=$(CommandClassifier::classify "brew install wget")
    assert_equals "$type" "package_management" "brew install classified"
    
    test_pass
}

test_testing_commands() {
    test_start "Testing command classification"
    
    local type=$(CommandClassifier::classify "npm test")
    assert_equals "$type" "testing" "npm test classified"
    
    type=$(CommandClassifier::classify "pytest tests/")
    assert_equals "$type" "testing" "pytest classified"
    
    type=$(CommandClassifier::classify "./run_tests.sh")
    assert_equals "$type" "testing" "test script classified"
    
    test_pass
}

test_container_commands() {
    test_start "Container command classification"
    
    local type=$(CommandClassifier::classify "docker run ubuntu")
    assert_equals "$type" "container" "docker run classified"
    
    type=$(CommandClassifier::classify "docker-compose up")
    assert_equals "$type" "container" "docker-compose classified"
    
    type=$(CommandClassifier::classify "kubectl get pods")
    assert_equals "$type" "container" "kubectl classified"
    
    test_pass
}

test_sensitive_commands() {
    test_start "Sensitive command detection"
    
    local sens=$(CommandClassifier::is_sensitive "export AWS_SECRET_KEY=xxx")
    assert_equals "$sens" "true" "AWS secret detected"
    
    sens=$(CommandClassifier::is_sensitive "echo 'password123' | sudo -S apt update")
    assert_equals "$sens" "true" "Password in command detected"
    
    sens=$(CommandClassifier::is_sensitive "ls -la")
    assert_equals "$sens" "false" "Normal command not sensitive"
    
    test_pass
}

test_complexity_assessment() {
    test_start "Command complexity assessment"
    
    local comp=$(CommandClassifier::get_complexity "ls")
    assert_equals "$comp" "1" "Simple command complexity"
    
    comp=$(CommandClassifier::get_complexity "ls | grep test")
    assert_equals "$comp" "2" "Piped command complexity"
    
    comp=$(CommandClassifier::get_complexity "find . -name '*.txt' | xargs grep 'pattern' | sort | uniq")
    # This has 3 pipes + xargs = 4 complexity
    assert_equals "$comp" "5" "Complex pipeline complexity"
    
    test_pass
}

# Main test runner
main() {
    test_suite_start "Command Classifier Unit Tests"
    
    test_git_commands
    test_file_operations
    test_package_management
    test_testing_commands
    test_container_commands
    test_sensitive_commands
    test_complexity_assessment
    
    test_suite_end
}

main "$@"