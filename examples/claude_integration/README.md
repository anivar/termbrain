# Claude Integration Example

This example demonstrates how to integrate TermBrain with Anthropic's Claude API for intelligent command analysis, suggestions, and learning.

## Features

- **Command Analysis**: Get detailed explanations of complex commands
- **Suggestions**: Receive AI-powered command suggestions based on your history
- **Error Diagnosis**: Analyze failed commands and get fixes
- **Learning Mode**: Learn new commands and best practices
- **Pattern Recognition**: Discover workflow patterns in your command history

## Setup

### 1. Install Dependencies

```bash
cd examples/claude_integration
cargo build
```

### 2. Configure API Access

Create a `.env` file:

```bash
# Anthropic Claude API
ANTHROPIC_API_KEY=your_claude_api_key_here

# Optional: Configure model preferences
CLAUDE_MODEL=claude-3-5-sonnet-20241022
CLAUDE_MAX_TOKENS=4096
CLAUDE_TEMPERATURE=0.1

# TermBrain Integration
TERMBRAIN_DATA_DIR=/path/to/your/termbrain/data
```

### 3. Set Up TermBrain

```bash
# Ensure TermBrain is installed and configured
tb status

# Enable shell integration for data collection
tb install --shell $(basename $SHELL)
```

## Usage Examples

### Basic Command Analysis

```bash
# Analyze a specific command
./claude-analyzer analyze "find . -name '*.rs' -exec grep -l 'async fn' {} \;"

# Output:
# 🔍 Command Analysis
# 
# This command searches for Rust files and finds those containing async functions:
# 
# 1. `find . -name '*.rs'` - Recursively searches for files ending in .rs
# 2. `-exec grep -l 'async fn' {} \;` - For each file, runs grep to find "async fn"
#    - `-l` flag shows only filenames with matches
#    - `{}` is replaced with each found filename
#    - `\;` terminates the exec command
# 
# 💡 Suggestions:
# - Use `-type f` to ensure only files are searched
# - Consider `ripgrep` for faster searching: `rg -l "async fn" --type rust`
# - Add `--exclude-dir target` to skip build directories
```

### Command Suggestions Based on History

```bash
# Get suggestions for git workflow
./claude-analyzer suggest --context "git workflow"

# Output:
# 🤖 AI Suggestions based on your history
# 
# I notice you frequently use these git commands:
# - git status (47 times)
# - git add . (23 times)  
# - git commit -m (31 times)
# 
# 💡 Workflow Optimization:
# 1. Create an alias: `alias gac="git add . && git commit -m"`
# 2. Use git hooks for automated checks
# 3. Consider `git commit -am "message"` for tracked files
# 
# 🔄 Suggested next commands:
# - git push origin main
# - git pull --rebase origin main
# - git log --oneline -10
```

### Error Diagnosis and Fixes

```bash
# Analyze a failed command from history
./claude-analyzer diagnose --command "docker run -p 8080:80 nginx" --exit-code 125

# Output:
# ❌ Error Diagnosis
# 
# Exit code 125 typically indicates Docker daemon issues or port conflicts.
# 
# 🔍 Likely causes:
# 1. Port 8080 already in use
# 2. Docker daemon not running
# 3. Insufficient permissions
# 
# 🛠️ Suggested fixes:
# 1. Check port usage: `lsof -i :8080` or `netstat -tulpn | grep 8080`
# 2. Start Docker: `sudo systemctl start docker`
# 3. Use different port: `docker run -p 8081:80 nginx`
# 4. Stop conflicting service: `sudo kill $(lsof -t -i:8080)`
```

### Learning Mode

```bash
# Learn about a command category
./claude-analyzer learn --topic "kubernetes"

# Output:
# 📚 Learning: Kubernetes Commands
# 
# Based on your command history, here are essential kubectl commands:
# 
# 🏗️ Basic Operations:
# kubectl get pods                    # List running pods
# kubectl describe pod <name>         # Detailed pod information
# kubectl logs <pod-name>            # View pod logs
# kubectl exec -it <pod> -- /bin/bash # Access pod shell
# 
# 🔄 Deployments:
# kubectl apply -f deployment.yaml    # Apply configuration
# kubectl scale deployment <name> --replicas=3
# kubectl rollout status deployment/<name>
# 
# 🧪 Try these commands in your environment and I'll help you understand the output!
```

### Pattern Recognition

