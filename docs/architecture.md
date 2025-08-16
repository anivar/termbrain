# Termbrain Architecture

This document provides a comprehensive technical overview of Termbrain's architecture, implementation details, and design decisions.

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Layers](#architecture-layers)
3. [Component Architecture](#component-architecture)
4. [Database Design](#database-design)
5. [Data Flow](#data-flow)
6. [Technical Implementation](#technical-implementation)
7. [Security Architecture](#security-architecture)
8. [Performance Architecture](#performance-architecture)
9. [Extension Architecture](#extension-architecture)
10. [Future Architecture](#future-architecture)

## System Overview

Termbrain is a terminal memory and intelligence system built with a three-layer progressive enhancement architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                        Shell Session                         │
├─────────────────────────────────────────────────────────────┤
│  Shell Hooks (preexec/precmd) → Command Capture System      │
├─────────────────────────────────────────────────────────────┤
│                    Termbrain Core Layer                      │
│  ┌─────────────┐ ┌──────────────┐ ┌───────────────────┐    │
│  │  Semantic   │ │    Error     │ │   AI Context      │    │
│  │  Analysis   │ │   Learning   │ │   Generation      │    │
│  └─────────────┘ └──────────────┘ └───────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                  Enhanced Features Layer                     │
│  ┌─────────────┐ ┌──────────────┐ ┌───────────────────┐    │
│  │  Conceptual │ │   Project    │ │   Architecture    │    │
│  │  Reasoning  │ │   Memory     │ │   Decisions       │    │
│  └─────────────┘ └──────────────┘ └───────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                   Cognitive Layer                            │
│  ┌─────────────┐ ┌──────────────┐ ┌───────────────────┐    │
│  │  Intention  │ │  Knowledge   │ │   Mental          │    │
│  │  Tracking   │ │  Extraction  │ │   Models          │    │
│  └─────────────┘ └──────────────┘ └───────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                    SQLite Database                           │
│  Core Tables: commands, errors, patterns, workflows, contexts│
│  Enhanced: concepts, decisions, explorations, projects       │
│  Cognitive: intentions, knowledge, connections, mental_models│
└─────────────────────────────────────────────────────────────┘
```

## Architecture Layers

### 1. Core Layer (termbrain.sh)
- **Purpose**: Fundamental command capture and analysis
- **Features**: Command tracking, error learning, pattern detection, AI context generation
- **Dependencies**: SQLite3, jq
- **Size**: ~700 lines of bash

### 2. Enhanced Layer (termbrain-enhanced.sh)
- **Purpose**: High-level conceptual understanding
- **Features**: Reasoning capture, architecture decisions, project contexts
- **Dependencies**: Core layer
- **Size**: ~400 lines of bash

### 3. Cognitive Layer (termbrain-cognitive.sh)
- **Purpose**: Learning and knowledge management
- **Features**: Intention tracking, knowledge extraction, mental models
- **Dependencies**: Core + Enhanced layers
- **Size**: ~500 lines of bash

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

## Component Architecture

### Directory Structure

```
~/.termbrain/
├── bin/
│   ├── termbrain          # Main script
│   ├── tb-wrapper         # Non-sourced execution wrapper
│   └── tb → tb-wrapper    # Symlink
├── lib/
│   ├── termbrain-enhanced.sh   # Enhanced layer
│   ├── termbrain-cognitive.sh  # Cognitive layer
│   ├── capture.sh         # Command capture utilities
│   ├── semantic.sh        # Semantic analysis engine
│   ├── patterns.sh        # Pattern detection algorithms
│   └── safety.sh          # Privacy/security functions
├── providers/
│   ├── claude.sh          # Claude AI integration
│   ├── cursor.sh          # Cursor integration
│   └── copilot.sh         # GitHub Copilot integration
├── data/
│   └── termbrain.db       # SQLite database
├── cache/                 # Temporary context files
├── exports/               # Data export directory
└── init.sh               # Shell initialization script
```

### Core Components

#### 1. Shell Integration

**Bash Integration:**
```bash
trap 'tb::preexec "$BASH_COMMAND"' DEBUG
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}tb::precmd"
```

**Zsh Integration:**
```bash
autoload -U add-zsh-hook
add-zsh-hook preexec tb::preexec
add-zsh-hook precmd tb::precmd
```

#### 2. Command Capture Pipeline

```
User Input → preexec() → Safety Check → Semantic Analysis → Database Storage
                ↓
         Command Execution
                ↓
           precmd() → Exit Code → Duration → Error Detection → Pattern Update
```

#### 3. Semantic Analysis Engine

```bash
tb::analyze_semantic() {
    local cmd="$1"
    case "$cmd" in
        git*) echo "version_control" ;;
        npm*|yarn*|pnpm*|bun*) echo "package_management" ;;
        docker*|kubectl*|podman*) echo "containerization" ;;
        *test*|*spec*|jest*|pytest*) echo "testing" ;;
        *lint*|*format*|prettier*) echo "code_quality" ;;
        make*|cargo\ build*|go\ build*) echo "building" ;;
        curl*|wget*|http*) echo "http_request" ;;
        ssh*|scp*|rsync*) echo "remote_access" ;;
        vim*|nvim*|code*) echo "editing" ;;
        cd*|ls*|find*|grep*) echo "navigation" ;;
        psql*|mysql*|mongo*) echo "database" ;;
        python*|node*|ruby*) echo "code_execution" ;;
        *) echo "general" ;;
    esac
}
```

#### 4. Project Detection

```bash
tb::detect_project() {
    if [[ -f "package.json" ]]; then
        [[ -f "tsconfig.json" ]] && echo "typescript" || echo "javascript"
    elif [[ -f "Cargo.toml" ]]; then echo "rust"
    elif [[ -f "go.mod" ]]; then echo "go"
    elif [[ -f "requirements.txt" ]]; then echo "python"
    elif [[ -f "Gemfile" ]]; then echo "ruby"
    elif [[ -f "pom.xml" ]]; then echo "java_maven"
    elif [[ -f "Dockerfile" ]]; then echo "docker"
    else echo "unknown"
    fi
}
```

#### 5. Error Learning System

```
1. Command fails (exit_code != 0)
2. System enters "error mode"
3. Captures error context
4. Watches subsequent commands
5. When command succeeds:
   - Links error to solution
   - Stores for future reference
