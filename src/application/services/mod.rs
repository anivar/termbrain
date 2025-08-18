use crate::domain::entities::ProjectType;
use anyhow::Result;
use std::path::Path;
use tokio::fs;

pub struct GitService;

impl GitService {
    pub fn new() -> Self {
        Self
    }
    
    pub async fn current_branch(&self, directory: &str) -> Result<String> {
        let git_head = Path::new(directory).join(".git/HEAD");
        
        if git_head.exists() {
            let content = fs::read_to_string(git_head).await?;
            if let Some(branch) = content.strip_prefix("ref: refs/heads/") {
                return Ok(branch.trim().to_string());
            }
        }
        
        Ok("main".to_string())
    }
}

pub struct ProjectDetector;

impl ProjectDetector {
    pub fn new() -> Self {
        Self
    }
    
    pub async fn detect(&self, directory: &str) -> Result<ProjectType> {
        let dir = Path::new(directory);
        
        // Check for language-specific files
        if dir.join("Cargo.toml").exists() {
            Ok(ProjectType::Rust)
        } else if dir.join("package.json").exists() {
            Ok(ProjectType::JavaScript)
        } else if dir.join("requirements.txt").exists() || dir.join("setup.py").exists() {
            Ok(ProjectType::Python)
        } else if dir.join("go.mod").exists() {
            Ok(ProjectType::Go)
        } else if dir.join("Gemfile").exists() {
            Ok(ProjectType::Ruby)
        } else if dir.join("pom.xml").exists() || dir.join("build.gradle").exists() {
            Ok(ProjectType::Java)
        } else if dir.join("*.csproj").exists() {
            Ok(ProjectType::CSharp)
        } else if dir.join("CMakeLists.txt").exists() {
            Ok(ProjectType::Cpp)
        } else {
            Ok(ProjectType::Unknown)
        }
    }
}

pub struct PatternDetector;

impl PatternDetector {
    pub fn new() -> Self {
        Self
    }
    
    pub async fn detect_patterns(&self, commands: &[String]) -> Vec<Vec<String>> {
        // Simple pattern detection - find sequences of commands that repeat
        let mut patterns = Vec::new();
        
        for window_size in 2..=5 {
            for i in 0..commands.len().saturating_sub(window_size) {
                let pattern = &commands[i..i + window_size];
                
                // Check if this pattern appears elsewhere
                for j in (i + window_size)..commands.len().saturating_sub(window_size) {
                    let candidate = &commands[j..j + window_size];
                    
                    if pattern == candidate {
                        patterns.push(pattern.to_vec());
                    }
                }
            }
        }
        
        // Deduplicate patterns
        patterns.sort();
        patterns.dedup();
        
        patterns
    }
}