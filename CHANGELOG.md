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
  - Context generation for Claude, Cursor, and GitHub Copilot
  - Provider-specific file formats (.claude.md, .cursorrules, etc.)
  - Rich context including commands, errors, solutions, and patterns

- 📚 **Enhanced Memory Layer**
  - High-level concept capture (architecture, decisions, learning)
  - Reasoning documentation
  - Project-level memory management
  - Memory links between commands and concepts
  - Interactive memory explorer UI

- 🎯 **Cognitive Layer**
  - Intention tracking (set goals, track achievements)
  - Automatic knowledge extraction
  - Mental model detection
  - Flow state tracking
  - Productivity metrics
  - Personalized suggestions

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
  - NPM package
  - Homebrew formula (planned)
  - Automated installer script
  - Comprehensive test suite

### Technical Details
- SQLite-based storage for reliability and performance
- Modular architecture with progressive enhancement
- Zero external dependencies (only sqlite3 and jq required)
- Extensive test coverage (33+ test cases)
- Well-documented codebase

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