# 🦀 Termbrain Rust Rewrite

This is the Rust rewrite of termbrain, bringing 10x performance improvements and single-binary distribution.

## 🚧 Status: In Development

The Rust version is currently being developed on the `rust-rewrite` branch.

### Why Rust?

- **Single Binary** - No more 77 shell scripts, just one executable
- **Performance** - 10x faster startup and execution
- **Cross-Platform** - True Windows/macOS/Linux support
- **Type Safety** - Catch bugs at compile time
- **Future-Ready** - Can embed AI models directly

### Architecture

Following the same clean architecture as the bash version:

```
src/
├── domain/         # Core business logic
├── application/    # Use cases
├── infrastructure/ # External services
└── presentation/   # CLI interface
```

### Progress

- [x] Project structure
- [x] Domain entities
- [x] Repository traits
- [ ] SQLite implementation
- [ ] CLI commands
- [ ] Shell integration
- [ ] Migration from v1
- [ ] Predictive features
- [ ] AI context generation

### Building

```bash
cargo build --release
```

### Testing

```bash
cargo test
```

### Benchmarks

Coming soon - targeting:
- Startup time: <5ms (vs 44ms)
- Search time: <10ms (vs 100ms)
- Memory usage: <10MB (vs 50MB)