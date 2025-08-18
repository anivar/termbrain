use async_trait::async_trait;
use sqlx::SqlitePool;
use anyhow::Result;
use std::path::Path;
use uuid::Uuid;

use crate::domain::{
    entities::Workflow,
    repositories::WorkflowRepository,
};

pub struct SqliteWorkflowRepository {
    pool: SqlitePool,
}

impl SqliteWorkflowRepository {
    pub async fn new(db_path: &Path) -> Result<Self> {
        // Reuse the same pool as command repository
        let db_url = format!("sqlite://{}?mode=rwc", db_path.display());
        
        let pool = sqlx::SqlitePoolOptions::new()
            .max_connections(5)
            .connect(&db_url)
            .await?;
        
        Ok(Self { pool })
    }
}

#[async_trait]
impl WorkflowRepository for SqliteWorkflowRepository {
    async fn save(&self, workflow: &Workflow) -> Result<()> {
        let id = workflow.id.to_string();
        let created_at = workflow.created_at.timestamp();
        let updated_at = workflow.updated_at.timestamp();
        
        // Start transaction
        let mut tx = self.pool.begin().await?;
        
        // Insert workflow
        sqlx::query!(
            r#"
            INSERT INTO workflows (id, name, description, created_at, updated_at, execution_count)
            VALUES (?, ?, ?, ?, ?, ?)
            "#,
            id,
            workflow.name,
            workflow.description,
            created_at,
            updated_at,
            workflow.execution_count
        )
        .execute(&mut *tx)
        .await?;
        
        // Insert workflow commands
        for (position, cmd) in workflow.commands.iter().enumerate() {
            sqlx::query!(
                r#"
                INSERT INTO workflow_commands (workflow_id, position, command)
                VALUES (?, ?, ?)
                "#,
                id,
                position as i64,
                cmd
            )
            .execute(&mut *tx)
            .await?;
        }
        
        tx.commit().await?;
        Ok(())
    }
    
    async fn find_by_name(&self, name: &str) -> Result<Option<Workflow>> {
        let workflow_record = sqlx::query!(
            r#"
            SELECT * FROM workflows WHERE name = ?
            "#,
            name
        )
        .fetch_optional(&self.pool)
        .await?;
        
        match workflow_record {
            Some(record) => {
                // Get commands
                let commands = sqlx::query!(
                    r#"
                    SELECT position, command FROM workflow_commands
                    WHERE workflow_id = ?
                    ORDER BY position
                    "#,
                    record.id
                )
                .fetch_all(&self.pool)
                .await?;
                
                Ok(Some(Workflow {
                    id: Uuid::parse_str(&record.id)?,
                    name: record.name,
                    description: record.description,
                    commands: commands.into_iter()
                        .map(|c| c.command)
                        .collect(),
                    created_at: chrono::DateTime::from_timestamp(record.created_at, 0).unwrap().into(),
                    updated_at: chrono::DateTime::from_timestamp(record.updated_at, 0).unwrap().into(),
                    execution_count: record.execution_count as u32,
                }))
            }
            None => Ok(None),
        }
    }
    
    async fn list(&self) -> Result<Vec<Workflow>> {
        let workflows = sqlx::query!(
            r#"
            SELECT * FROM workflows ORDER BY name
            "#
        )
        .fetch_all(&self.pool)
        .await?;
        
        let mut result = Vec::new();
        
        for record in workflows {
            // Get commands for each workflow
            let commands = sqlx::query!(
                r#"
                SELECT position, command FROM workflow_commands
                WHERE workflow_id = ?
                ORDER BY position
                "#,
                record.id
            )
            .fetch_all(&self.pool)
            .await?;
            
            result.push(Workflow {
                id: Uuid::parse_str(&record.id)?,
                name: record.name,
                description: record.description,
                commands: commands.into_iter()
                    .map(|c| c.command)
                    })
                    .collect(),
                created_at: chrono::DateTime::from_timestamp(record.created_at, 0).unwrap().into(),
                updated_at: chrono::DateTime::from_timestamp(record.updated_at, 0).unwrap().into(),
                execution_count: record.execution_count as u32,
            });
        }
        
        Ok(result)
    }
    
    async fn update(&self, workflow: &Workflow) -> Result<()> {
        let id = workflow.id.to_string();
        let updated_at = workflow.updated_at.timestamp();
        
        sqlx::query!(
            r#"
            UPDATE workflows 
            SET description = ?, updated_at = ?, execution_count = ?
            WHERE id = ?
            "#,
            workflow.description,
            updated_at,
            workflow.execution_count,
            id
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    async fn delete(&self, name: &str) -> Result<()> {
        // Cascading delete will remove workflow_commands
        sqlx::query!(
            r#"
            DELETE FROM workflows WHERE name = ?
            "#,
            name
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    async fn get_by_name(&self, name: &str) -> Result<Option<Workflow>> {
        // Just delegate to find_by_name
        self.find_by_name(name).await
    }
}