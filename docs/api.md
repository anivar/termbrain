# Termbrain API Reference

This document describes the internal API for extending and customizing Termbrain.

## Core Functions

### Command Capture

#### `tb::preexec(command)`
Called before command execution.

```bash
tb::preexec "git status"
```

**Parameters:**
- `command` - The command string to be executed

**Actions:**
- Performs safety checks
- Analyzes semantic type
- Stores in database
- Triggers pattern detection

#### `tb::precmd()`
Called after command execution.

**Actions:**
- Captures exit code
- Records duration
- Updates command record
- Handles error learning

### Semantic Analysis

#### `tb::analyze_semantic(command)`
Categorizes commands by type.

```bash
local type=$(tb::analyze_semantic "npm install")
# Returns: "package_management"
```

**Returns:** Semantic type string

#### `tb::detect_project()`
Detects project type based on files.

```bash
local project=$(tb::detect_project)
# Returns: "javascript", "python", "rust", etc.
```

### Safety Functions

#### `tb::is_safe_to_record(command)`
Checks if command should be recorded.

```bash
if tb::is_safe_to_record "$cmd"; then
    # Record command
fi
```

**Returns:** 0 if safe, 1 if not

#### `tb::check_sensitive(command)`
Detects sensitive information.

```bash
local is_sensitive=$(tb::check_sensitive "export API_KEY=secret")
# Returns: "1"
```

#### `tb::escape_sql(text)`
Escapes text for SQL queries.

```bash
local escaped=$(tb::escape_sql "O'Brien")
# Returns: "O''Brien"
```

### Database Operations

#### `tb::init_db()`
Initializes the database schema.

```bash
tb::init_db
```

### Context Generation

#### `tb::ai(query, provider)`
Generates AI context.

```bash
tb::ai "help with docker" "claude"
```

**Parameters:**
- `query` - Topic to focus on (optional)
- `provider` - AI provider (optional)

### Pattern Detection

#### `tb::detect_patterns(command)`
Async pattern detection.

```bash
tb::detect_patterns "git add ."
```

### Error Learning

#### `tb::capture_error(exit_code)`
Records command failure.

```bash
tb::capture_error 1
```

#### `tb::learn_solution()`
Links solution to error.

```bash
tb::learn_solution
```

## Enhanced Functions

### Concept Management

#### `tb::capture_concept(type, title, description)`
Captures high-level concepts.

```bash
tb::capture_concept "architecture" "Microservices" "Using Docker containers"
```

#### `tb::why()`
Interactive reasoning capture.

```bash
tb::why
# Prompts for reason behind last command
```

#### `tb::arch(title, description)`
Documents architectural decisions.

```bash
tb::arch "API Design" "RESTful with JWT auth"
```

### Project Management

#### `tb::project(action, name)`
Manages project contexts.

```bash
tb::project init "my-app"
tb::project switch
tb::project list
```

## Cognitive Functions

### Intention Tracking

#### `tb::intend(goal)`
Sets current intention.

```bash
tb::intend "implement user authentication"
```

#### `tb::achieved()`
Marks intention complete.

```bash
tb::achieved
# Prompts for learnings
```

### Knowledge Management

#### `tb::extract_knowledge(insight, source)`
Stores learned knowledge.

```bash
tb::extract_knowledge "Use mocks for external APIs" "experience"
```

### Flow State

#### `tb::flow(action)`
Manages flow state tracking.

```bash
tb::flow start
tb::flow end
tb::flow status
```

### Mental Models

#### `tb::detect_mental_models()`
Finds workflow patterns.

```bash
tb::detect_mental_models
```

## Database Schema

### Core Tables

```sql
commands (
    id INTEGER PRIMARY KEY,
    timestamp DATETIME,
    command TEXT,
    directory TEXT,
    exit_code INTEGER,
    duration_ms INTEGER,
    git_branch TEXT,
    project_type TEXT,
    semantic_type TEXT,
    session_id TEXT,
    is_sensitive BOOLEAN
)

errors (
    id INTEGER PRIMARY KEY,
    command_id INTEGER,
    error_output TEXT,
    solution_commands TEXT,
    solved BOOLEAN
)

patterns (
    id INTEGER PRIMARY KEY,
    pattern_type TEXT,
    pattern_data JSON,
    frequency INTEGER,
    last_seen DATETIME
)
```

### Enhanced Tables

```sql
concepts (
    id INTEGER PRIMARY KEY,
    concept_type TEXT,
    title TEXT,
    description TEXT,
    importance INTEGER
)

reasoning (
    id INTEGER PRIMARY KEY,
    decision TEXT,
    why TEXT,
    outcome TEXT
)
```

### Cognitive Tables

```sql
intentions (
    id INTEGER PRIMARY KEY,
    goal TEXT,
    success BOOLEAN,
    learnings TEXT,
    time_spent INTEGER
)

knowledge (
    id INTEGER PRIMARY KEY,
    topic TEXT,
    insight TEXT,
    confidence INTEGER,
    source TEXT
)
```

## Extension Points

### Custom Providers

Create `providers/custom.sh`:

```bash
#!/usr/bin/env bash

tb::custom_export() {
    local context_file="${1:-.custom-context.md}"
    local query="$2"
    
    # Generate custom context
    tb::ai "$query" > "$context_file"
    
    # Add custom formatting
    echo "Custom context saved to $context_file"
}
```

### Custom Analyzers

Add to semantic analysis:

```bash
# In lib/semantic-custom.sh
tb::analyze_custom() {
    local cmd="$1"
    
    case "$cmd" in
        terraform*) echo "infrastructure" ;;
        kubectl*) echo "kubernetes" ;;
        *) tb::analyze_semantic "$cmd" ;;
    esac
}
```

### Hook Extensions

Add pre/post hooks:

```bash
# Custom preexec
tb::preexec_custom() {
    tb::preexec "$1"
    # Add custom logic
}

# Custom precmd
tb::precmd_custom() {
    tb::precmd
    # Add custom logic
}
```

## Best Practices

1. **Always escape SQL** - Use `tb::escape_sql`
2. **Check safety** - Use `tb::is_safe_to_record`
3. **Handle errors** - Check return codes
4. **Be async** - Use background processes for heavy work
5. **Respect privacy** - Honor `TERMBRAIN_PAUSED`

## Examples

### Custom Command

```bash
tb::my_command() {
    local query="$1"
    
    # Query database
    local results=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT command, COUNT(*) as count
        FROM commands
        WHERE command LIKE '%$query%'
        GROUP BY command
        ORDER BY count DESC
        LIMIT 10;
    ")
    
    echo "Top commands matching '$query':"
    echo "$results"
}
```

### Custom Pattern

```bash
tb::detect_my_pattern() {
    # Find custom patterns
    sqlite3 "$TERMBRAIN_DB" "
        INSERT OR REPLACE INTO patterns (pattern_type, frequency)
        SELECT 'my-pattern', COUNT(*)
        FROM commands
        WHERE command LIKE 'my-specific%';
    "
}
```