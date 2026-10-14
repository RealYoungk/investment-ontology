"""Read captured public DocumentFacts; never collect or mutate any data.

Strict lexical evidence check identifies malformed joined numbers separately
from unmatched values. A numerical match alone is not proof of correct scope,
period, unit, or column. Ratio candidates are checked, never blindly exempted.
"""
import argparse, collections, hashlib, json, math, pathlib, re

STRICT = re.compile(r'^[+-]?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?$')
TOKEN = re.compile(r'[+\-△▲−]?\d[\d,.]*')
SCALAR = re.compile(r'^\(?[+\-△▲−]?\d[\d,.]*\)?%?$')


def normalize(s):
    return s.replace('△', '-').replace('▲', '-').replace('−', '-')


def same(a, b):
    return math.isfinite(a) and math.isfinite(b) and abs(a-b) <= max(1e-7, abs(b)*1e-12)


def evidence_numbers(text):
    valid, malformed = [], []
    for match in TOKEN.finditer(text):
        token = normalize(match.group()).rstrip('.')
        if match.start() > 0 and text[match.start()-1] == '(' and text[match.end():match.end()+1] == ')':
            token = '-'+token.lstrip('+')
        if STRICT.fullmatch(token):
            valid.append(float(token.replace(',', '')))
        else:
            if text[match.end():match.end()+1] == '%' and re.fullmatch(r'[+-]?\d+,\d{1,2}', token):
                valid.append(float(token.replace(',', '.')))
            try:
                number = float(token.replace(',', ''))
            except ValueError:
                continue
            malformed.append((match.group(), number))
    return valid, malformed


def audit(root):
    facts, files = {}, 0
    for path in sorted((root/'api-capture').glob('*/disclosure-factTrends.json')):
        files += 1
        try:
            content = json.loads(path.read_text())
        except (ValueError, OSError):
            continue
        if not isinstance(content, list):
            continue
        for fact in content:
            if not isinstance(fact, dict):
                continue
            key = fact.get('id') or (path.parent.name, fact.get('documentId'), fact.get('kind'), fact.get('label'), fact.get('asOf'), fact.get('value'))
            facts[key] = (path.parent.name, fact)
    counters = collections.Counter()
    findings = []
    for corp, fact in facts.values():
        value, evidence = fact.get('value'), fact.get('evidence', '')
        if not isinstance(value, (int, float)) or not math.isfinite(value):
            counters['nonfinite'] += 1
            findings.append({'corpCode': corp, 'classification': 'nonfinite', 'fact': fact})
            continue
        valid, malformed = evidence_numbers(evidence)
        if any(same(value, v) for v in valid):
            counters['strictEvidenceLiteral'] += 1
            continue
        bad = [token for token, v in malformed if same(value, v)]
        if bad:
            classification = 'malformedMergedLiteralMatchesStoredValue'
        else:
            # A candidate equation is recorded but is not accepted as verified:
            # source header and numerator/denominator mapping still need review.
            ratio = fact.get('unit') == '%' and any(
                b != 0 and abs(a/b*100-value) <= 0.11
                for a in valid for b in valid if a != b)
            classification = 'ratioEquationCandidateNeedsSourceMapping' if ratio else 'noStrictEvidenceLiteral'
        counters[classification] += 1
        findings.append({'corpCode': corp, 'classification': classification, 'malformedMatches': bad, 'fact': fact})
    return {'capturedCompanies': files, 'uniqueFacts': len(facts), 'counts': dict(counters), 'findings': findings,
            'scopeLimit': 'Literal matches establish lexical numeric support only; source column, unit, period and entity scope require separate validation.'}