6. Next time similar error occurs:
   - Suggests previous solution
```

## Database Design

### Schema Overview

Termbrain uses SQLite with 15 specialized tables across three layers:

#### Core Tables (5)

```sql
-- 1. commands: Every command with rich metadata
CREATE TABLE commands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    command TEXT NOT NULL,
    directory TEXT,
    exit_code INTEGER,
    duration_ms INTEGER,
    git_branch TEXT,
    project_type TEXT,      -- auto-detected: node, rust, python
    semantic_type TEXT,     -- categorized: git, npm, docker
    session_id TEXT,
    is_sensitive BOOLEAN DEFAULT FALSE
);

-- 2. errors: Track and learn from failures
CREATE TABLE errors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    command_id INTEGER,
    error_output TEXT,
    solution_commands TEXT,  -- commands that fixed it
    solved BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (command_id) REFERENCES commands(id)
);

-- 3. patterns: Detect repeated workflows
CREATE TABLE patterns (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern_type TEXT NOT NULL,
    pattern_data JSON,      -- sequence of commands
    frequency INTEGER DEFAULT 1,
    last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(pattern_type)
);

-- 4. workflows: Automation opportunities
CREATE TABLE workflows (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    description TEXT,
    command_sequence JSON,
    trigger_conditions JSON,
    success_rate REAL,
    times_used INTEGER DEFAULT 0
);

