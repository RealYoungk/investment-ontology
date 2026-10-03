#!/usr/bin/env python3
"""Local only: verify exact PDF, then prepare immutable complete-text private cache.
Cloud requires neither Python nor Poppler. No network or database writes.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from infrastructure_proof import proof

def prepare(pdf, cache):
    result = proof(pdf)
    version = subprocess.run(['pdftotext', '-v'], capture_output=True, check=True).stderr.decode().splitlines()[0]
    if version != 'pdftotext version 26.02.0':
        raise ValueError('Pinned extraction tool version required')
    text = subprocess.check_output(['pdftotext', '-layout', '-enc', 'UTF-8', str(pdf), '-'])
    if hashlib.sha256(text).hexdigest() != result['rawTextSha256']:
        raise ValueError('Extraction bytes changed between reads')
    cache.mkdir(parents=True, exist_ok=True)
    original = pdf.read_bytes()
    if hashlib.sha256(original).hexdigest() != result['metadata']['sha256']:
        raise ValueError('Original PDF changed during preparation')
    for ext, raw in [('pdf', original), ('infrastructure.raw.txt', text)]:
        target = cache / (result['metadata']['sha256'] + '.' + ext)
        if target.exists() and target.read_bytes() != raw:
            raise ValueError('Immutable private cache collision')
        if not target.exists():
            with target.open('xb') as f:
                f.write(raw)
            target.chmod(0o600)
    return {'sha256': result['metadata']['sha256'], 'rawTextSha256': result['rawTextSha256'],
            'decodedTextSha256': result['decodedTextSha256'], 'decodedPages': result['decodedPages'],
            'textTransformation': result['textTransformation'], 'corpCode':result['metadata']['corpCode'],
            'officialUrl':result['metadata']['officialUrl'],
            'periodEnd': result['metadata']['periodEnd'], 'numericState': 'partialPrintedInfrastructureFundCategories',
            'toolVersion': version, 'privateOnly': True}

if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('pdf', type=Path)
    p.add_argument('--cache-dir', type=Path, required=True)
    a = p.parse_args()
    print(json.dumps(prepare(a.pdf.resolve(strict=True), a.cache_dir), ensure_ascii=False))
