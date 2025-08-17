#!/usr/bin/env bash
# Migration system entry point

source "${TERMBRAIN_LIB}/infrastructure/database/migration_runner.sh"

# Run migrations
Migrations::run() {
    MigrationRunner::run "$@"
}

# Export functions
export -f Migrations::run