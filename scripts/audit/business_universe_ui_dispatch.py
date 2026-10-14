"""Bounded two-worker browser batches; preserves one authoritative append-only ledger."""
import collections
import hashlib
import json
import os
import pathlib
import subprocess
import sys
import time

root = pathlib.Path(os.environ.get('BUSINESS_UI_ROOT', 'tmp/business-universe-audit-2026-10-13'))
run_name = os.environ.get('BUSINESS_UI_RUN', 'ui-all-final')
run = root / run_name
run.mkdir(parents=True, exist_ok=True)
node = '/Users/realyoungk/.nvm/versions/node/v20.19.5/bin/node'
script = 'scripts/audit/business_universe_ui.cjs'
excluded = {x['corpCode'] for x in json.loads((root / 'inventory.json').read_text())['unmatchedCompanies']}
targets = {x['corpCode'] for x in json.loads((root / 'universe.json').read_text()) if x['corpCode'] not in excluded}
digest = hashlib.sha256()
paths = sorted(str(p) for tree in ['investment_ontology_serverpod_flutter/lib', 'investment_ontology_serverpod_server/lib', 'investment_ontology_serverpod_client/lib'] for p in pathlib.Path(tree).rglob('*.dart'))
for path in paths:
    digest.update((path + '\n').encode())
    digest.update(pathlib.Path(path).read_bytes())
source_fingerprint = digest.hexdigest()
batch = 0
while True:
    rows = [json.loads(line) for line in (run / 'ledger.jsonl').read_text().splitlines()] if (run / 'ledger.jsonl').exists() else []
    latest = {x['corpCode']: x for x in rows}
    done = {code for code, x in latest.items() if x['status'] == 'pass' and not x.get('consoleErrors') and x.get('sourceTreeFingerprint') == source_fingerprint and all(any(p.get('scan') == scan and p.get('before') == p.get('after') for p in x.get('physicalEndPaintProof', [])) for scan in ['primary', 'verification'])}
    if done == targets:
        print(json.dumps({'dispatcherComplete': True, 'actualPass': len(done), 'target': len(targets)}), flush=True)
        break
    before = len(rows)
    batch += 1
    stamp = time.strftime('%Y%m%d-%H%M%S')
    env = {**os.environ, 'BUSINESS_UI_ROOT': str(root), 'BUSINESS_UI_RUN': run_name, 'BUSINESS_UI_WORKERS': '2', 'BUSINESS_UI_LIMIT': '20'}
    log = run / f'batch-{stamp}-{batch}.log'
    print(json.dumps({'batch': batch, 'priorActualPass': len(done), 'remaining': len(targets-done), 'log': str(log)}), flush=True)
    with log.open('w') as output:
        result = subprocess.run([node, script], env=env, stdout=output, stderr=subprocess.STDOUT)
    rows = [json.loads(line) for line in (run / 'ledger.jsonl').read_text().splitlines()]
    fresh = rows[before:]
    counts = collections.Counter(x['status'] for x in fresh)
    print(json.dumps({'batchEnded': batch, 'exitCode': result.returncode, 'statuses': counts}), flush=True)
    proof = json.loads((run / 'source-fingerprint-final.json').read_text()) if (run / 'source-fingerprint-final.json').exists() else {}
    if result.returncode or not proof.get('stable') or proof.get('initial') != source_fingerprint or counts.get('infrastructure-error') or not counts.get('pass'):
        print(json.dumps({'dispatcherStopped': True, 'reason': 'Infrastructure/source stability/no progress needs diagnosis', 'log': str(log)}), flush=True)
        sys.exit(1)
