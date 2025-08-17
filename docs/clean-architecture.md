# Termbrain Clean Architecture

## Architecture Layers

```
┌─────────────────────────────────────────────────┐
│                 Presentation                     │
│  CLI Interface (bin/termbrain)                  │
├─────────────────────────────────────────────────┤
│                 Application                      │
│  Use Cases / Command Handlers                   │
│  (lib/application/*)                           │
├─────────────────────────────────────────────────┤
│                   Domain                         │
│  Core Business Logic & Entities                 │
│  (lib/domain/*)                                │
├─────────────────────────────────────────────────┤
│                Infrastructure                    │
│  Database, Shell Hooks, External Services       │
│  (lib/infrastructure/*)                        │
└─────────────────────────────────────────────────┘
```

## Directory Structure

```
termbrain/
├── bin/
│   └── termbrain                    # Entry point (minimal)
├── lib/
│   ├── domain/                      # Core business logic
│   │   ├── entities/
│   │   │   ├── command.sh          # Command entity
│   │   │   ├── workflow.sh         # Workflow entity
│   │   │   ├── pattern.sh          # Pattern entity
│   │   │   └── context.sh          # Context entity
│   │   ├── services/
│   │   │   ├── semantic_analyzer.sh # Semantic analysis
│   │   │   ├── pattern_detector.sh  # Pattern detection
│   │   │   └── privacy_guard.sh     # Privacy rules
│   │   └── repositories/            # Repository interfaces
│   │       ├── command_repository.sh
│   │       └── workflow_repository.sh
│   │
│   ├── application/                 # Use cases
│   │   ├── commands/
│   │   │   ├── record_command.sh    # Record command use case
│   │   │   ├── search_history.sh    # Search use case
│   │   │   └── generate_stats.sh    # Stats use case
│   │   ├── workflows/
│   │   │   ├── create_workflow.sh   # Create workflow use case
│   │   │   ├── run_workflow.sh      # Run workflow use case
│   │   │   └── detect_patterns.sh   # Pattern detection use case
│   │   └── ai/
│   │       └── generate_context.sh   # AI context use case
│   │
│   ├── infrastructure/              # External dependencies
│   │   ├── database/
│   │   │   ├── sqlite_adapter.sh    # SQLite implementation
│   │   │   └── migrations/          # Database migrations
│   │   ├── shell/
│   │   │   ├── bash_hooks.sh        # Bash integration
│   │   │   └── zsh_hooks.sh         # Zsh integration
│   │   └── repositories/            # Repository implementations
│   │       ├── sqlite_command_repo.sh
│   │       └── sqlite_workflow_repo.sh
│   │
│   └── presentation/                # UI/CLI layer
│       ├── cli_router.sh            # Command routing
│       ├── formatters/              # Output formatting
│       │   ├── table_formatter.sh
│       │   └── json_formatter.sh
│       └── validators/              # Input validation
│           └── command_validator.sh
│
├── config/
│   ├── default.conf                 # Default configuration
│   └── environment.sh               # Environment setup
│
└── tests/
    ├── unit/                        # Unit tests per layer
    ├── integration/                 # Integration tests
    └── e2e/                        # End-to-end tests
```

## Key Principles

### 1. Dependency Rule
Dependencies only point inward. Domain doesn't know about infrastructure.

### 2. Interface Segregation
Each layer defines interfaces that outer layers implement.

### 3. Single Responsibility
Each module has one reason to change.

### 4. Dependency Injection
Infrastructure details are injected, not hardcoded.

## Example: Recording a Command

```bash
# Domain Layer (lib/domain/entities/command.sh)
Command::new() {
    local cmd="$1"
    local timestamp="$2"
    # Return command object
}

# Application Layer (lib/application/commands/record_command.sh)
RecordCommand::execute() {
    local cmd="$1"
    local command=$(Command::new "$cmd" "$(date)")
    CommandRepository::save "$command"
}

# Infrastructure Layer (lib/infrastructure/repositories/sqlite_command_repo.sh)
SqliteCommandRepository::save() {
    local command="$1"
    sqlite3 "$DB" "INSERT INTO commands..."
}

# Presentation Layer (bin/termbrain)
tb::preexec() {
    RecordCommand::execute "$1"
}
```

## Benefits

1. **Testability** - Each layer can be tested in isolation
2. **Flexibility** - Easy to swap implementations (e.g., different databases)
3. **Maintainability** - Clear boundaries and responsibilities
4. **Scalability** - New features don't break existing ones
5. **Understandability** - Clear flow from user action to data storage