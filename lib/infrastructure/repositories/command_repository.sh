#!/usr/bin/env bash
# Command Repository Infrastructure Interface

# This file serves as a bridge to the concrete implementation
source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_command_repository.sh"

# Export all functions from SQLite implementation
export -f CommandRepository::save
export -f CommandRepository::find_by_id
export -f CommandRepository::search
export -f CommandRepository::get_recent
export -f CommandRepository::find_by_semantic_type
export -f CommandRepository::get_statistics
export -f CommandRepository::update
export -f CommandRepository::count
export -f CommandRepository::delete