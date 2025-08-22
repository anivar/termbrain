//! Local text embeddings for semantic search
//! 
//! Uses a simple approach for now - can be upgraded to use local models later

use anyhow::Result;
use std::collections::HashMap;

/// Embedding dimension (must match schema)
pub const EMBEDDING_DIM: usize = 384;

/// Simple text embedding generator
/// For now, uses a basic approach. Can be replaced with:
/// - candle for local transformer models
/// - ONNX runtime for optimized models
/// - Remote API calls (with user consent)
pub struct EmbeddingGenerator {
    // Vocabulary for simple word embeddings
    vocab: HashMap<String, usize>,
}

impl EmbeddingGenerator {
    pub fn new() -> Self {
        // Build a simple vocabulary from common command words
        let mut vocab = HashMap::new();
        let common_words = [
            "git", "commit", "push", "pull", "clone", "checkout", "branch", "merge",
            "status", "add", "diff", "log", "reset", "rebase", "fetch", "remote",
            "version", "control", "vcs", "repository", "repo",
            "npm", "install", "run", "build", "test", "start", "dev",
            "cargo", "rustc", "python", "pip", "node", "yarn",
            "docker", "compose", "up", "down", "exec", "logs",
            "cd", "ls", "cat", "grep", "find", "sed", "awk",
            "curl", "wget", "ssh", "scp", "rsync",
            "make", "cmake", "gcc", "clang",
            "vim", "emacs", "nano", "code",
            "systemctl", "service", "sudo", "chmod", "chown",
            "create", "delete", "update", "list", "show", "get", "set",
            "file", "directory", "folder", "path", "home", "root",
            "user", "group", "permission", "owner",
            "process", "kill", "stop", "restart", "status",
            "network", "port", "ip", "dns", "http", "https",
            "database", "table", "query", "insert", "select", "update", "delete",
            "error", "warning", "info", "debug", "log", "trace",
            "config", "configuration", "setting", "option", "flag",
            "help", "version", "usage", "manual", "documentation",
        ];
        
        for (idx, word) in common_words.iter().enumerate() {
            vocab.insert(word.to_string(), idx);
        }
        
        Self { vocab }
    }
    
    /// Generate embedding for a command
    /// This is a simplified implementation - in production, use a proper model
    pub fn embed(&self, text: &str) -> Result<Vec<f32>> {
        let mut embedding = vec![0.0f32; EMBEDDING_DIM];
        
        // Tokenize and normalize
        let normalized = text.to_lowercase();
        let tokens: Vec<&str> = normalized
            .split_whitespace()
            .collect();
        
        if tokens.is_empty() {
            return Ok(embedding);
        }
        
        // Simple bag-of-words with TF-IDF-like weighting
        let mut word_counts = HashMap::new();
        for token in &tokens {
            *word_counts.entry(token.to_string()).or_insert(0) += 1;
        }
        
        // Fill embedding based on vocabulary
        for (word, count) in word_counts {
            if let Some(&idx) = self.vocab.get(&word) {
                if idx < EMBEDDING_DIM {
                    // TF-IDF-like score
                    let tf = count as f32 / tokens.len() as f32;
                    let idf = (1.0 + (100.0 / (1.0 + count as f32))).ln();
                    embedding[idx] = tf * idf;
                }
            } else {
                // Hash unknown words to indices
                let hash = word.bytes().fold(0u32, |acc, b| {
                    acc.wrapping_mul(31).wrapping_add(b as u32)
                });
                let idx = (hash as usize) % EMBEDDING_DIM;
                embedding[idx] += 0.1; // Small weight for unknown words
            }
        }
        
        // Add positional and contextual features
        self.add_contextual_features(&mut embedding, text, &tokens);
        
        // Normalize to unit vector
        let norm = embedding.iter().map(|x| x * x).sum::<f32>().sqrt();
        if norm > 0.0 {
            for x in &mut embedding {
                *x /= norm;
            }
        }
        
        Ok(embedding)
    }
    
    /// Add contextual features to embedding
    fn add_contextual_features(&self, embedding: &mut [f32], text: &str, tokens: &[&str]) {
        // Reserve last 50 dimensions for special features
        let feature_start = EMBEDDING_DIM - 50;
        
        // Command type indicators
        if tokens.first() == Some(&"git") {
            embedding[feature_start] = 1.0;
        } else if tokens.first() == Some(&"npm") || tokens.first() == Some(&"yarn") {
            embedding[feature_start + 1] = 1.0;
        } else if tokens.first() == Some(&"docker") {
            embedding[feature_start + 2] = 1.0;
        }
        
        // Length features
        embedding[feature_start + 10] = (tokens.len() as f32).ln();
        embedding[feature_start + 11] = (text.len() as f32).ln();
        
        // Special patterns
        if text.contains("--help") || text.contains("-h") {
            embedding[feature_start + 20] = 1.0;
        }
        if text.contains("error") || text.contains("fail") {
            embedding[feature_start + 21] = 1.0;
        }
        if text.contains("sudo") {
            embedding[feature_start + 22] = 1.0;
        }
        
        // Pipe/redirect detection
        if text.contains("|") {
            embedding[feature_start + 30] = 1.0;
        }
        if text.contains(">") || text.contains("<") {
            embedding[feature_start + 31] = 1.0;
        }
    }
    
    /// Calculate cosine similarity between two embeddings
    pub fn similarity(a: &[f32], b: &[f32]) -> f32 {
        if a.len() != b.len() {
            return 0.0;
        }
        
        let dot_product: f32 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
        
        // Since we normalize embeddings, this is just the dot product
        dot_product
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_embedding_generation() {
        let generator = EmbeddingGenerator::new();
        
        let embedding1 = generator.embed("git commit -m 'test'").unwrap();
        assert_eq!(embedding1.len(), EMBEDDING_DIM);
        
        // Check normalization
        let norm: f32 = embedding1.iter().map(|x| x * x).sum::<f32>().sqrt();
        assert!((norm - 1.0).abs() < 0.001);
    }
    
    #[test]
    fn test_similarity() {
        let generator = EmbeddingGenerator::new();
        
        let e1 = generator.embed("git commit").unwrap();
        let e2 = generator.embed("git commit -m 'message'").unwrap();
        let e3 = generator.embed("npm install").unwrap();
        
        let sim_12 = EmbeddingGenerator::similarity(&e1, &e2);
        let sim_13 = EmbeddingGenerator::similarity(&e1, &e3);
        
        // Similar commands should have higher similarity
        assert!(sim_12 > sim_13);
    }
}