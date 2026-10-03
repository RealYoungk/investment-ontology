"""Verify the pinned vendor source; do not reformat third-party source."""
import hashlib
import json
from pathlib import Path
root = Path(__file__).resolve().parent.parent / 'third_party/shad'
manifest = json.loads((root / 'SOURCE.json').read_text())
changed = []
for name, digest in manifest['baseline_dart_sha256'].items():
    if hashlib.sha256((root / name).read_bytes()).hexdigest() != digest:
        changed.append(name)
assert sorted(changed) == sorted(manifest['changed_files']), changed
assert len(list((root / 'lib').rglob('*.dart'))) == manifest['published_dart_files']
print('Pinned shad source verified; only documented input patch differs.')
