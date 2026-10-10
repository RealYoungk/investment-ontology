#!/usr/bin/env bash
# Same validation for GitHub Actions and a clean, pinned local checkout.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -n "$(git status --porcelain --untracked-files=all)" ]]; then
  echo 'Release validation requires a clean checkout.' >&2
  exit 1
fi
export ALFINDER_BUILD_COMMIT
ALFINDER_BUILD_COMMIT="$(git rev-parse HEAD)"
flutter --version --machine | python3 -c 'import json,sys; version=json.load(sys.stdin)["frameworkVersion"]; assert version == "3.47.5", "Expected Flutter 3.47.5, got " + version'
flutter pub get --enforce-lockfile
python3 scripts/verify_shad_source.py
mkdir -p output
rm -f output/validation-results.json
check() { python3 scripts/check_cache.py --report output/validation-results.json -- "$@"; }
check dart analyze --fatal-infos
git ls-files -z '*.dart' | python3 -c 'import sys; paths=sys.stdin.buffer.read().split(b"\0"); excluded=(b"third_party/", b"investment_ontology_serverpod_client/", b"investment_ontology_serverpod_server/lib/src/generated/", b"investment_ontology_serverpod_server/test/integration/test_tools/"); sys.stdout.buffer.write(b"\0".join(p for p in paths if p and not p.startswith(excluded))+b"\0")' | xargs -0 dart format --output=none --set-exit-if-changed
check python3 -m unittest discover -s scripts/tests -v
check node --test investment_ontology_serverpod_flutter/test/web/*_test.cjs
check node --test deploy/cloudflare/worker.test.mjs
check bash scripts/test-server.sh
python3 scripts/check_cache.py --cwd investment_ontology_serverpod_flutter --report output/validation-results.json -- flutter test
bash scripts/test-billing-browser.sh
(cd investment_ontology_serverpod_flutter && flutter build web --release --no-web-resources-cdn --dart-define-from-file=../deploy/web-build-defines.json)
python3 scripts/prepare_public_web.py
python3 scripts/release_bundle.py
tar -czf output/web-release.tar.gz -C output/public-deploy .vercel/output manifest.json
