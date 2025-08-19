use termbrain::infrastructure::persistence::{
    SqliteCommandRepository, SqliteWorkflowRepository,
    SqliteIntentionRepository, SqlitePatternRepository
};
use termbrain::domain::entities::{Command, Workflow, Intention, Pattern};
use termbrain::domain::repositories::{CommandRepository, WorkflowRepository, IntentionRepository, PatternRepository};
use tempfile::TempDir;
use uuid::Uuid;
use chrono::Utc;

async fn setup_test_db() -> (TempDir, sqlx::SqlitePool) {
    let temp_dir = TempDir::new().unwrap();
    let db_path = temp_dir.path().join("test.db");
    
    let db_url = format!("sqlite://{}?mode=rwc", db_path.display());
    let pool = sqlx::SqlitePoolOptions::new()
        .max_connections(1)
        .connect(&db_url)
        .await
        .unwrap();
    
    // Run migrations
    termbrain::infrastructure::persistence::run_migrations(&pool).await.unwrap();
    
    (temp_dir, pool)
}

#[tokio::test]
async fn test_command_repository_crud() {
    let temp_dir = TempDir::new().unwrap();
    let db_path = temp_dir.path().join("test.db");
    let repo = SqliteCommandRepository::new(&db_path).await.unwrap();
    
    // Create
    let mut command = Command::new("git status".to_string(), "/project".to_string());
    command.exit_code = 0;
    command.duration_ms = 150;
    
    repo.save(&command).await.unwrap();
    
    // Read
    let found = repo.find_by_id(&command.id.to_string()).await.unwrap();
    assert!(found.is_some());
    let found_cmd = found.unwrap();
    assert_eq!(found_cmd.command, "git status");
    assert_eq!(found_cmd.directory, "/project");
    
    // Search
    let search_results = repo.search("git", 10).await.unwrap();
    assert_eq!(search_results.len(), 1);
    
    // Count
    let count = repo.count().await.unwrap();
    assert_eq!(count, 1);
}

#[tokio::test]
async fn test_command_repository_get_recent() {
    let temp_dir = TempDir::new().unwrap();
    let db_path = temp_dir.path().join("test.db");
    let repo = SqliteCommandRepository::new(&db_path).await.unwrap();
    
    // Insert multiple commands
    for i in 0..5 {
        let mut cmd = Command::new(format!("command {}", i), "/test".to_string());
        tokio::time::sleep(tokio::time::Duration::from_millis(10)).await; // Ensure different timestamps
        repo.save(&cmd).await.unwrap();
    }
    
    // Get recent
    let recent = repo.get_recent(3).await.unwrap();
    assert_eq!(recent.len(), 3);
    
    // Should be ordered by timestamp descending
    assert!(recent[0].command.contains("4")); // Most recent
}

#[tokio::test]
async fn test_workflow_repository_crud() {
    let temp_dir = TempDir::new().unwrap();
    let db_path = temp_dir.path().join("test.db");
    let repo = SqliteWorkflowRepository::new(&db_path).await.unwrap();
    
    // Create
    let workflow = Workflow {
        id: Uuid::new_v4(),
        name: "deploy".to_string(),
        description: "Deploy to production".to_string(),
        commands: vec![
            "npm test".to_string(),
            "npm build".to_string(),
            "npm deploy".to_string(),
        ],
        created_at: Utc::now(),
        updated_at: Utc::now(),
        execution_count: 0,
    };
    
    repo.save(&workflow).await.unwrap();
    
    // Read by name
    let found = repo.get_by_name("deploy").await.unwrap();
    assert!(found.is_some());
    let found_wf = found.unwrap();
    assert_eq!(found_wf.name, "deploy");
    assert_eq!(found_wf.commands.len(), 3);
    
    // List
    let all = repo.list().await.unwrap();
    assert_eq!(all.len(), 1);
    
    // Update
    let mut updated_wf = found_wf;
    updated_wf.execution_count = 5;
    repo.save(&updated_wf).await.unwrap();
    
    let updated = repo.get_by_name("deploy").await.unwrap().unwrap();
    assert_eq!(updated.execution_count, 5);
    
    // Delete
    repo.delete("deploy").await.unwrap();
    let deleted = repo.get_by_name("deploy").await.unwrap();
    assert!(deleted.is_none());
}

