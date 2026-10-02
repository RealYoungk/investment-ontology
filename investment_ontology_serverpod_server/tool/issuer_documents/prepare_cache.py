#!/usr/bin/env python3
"""Offline evidence preparation; no network, DB, imports or license claims.
Usage: prepare_cache.py manifest.json --cache-dir PATH
Manifest: list of {metadata: issuerDocuments row, pdfPath, textPath}.
PDF SHA and both printed evidence quotes must match before immutable local copy.
The deployment pipeline must supply an internal cache directory (not web assets).
"""
import argparse, hashlib, json, pathlib, re, shutil

def prepare(manifest, cache):
    result = []
    for item in manifest:
        row = item['metadata']
        raw = pathlib.Path(item['pdfPath']).read_bytes()
        text = pathlib.Path(item['textPath']).read_text()
        sha = hashlib.sha256(raw).hexdigest()
        if not raw.startswith(b'%PDF-') or sha != row['sha256']:
            raise ValueError('PDF bytes/SHA mismatch')
        if any(not isinstance(row.get(k), str) or not row[k] or
               row[k] not in text for k in ['issuerQuote', 'periodQuote']):
            raise ValueError('printed evidence quote missing')
        if row['numericState'] != 'notExtracted' or row['financialValues'] is not None:
            raise ValueError('numeric extraction not supported')
        if row['publicContent'] != 'linkOnly':
            raise ValueError('no PDF redistribution assertion')
        target = cache / (sha + '.pdf')
        if target.exists() and target.read_bytes() != raw:
            raise ValueError('immutable cache collision')
        cache.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            with target.open('xb') as output:
                output.write(raw)
        result.append(row)
    return result

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('manifest', type=pathlib.Path)
    p.add_argument('--cache-dir', type=pathlib.Path, required=True)
    a = p.parse_args()
    print(json.dumps(prepare(json.loads(a.manifest.read_text()), a.cache_dir), ensure_ascii=False, indent=2))