def source_crosscheck(result, corpus):
    # Evidence for vertical production facts sometimes includes only the last
    # utilization row. Check the stored document, retaining an explicit warning
    # that mere presence does not prove the right column/period.
    pending = collections.defaultdict(list)
    for finding in result['findings']:
        if finding['classification'] == 'noStrictEvidenceLiteral':
            pending[finding['fact'].get('documentId')].append(finding)
    counts = collections.Counter(); examples = []; docs = 0
    for line in corpus.open():
        doc = json.loads(line); docs += 1; text = doc['text']
        for row in text.splitlines():
            if '|' not in row:
                continue
            for cell in row.split('|'):
                scalar = normalize(cell.strip()).strip('()%')
                if SCALAR.fullmatch(cell.strip()) and ',' in scalar and not STRICT.fullmatch(scalar):
                    if cell.strip().endswith('%') and re.fullmatch(r'[+-]?\d+,\d{1,2}', scalar):
                        counts['explicitPercentCommaDecimalCells'] += 1
                        continue
                    counts['malformedNumericCells'] += 1
                    if len(examples) < 100:
                        examples.append({'documentId': doc['documentId'], 'corpCode': doc['corpCode'], 'name': doc['name'], 'cell': cell.strip(), 'row': row})
        candidates = pending.get(doc['documentId'])
        if not candidates:
            continue
        valid, _ = evidence_numbers(text)
        for finding in candidates:
            value = finding['fact']['value']
            if any(same(value, v) for v in valid):
                finding['sourceDocumentLiteralPresent'] = True
                finding['assessment'] = 'literalPresentElsewhereOnlyNeedsSourceColumnMapping'
                counts['missingEvidenceLiteralPresentInStoredDocument'] += 1
            else:
                finding['sourceDocumentLiteralPresent'] = False
                counts['valueAbsentFromStrictDocumentLiterals'] += 1
                evidence_values, _ = evidence_numbers(finding['fact'].get('evidence', ''))
                kind = finding['fact'].get('kind', '')
                if kind == 'orderTotal' and any(same(a+b, value) for a in evidence_values for b in evidence_values):
                    finding['computedCheck'] = 'twoPrintedAmountsSumMatchesNeedsFlowHeaderMapping'
                    finding['assessment'] = 'unknownSourceMappingNotEstablished'
                elif value == 0 and '|' in finding['fact'].get('evidence', '') and any(c.strip() == '-' for c in finding['fact']['evidence'].split('|')):
                    finding['computedCheck'] = 'zeroWithDashPlaceholderNeedsDisclosureMeaning'
                else:
                    finding['computedCheck'] = 'unresolvedSourceValue'
                    finding['assessment'] = 'unknownSourceMappingNotEstablished'
                counts[finding['computedCheck']] += 1
    result['corpusChecks'] = {'documents': docs, 'counts': dict(counts), 'malformedCellExamples': examples}
    return result


def apply_order_row_proofs(result, path):
    if not path.exists():
        result['orderSourceProofs'] = {'available': False}
        return result
    metadata = json.loads(path.read_text())
    parser = pathlib.Path(__file__).resolve().parents[2]/'investment_ontology_serverpod_server/lib/src/ontology/disclosure/order_facts.dart'
    if metadata.get('parserSha256') != hashlib.sha256(parser.read_bytes()).hexdigest():
        result['orderSourceProofs'] = {'available': False, 'reason': 'parserChangedProofNeedsRefresh'}
        return result
    for filename, expected in metadata.get('dependencySha256', {}).items():
        dependency = parser.parent/filename
        if not dependency.exists() or hashlib.sha256(dependency.read_bytes()).hexdigest() != expected:
            result['orderSourceProofs'] = {'available': False, 'reason': 'dependencyChangedProofNeedsRefresh', 'file': filename}
            return result
    proofs = metadata['documents']; counts = collections.Counter()
    fields = {'orderTotal': 'total', 'orderDelivered': 'delivered', 'orderBacklog': 'backlog'}
    for finding in result['findings']:
        fact = finding['fact']; field = fields.get(fact.get('kind'))
        if not field:
            continue
        exact_rows = [row for row in proofs.get(str(fact.get('documentId')), [])
                      if row['unit'] == fact.get('unit') and
                      row['evidence'].strip() == fact.get('evidence', '').strip() and
                      same(row[field], fact['value'])]
        if exact_rows:
            finding['orderRowMappingProof'] = exact_rows
            finding['assessment'] = 'validatedByCurrentOrderParserExactSourceRow'
            counts[field] += 1
        elif finding.get('computedCheck'):
            finding['assessment'] = 'unknownSourceMappingNotEstablished'
    result['orderSourceProofs'] = {'available': True, 'matchedFields': dict(counts),
                                 'method': 'current OrderFacts.verifiedRows exact evidence/unit/selected column'}
    return result


