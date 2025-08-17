#!/usr/bin/env bash
# Simple docker test runner

docker run --rm -v "$PWD":/workspace -w /workspace ubuntu:22.04 bash -c "
    apt-get update -qq && apt-get install -y -qq shellcheck sqlite3 jq >/dev/null 2>&1
    echo 'Running tests in Docker...'
    ./tests/run_tests.sh
"