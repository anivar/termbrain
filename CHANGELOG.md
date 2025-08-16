# Changelog

All notable changes to Termbrain will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Next features and improvements will be listed here

## [1.0.0] - 2024-01-XX

### Added
- 🧠 **Core Memory System**
  - Automatic command capture with preexec/precmd hooks
  - Semantic command analysis (git, npm, docker, testing, etc.)
  - Smart project type detection
  - Error tracking and solution learning
  - Pattern detection for workflow automation
  - Privacy controls with sensitive data detection

- 🔍 **Search & Analytics**
  - Interactive FZF-powered search
  - Command usage statistics
  - Performance metrics
  - Error rate analysis
  - Workflow pattern discovery

- 🤖 **AI Integration**
  - Context generation for AI assistants
  - Creates .ai-context.md file with relevant history
  - Provider-specific file naming (experimental)

- 🛡️ **Privacy & Security**
  - 100% local storage
  - Automatic secret redaction
  - Pause recording mode
  - Data export capabilities
  - Configurable privacy settings

- 🐚 **Shell Support**
  - Full Bash support (4.0+)
  - Full Zsh support (5.0+)
  - Cross-platform (macOS, Linux)

- 📦 **Distribution**
  - Git-based installation
  - Automated installer script
  - Basic test suite

### Technical Details
- SQLite-based storage for reliability and performance
- Simple architecture with room for growth
- Minimal dependencies (sqlite3 and jq required)
- Test framework included
- Documentation included

### Known Issues
- Fish shell support not yet implemented
- Windows support not yet available
- Some terminal emulators may have issues with ANSI colors

## [0.9.0-beta] - 2024-01-XX (Pre-release)

### Added
- Initial beta release for testing
- Core command capture functionality
- Basic AI context generation
- Simple analytics

### Changed
- Migrated from dotfiles-context project
- Rebranded as Termbrain

### Fixed
- SQL injection vulnerabilities
- Memory leaks in long-running sessions

## Development History

This project evolved from:
- `dotfiles-context` - Original proof of concept
- Added automatic command capture
- Added semantic understanding
- Added cognitive features
- Complete rewrite for production readiness

---

For more details on each release, see the [GitHub Releases](https://github.com/anivar/termbrain/releases) page.