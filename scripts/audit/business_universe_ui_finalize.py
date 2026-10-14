"""Finalize existing real-browser evidence; no network or data mutation."""
import collections
import datetime
import hashlib
import json
import pathlib

root = pathlib.Path('tmp/business-universe-audit-2026-10-13')
run = root / 'ui-all-final'
aggregate = json.loads((run / 'independent-aggregate.json').read_text())
db = json.loads((run / 'db-after-ui.json').read_text())
baseline_db = json.loads((root / 'final-db-after.json').read_text())
proof = json.loads((run / 'source-fingerprint-final.json').read_text())
rows = [json.loads(line) for line in (run / 'ledger.jsonl').read_text().splitlines()]
latest = {row['corpCode']: row for row in rows}
digest = hashlib.sha256()
paths = sorted(str(p) for tree in ['investment_ontology_serverpod_flutter/lib', 'investment_ontology_serverpod_server/lib', 'investment_ontology_serverpod_client/lib'] for p in pathlib.Path(tree).rglob('*.dart'))
for path in paths:
    digest.update((path + '\n').encode())
    digest.update(pathlib.Path(path).read_bytes())
current_source = digest.hexdigest()
assert aggregate['complete'] and aggregate['latestActualPassCount'] == 2745
assert aggregate['actualFailureCount'] == aggregate['infrastructureErrorCount'] == 0
assert aggregate['physicalEndPaintProofCount'] == 2745
assert db == baseline_db
assert current_source == proof['initial'] == proof['final'] and proof['stable']
assert all(row['status'] == 'pass' and row.get('visited') and not row.get('consoleErrors') and not row.get('pageErrors') and not row.get('frameworkErrors') and row['sourceTreeFingerprint'] == current_source for row in latest.values())
inventory = json.loads((root / 'inventory.json').read_text())
manifest = {
    'status': 'FINAL_ACTUAL_UI_VERIFIED_COMPLETE',
    'completedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'scope': aggregate['scope'],
    'base': 'http://localhost:8100',
    'workers': 2,
    'maxCompaniesPerBrowserLifetime': 20,
    'targetCount': 2745,
    'actualVisitedPassCount': len(latest),
    'excludedCompanies': inventory['unmatchedCompanies'],
    'dbAfterUi': db,
    'dbMatchesFinalApiBaseline': True,
    'currentSourceTreeFingerprint': current_source,
    'sourceFingerprintProof': proof,
    'gatePassCounts': aggregate['gatePassCounts'],
    'presentTabPassCounts': aggregate['presentTabPassCounts'],
    'physicalEndPaintProofCount': aggregate['physicalEndPaintProofCount'],
    'finalActualFailureCount': 0,
    'finalInfrastructureErrorCount': 0,
    'harnessVersionCounts': aggregate['harnessVersionCounts'],
    'rawAttemptStatusCounts': dict(collections.Counter(row['status'] for row in rows)),
    'rawLedgerPreserved': True,
    'infrastructureCorrections': str(run / 'infrastructure-corrections.json'),
    'sourceEvidenceRecollected': False,
    'artifacts': {},
    'companies': [{'corpCode': row['corpCode'], 'name': row['name'], 'url': row['url'], 'endedAt': row['endedAt'], 'sourceTreeFingerprint': row['sourceTreeFingerprint'], 'harnessFingerprint': row['harnessFingerprint']} for row in sorted(latest.values(), key=lambda item: item['corpCode'])],
}
for name in ['ledger.jsonl', 'independent-aggregate.json', 'db-after-ui.json', 'source-fingerprint-final.json', 'run-manifest.json', 'infrastructure-corrections.json']:
    path = run / name
    manifest['artifacts'][name] = {'path': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
(run / 'final-ui-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({key: manifest[key] for key in ['status', 'actualVisitedPassCount', 'finalActualFailureCount', 'dbMatchesFinalApiBaseline', 'currentSourceTreeFingerprint']}))