def compare_before(before_path, root):
    before = json.loads(before_path.read_text())
    targets = [f for f in before['findings']
               if f['classification'] == 'malformedMergedLiteralMatchesStoredValue']
    cache = {}; results = []; counts = collections.Counter()
    for target in targets:
        corp = target['corpCode']; old = target['fact']
        if corp not in cache:
            path = root/'api-capture'/corp/'disclosure-factTrends.json'
            cache[corp] = json.loads(path.read_text()) if path.exists() else None
        after = cache[corp]
        key = lambda f: (f.get('kind'), (f.get('asOf') or '').replace('.000Z', 'Z'))
        candidates = [] if after is None else [f for f in after if key(f) == key(old)]
        literal_matches = [f for f in candidates if f.get('unit') == old.get('unit') and
                           any(same(f['value'], n) for n in evidence_numbers(f.get('evidence', ''))[0])]
        if after is None:
            status = 'captureUnavailable'
        elif not candidates:
            status = 'removed'
        elif any(same(f['value'], old['value']) for f in literal_matches):
            status = 'validated-retained'
        elif literal_matches and not any(same(f['value'], old['value']) for f in candidates):
            status = 'corrected'
        else:
            status = 'unknownNeedsSourceMapping'
        counts[status] += 1
        results.append({'corpCode': corp, 'kind': old['kind'], 'asOf': old.get('asOf'),
                        'beforeId': old.get('id'), 'beforeDocumentId': old.get('documentId'),
                        'beforeValue': old['value'], 'beforeMalformed': target.get('malformedMatches'),
                        'status': status, 'after': candidates,
                        'validationScope': 'strict literal and matching corp/kind/asOf; source column/period mapping is separate'})
    return {'beforeTargets': len(targets), 'counts': dict(counts), 'results': results}


def compare_order_carryforward(root):
    path = root/'order-projection-all-audit-before-final-immutable.json'
    if not path.exists():
        path = root/'order-projection-all-audit.json'
    if not path.exists():
        return {'available': False}
    before = json.loads(path.read_text()); cache = {}; results = []; counts = collections.Counter()
    for old in before['results']:
        corp = old['corpCode']
        if corp not in cache:
            source = root/'api-capture'/corp/'disclosure-factTrends.json'
            cache[corp] = json.loads(source.read_text()) if source.exists() else None
        after = cache[corp]
        candidates = [] if after is None else [f for f in after if f.get('id') == old['factId']]
        if not candidates and after is not None:
            candidates = [f for f in after if f.get('documentId') == old['documentId'] and
                          f.get('kind') == old['kind'] and f.get('evidence', '').strip() == old['evidence'].strip()]
        expected = old.get('projectedValue')
        if after is None:
            state = 'captureUnavailable'
        elif not candidates:
            state = 'removedOrCanonicalReplacement'
        elif expected is None:
            state = 'stillNumericDespiteNoSourceScalarProof'
        elif any(same(f['value'], expected) for f in candidates):
            state = 'expectedProjectedValuePresent'
        else:
            state = 'differentValueNeedsSourceMapping'
        counts[state] += 1
        results.append({'corpCode': corp, 'factId': old['factId'], 'documentId': old['documentId'],
                        'kind': old['kind'], 'beforeValue': old['storedValue'],
                        'sourceClassification': old['classification'], 'expectedValue': expected,
                        'state': state, 'after': candidates,
                        'sourceEvidencePresent': old.get('sourceEvidencePresent'),
                        'scopeLimit': 'Removal may reflect canonical source selection; original source-row proof is retained separately.'})
    return {'beforeTargets': before['selectedFacts'], 'counts': dict(counts), 'results': results}


def compare_market_share_carryforward(root):
    path = root/'market-share-api-source-comparison-before-refresh.json'
    proof_path = root/'market-share-current-parser-proofs.json'
    if not path.exists() or not proof_path.exists():
        return {'available': False}
    before = json.loads(path.read_text()); proof = json.loads(proof_path.read_text()); cache = {}; results = []; counts = collections.Counter()
    reviewed_path = root/'market-share-remaining35-source-classification.json'
    reviewed = {c['factId']: c for c in json.loads(reviewed_path.read_text())['cases']} if reviewed_path.exists() else {}
    for old in before['facts']:
        corp = old['corpCode']
        if corp not in cache:
            source = root/'api-capture'/corp/'disclosure-factTrends.json'
            cache[corp] = json.loads(source.read_text()) if source.exists() else None
        after = cache[corp]
        candidates = [] if after is None else [f for f in after if f.get('id') == old['factId']]
        if after is None:
            state = 'captureUnavailable'
        elif not candidates:
            state = 'removedOrCanonicalReplacement'
        else:
            rows = proof['rowsByDocument'].get(str(old['documentId']), [])
            valid = any(not row['holding'] and any(row['evidence'].strip() == f.get('evidence','').strip()
                        and same(row['value'], f['value']) for f in candidates) for row in rows)
            state = 'currentParserExactRowAndValue' if valid else 'unresolvedUnsupportedOrScopeMismatch'
        review = reviewed.get(old['factId'])
        if review:
            if candidates and review['sourceClassification'].endswith('Preserve'):
                state = 'sourceReviewedSupportedOrExplicitRelativeScopePreserved'
            elif not candidates and review['sourceClassification'].endswith('RawOnly'):
                state = 'sourceHoldingScopePolicyRawOnlyNotNumericError'
        counts[state] += 1
        results.append({**old, 'state': state, 'after': candidates,
                        'sourceReview': review})
    return {'beforeTargets': len(before['facts']), 'counts': dict(counts), 'results': results,
            'scopeLimit': 'Row/value proof and holding scope are checked; date/label/source-account constraints are independent.'}


