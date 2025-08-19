# Migration from Bash to Rust

## For Users

The Rust version is designed to be a drop-in replacement:

1. **Database Compatible** - Same SQLite schema, no data migration needed
2. **Command Compatible** - All `tb` commands work identically
3. **Config Compatible** - Same config file format and location

### Installation

```bash
# Backup existing data (optional)
tb export json ~/termbrain-backup.json

# Install Rust version
curl -sSL https://raw.githubusercontent.com/anivar/termbrain/rust-rewrite/install.sh | bash

# Your data and workflows are preserved!
```

## For Contributors

### Key Differences

**Bash Version:**
- 77 shell scripts
- Source-based execution
- Runtime interpretation

**Rust Version:**
- Single binary
- Compiled execution
- Static type checking

### Architecture Mapping

| Bash | Rust |
|------|------|
| `lib/domain/entities/*.sh` | `src/domain/entities/mod.rs` |
| `lib/domain/repositories/*.sh` | `src/domain/repositories/mod.rs` |
| `lib/application/commands/*.sh` | `src/application/use_cases/*.rs` |
| `lib/infrastructure/repositories/*.sh` | `src/infrastructure/persistence/*.rs` |
| `lib/presentation/*.sh` | `src/presentation/cli.rs` |

### Development Workflow

1. Each bash module maps to a Rust module
2. Shell functions become Rust methods
3. Global variables become struct fields
4. Pipes become iterators/streams

### Testing Strategy

- Unit tests for each module
- Integration tests for workflows
- Property-based tests for parsers
- Benchmarks for performance claims