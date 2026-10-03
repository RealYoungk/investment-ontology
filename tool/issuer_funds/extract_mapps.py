#!/usr/bin/env python3
"""Read-only extraction of six pinned Mapps audits; never posts database data.

PDF bytes must match the repository's reviewed official source. Printed fund
categories and actual fiscal durations stay distinct from industrial metrics.
"""
import argparse
from datetime import date
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / 'investment_ontology_serverpod_server/assets/issuer_documents/verified_fund_documents.json'
VERSION = 'mapps-own-audit-current-printed-fund-categories-v1'
NUMBER = re.compile(r'(?<![\w\d])(?:\(?-?\d{1,3}(?:,\d{3})+\)?|\(?-?\d+\)?|[-–])(?![\d\w.])')


def compact(value):
    return re.sub(r'\s+', '', value)


def integer(value):
    if value in ('-', '–'):
        return None
    if not re.fullmatch(r'\(?-?\d+(?:,\d{3})*\)?', value):
        raise ValueError('Non-integer printed amount')
    if value.startswith('(') != value.endswith(')'):
        raise ValueError('Unpaired printed sign')
    if value.startswith('('):
        return -int(value[1:-1].replace(',', ''))
    return int(value.replace(',', ''))


def date_text(value):
    d = date.fromisoformat(value)
    return f'{d.year}년{d.month}월{d.day}일'


