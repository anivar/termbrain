<div align="center">
  
# 🧠 TermBrain

### AI-Ready Terminal Command Intelligence System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/anivar/termbrain)](https://github.com/anivar/termbrain/stargazers)
[![GitHub release](https://img.shields.io/github/release/anivar/termbrain.svg)](https://github.com/anivar/termbrain/releases)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

[**Features**](#features) • [**Quick Start**](#quick-start) • [**Architecture**](#architecture) • [**Contributing**](#contributing)

</div>

---

## What is TermBrain?

**TermBrain v2.0** is a complete rewrite in Rust that transforms your terminal into an intelligent command memory system. It captures, analyzes, and makes your command history searchable while providing rich context for AI assistants.

Built with security, performance, and extensibility in mind, TermBrain offers a clean architecture that can scale from personal use to enterprise environments.

> ⚠️ **Alpha Software**: This is v2.0.0-alpha.1. While core features work, some advertised features are placeholders or partially implemented. See the [roadmap](#-roadmap) for details.

## ✨ Features

🧠 **Intelligent Memory** - Records and analyzes every command with metadata  
🔍 **Smart Search** - Pattern matching with basic keyword relevance scoring  
🔒 **Security First** - Input validation, SQL injection protection, secure shell integration  
📊 **Basic Analytics** - Command frequency and success rate statistics  
⚡ **High Performance** - Rust-powered with SQLite backend for speed and reliability  
🤖 **AI Agent Detection** - Automatic detection and tracking of AI agent commands  
🎯 **AI Integration** - Built-in support for Claude, Gemini, Aider, Cursor, and more  
🛡️ **Privacy Focused** - All data stays local on your machine  
🔄 **Context Rot Prevention** - Never lose AI conversation context across sessions  

## 🏗️ Architecture

TermBrain v2.0 uses a modern three-layer architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                      CLI Interface (tb)                     │
│                   Rust + Clap + Tokio                       │
├─────────────────────────────────────────────────────────────┤
│                     Core Domain Layer                       │
│              • Command entities & validation                │
│              • Repository traits & services                 │
│              • Business logic & rules                       │
├─────────────────────────────────────────────────────────────┤
│                    Storage Layer                            │
│              • SQLite with vector search                    │
│              • Migration system                             │
│              • Query optimization                           │
├─────────────────────────────────────────────────────────────┤
│                  Shell Integration                          │
│              • Bash, Zsh, Fish support                      │
│              • Secure command capture                       │
│              • Real-time recording                          │
└─────────────────────────────────────────────────────────────┘
```

### Key Technical Features:
- **Type Safety**: Full Rust type system protection
- **Async/Await**: Non-blocking operations with Tokio
- **Security**: Input validation, SQL injection prevention
- **Performance**: Optimized queries, connection pooling
- **Extensibility**: Plugin architecture for AI providers

## 🚀 Quick Start

### Prerequisites
- Rust 1.70+ (install via [rustup](https://rustup.rs/))
- SQLite 3.35+ (sqlite-vec included but not yet utilized)

### Installation

```bash
# Clone the repository
git clone https://github.com/anivar/termbrain.git
cd termbrain

# Build and install
cargo install --path crates/termbrain-cli

# Setup shell integration
tb install --shell bash  # or zsh, fish
```

### Basic Usage

```bash
# Shell integration automatically records all commands
# Just run commands normally after installation!

# Search your history
tb search "git"

# View recent commands
tb history --limit 10

# View commands from AI sessions
tb history --ai-agent claude
tb history --ai-agent cursor

# Wrap AI agent execution
tb wrap --ai-agent "aider" --context "bug fixing" -- aider --message "Fix auth bug"

# Show usage statistics
tb statistics

# Detect patterns (basic 3-command sequences)
tb patterns --confidence 0.8

# Export data
tb export -o commands.json --export-format json
tb export -o commands.csv --export-format csv
tb export -o commands.md --export-format markdown --since "7 days ago"
```

## 🔧 Configuration

TermBrain stores data in `~/.termbrain/` by default:

```
~/.termbrain/
├── termbrain.db        # Main SQLite database
├── config.toml         # Configuration file (optional)
└── logs/              # Application logs
```

### Configuration File

TermBrain loads configuration from (in order of priority):
1. `$TERMBRAIN_CONFIG` environment variable path
2. `~/.config/termbrain/config.toml`
3. `~/.termbrain/config.toml`
4. `/etc/termbrain/config.toml`

Example `config.toml`:
```toml
# Database settings
database_path = "~/.termbrain/termbrain.db"
max_database_size_mb = 500    # Auto-cleanup when exceeded

# Feature toggles
shell_integration = true
auto_record = true
semantic_search = true        # Uses sqlite-vec extension

# History settings
max_history_size = 10000
retention_days = 90          # Optional: auto-delete old records

# Logging
log_level = "info"           # debug, info, warn, error
```

### Environment Variables

Environment variables override config file settings:

```bash
# Core configuration
export TERMBRAIN_DATABASE_PATH="$HOME/.termbrain/termbrain.db"
export TERMBRAIN_LOG_LEVEL="info"
export TERMBRAIN_MAX_DB_SIZE_MB="1000"
export TERMBRAIN_AUTO_RECORD="true"
export TERMBRAIN_SESSION_ID="$(date +%s)-$$"

# AI agent detection (automatically set by TermBrain)
export TERMBRAIN_AI_AGENT="claude"           # Detected AI agent name
export TERMBRAIN_AI_SESSION="session-123"    # AI session identifier
export TERMBRAIN_AI_CONTEXT="bug fixing"     # Optional context description
```

## 🚨 Operational Features

### Logging & Monitoring
- **Location**: `~/.termbrain/logs/`
- **Format**: Structured JSON logs
- **Rotation**: Daily rotation, 7-day retention
- **Size Limit**: 100MB total log directory size
- **Log Levels**: debug, info, warn, error

Example log entry:
```json
{
  "timestamp": "2025-08-22T03:33:27.176516Z",
  "level": "INFO",
  "fields": {
    "message": "Command recorded",
    "command": "git status",
    "exit_code": 0,
    "duration_ms": 5
  }
}
```

### Garbage Collection
Runs automatically every hour to:
- Enforce database size limits (deletes oldest commands)
- Apply retention policy (removes commands older than configured days)
- Clean up logs older than 7 days
- Remove temporary files older than 1 hour
- Vacuum database to reclaim space

### Resource Limits
- **Database Size**: Configurable via `max_database_size_mb`
- **Log Size**: 100MB maximum
- **Connection Pool**: 5 concurrent SQLite connections
- **Async Tasks**: Non-blocking operations

## 🤖 AI Agent Integration

TermBrain v2.0 automatically detects and tracks commands executed by AI agents:

### Automatic Detection
TermBrain detects AI agents through:
- Environment variables (CLAUDE_SESSION_ID, AIDER_CHAT_ID, etc.)
- Process tree analysis (detects parent AI processes)
- Manual tagging with `tb wrap`

### Supported AI Agents
- **Claude** (Anthropic) - Auto-detected via process/env
- **Gemini** (Google AI) - Auto-detected via process/env
- **Aider** - Auto-detected via AIDER_CHAT_ID
- **Cursor** - Auto-detected via CURSOR_SESSION_ID
- **Continue** - Auto-detected via CONTINUE_SESSION
- **Cody** - Auto-detected via CODY_SESSION_ID
- **GitHub Copilot** - Auto-detected via COPILOT_SESSION

### Usage Examples

```bash
# View all commands from Claude sessions
tb history --ai-agent claude

# Explicitly wrap an AI agent session
tb wrap --ai-agent "claude" --context "refactoring auth" -- claude chat

# Check if AI agent is detected
source ~/.bashrc  # or ~/.zshrc
termbrain_status  # or 'tbs' alias

# Export AI session data for analysis
tb export -o ai_sessions.json --export-format json --since "30 days ago"
tb export ai-sessions.json --format json --ai-agent aider --since "1 week ago"
```

### Context Rot Prevention
TermBrain solves the "context rot" problem by:
- Preserving complete command history across AI sessions
- Tracking AI agent context and session IDs
- Enabling reconstruction of past AI interactions
- Providing searchable AI command history

## 🛡️ Security & Production Features

### Security
- **Input Validation**: Comprehensive validation for all user inputs
- **SQL Injection Protection**: Parameterized queries and safe dynamic SQL
- **Command Injection Prevention**: Secure shell integration with proper escaping
- **Path Traversal Protection**: Safe file operations with path validation
- **Data Privacy**: All data stored locally, no external connections

### Production Readiness
- **Logging**: Structured JSON logs with daily rotation
- **Monitoring**: Detailed operation logging for debugging
- **Garbage Collection**: Automatic cleanup of old data
- **Database Size Management**: Configurable size limits with auto-cleanup
- **Graceful Shutdown**: Signal handling for clean termination
- **Resource Management**: Connection pooling and async operations

## 📊 Performance

Built for performance with:
- **Efficient Queries**: SQLite with indexing
- **Async Operations**: Non-blocking I/O with Tokio runtime
- **Memory Management**: Rust's zero-cost abstractions
- **Connection Pooling**: SQLx connection pool

Performance targets (not yet benchmarked):
- Command recording: < 5ms
- Search queries: < 50ms
- Startup time: < 100ms

## 🧪 Development

### Building from Source

```bash
# Clone and build
git clone https://github.com/anivar/termbrain.git
cd termbrain

# Run tests
cargo test --workspace

# Build release
cargo build --release

# Run with debugging
RUST_LOG=debug cargo run -- search "test"
```

### Project Structure

```
termbrain/
├── crates/
│   ├── termbrain-core/      # Domain logic and entities
│   ├── termbrain-storage/   # Database and storage layer
│   └── termbrain-cli/       # Command-line interface
├── shell-integration/       # Shell hooks (bash, zsh, fish)
├── examples/               # AI integration examples
├── migrations/             # Database migrations
└── tests/                  # Integration tests
```

## 🔄 Migration from v1.x

TermBrain v2.0 is a complete rewrite. To migrate from the shell-based v1.x:

```bash
# Export data from v1.x (if you have it)
tb-v1 export legacy-data.json

# Install v2.0
cargo install --path crates/termbrain-cli

# Import feature coming in v2.1.0
```

**Note**: v1.x shell-based version is now deprecated. v2.0 provides all features with better performance and security.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md).

### Development Setup

```bash
# Install development dependencies
cargo install cargo-watch cargo-audit

# Run tests in watch mode
cargo watch -x "test --workspace"

# Check for security issues
cargo audit

# Format code
cargo fmt --all

# Run lints
cargo clippy --workspace --all-targets
```

## 📈 Roadmap

### v2.0.0-alpha.1 (Current)
- ✅ Rust rewrite with clean architecture
- ✅ Security improvements and input validation
- ✅ Multi-shell support (bash, zsh, fish)
- ✅ Automatic AI agent detection and tracking
- ✅ Command recording with AI metadata
- ✅ AI agent filtering in history
- ✅ Configuration file support with environment overrides
- ✅ Export functionality (JSON, CSV, Markdown)
- ✅ Date filtering for exports
- ✅ Comprehensive logging with JSON structured logs
- ✅ Log rotation (daily, 7-day retention)
- ✅ Database garbage collection and size management
- ✅ Graceful shutdown with signal handling
- ✅ Automatic cleanup of logs and temp files
- ⚠️ Basic pattern detection (3-command sequences only)
- ⚠️ Placeholder workflow automation

### v2.0.0-alpha.2 (Next Release)
- [ ] Metrics collection and health endpoints
- [ ] Complete test coverage
- [ ] Performance benchmarks
- [ ] Documentation improvements

### v2.1.0 (Planned)
- [ ] Database migration system
- [ ] Backup/restore functionality
- [ ] Semantic search using sqlite-vec
- [ ] Advanced pattern detection
- [ ] Working workflow automation
- [ ] Performance optimizations

### v2.2.0 (Future)
- [ ] Distributed architecture for teams
- [ ] Plugin system for extensibility
- [ ] Advanced analytics and insights
- [ ] Cross-platform support (Windows)

## 📄 License

MIT © [Anivar Aravind](https://github.com/anivar)

## 🙏 Acknowledgments

- Rust community for excellent tooling and ecosystem
- SQLite team for reliable embedded database
- Security researchers for vulnerability disclosure
- Contributors and early adopters

---

<div align="center">

**Built with 🦀 Rust for Performance and Safety**

[Report Bug](https://github.com/anivar/termbrain/issues) • [Request Feature](https://github.com/anivar/termbrain/issues) • [Discussions](https://github.com/anivar/termbrain/discussions)

⭐ Star us on GitHub — it helps!

</div>