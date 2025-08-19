#[cfg(test)]
mod tests {
    use super::*;
    use termbrain_core::domain::Command;
    use crate::SqliteStorage;
    
    #[tokio::test]
    async fn test_save_and_find_command() {
        let storage = SqliteStorage::in_memory().await.unwrap();
        storage.run_migrations().await.unwrap();
        
        let repo = SqliteCommandRepository::new(storage.pool().clone());
        
        let command = Command {
            id: uuid::Uuid::new_v4(),
            command: "git status".to_string(),
        };
        
        repo.save(&command).await.unwrap();
        
        let found = repo.find_by_id(&command.id).await.unwrap();
        assert!(found.is_some());
        assert_eq!(found.unwrap().command, "git status");
    }
    
    #[tokio::test]
    async fn test_find_recent() {
        let storage = SqliteStorage::in_memory().await.unwrap();
        storage.run_migrations().await.unwrap();
        
        let repo = SqliteCommandRepository::new(storage.pool().clone());
        
        for i in 0..5 {
            let command = Command {
                id: uuid::Uuid::new_v4(),
                command: format!("command {}", i),
            };
            repo.save(&command).await.unwrap();
        }
        
        let recent = repo.find_recent(3).await.unwrap();
        assert_eq!(recent.len(), 3);
    }
}