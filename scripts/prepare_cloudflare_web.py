#!/usr/bin/env python3
"""Convert a verified release artifact into a Pages upload; no source or secrets."""
import argparse
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def prepare(release: Path, output: Path):
    release = release.resolve()
    output = output.resolve()
    if output == release or release in output.parents or output in release.parents:
        raise ValueError('Input and output must be separate directories')
    if output.exists():
        raise ValueError('Output already exists; choose a fresh release directory')
    manifest = json.loads((release / 'manifest.json').read_text())
    payload = release / '.vercel/output'
    static = payload / 'static'
    files = sorted(path for path in static.rglob('*') if path.is_file())
    if not files or len(files) + 3 > 20000:
        raise ValueError('Pages file count limit exceeded or empty artifact')
    for path in files:
        if path.is_symlink() or path.stat().st_size > 25 * 1024 * 1024:
            raise ValueError('Unsafe or oversized asset')
        expected = manifest['files'].get(path.relative_to(payload).as_posix())
        if hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            raise ValueError('Release checksum mismatch: ' + path.name)
    if not (static / 'main.dart.js').is_file() or not (static / 'release.json').is_file():
        raise ValueError('Incomplete release')
    if (static / '404.html').exists():
        raise ValueError('404.html would disable Pages SPA fallback')
    shutil.copytree(static, output)
    for name in ['_worker.js', '_routes.json', '_headers']:
        shutil.copyfile(ROOT / 'deploy/cloudflare' / name, output / name)
    return {'commit': manifest['commit'], 'files': len(files) + 3, 'output': str(output)}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--release', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(prepare(args.release, args.output)))
