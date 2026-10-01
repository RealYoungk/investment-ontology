#!/usr/bin/env bash
set -euo pipefail
# Prime the in-memory screener after boot/redeploy. This is a read-only loopback
# request, so it consumes no external traffic and never needs authentication keys.
curl --silent --show-error --fail --retry 3 --retry-all-errors --retry-delay 5 \
  --max-time 90 --resolve alfinder-api.49.247.192.41.sslip.io:443:127.0.0.1 \
  -H 'Content-Type: application/json' --data '{"limit":1}' \
  -o /dev/null https://alfinder-api.49.247.192.41.sslip.io/api/screen/list
