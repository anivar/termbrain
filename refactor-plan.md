# Termbrain Refactoring Plan

## Current State Analysis
- Monolithic `src/termbrain.sh` with 745 lines
- Mixed concerns (core, enhanced, cognitive, workflows)
- Tight coupling between layers
- Hard to test individual components

## Refactoring Strategy

### Phase 1: Extract Domain Layer
1. Create domain entities (Command, Workflow, Pattern)
2. Define repository interfaces
3. Extract business rules (semantic analysis, privacy)

### Phase 2: Build Infrastructure Layer
1. Move SQLite operations to adapters
2. Create repository implementations
3. Extract shell hook integrations

### Phase 3: Create Application Layer
1. Define use cases for each feature
2. Implement command handlers
3. Remove business logic from presentation

### Phase 4: Clean Presentation Layer
1. Simplify main entry point
2. Create command router
3. Add proper input validation

### Phase 5: Testing & Migration
1. Add tests for each layer
2. Create migration script
3. Update installation process

## Implementation Order

1. **Start with Workflows** (newest, cleanest feature)
   - Extract WorkflowEntity
   - Create WorkflowRepository interface
   - Implement SqliteWorkflowRepository
   - Create workflow use cases

2. **Then Core Command Recording**
   - Extract CommandEntity
   - Create CommandRepository
   - Move capture logic

3. **Finally, Complex Features**
   - AI context generation
   - Pattern detection
   - Statistics

## Success Criteria
- [ ] No file > 200 lines
- [ ] Each file has single responsibility
- [ ] All database access through repositories
- [ ] Business logic in domain layer only
- [ ] 80%+ test coverage
- [ ] Faster startup time

## Risks & Mitigation
- **Risk**: Breaking existing functionality
- **Mitigation**: Comprehensive tests before refactoring

- **Risk**: Over-engineering
- **Mitigation**: Start simple, iterate based on needs