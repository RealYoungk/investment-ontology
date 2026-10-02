"""Read-only immutable candidate-byte validation; not runtime financial ingestion."""
import hashlib
import json
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'investment_ontology_serverpod_server'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def verify(entry):
    folder = ASSETS / entry['directory']
    raw = (folder / 'manifest.json').read_bytes()
    assert sha(raw) == entry['manifestSha256'], 'manifest digest'
    manifest = json.loads(raw)
    for field in ['targetReceipt', 'originalReceipt', 'corpCode', 'basis', 'year', 'sourceRole']:
        assert manifest[field] == entry[field], field
    assert manifest['periodStart'] == f"{entry['year']}-01-01"
    assert manifest['periodEnd'] == f"{entry['year']}-12-31"
    assert manifest['kind'] == 'annual'
    labels = {source['label'] for source in manifest['sources']}
    assert labels == ({'targetShell', 'originalShell', 'cover', 'primary', 'auditShell', 'audit'}
                      if entry['numeric'] else {'targetShell', 'originalShell', 'cover', 'primary'})
    for source in manifest['sources']:
        assert source['file'] == source['label'] + '.html'
        assert sha((folder / source['file']).read_bytes()) == source['sha256'], source['label']
        uri = urlsplit(source['url'])
        assert uri.scheme == 'https' and uri.netloc == 'dart.fss.or.kr'
        query = parse_qs(uri.query)
        assert all(len(values) == 1 for values in query.values())
        receipt = query['rcpNo'][0]
        expected = manifest['targetReceipt'] if source['label'] == 'targetShell' else manifest['originalReceipt']
        if source['label'] in {'audit', 'auditShell'}:
            expected = manifest['numericSourceReceipt'] if manifest['sourceRole'] in {'same_receipt_audit', 'corrected_audit'} else receipt
        assert receipt == expected, source['label'] + ' receipt'
        assert uri.path in {'/dsaf001/main.do', '/report/viewer.do'}
        if uri.path == '/report/viewer.do':
            assert set(query) == {'rcpNo', 'dcmNo', 'eleId', 'offset', 'length', 'dtd'}
            assert all(query[key][0].isdigit() for key in {'rcpNo', 'dcmNo', 'eleId', 'offset', 'length'})
            assert query['dtd'][0] in {'dart3.xsd', 'dart4.xsd'}
    if entry['numeric']:
        expected = (folder / 'expected-rows.json').read_bytes()
        assert sha(expected) == manifest['expectedRowsSha256']
        rows = json.loads(expected)
        assert len(rows) in {7, 8}
        assert all(row['account_id'] is None for row in rows)
        assert sum(row['sj_div'] == 'BS' for row in rows) == 3
    else:
        assert manifest['absenceLiteral'].strip()
    return {'receipt': entry['targetReceipt'], 'basis': entry['basis'], 'numeric': entry['numeric'],
            'byteVerified': True, 'runtimeIntegrated': False}


if __name__ == '__main__':
    entries = json.loads((ASSETS / 'assets/financial_source_cache/header18-candidates.json').read_text())
    assert len(entries) == 18
    assert len({(e['targetReceipt'], e['basis']) for e in entries}) == 18
    results = [verify(entry) for entry in entries]
    print(json.dumps({'packages': len(results), 'numeric': sum(e['numeric'] for e in results),
                      'absence': sum(not e['numeric'] for e in results), 'results': results}, ensure_ascii=False))
