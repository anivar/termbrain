# Termbrain Architecture

This document describes the technical architecture of Termbrain, including its design principles, components, and data flow.

## Overview

Termbrain is built as a progressive enhancement system with three layers:

1. **Core Layer** - Basic command capture and analysis
2. **Enhanced Layer** - High-level concepts and reasoning
3. **Cognitive Layer** - Intentions, knowledge, and mental models

## Design Principles

### 1. Local-First
- All data stored locally in SQLite
- No network requests or cloud dependencies
- User owns and controls all data

### 2. Progressive Enhancement
- Each layer builds on the previous
- Can run with just core features
- Advanced features are optional

### 3. Shell Integration
- Uses native shell hooks (preexec/precmd)
- No daemon processes
- Minimal performance impact

### 4. Privacy by Design
- Automatic sensitive data detection
- Redaction capabilities
- Pause/resume recording

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    User Terminal                         │
├─────────────────────────────────────────────────────────┤
│                   Shell (Bash/Zsh)                       │
│  ┌────────────┐  ┌────────────┐  ┌─────────────────┐   │
│  │  preexec   │  │  precmd    │  │  User Commands  │   │
│  │   Hook     │  │   Hook     │  │  (tb, tb-*)     │   │
│  └─────┬──────┘  └─────┬──────┘  └────────┬────────┘   │
│        │               │                   │             │
├────────┼───────────────┼───────────────────┼────────────┤
│        ▼               ▼                   ▼            │
│ ┌─────────────────────────────────────────────────────┐ │
│ │              Termbrain Core Engine                  │ │
│ │  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │ │
│ │  │  Command    │  │  Semantic    │  │   Error    │ │ │
│ │  │  Capture    │  │  Analysis    │  │  Learning  │ │ │
│ │  └─────────────┘  └──────────────┘  └────────────┘ │ │
│ └─────────────────────────┬───────────────────────────┘ │
│                           ▼                              │
│ ┌─────────────────────────────────────────────────────┐ │
│ │              SQLite Database                        │ │
│ │  ┌──────────┐ ┌──────────┐ ┌──────────┐           │ │
│ │  │ Commands │ │  Errors  │ │ Patterns │  ...      │ │
│ │  └──────────┘ └──────────┘ └──────────┘           │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Component Details

### Shell Integration

**preexec Hook**
- Triggered before command execution
- Captures command text
- Performs semantic analysis
- Stores in database with context

**precmd Hook**
- Triggered after command execution
- Captures exit code and duration
- Links errors to solutions
- Updates patterns

### Core Engine

**Command Capture**
```bash
tb::preexec() {
    # 1. Safety check
    # 2. Semantic analysis
    # 3. Project detection
    # 4. Store in database
    # 5. Async pattern detection
}
```

**Semantic Analysis**
- Categorizes commands (git, npm, docker, etc.)
- Detects project types
- Identifies sensitive data
- Maps to semantic types

**Error Learning**
- Tracks command failures
- Watches for solutions
- Links errors to fixes
- Builds solution database

### Database Schema

**Core Tables**
- `commands` - All captured commands
- `errors` - Error tracking
- `patterns` - Detected workflows
- `workflows` - Automation opportunities
- `contexts` - AI context cache

**Enhanced Tables**
- `concepts` - High-level understanding
- `reasoning` - Decision documentation
- `projects` - Project contexts
- `memory_links` - Connections

**Cognitive Tables**
- `intentions` - Goals and achievements
- `knowledge` - Extracted insights
- `mental_models` - Workflow patterns
- `cognitive_state` - Productivity tracking

### Data Flow

1. **Command Entry**
   ```
   User types command → Shell → preexec hook → Termbrain
   ```

2. **Processing Pipeline**
   ```
   Command → Safety Check → Semantic Analysis → Storage → Pattern Detection
   ```

3. **Context Generation**
   ```
   Query → Database Search → Context Building → AI File Creation
   ```

## Security Architecture

### Input Validation
- SQL parameter escaping
- Path validation
- Command injection prevention

### Privacy Protection
- Automatic password detection
- Sensitive directory blocking
- Redaction capabilities

### Data Isolation
- User-specific database
- No shared state
- Local file permissions

## Performance Considerations

### Optimization Strategies
- Indexed database columns
- Async pattern detection
- Batch operations
- Minimal shell overhead

### Resource Usage
- SQLite: ~10-50MB typical
- Memory: < 10MB overhead
- CPU: < 1% impact
- Disk I/O: Minimal

## Extension Points

### Provider Integration
New AI providers can be added:
```bash
providers/
├── claude.sh
├── cursor.sh
├── copilot.sh
└── custom.sh  # Add your own
```

### Custom Analyzers
Add semantic analyzers:
```bash
lib/
├── analyzers/
│   ├── terraform.sh
│   ├── kubernetes.sh
│   └── custom.sh
```

### Workflow Automation
Create custom workflows:
```bash
workflows/
├── git-flow.sh
├── deploy.sh
└── test-suite.sh
```

## Future Architecture

### Planned Enhancements
1. **Plugin System** - Dynamic loading of extensions
2. **Sync Protocol** - Optional encrypted sync
3. **Team Sharing** - Collaborative memory
4. **API Server** - REST/GraphQL interface

### Scalability Path
1. **Sharded Storage** - Multiple databases
2. **Index Optimization** - Better search
3. **Compression** - Historical data
4. **Archival** - Cold storage

## Development Guidelines

### Adding Features
1. Identify which layer (core/enhanced/cognitive)
2. Update database schema if needed
3. Add functions with `tb::` prefix
4. Include tests
5. Update documentation

### Code Organization
```
src/
├── termbrain.sh          # Core layer
├── termbrain-enhanced.sh # Enhanced layer
└── termbrain-cognitive.sh # Cognitive layer

lib/
├── capture.sh      # Command capture
├── semantic.sh     # Analysis
├── patterns.sh     # Pattern detection
└── safety.sh       # Security
```

### Testing Strategy
- Unit tests for functions
- Integration tests for workflows
- Performance benchmarks
- Security audits

## Conclusion

Termbrain's architecture prioritizes:
- **Simplicity** - Easy to understand and extend
- **Performance** - Minimal overhead
- **Privacy** - Local-first design
- **Extensibility** - Multiple extension points

This architecture enables a powerful yet lightweight system that enhances terminal productivity without compromising user control or system performance.