-- 5. contexts: AI-ready contexts
CREATE TABLE contexts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    query TEXT,
    context_type TEXT,
    content TEXT,
    provider TEXT           -- claude, cursor, copilot
);
```

#### Enhanced Tables (5)

```sql
-- 6. concepts: High-level understanding
CREATE TABLE concepts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    name TEXT UNIQUE,
    description TEXT,
    related_commands JSON,
    mental_model TEXT,
    confidence REAL DEFAULT 0.5
);

-- 7. reasoning: Decision documentation
CREATE TABLE reasoning (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    command_id INTEGER,
    why TEXT,               -- why you ran this command
    goal TEXT,              -- what you're trying to achieve
    learned TEXT,           -- what you learned
    FOREIGN KEY (command_id) REFERENCES commands(id)
);

-- 8. decisions: Architecture choices
CREATE TABLE decisions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    title TEXT,
    reasoning TEXT,
    alternatives_considered TEXT,
    outcome TEXT,
    project TEXT
);

-- 9. projects: Project contexts
CREATE TABLE projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT UNIQUE,
    name TEXT,
    description TEXT,
    tech_stack JSON,
    conventions JSON,
    last_active DATETIME
);

-- 10. memory_links: Connect everything
CREATE TABLE memory_links (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_type TEXT,         -- command, concept, decision
    from_id INTEGER,
    to_type TEXT,
    to_id INTEGER,
    link_type TEXT,         -- caused_by, related_to, implements
    strength REAL DEFAULT 0.5
);
```

#### Cognitive Tables (5)

```sql
-- 11. intentions: Goal tracking
CREATE TABLE intentions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    goal TEXT,
    context TEXT,
    success BOOLEAN DEFAULT FALSE,
    learnings TEXT,
    time_spent INTEGER,     -- seconds
    commands_count INTEGER
);

-- 12. knowledge: Extracted insights
CREATE TABLE knowledge (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    insight TEXT,
    topic TEXT,
    source TEXT,            -- experience, documentation, error
    confidence REAL DEFAULT 0.5,
    validated BOOLEAN DEFAULT FALSE,
    usage_count INTEGER DEFAULT 0
);

-- 13. connections: Knowledge graph
CREATE TABLE connections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_type TEXT,         -- command, concept, knowledge
    from_id INTEGER,
    to_type TEXT,
    to_id INTEGER,
    relationship TEXT,      -- causes, requires, related_to
    strength REAL DEFAULT 0.5,
    evidence_count INTEGER DEFAULT 1
);

-- 14. mental_models: Named patterns
CREATE TABLE mental_models (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    description TEXT,
    pattern TEXT,           -- JSON of command sequences
    context_triggers TEXT,  -- when to apply
    effectiveness REAL DEFAULT 0.5,
    usage_count INTEGER DEFAULT 0
);

-- 15. cognitive_state: Productivity tracking
CREATE TABLE cognitive_state (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    focus_area TEXT,
    productivity_score INTEGER,  -- 1-10
    interruption_count INTEGER DEFAULT 0,
    flow_duration INTEGER,       -- seconds in flow
    energy_level INTEGER DEFAULT 5
);
```

### Indexes for Performance

```sql
-- Core indexes
CREATE INDEX idx_commands_timestamp ON commands(timestamp);
CREATE INDEX idx_commands_semantic ON commands(semantic_type);
CREATE INDEX idx_commands_session ON commands(session_id);
CREATE INDEX idx_errors_solved ON errors(solved);
CREATE INDEX idx_patterns_type ON patterns(pattern_type);

-- Enhanced indexes
CREATE INDEX idx_concepts_name ON concepts(name);
CREATE INDEX idx_decisions_project ON decisions(project);
CREATE INDEX idx_projects_path ON projects(path);

-- Cognitive indexes
CREATE INDEX idx_intentions_goal ON intentions(goal);
CREATE INDEX idx_knowledge_topic ON knowledge(topic);
CREATE INDEX idx_connections_from ON connections(from_type, from_id);
CREATE INDEX idx_mental_models_name ON mental_models(name);
```

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