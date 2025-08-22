# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- AI agent detection and tracking capabilities
- `tb wrap` command for explicit AI agent monitoring
- AI agent filtering in history with `--ai-agent` flag
- Automatic detection of Claude, Gemini, Aider, Cursor, Continue, Cody, and Copilot
- Environment variable detection for AI sessions
- Process tree scanning for AI agent detection
- AI metadata fields in command records (ai_agent, ai_session_id, ai_context)
- Configuration file support with TOML format
- Multiple config path locations with priority loading
- Environment variable overrides for all config settings
- Full export functionality (JSON, CSV, Markdown formats)
- Date filtering for exports with relative and absolute dates
- Maximum database size configuration with auto-cleanup
- Comprehensive logging with structured JSON output
- Log rotation with daily files and 7-day retention
- Database garbage collection with size and age-based cleanup
- Graceful shutdown with SIGTERM/SIGINT handling
- Automatic cleanup of logs and temporary files
- Database vacuum operations for space reclamation

### Changed
- Improved error handling throughout the codebase
- Enhanced database persistence and stability
- Optimized build process

### Security
- Comprehensive input validation for all user inputs
- SQL injection protection with parameterized queries
- Command injection prevention in shell integration
- Path traversal protection with safe path validation

## [2.0.0-alpha.1] - 2024-01-21

### Added
- Complete rewrite in Rust for performance and safety
- Three-layer architecture (CLI, Core Domain, Storage)
- SQLite storage with connection pooling
- Multi-shell support (bash, zsh, fish)
- Async operations with Tokio runtime
- Basic command recording and search functionality
- Command history with filtering options
- Statistics and pattern detection
- Export functionality placeholders (actual export not implemented)
- Shell integration with automatic command capture
- Uninstall command with cleanup options
- Workflow management placeholders (not functional)
- Basic pattern detection (3-command sequences only)

### Changed
- Migrated from shell-based implementation to Rust
- Replaced file-based storage with SQLite database
- Improved security with input validation
- Enhanced performance with optimized queries

### Deprecated
- Shell-based v1.x version is now deprecated

### Known Issues
- Configuration loading returns defaults only
- No database migration system beyond initial schema
- Limited error handling in some areas
- No backup/restore functionality
- No data retention policies

## [1.0.0] - 2023-XX-XX (Legacy Shell Version)

### Added
- Initial shell-based implementation
- Basic command recording
- Simple search functionality
- Bash integration

### Deprecated
- This version is now deprecated in favor of v2.0 Rust implementation