```bash
# Discover patterns in command usage
./claude-analyzer patterns

# Output:
# 🔄 Discovered Patterns in Your Workflow
# 
# **Development Cycle** (Confidence: 92%)
# 1. git status → git add . → git commit -m → git push
# 2. Occurs 15 times in last week
# 3. Average cycle time: 3.2 minutes
# 
# **Testing Pattern** (Confidence: 87%)
# 1. cargo build → cargo test → cargo run
# 2. Often followed by git commands when tests pass
# 3. Suggestion: Create alias `alias ctr="cargo test && cargo run"`
# 
# **Directory Navigation** (Confidence: 78%)
# 1. cd projects/termbrain → code . → cargo watch
# 2. Suggestion: Use direnv for automatic environment setup
```

## Advanced Integration

### Custom Analysis Workflows

```rust
// examples/claude_integration/src/custom_analyzer.rs
use termbrain_core::Command;
use claude_api::ClaudeClient;

pub struct CustomAnalyzer {
    claude: ClaudeClient,
    history: Vec<Command>,
}

impl CustomAnalyzer {
    pub async fn analyze_productivity(&self) -> Result<ProductivityReport> {
        let prompt = format!(
            "Analyze this command history for productivity insights:\n{}",
            self.format_history_for_analysis()
        );
        
        let response = self.claude.send_message(&prompt).await?;
        Ok(ProductivityReport::from_claude_response(response))
    }
    
    pub async fn suggest_optimizations(&self) -> Result<Vec<Optimization>> {
        // Implementation for optimization suggestions
    }
}
```

### Webhook Integration

```rust
// examples/claude_integration/src/webhook_handler.rs
use axum::{extract::Json, http::StatusCode, response::Json as ResponseJson, routing::post, Router};

pub async fn command_analysis_webhook(
    Json(payload): Json<CommandExecutedEvent>,
) -> Result<ResponseJson<AnalysisResponse>, StatusCode> {
    let analyzer = ClaudeAnalyzer::new().await?;
    
    // Only analyze interesting commands (not basic ls, cd, etc.)
    if is_analysis_worthy(&payload.command) {
        let analysis = analyzer.analyze_command(&payload.command).await?;
        
        // Store insights for later retrieval
        store_analysis(&payload.command, &analysis).await?;
        
        // Optionally send real-time suggestions
        if analysis.confidence > 0.8 {
            send_suggestion_notification(&analysis.suggestion).await?;
        }
    }
    
    Ok(ResponseJson(AnalysisResponse { 
        status: "processed".to_string() 
    }))
}
```

## Configuration Options

### Model Selection

```toml
# claude_config.toml
[claude]
model = "claude-3-5-sonnet-20241022"  # Most capable for code analysis
# model = "claude-3-haiku-20240307"   # Faster for simple queries
max_tokens = 4096
temperature = 0.1  # Lower for more focused, deterministic responses

[analysis]
# Commands to always analyze
always_analyze = ["docker", "kubectl", "aws", "terraform"]

# Commands to ignore
ignore_patterns = ["ls", "cd", "pwd", "clear", "exit"]

# Minimum execution time to trigger analysis (seconds)
min_execution_time = 2.0

# Enable real-time suggestions
real_time_suggestions = true

[privacy]
# Sanitize commands before sending to API
sanitize_paths = true
sanitize_secrets = true
exclude_env_vars = ["PASSWORD", "SECRET", "TOKEN", "KEY"]
```

### Privacy and Security

```rust
// examples/claude_integration/src/privacy.rs
pub struct CommandSanitizer {
    secret_patterns: Vec<Regex>,
    path_sanitizer: PathSanitizer,
}

impl CommandSanitizer {
    pub fn sanitize_command(&self, cmd: &str) -> String {
        let mut sanitized = cmd.to_string();
        
        // Remove potential secrets
        for pattern in &self.secret_patterns {
            sanitized = pattern.replace_all(&sanitized, "[REDACTED]").to_string();
        }
        
        // Sanitize file paths
        sanitized = self.path_sanitizer.sanitize(&sanitized);
        
        sanitized
    }
}
```

## Best Practices

### 1. Rate Limiting and Caching

