"""Refresh the data-page reference from tracked Serverpod model definitions."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[2]
server = root / 'investment_ontology_serverpod_server/lib/src/ontology'
groups = {
    'company': ['company', 'industry', 'company_change'],
    'financial': ['dart_filing', 'financial_report', 'financial_fact', 'fs_div', 'financial_report_code', 'financial_statement_kind'],
    'disclosure': ['dart_filing_section', 'disclosure_report', 'disclosure_row', 'shareholder_entry', 'executive_entry', 'investment_entry', 'dividend_entry', 'treasury_stock_entry', 'dart_section'],
    'business': ['business_document', 'document_fact', 'document_fact_kind', 'ontology_relation', 'relation_status', 'relation_predicate'],
    'market': ['security', 'market_snapshot', 'market_snapshot_day', 'market_index_snapshot', 'market_index_day'],
}
base = 'https://opendart.fss.or.kr/api/'
sections = re.findall(r"DartSectionInfo\(\s*'([^']+)'\s*,\s*'([^']+)'", (server / 'dart/dart_sections.dart').read_text())
sections = [(api, label) for api, label in sections if api != 'document']
endpoints = {
    'company': [('기업 목록', base + 'corpCode.xml', 'crtfc_key'), ('기업개황', base + 'company.json', 'crtfc_key, corp_code')],
    'financial': [('공시 목록', base + 'list.json', 'crtfc_key, bgn_de, end_de, pblntf_ty, page_no, page_count (기업별 조회: corp_code)'), ('전체 재무제표', base + 'fnlttSinglAcntAll.json', 'crtfc_key, corp_code, bsns_year, reprt_code, fs_div')],
    'disclosure': [(label, base + api + '.json', 'crtfc_key, corp_code, bsns_year, reprt_code') for api, label in sections],
    'business': [('공시 원문 ZIP/XML', base + 'document.xml', 'crtfc_key, rcept_no')],
    'market': [('주식시세', 'https://apis.data.go.kr/1160100/GetStockSecuritiesInfoService_V2/getStockPriceInfo_V2', 'serviceKey, basDt, resultType=json, pageNo, numOfRows'), ('KRX 상장종목', 'https://apis.data.go.kr/1160100/GetKrxListedInfoService_V2/getItemInfo_V2', 'serviceKey, basDt, resultType=json, pageNo, numOfRows'), ('시장 지수', 'https://apis.data.go.kr/1160100/GetMarketIndexInfoService_V2/getStockMarketIndex_V2', 'serviceKey, basDt, resultType=json, pageNo, numOfRows')],
}
def schema(name):
    definition = (server / 'models' / (name + '.spy.yaml')).read_text()
    fields = []
    inside = False
    notes = []
    for line in definition.splitlines():
        if line == 'fields:':
            inside = True
            continue
        if inside and line and not line.startswith(' '):
            break
        if inside and line.startswith('  ### '):
            notes.append(line[6:])
        elif inside and re.match(r'  \w+:', line):
            field, value = line.strip().split(':', 1)
            fields.append({'name': field, 'type': value.strip(), 'description': ' '.join(notes)})
            notes = []
    return {'file': name + '.spy.yaml', 'definition': definition, 'fields': fields}

out = {}
for key, models in groups.items():
    models = models + ['source', 'source_kind']
    out[key] = {'endpoints': [{'label': label, 'url': url, 'params': params} for label, url, params in endpoints[key]],
                'schemas': [schema(name) for name in models]}
p = root / 'investment_ontology_serverpod_flutter/assets/data/catalog.json'
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n')
print(f'{len(sections)} disclosure APIs; wrote {p}')
