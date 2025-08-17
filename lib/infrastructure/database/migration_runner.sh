#!/usr/bin/env bash
# Database Migration Runner

MigrationRunner::init() {
    local db="$1"
    
    # Create migrations table
    sqlite3 "$db" "
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version TEXT PRIMARY KEY,
            applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    "
}

MigrationRunner::run_all() {
    local db="$1"
    local migrations_dir="${TERMBRAIN_LIB}/infrastructure/database/migrations"
    
    # Initialize migrations table
    MigrationRunner::init "$db"
    
    # Find all migration scripts
    for migration in "$migrations_dir"/*.sh; do
        [[ -f "$migration" ]] || continue
        
        local version=$(basename "$migration" .sh)
        
        # Check if already applied
        if MigrationRunner::is_applied "$db" "$version"; then
            continue
        fi
        
        echo "Applying migration: $version" >&2
        
        # Source and run migration
        source "$migration"
        if [[ $(Migration001::needed "$db") == "true" ]]; then
            Migration001::up "$db"
            MigrationRunner::mark_applied "$db" "$version"
        fi
    done
}

MigrationRunner::is_applied() {
    local db="$1"
    local version="$2"
    
    local count=$(sqlite3 "$db" "
        SELECT COUNT(*) FROM schema_migrations WHERE version = '$version';
    ")
    
    [[ "$count" -gt 0 ]]
}

MigrationRunner::mark_applied() {
    local db="$1"
    local version="$2"
    
    sqlite3 "$db" "
        INSERT INTO schema_migrations (version) VALUES ('$version');
    "
}

# Auto-run migrations when sourced
if [[ -n "$TERMBRAIN_DB" ]] && [[ -f "$TERMBRAIN_DB" ]]; then
    MigrationRunner::run_all "$TERMBRAIN_DB"
fi