def parse_current(metadata, text):
    if metadata['corpCode'] != '00600013' or metadata['documentType'] != 'auditReport':
        raise ValueError('Only reviewed own Mapps audits supported')
    start, end = metadata['periodStart'], metadata['periodEnd']
    if start != f'{end[:4]}-01-01' or end not in [f'{y}-12-31' for y in range(2021, 2026)] + ['2026-06-30']:
        raise ValueError('Unreviewed fiscal period')
    if len(text) > 4_000_000:
        raise ValueError('Oversized PDF text')
    sections = {}
    active = None
    for page_index, page in enumerate(text.split('\f'), 1):
        lines = page.splitlines()
        first = compact(next((x for x in lines if x.strip()), ''))
        if first in ('재무상태표', '손익계산서', '자본변동표', '현금흐름표'):
            if first in sections:
                raise ValueError('Ambiguous repeated primary statement')
            header = compact(page[:650])
            if compact(metadata['issuerQuote']) not in header or '(단위:원)' not in header:
                raise ValueError('Statement own issuer or printed won unit mismatch')
            required = date_text(end) + '현재' if first == '재무상태표' else date_text(start) + '부터' + date_text(end) + '까지'
            if required not in header:
                raise ValueError('Actual statement period mismatch')
            # The current period must precede its comparative header.
            current_match = re.search(r'제\d+기(\d{4}년\d+월\d+일)', header)
            if not current_match or current_match[1] != date_text(end if first == '재무상태표' else start):
                raise ValueError('Current/comparative order mismatch')
            active = first
            sections[first] = []
        elif first == '주석':
            active = None
        if active:
            sections[active].extend((page_index, i, line) for i, line in enumerate(lines, 1))
    if set(sections) != {'재무상태표', '손익계산서', '자본변동표', '현금흐름표'}:
        raise ValueError('Four own primary statements required')

    def cell(section, label, optional=False):
        matches = []
        for page_no, line_no, line in sections[section]:
            # Exact printed category, allowing a Roman numbering prefix and notes.
            amounts = list(NUMBER.finditer(line))
            if len(amounts) < 2:
                continue
            head = line[:amounts[-2].start()].strip()
            normalized = re.sub(r'^(?:[IVXivxⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩ]+[.．]?|\d+[.．])', '', compact(head))
            normalized = re.sub(r'^\(\d+\)', '', normalized)
            normalized = re.sub(r'\(주석[^)]*\)', '', normalized)
            if normalized != label:
                continue
            tokens = [m.group() for m in NUMBER.finditer(line)]
            if len(tokens) < 2:
                raise ValueError('Current and comparative monetary cells required')
            current, prior = tokens[-2:]
            matches.append({'statement': section, 'accountLabel': head,
                            'printedAmount': current, 'amountInteger': None if integer(current) is None else str(integer(current)),
                            'comparativePrintedAmount': prior, 'pageOrdinal': page_no,
                            'lineOrdinal': line_no, 'rawLine': line, 'currentColumn': 0,
                            'currency': 'KRW', 'printedUnit': '원', 'precisionUnit': '1'})
        if len(matches) != 1:
            if optional and not matches:
                return None
            raise ValueError(f'Ambiguous or missing primary {label}')
        return matches[0]

    observations = {}
    for metric, section, label in [
        ('assets', '재무상태표', '자산총계'), ('liabilities', '재무상태표', '부채총계'), ('equity', '재무상태표', '자본총계'),
        ('fundOperatingIncome', '손익계산서', '운용수익'), ('netProfit', '손익계산서', '당기순이익'),
        ('assetManagementCashFlow', '현금흐름표', '자산운용활동현금흐름'), ('investmentPropertyAcquisition', '현금흐름표', '부동산취득'),
    ]:
        value = cell(section, label)
        value.update(metric=metric, periodStart=end if section == '재무상태표' else start, periodEnd=end,
                     amountScope='stockAtPeriodEnd' if section == '재무상태표' else 'ownFiscalDuration',
                     cashDirection='outflow' if metric == 'investmentPropertyAcquisition' else None)
        observations[metric] = value
    if any(x['amountInteger'] is None for x in observations.values()):
        raise ValueError('Missing printed core fund category; no zero fabrication')
    values = {k: int(v['amountInteger']) for k, v in observations.items()}
    opening = cell('현금흐름표', '기초의현금')
    closing = cell('현금흐름표', '기말의현금')
    increase_labels = ['현금의증가(감소)(Ⅰ+Ⅱ+Ⅲ)', '현금의증가(Ⅰ+Ⅱ+Ⅲ)']
    increases = [v for label in increase_labels if (v := cell('현금흐름표', label, optional=True))]
    if len(increases) != 1:
        raise ValueError('Unique own current cash movement required')
    cash_difference = int(opening['amountInteger']) + int(increases[0]['amountInteger']) - int(closing['amountInteger'])
    balance_difference = values['assets'] - values['liabilities'] - values['equity']
    financing = cell('현금흐름표', '재무활동현금흐름')
    fx_candidates = [v for label in ['외화현금의환산차익', '외화현금의환산차(손)익']
                     if (v := cell('현금흐름표', label, optional=True))]
    if len(fx_candidates) != 1:
        raise ValueError('Unique directly printed cash FX required')
    activity_difference = values['assetManagementCashFlow'] + int(financing['amountInteger']) + int(fx_candidates[0]['amountInteger']) - int(increases[0]['amountInteger'])
    ce = sections['자본변동표']

    def ce_total(day, flag):
        marker = date_text(day) + f'({flag})'
        indices = [i for i, (_, _, line) in enumerate(ce) if compact(line).startswith(marker)]
        if len(indices) != 1:
            raise ValueError('Explicit unique own CE date marker required')
        i = indices[0]
        for j in range(i, min(i + 5, len(ce))):
            raw_line = ce[j][2]
            tokens = [m.group() for m in NUMBER.finditer(raw_line)]
            if len(tokens) == 3:
                components = [integer(t) for t in tokens]
                if any(v is None for v in components) or sum(components[:-1]) != components[-1]:
                    raise ValueError('CE opening/closing components do not sum to printed total')
                return i, int(integer(tokens[-1])), {'marker': ce[i][2], 'rawAmountLine': raw_line,
                                                    'pageOrdinal': ce[j][0], 'lineOrdinal': ce[j][1]}
        raise ValueError('CE total column not directly recoverable')

    start_i, start_equity, start_witness = ce_total(start, '당기초')
    end_i, end_equity, end_witness = ce_total(end, '당기말')
    if end_i <= start_i:
        raise ValueError('Own CE interval order mismatch')
    movements = []
    for page_no, line_no, line in ce[start_i + 1:end_i]:
        label = compact(line)
        if not re.match(r'^[12]\.(당기순이익|현금분배금|이익분배금|이익배당금)', label):
            continue
        tokens = [m.group() for m in NUMBER.finditer(line)]
        if len(tokens) != 3:
            raise ValueError('Whole CE component row required')
        components = [integer(t) for t in tokens]
        if components[-1] is None or sum(v for v in components[:-1] if v is not None) != components[-1]:
            raise ValueError('CE movement components do not sum to printed total')
        movements.append({'rawLine': line, 'pageOrdinal': page_no, 'lineOrdinal': line_no,
                          'totalPrintedAmount': tokens[-1], 'printedComponents': tokens,
                          'unprintedComponentCount': sum(v is None for v in components[:-1]),
                          'total': int(integer(tokens[-1]))})
    if len(movements) != 2 or '당기순이익' not in compact(movements[0]['rawLine']):
        raise ValueError('Exactly printed own profit and distribution rows required')
    equity_close_difference = end_equity - values['equity']
    equity_move_difference = start_equity + sum(m['total'] for m in movements) - end_equity
    profit_difference = movements[0]['total'] - values['netProfit']
    if any([balance_difference, cash_difference, activity_difference, equity_close_difference, equity_move_difference, profit_difference]):
        raise ValueError('Exact printed BS/CE/CF equations mismatch')
    bs_cash = cell('재무상태표', '현금및현금성자산')
    current_cash_scope_difference = int(bs_cash['amountInteger']) - int(closing['amountInteger'])
    comparative_cash_scope_difference = integer(bs_cash['comparativePrintedAmount']) - integer(closing['comparativePrintedAmount'])
    bs_cash_and_deposits = cell('재무상태표', '현금및예치금')
    cash_subtotal_difference = int(bs_cash_and_deposits['amountInteger']) - int(closing['amountInteger'])
    prior_cash_subtotal_difference = integer(bs_cash_and_deposits['comparativePrintedAmount']) - integer(closing['comparativePrintedAmount'])
    notes_scope_line = next((line for line in text.splitlines()
                             if '현금흐름표의현금은재무상태표상의현금및현금성자산입니다.' in compact(line)), None)
    return {'corpCode': metadata['corpCode'], 'officialUrl': metadata['officialUrl'], 'sha256': metadata['sha256'],
            'documentType': metadata['documentType'], 'periodStart': start, 'periodEnd': end,
            'basis': 'singleFundEntity', 'periodKind': 'ownSixMonthFiscalYear' if end == '2026-06-30' else 'ownTwelveMonthFiscalYear',
            'parserVersion': VERSION, 'numericState': 'pendingCashScope' if current_cash_scope_difference or comparative_cash_scope_difference else 'partialPrintedFundCategories', 'automaticPosting': False,
            'regularReportCode': None, 'xbrlAccountId': None, 'fullStatementCollected': False,
            'metricMapping': 'Printed fund categories only; no industrial revenue, operating profit, CFO or PPE mapping',
            'observations': list(observations.values()),
            'validation': {'balanceDifference': str(balance_difference), 'cashRollDifference': str(cash_difference),
                           'cashActivityDifference': str(activity_difference), 'equityCloseDifference': str(equity_close_difference),
                           'equityMovementDifference': str(equity_move_difference), 'wholeProfitDifference': str(profit_difference),
                           'currentBSCashMinusCF': str(current_cash_scope_difference),
                           'comparativeBSCashMinusCF': str(comparative_cash_scope_difference),
                           'currentBSCashAndDepositsMinusCF': str(cash_subtotal_difference),
                           'comparativeBSCashAndDepositsMinusCF': str(prior_cash_subtotal_difference),
                           'notesCashDefinitionQuote': notes_scope_line,
                           'notesCashDefinitionContradiction': bool(notes_scope_line and (current_cash_scope_difference or comparative_cash_scope_difference)),
                           'cashScopeReason': 'Printed cash definitions or discrepancies unresolved; no implicit equivalence' if current_cash_scope_difference or comparative_cash_scope_difference else 'Exact printed BS and CF cash columns agree',
                           'cashWitnesses': [bs_cash, bs_cash_and_deposits, opening, increases[0], closing, financing, fx_candidates[0]],
                           'equityWitnesses': [start_witness, *movements, end_witness]}}


def extract_pdf(path):
    raw = path.read_bytes()
    if not raw.startswith(b'%PDF-') or len(raw) > 20_000_000:
        raise ValueError('Bounded original PDF required')
    digest = hashlib.sha256(raw).hexdigest()
    documents = json.loads(MANIFEST.read_text())['documents']
    selected = [d['metadata'] for d in documents if d['metadata']['sha256'] == digest and d['metadata']['corpCode'] == '00600013']
    if len(selected) != 1:
        raise ValueError('Original bytes do not match a reviewed own audit')
    result = subprocess.run(['pdftotext', '-layout', '-enc', 'UTF-8', str(path), '-'],
                            capture_output=True, timeout=30, check=True)
    text = result.stdout.decode('utf-8')
    extracted = parse_current(selected[0], text)
    extracted['extractedTextSha256'] = hashlib.sha256(result.stdout).hexdigest()
    return extracted


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('pdf', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = extract_pdf(args.pdf.resolve(strict=True))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(f"Validated {len(result['observations'])} printed categories; read-only output {args.output}")
