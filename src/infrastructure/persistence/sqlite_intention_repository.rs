use async_trait::async_trait;
use sqlx::SqlitePool;
use anyhow::Result;
use uuid::Uuid;

use crate::domain::{
    entities::Intention,
    repositories::IntentionRepository,
};

pub struct SqliteIntentionRepository {
    pool: SqlitePool,
}

impl SqliteIntentionRepository {
    pub async fn new(pool: SqlitePool) -> Result<Self> {
        Ok(Self { pool })
    }
}

#[async_trait]
impl IntentionRepository for SqliteIntentionRepository {
    async fn save(&self, intention: &Intention) -> Result<()> {
        let id = intention.id.to_string();
        let created_at = intention.created_at.timestamp();
        
        sqlx::query!(
            r#"
            INSERT INTO intentions (
                id, session_id, intention, created_at, achieved, commands_count
            ) VALUES (?, ?, ?, ?, ?, ?)
            "#,
            id,
            intention.session_id,
            intention.intention,
            created_at,
            intention.achieved as i32,
            intention.commands_count as i32
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    async fn get_current(&self, session_id: &str) -> Result<Option<Intention>> {
        let record = sqlx::query!(
            r#"
            SELECT * FROM intentions 
            WHERE session_id = ? AND achieved = 0
            ORDER BY created_at DESC
            LIMIT 1
            "#,
            session_id
        )
        .fetch_optional(&self.pool)
        .await?;
        
        match record {
            Some(r) => {
                Ok(Some(Intention {
                    id: Uuid::parse_str(&r.id)?,
                    session_id: r.session_id,
                    intention: r.intention,
                    created_at: chrono::DateTime::from_timestamp(r.created_at, 0).unwrap().into(),
                    achieved: r.achieved != 0,
                    commands_count: r.commands_count as u32,
                }))
            }
            None => Ok(None),
        }
    }
    
    async fn mark_achieved(&self, id: &str) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE intentions 
            SET achieved = 1
            WHERE id = ?
            "#,
            id
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
}