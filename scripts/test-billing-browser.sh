#!/usr/bin/env bash
# Test-only bearer authentication and provider mock, isolated PostgreSQL.
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."
billing_fixture=$(mktemp /tmp/alfinder-browser-fixture.XXXXXX)
rm "$billing_fixture"
cleanup() { if [[ -n "${billing_fixture_pid:-}" ]]; then kill "$billing_fixture_pid" 2>/dev/null || true; fi; rm -f "$billing_fixture"; }
trap cleanup EXIT
export ALFINDER_BROWSER_FIXTURE="$billing_fixture"
export ALFINDER_BILLING_SANDBOX_ENABLED=true
export ALFINDER_BILLING_PROVIDER=toss
export TOSS_TEST_SECRET_KEY=test_sk_fixture TOSS_TEST_CLIENT_KEY=test_ck_fixture
export BILLING_ENCRYPTION_KEY=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
bash scripts/test-server.sh test/integration/billing_browser_fixture_test.dart > /tmp/alfinder-browser-fixture.log 2>&1 &
billing_fixture_pid=$!
for ((i=0;i<150;i++)); do
  if [[ -s "$billing_fixture" ]]; then break; fi
  if ! kill -0 "$billing_fixture_pid" 2>/dev/null; then cat /tmp/alfinder-browser-fixture.log; exit 1; fi
  sleep 0.2
done
if [[ ! -s "$billing_fixture" ]]; then cat /tmp/alfinder-browser-fixture.log; exit 1; fi
cd investment_ontology_serverpod_flutter
flutter test --platform chrome --dart-define-from-file="$billing_fixture" test/billing_browser_e2e_test.dart
wait "$billing_fixture_pid"
