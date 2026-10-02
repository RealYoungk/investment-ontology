#!/usr/bin/env bash
# Serverpod 4 config still requires a database password when dataPath is used.
# This synthetic value is only for the isolated test database, never application auth.
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/investment_ontology_serverpod_server"
export SERVERPOD_PASSWORD_database=serverpod-isolated-test-only
if (( $# > 0 )); then
  exec dart test "$@"
fi

# Each test runner owns compiler temporaries until it exits. Sequential bounded
# runners limit retained kernels without deleting files or changing DB setup.
tracked_tests=()
enumeration_file="$(mktemp "${TMPDIR:-/tmp}/alfinder-server-test-list.XXXXXX")"
git -C "$project_root" ls-files -z -- 'investment_ontology_serverpod_server/test/*_test.dart' > "$enumeration_file"
while IFS= read -r -d '' path; do
  if [[ ! -f "$project_root/$path" ]]; then
    echo "Tracked server test missing: $path" >&2
    exit 1
  fi
  tracked_tests+=("${path#investment_ontology_serverpod_server/}")
done < "$enumeration_file"
if (( ${#tracked_tests[@]} == 0 )); then
  echo 'No tracked server tests found; refusing an empty full gate.' >&2
  exit 1
fi

tests=()
discovery_file="$(mktemp "${TMPDIR:-/tmp}/alfinder-server-test-discovery.XXXXXX")"
find test -type f -name '*_test.dart' -print0 > "$discovery_file"
while IFS= read -r -d '' path; do
  tests+=("$path")
done < "$discovery_file"
for tracked in "${tracked_tests[@]}"; do
  found=false
  for path in "${tests[@]}"; do
    if [[ "$path" == "$tracked" ]]; then found=true; break; fi
  done
  if [[ "$found" != true ]]; then
    echo "Server test omitted from enumeration: $tracked" >&2
    exit 1
  fi
done

batch_size=25
for (( start=0; start<${#tests[@]}; start+=batch_size )); do
  batch=("${tests[@]:start:batch_size}")
  echo "Server test batch $((start / batch_size + 1)): ${#batch[@]} files (${#tests[@]} total)"
  dart test "${batch[@]}"
done
