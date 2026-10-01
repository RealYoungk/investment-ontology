#!/usr/bin/env bash
# Explicit local test-only renderer; synthetic auth, isolated DB, no real Google/PG.
set -euo pipefail
umask 077
cd "$(dirname "$0")/.."
fixture=$(mktemp /tmp/alfinder-native-fixture.XXXXXX)
rm "$fixture"
cleanup(){ if [[ -n "${fixture_pid:-}" ]]; then kill "$fixture_pid" 2>/dev/null || true; fi; rm -f "$fixture"; rm -rf output/private/ad-native-web; rm -f output/private/ad-native-build.log; }
trap cleanup EXIT
export ALFINDER_BROWSER_FIXTURE="$fixture" ALFINDER_BILLING_SANDBOX_ENABLED=true
export TOSS_TEST_SECRET_KEY=test_sk_fixture TOSS_TEST_CLIENT_KEY=test_ck_fixture
export BILLING_ENCRYPTION_KEY=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
bash scripts/test-server.sh test/integration/billing_browser_fixture_test.dart > /tmp/alfinder-native-fixture.log 2>&1 &
fixture_pid=$!
for ((i=0;i<300;i++));do [[ -s "$fixture" ]] && break; kill -0 "$fixture_pid" 2>/dev/null || exit 1; sleep .2;done
[[ -s "$fixture" ]]
mkdir -p output/private
if ! (cd investment_ontology_serverpod_flutter && flutter build web --debug --no-wasm-dry-run --dart-define-from-file="$fixture" -t tool/ad_membership_browser.dart --output=../output/private/ad-native-web) > output/private/ad-native-build.log 2>&1; then
  python3 -c "from pathlib import Path; print(chr(10).join(s for s in Path('output/private/ad-native-build.log').read_text().splitlines() if s.startswith('Error:')))"
  exit 1
fi
python3 -m http.server 9211 --bind 127.0.0.1 --directory output/private/ad-native-web
