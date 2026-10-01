#!/usr/bin/env python3
"""Copy the newest completed iwinv backup to this Mac, checking its checksum."""
import hashlib
import os
from pathlib import Path
import re
import subprocess

KEY = Path.home() / '.ssh/alfinder_iwinv_20261001'
DEST = Path.home() / '.config/alfinder/backups/iwinv/offsite'
SSH = ['ssh', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-i', str(KEY),
       'root@49.247.192.41']
DEST.mkdir(parents=True, exist_ok=True, mode=0o700)
os.chmod(DEST, 0o700)
result = subprocess.run(SSH + [
    "find /opt/alfinder/backups -maxdepth 1 \\( -name 'alfinder-*.dump' "
    "-o -name 'alfinder-*.dump.gz' \\) "
    "-printf '%f\\n' | sort -r | head -n 1"],
    check=True, capture_output=True, text=True)
name = result.stdout.strip()
if not name:
    raise SystemExit(0)
if not re.fullmatch(r'alfinder-\d{8}T\d{6}Z\.dump(?:\.gz)?', name):
    raise SystemExit('Unexpected backup filename')
target = DEST / name
if target.exists():
    raise SystemExit(0)
remote = '/opt/alfinder/backups/' + name
digest = subprocess.run(SSH + ['sha256sum ' + remote], check=True,
                        capture_output=True, text=True).stdout.split()[0]
if not re.fullmatch(r'[0-9a-f]{64}', digest):
    raise SystemExit('Invalid remote checksum')
partial = target.with_name(target.name + '.partial')
subprocess.run(['rsync', '-a', '--partial', '-e',
                f'ssh -o BatchMode=yes -o ConnectTimeout=10 -i {KEY}',
                'root@49.247.192.41:' + remote, str(partial)], check=True)
actual = hashlib.sha256()
with partial.open('rb') as stream:
    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
        actual.update(chunk)
if actual.hexdigest() != digest:
    raise SystemExit('Offsite backup checksum mismatch')
os.chmod(partial, 0o600)
partial.rename(target)
target.with_suffix('.json').write_text('{"sha256":"' + digest + '"}\n')
os.chmod(target.with_suffix('.json'), 0o600)
snapshots = [*DEST.glob('alfinder-*.dump'), *DEST.glob('alfinder-*.dump.gz')]
for old in sorted(snapshots, reverse=True)[3:]:
    old.unlink()
    old.with_suffix('.json').unlink(missing_ok=True)
print('Offsite backup verified: ' + name)
