"""Read-only independent aggregation of real browser evidence (never dispatches visits)."""
import collections
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'tmp/business-universe-audit-2026-10-13')
run = root / (sys.argv[2] if len(sys.argv) > 2 else 'ui-all-final')
read = lambda p: json.loads(p.read_text())
excluded = {x['corpCode'] for x in read(root / 'inventory.json')['unmatchedCompanies']}
targets = {x['corpCode'] for x in read(root / 'universe.json') if x['corpCode'] not in excluded}
attempts = [json.loads(line) for line in (run / 'ledger.jsonl').read_text().splitlines() if line]
corrections_path = run / 'infrastructure-corrections.json'
corrections = {(x['corpCode'], x['originalEndedAt']): x for x in read(corrections_path)} if corrections_path.exists() else {}
for row in attempts:
    correction = corrections.get((row['corpCode'], row.get('endedAt')))
    if correction:
        row.update(status=correction['status'], visited=False, infrastructureCorrection=correction['reason'])
latest = {x['corpCode']: x for x in attempts}
actual = {code: x for code, x in latest.items() if x.get('visited') is True}
gates = ['sourceProvenanceMatched', 'sourceCardsRendered', 'scrollExhausted', 'nativeFinalScanExhausted', 'allNativeAccordionsExpanded', 'allPresentTabsPassed']
failures = []
for code, row in latest.items():
    reasons = []
    if code not in targets:
        reasons.append('outside-target-inventory')
    if row.get('status') != 'pass' or row.get('visited') is not True:
        reasons.append('not-an-actual-pass')
    reasons.extend(g for g in gates if row.get(g) is not True)
    for field in ['sourceTableTitlesUnseen', 'nativeAccordionsUnopened', 'frameworkErrors', 'pageErrors', 'consoleErrors']:
        if row.get(field):
            reasons.append(field)
    if row.get('liveSourceProvenance') != row.get('goldenSourceProvenance'):
        reasons.append('source-provenance-mismatch')
    for tab in row.get('tabs', []):
        if tab.get('present') and (tab.get('status') != 'pass' or not tab.get('headingConfirmed')):
            reasons.append('tab:' + tab['name'])
    for trace in row.get('sourceAccordionTrace', []):
        if not trace.get('contentMounted'):
            reasons.append('accordion-not-mounted')
    files = [row.get('snapshot')] + [t.get('snapshot') for t in row.get('tabs', []) if t.get('present')]
    if any(not f or not pathlib.Path(f).is_file() for f in files):
        reasons.append('missing-snapshot')
    if reasons:
        failures.append({'corpCode': code, 'name': row.get('name'), 'reasons': sorted(set(reasons))})
source_proof = read(run / 'source-fingerprint-final.json') if (run / 'source-fingerprint-final.json').exists() else None
physical_end_proof_count = sum(all(any(p.get('scan') == scan and p.get('before') == p.get('after') for p in x.get('physicalEndPaintProof', [])) for scan in ['primary', 'verification']) for x in latest.values())
result = {
    'physicalEndPaintProofCount': physical_end_proof_count,
    'actualFailureCount': sum(x['corpCode'] in actual for x in failures),
    'scope': 'actual business source cards and every present company tab',
    'targetCount': len(targets), 'excludedCount': len(excluded), 'attemptCount': len(attempts),
    'latestUniqueCount': len(latest), 'latestActualVisitedCount': len(actual), 'infrastructureErrorCount': sum(x.get('status') == 'infrastructure-error' for x in latest.values()), 'latestActualPassCount': sum(x.get('status') == 'pass' and x.get('visited') is True for x in latest.values()),
    'unvisitedCorpCodes': sorted(targets - actual.keys()), 'failures': failures,
    'gatePassCounts': {g: sum(x.get(g) is True for x in latest.values()) for g in gates},
    'presentTabPassCounts': dict(collections.Counter(t['name'] for x in latest.values() for t in x.get('tabs', []) if t.get('present') and t.get('status') == 'pass')),
    'harnessVersionCounts': dict(collections.Counter(x.get('harnessFingerprint', 'historical-record-no-inline-sha') for x in latest.values())),
    'sourceVersionCounts': dict(collections.Counter(x.get('sourceTreeFingerprint', 'historical-record-run-manifest') for x in latest.values())),
    'ledgerSha256': hashlib.sha256((run / 'ledger.jsonl').read_bytes()).hexdigest(), 'sourceFingerprintProof': source_proof,
}
result['complete'] = set(latest) == targets and physical_end_proof_count == len(targets) and not failures and bool(source_proof and source_proof.get('stable') and all(x.get('sourceTreeFingerprint') == source_proof.get('initial') for x in latest.values()) and source_proof.get('endedAt', '') >= max((x.get('endedAt', '') for x in latest.values()), default=''))
(run / 'independent-aggregate.json').write_text(json.dumps(result, ensure_ascii=False, indent=2))
print(json.dumps({'actualFailureCount': result['actualFailureCount'], 'infrastructureErrorCount': result['infrastructureErrorCount'], **{k: result[k] for k in ['complete', 'targetCount', 'latestUniqueCount', 'latestActualPassCount', 'physicalEndPaintProofCount', 'failures'] if k != 'failures'}}, ensure_ascii=False))
