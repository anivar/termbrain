use async_trait::async_trait;
use sqlx::SqlitePool;
use anyhow::Result;
use uuid::Uuid;

use crate::domain::{
    entities::Pattern,
    repositories::PatternRepository,
};

pub struct SqlitePatternRepository {
    pool: SqlitePool,
}

impl SqlitePatternRepository {
    pub async fn new(pool: SqlitePool) -> Result<Self> {
        Ok(Self { pool })
    }
}

#[async_trait]
impl PatternRepository for SqlitePatternRepository {
    async fn save(&self, pattern: &Pattern) -> Result<()> {
        let id = pattern.id.to_string();
        let contexts = serde_json::to_string(&pattern.contexts)?;
        
        sqlx::query!(
            r#"
            INSERT INTO patterns (
                id, pattern, frequency, contexts, suggested_workflow
            ) VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                frequency = excluded.frequency,
                contexts = excluded.contexts,
                suggested_workflow = excluded.suggested_workflow
            "#,
            id,
            pattern.pattern,
            pattern.frequency as i32,
            contexts,
            pattern.suggested_workflow
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    async fn find_patterns(&self, min_frequency: u32) -> Result<Vec<Pattern>> {
        let min_freq = min_frequency as i32;
        
        let records = sqlx::query!(
            r#"
            SELECT * FROM patterns 
            WHERE frequency >= ?
            ORDER BY frequency DESC
            "#,
            min_freq
        )
        .fetch_all(&self.pool)
        .await?;
        
        let mut patterns = Vec::new();
        for r in records {
            let contexts: Vec<String> = serde_json::from_str(&r.contexts)?;
            
            patterns.push(Pattern {
                id: Uuid::parse_str(&r.id)?,
                pattern: r.pattern,
                frequency: r.frequency as u32,
                contexts,
                suggested_workflow: r.suggested_workflow,
            });
        }
        
        Ok(patterns)
    }
    
    async fn update_frequency(&self, pattern_id: &str) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE patterns 
            SET frequency = frequency + 1
            WHERE id = ?
            "#,
            pattern_id
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
}