#[tokio::test]
async fn test_intention_repository() {
    let (_temp_dir, pool) = setup_test_db().await;
    let repo = SqliteIntentionRepository::new(pool).await.unwrap();
    
    // Create
    let intention = Intention {
        id: Uuid::new_v4(),
        session_id: "test_session".to_string(),
        intention: "Fix authentication bug".to_string(),
        created_at: Utc::now(),
        achieved: false,
        commands_count: 0,
    };
    
    repo.save(&intention).await.unwrap();
    
    // Get current
    let current = repo.get_current("test_session").await.unwrap();
    assert!(current.is_some());
    let current_intention = current.unwrap();
    assert_eq!(current_intention.intention, "Fix authentication bug");
    assert!(!current_intention.achieved);
    
    // Mark achieved
    repo.mark_achieved(&intention.id.to_string()).await.unwrap();
    
    // Should no longer be current (achieved intentions are not current)
    let after_achieved = repo.get_current("test_session").await.unwrap();
    assert!(after_achieved.is_none());
}

#[tokio::test]
async fn test_pattern_repository() {
    let (_temp_dir, pool) = setup_test_db().await;
    let repo = SqlitePatternRepository::new(pool).await.unwrap();
    
    // Create patterns with different frequencies
    for i in 1..=5 {
        let pattern = Pattern {
            id: Uuid::new_v4(),
            pattern: format!("pattern {}", i),
            frequency: i * 2, // 2, 4, 6, 8, 10
            contexts: vec!["/project".to_string()],
            suggested_workflow: Some(format!("workflow {}", i)),
        };
        repo.save(&pattern).await.unwrap();
    }
    
    // Find patterns with minimum frequency
    let min_freq_5 = repo.find_patterns(5).await.unwrap();
    assert_eq!(min_freq_5.len(), 3); // patterns with frequency 6, 8, 10
    
    let min_freq_8 = repo.find_patterns(8).await.unwrap();
    assert_eq!(min_freq_8.len(), 2); // patterns with frequency 8, 10
    
    // Update frequency
    let pattern_to_update = Pattern {
        id: Uuid::new_v4(),
        pattern: "updatable".to_string(),
        frequency: 1,
        contexts: vec![],
        suggested_workflow: None,
    };
    repo.save(&pattern_to_update).await.unwrap();
    
    repo.update_frequency(&pattern_to_update.id.to_string()).await.unwrap();
    
    // Verify frequency was incremented
    let all_patterns = repo.find_patterns(1).await.unwrap();
    let updated = all_patterns.iter()
        .find(|p| p.id == pattern_to_update.id)
        .expect("Pattern should exist");
    assert_eq!(updated.frequency, 2);
}

#[tokio::test]
async fn test_sensitive_commands_not_searchable() {
    let temp_dir = TempDir::new().unwrap();
    let db_path = temp_dir.path().join("test.db");
    let repo = SqliteCommandRepository::new(&db_path).await.unwrap();
    
    // Save sensitive command
    let mut sensitive = Command::new("export PASSWORD=secret123".to_string(), "/tmp".to_string());
    assert!(sensitive.is_sensitive); // Should be auto-detected
    repo.save(&sensitive).await.unwrap();
    
    // Save normal command
    let normal = Command::new("ls -la".to_string(), "/tmp".to_string());
    repo.save(&normal).await.unwrap();
    
    // Search should not return sensitive commands
    let results = repo.search("export", 10).await.unwrap();
    assert_eq!(results.len(), 0);
    
    let all_results = repo.get_recent(10).await.unwrap();
    assert_eq!(all_results.len(), 1);
    assert_eq!(all_results[0].command, "ls -la");
}