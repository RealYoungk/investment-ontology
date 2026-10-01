#!/usr/bin/env python3
"""Create a complete logical backup of the running local ontology database.

Includes authentication and ingestion state. Never writes credentials to output.
The dump has its own consistent snapshot; this does not pause local ingestion.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
LOCAL = ROOT / 'investment_ontology_serverpod_server/.serverpod/development'
BIN = Path.home() / 'Library/Caches/serverpod/pg-binaries/16.13.0-r1/macos-arm64/bin'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--directory', type=Path,
                    default=Path.home() / '.config/alfinder/backups/iwinv')
args = parser.parse_args()
args.directory.mkdir(parents=True, exist_ok=True, mode=0o700)
os.chmod(args.directory, 0o700)
stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
dump = args.directory / f'local-full-{stamp}.dump'
if dump.exists():
    raise SystemExit('Refusing to overwrite a backup.')
with tempfile.TemporaryDirectory(prefix='alfinder-full-') as temporary:
    socket = Path(temporary) / 's'
    socket.symlink_to(LOCAL / 'run', target_is_directory=True)
    env = os.environ.copy()
    env.update(PGHOST=str(socket), PGPORT='5432', PGUSER='postgres',
               PGDATABASE='investment_ontology_serverpod',
               PGPASSWORD=(LOCAL / 'postgres.password').read_text().strip(),
               PGOPTIONS='-c default_transaction_read_only=on')
    old_mask = os.umask(0o077)
    try:
        subprocess.run([str(BIN / 'pg_dump'), '--format=custom', '--no-owner',
                        '--no-privileges', '--file', str(dump)], env=env, check=True)
        subprocess.run([str(BIN / 'pg_restore'), '--list', str(dump)],
                       check=True, stdout=subprocess.DEVNULL)
    except Exception:
        dump.unlink(missing_ok=True)
        raise
    finally:
        os.umask(old_mask)
digest = hashlib.sha256()
with dump.open('rb') as stream:
    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
        digest.update(chunk)
manifest = {'createdUtc': stamp, 'database': 'investment_ontology_serverpod',
            'includesAuth': True, 'bytes': dump.stat().st_size,
            'sha256': digest.hexdigest(), 'restoreTested': False,
            'note': 'Local writes continued; a final backup is required at cutover.'}
manifest_file = dump.with_suffix('.json')
manifest_file.write_text(json.dumps(manifest, indent=2) + '\n')
os.chmod(manifest_file, 0o600)
print(json.dumps({'dump': str(dump), **manifest}, indent=2))