def compare_narrow_market_recovery(root):
    path = root/'market-share-narrow-recovery-candidates.json'
    if not path.exists():
        return {'available': False}
    targets = json.loads(path.read_text()); cache = {}; counts = collections.Counter(); results = []
    for doc in targets:
        corp = doc['corpCode']
        if corp not in cache:
            source = root/'api-capture'/corp/'disclosure-factTrends.json'
            cache[corp] = json.loads(source.read_text()) if source.exists() else None
        after = cache[corp]
        for row in doc['candidates']:
            matches = [] if after is None else [f for f in after if f.get('kind') == 'marketShare' and
                      f.get('documentId') == doc['documentId'] and f.get('unit') == '%' and
                      f.get('label') == row['label'] and f.get('evidence','').strip() == row['evidence'].strip() and
                      same(f['value'],row['value']) and (f.get('asOf') or '')[:4] == str(row['year'])]
            state = 'captureUnavailable' if after is None else 'exactSourceCandidatePublished' if matches else 'notPublishedOrCanonicalReplacement'
            counts[state] += 1
            results.append({'corpCode':corp,'documentId':doc['documentId'],'sourceReceipt':doc['receipt'],
                            'candidate':row,'state':state,'after':matches,
                            'scopeLimit':'Narrow numeric-row-as-header recovery; canonical filing selection may replace repeated historical rows.'})
    return {'sourceCandidates':len(results),'counts':dict(counts),'results':results}


def compare_known_market_scope_failures(root):
    path = root/'market-share-other-company-candidates.json'
    if not path.exists():
        return {'available': False}
    before = json.loads(path.read_text()); cache = {}; counts = collections.Counter(); results = []
    for candidate in before:
        old = candidate['fact']; corp = candidate['corpCode']
        if corp not in cache:
            source = root/'api-capture'/corp/'disclosure-factTrends.json'
            cache[corp] = json.loads(source.read_text()) if source.exists() else None
        after = cache[corp]
        present = [] if after is None else [f for f in after if f.get('id') == old.get('id') or
                  (f.get('kind') == 'marketShare' and f.get('documentId') == old['documentId'] and
                   f.get('evidence','').strip() == old['evidence'].strip())]
        state = 'captureUnavailable' if after is None else 'excludedFromParentVerifiedFacts' if not present else 'unexpectedScopeFailureStillPresent'
        counts[state] += 1
        results.append({'corpCode':corp,'beforeFactId':old.get('id'),'documentId':old['documentId'],
                        'otherCompany':candidate['first'],'state':state,'after':present})
    return {'beforeTargets':len(results),'counts':dict(counts),'results':results,
            'scope':'7 Daeju competitor facts and 3 Dongkuk holding-subsidiary parent facts; original source remains stored.'}


if __name__ == '__main__':
    p = argparse.ArgumentParser(); p.add_argument('--root', type=pathlib.Path, default=pathlib.Path('tmp/business-universe-audit-2026-10-13')); p.add_argument('--output', type=pathlib.Path); p.add_argument('--before', type=pathlib.Path)
    args = p.parse_args(); result = audit(args.root)
    corpus = args.root/'capture/corpus.jsonl'
    if corpus.exists():
        result = source_crosscheck(result, corpus)
    result = apply_order_row_proofs(result, args.root/'order-number-source-proofs.json')
    if args.before:
        result['beforeAfter'] = compare_before(args.before, args.root)
        result['orderCarryforward'] = compare_order_carryforward(args.root)
        result['marketShareCarryforward'] = compare_market_share_carryforward(args.root)
        result['narrowMarketRecovery'] = compare_narrow_market_recovery(args.root)
        result['knownMarketScopeFailures'] = compare_known_market_scope_failures(args.root)
    output = args.output or args.root/'fact-number-audit.json'
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2))
    print(json.dumps({k: v for k, v in result.items() if k not in {'findings', 'corpusChecks', 'beforeAfter', 'orderCarryforward', 'marketShareCarryforward', 'narrowMarketRecovery', 'knownMarketScopeFailures'}}, ensure_ascii=False))
