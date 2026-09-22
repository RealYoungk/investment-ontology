#!/usr/bin/env bash
# Serverpod 4 config still requires a database password when dataPath is used.
# This synthetic value is only for the isolated test database, never application auth.
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/investment_ontology_serverpod_server"
export SERVERPOD_PASSWORD_database=serverpod-isolated-test-only
exec dart test "$@"