```rust
use tokio::time::{Duration, Instant};
use std::collections::HashMap;

pub struct CachedClaudeClient {
    client: ClaudeClient,
    cache: HashMap<String, (Instant, String)>,
    cache_duration: Duration,
    rate_limiter: RateLimiter,
}

impl CachedClaudeClient {
    pub async fn analyze_with_cache(&mut self, command: &str) -> Result<String> {
        // Check cache first
        if let Some((timestamp, response)) = self.cache.get(command) {
            if timestamp.elapsed() < self.cache_duration {
                return Ok(response.clone());
            }
        }
        
        // Rate limiting
        self.rate_limiter.wait().await;
        
        // Make API call
        let response = self.client.analyze(command).await?;
        
        // Cache the response
        self.cache.insert(command.to_string(), (Instant::now(), response.clone()));
        
        Ok(response)
    }
}
```

### 2. Background Processing

```rust
use tokio::sync::mpsc;

pub struct BackgroundAnalyzer {
    command_rx: mpsc::Receiver<Command>,
    claude_client: ClaudeClient,
}

impl BackgroundAnalyzer {
    pub async fn run(&mut self) {
        while let Some(command) = self.command_rx.recv().await {
            // Process commands in background without blocking shell
            if let Ok(analysis) = self.claude_client.analyze(&command.raw).await {
                // Store analysis for later retrieval
                self.store_analysis(&command, &analysis).await;
                
                // Trigger notifications if needed
                if analysis.has_suggestions() {
                    self.notify_user(&analysis).await;
                }
            }
        }
    }
}
```

### 3. Error Handling and Fallbacks

```rust
pub enum AnalysisError {
    ApiError(String),
    RateLimitExceeded,
    NetworkError,
    InvalidResponse,
}

pub struct RobustAnalyzer {
    primary_client: ClaudeClient,
    fallback_analyzer: LocalAnalyzer,
}

impl RobustAnalyzer {
    pub async fn analyze(&self, command: &str) -> Result<Analysis> {
        match self.primary_client.analyze(command).await {
            Ok(analysis) => Ok(analysis),
            Err(AnalysisError::RateLimitExceeded) => {
                // Wait and retry
                tokio::time::sleep(Duration::from_secs(60)).await;
                self.primary_client.analyze(command).await
            },
            Err(_) => {
                // Fallback to local analysis
                self.fallback_analyzer.analyze(command).await
            }
        }
    }
}
```

## Example Outputs

### Daily Summary

```
📊 Daily Command Summary - Powered by Claude

🕒 **Time Period**: March 15, 2024 (142 commands executed)

🏆 **Top Activities**:
1. Git operations (31%) - Heavy development day
2. Docker commands (18%) - Container management focus  
3. Rust development (24%) - cargo build, test, run cycles
4. File operations (12%) - find, grep, sed usage

💡 **AI Insights**:
- You're following good git hygiene with frequent small commits
- Consider using `cargo watch` to automate build/test cycles
- Your Docker usage suggests microservices development - excellent!
- Pattern detected: You often forget to add `.dockerignore` files

🎯 **Suggestions for Tomorrow**:
- Try `git commit --amend` for quick commit fixes
- Use `docker-compose` for multi-container setups
- Consider `ripgrep` instead of `grep` for faster searches
- Set up pre-commit hooks to catch issues early

🚀 **Learning Opportunity**:
I noticed you're working with Kubernetes. Would you like me to suggest 
a learning path for kubectl commands based on your current skill level?
```

## Troubleshooting

### Common Issues

1. **API Key Issues**
   ```bash
   # Test your API key
   curl -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        https://api.anthropic.com/v1/messages
   ```

2. **Rate Limiting**
   ```bash
   # Check current rate limit status
   ./claude-analyzer status
   
   # Configure rate limiting
   export CLAUDE_REQUESTS_PER_MINUTE=50
   ```

3. **Memory Issues**
   ```bash
   # Clear analysis cache
   ./claude-analyzer cache clear
   
   # Limit history size for analysis
   export MAX_COMMANDS_FOR_ANALYSIS=100
   ```

## Next Steps

- Explore [Gemini Integration](../gemini_integration/) for comparison
- Check out [Multi-AI Analysis](../multi_ai_analysis/) for combined insights
- Read about [Privacy Best Practices](../privacy/) for sensitive environments

## Contributing

Found improvements or new use cases? Please contribute:

1. Fork the repository
2. Add your enhancements
3. Include tests and documentation
4. Submit a pull request

---

**Note**: This example uses mock API calls for demonstration. Replace with actual Claude API integration using the official Anthropic SDK.