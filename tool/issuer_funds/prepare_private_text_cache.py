#!/usr/bin/env python3
"""Local only: verify exact PDF, then prepare immutable complete-text private cache.
Cloud requires neither Python nor Poppler. No network or database writes.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from extract_mapps import extract_pdf

def prepare(pdf, cache):
    result = extract_pdf(pdf)
    version = subprocess.run(['pdftotext', '-v'], capture_output=True, check=True).stderr.decode().splitlines()[0]
    if version != 'pdftotext version 26.02.0':
        raise ValueError('Pinned extraction tool version required')
    text = subprocess.check_output(['pdftotext', '-layout', '-enc', 'UTF-8', str(pdf), '-'])
    if hashlib.sha256(text).hexdigest() != result['extractedTextSha256']:
        raise ValueError('Extraction bytes changed between reads')
    cache.mkdir(parents=True, exist_ok=True)
    original = pdf.read_bytes()
    if hashlib.sha256(original).hexdigest() != result['sha256']:
        raise ValueError('Original PDF changed during preparation')
    for ext, raw in [('pdf', original), ('fund.txt', text)]:
        target = cache / (result['sha256'] + '.' + ext)
        if target.exists() and target.read_bytes() != raw:
            raise ValueError('Immutable private cache collision')
        if not target.exists():
            with target.open('xb') as f:
                f.write(raw)
            target.chmod(0o600)
    return {'sha256': result['sha256'], 'extractedTextSha256': result['extractedTextSha256'],
            'periodEnd': result['periodEnd'], 'numericState': result['numericState'],
            'toolVersion': version, 'privateOnly': True}

if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('pdf', type=Path)
    p.add_argument('--cache-dir', type=Path, required=True)
    a = p.parse_args()
    print(json.dumps(prepare(a.pdf.resolve(strict=True), a.cache_dir), ensure_ascii=False))
