use assert_cmd::Command;
use predicates::prelude::*;
use tempfile::TempDir;

fn setup_test_env() -> TempDir {
    let temp_dir = TempDir::new().unwrap();
    std::env::set_var("TERMBRAIN_HOME", temp_dir.path());
    temp_dir
}

#[test]
fn test_cli_help() {
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.arg("--help")
        .assert()
        .success()
        .stdout(predicate::str::contains("The Terminal That Never Forgets"));
}

#[test]
fn test_cli_version() {
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.arg("--version")
        .assert()
        .success()
        .stdout(predicate::str::contains("termbrain"));
}

#[test]
fn test_status_command() {
    let _temp_dir = setup_test_env();
    
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.arg("status")
        .assert()
        .success()
        .stdout(predicate::str::contains("Termbrain Status"))
        .stdout(predicate::str::contains("Commands recorded:"))
        .stdout(predicate::str::contains("Workflows:"));
}

#[test]
fn test_record_and_search() {
    let _temp_dir = setup_test_env();
    
    // Record a command
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&["record", "git status", "/project", "0", "100"])
        .assert()
        .success();
    
    // Search for it
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&["search", "git"])
        .assert()
        .success()
        .stdout(predicate::str::contains("git status"));
}

#[test]
fn test_workflow_creation() {
    let _temp_dir = setup_test_env();
    
    // Create workflow
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&[
        "workflow", "create",
        "test-workflow",
        "Test workflow description",
        "echo 'step 1'",
        "echo 'step 2'"
    ])
        .assert()
        .success()
        .stdout(predicate::str::contains("Workflow 'test-workflow' created"));
    
    // List workflows
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&["workflow", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("test-workflow"));
}

#[test]
fn test_stats_command() {
    let _temp_dir = setup_test_env();
    
    // Record some commands first
    for i in 0..3 {
        let mut cmd = Command::cargo_bin("tb").unwrap();
        cmd.args(&[
            "record",
            &format!("echo 'test {}'", i),
            "/tmp",
            "0",
            "50"
        ])
        .assert()
        .success();
    }
    
    // Get stats
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&["stats"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Command Statistics"))
        .stdout(predicate::str::contains("Total commands:"));
}

#[test]
fn test_export_json() {
    let temp_dir = setup_test_env();
    let export_path = temp_dir.path().join("export.json");
    
    // Record a command
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&["record", "ls -la", "/home", "0", "25"])
        .assert()
        .success();
    
    // Export to JSON
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&["export", "json", export_path.to_str().unwrap()])
        .assert()
        .success()
        .stdout(predicate::str::contains("Exported to"));
    
    // Verify file exists and contains data
    assert!(export_path.exists());
    let content = std::fs::read_to_string(export_path).unwrap();
    assert!(content.contains("ls -la"));
}

#[test]
fn test_intention_tracking() {
    let _temp_dir = setup_test_env();
    
    // Set intention
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&["intend", "Fix the authentication bug"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Intention set"));
    
    // Mark achieved
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.arg("achieved")
        .assert()
        .success()
        .stdout(predicate::str::contains("Intention marked as achieved"));
}

#[test]
fn test_flow_commands() {
    let _temp_dir = setup_test_env();
    
    // Start flow
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&["flow", "start"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Flow state started"));
    
    // Check status
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&["flow", "status"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Currently in flow"));
    
    // End flow
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&["flow", "end"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Flow Summary"));
}

#[test]
fn test_predictive_mode() {
    let _temp_dir = setup_test_env();
    
    // Enable predictive mode
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&["predictive", "on"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Predictive mode enabled"));
    
    // Disable predictive mode
    let mut cmd = Command::cargo_bin("tb").unwrap();
    cmd.args(&["predictive", "off"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Predictive mode disabled"));
}