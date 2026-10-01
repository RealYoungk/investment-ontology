#!/usr/bin/env bash
# Explicit local-only Serverpod environment; never modifies tracked config.
set -euo pipefail
billing_project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$billing_project_root"
mkdir -p output/private
python3 - <<'PY'
from pathlib import Path
import secrets,socket
for port in (9080,9081,9082,9190):
    check=socket.socket()
    try:check.bind(('127.0.0.1',port))
    except OSError:raise SystemExit(f'Port {port} is busy; stop the existing sandbox first.')
    finally:check.close()
p=Path('output/private/billing-sandbox.env')
if not p.exists():
    p.write_text(''.join(f'export SERVERPOD_PASSWORD_{name}={secrets.token_hex(48)}\n' for name in ('database','serviceSecret','jwtRefreshTokenHashPepper','jwtHmacSha512PrivateKey','emailSecretHashPepper')))
    p.chmod(0o600)
PY
# This file contains only synthetic local secrets, never merchant/live keys.
source output/private/billing-sandbox.env
export SERVERPOD_API_SERVER_PORT=9080 SERVERPOD_API_SERVER_PUBLIC_PORT=9080
export SERVERPOD_API_SERVER_PUBLIC_HOST=localhost
export SERVERPOD_INSIGHTS_SERVER_PORT=9081 SERVERPOD_INSIGHTS_SERVER_PUBLIC_PORT=9081
export SERVERPOD_WEB_SERVER_PORT=9082 SERVERPOD_WEB_SERVER_PUBLIC_PORT=9082
export SERVERPOD_DATABASE_HOST=localhost SERVERPOD_DATABASE_PORT=9190
export SERVERPOD_DATABASE_NAME=alfinder_billing_sandbox
export SERVERPOD_DATABASE_DATA_PATH=.serverpod/billing/pgdata
export SERVERPOD_REDIS_ENABLED=false
export SERVERPOD_FUTURE_CALL_EXECUTION_ENABLED=false
export SERVERPOD_ALLOWED_ORIGINS=http://localhost:9110,http://127.0.0.1:9110,http://localhost:9082,http://127.0.0.1:9082
exec serverpod start --no-flutter --no-tui -- --mode development --apply-migrations
