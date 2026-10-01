import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/registered_offerings.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/registered_business_evidence.dart';

void main() {
  test('issuer heading and exact named subject do not become a subsidiary', () {
    const text = '## 1. 사업의 개요\n[(주)경농]\n지배회사인 (주)경농은 작물보호제를 생산하고 있습니다.';
    expect(
      RegisteredBusinessEvidence.find(
        text,
        industry: 'chemicals',
        code: '2032',
        companyName: '(주)경농',
      ),
      '지배회사인 (주)경농은 작물보호제를 생산하고 있습니다.',
    );
    expect(
      RegisteredBusinessEvidence.find(
        '## 1. 사업의 개요\n[주식회사 경농자회사]\n당사는 작물보호제를 생산하고 있습니다.',
        industry: 'chemicals',
        code: '2032',
        companyName: '(주)경농',
      ),
      isNull,
    );
  });

  test(
    'product revenue table accepts only aligned product and positive revenue',
    () {
      const header = '품 목 | 구체적용도 | 매출액 | 비율';
      const row = '의약품 | 질병 치료 | 12,345 | 80%';
      const text = '## 2. 주요 제품 및 서비스\n$header\n$row';
      expect(
        RegisteredBusinessEvidence.find(text, industry: 'pharma', code: '212'),
        '$header\n$row',
      );
      for (final table in [
        '품목 | 구체적용도 | 매출액 | 비율\n기계 | 의약품 | 12,345 | 80%',
        '품목 | 구체적용도 | 매출액 | 비율\n의약품 | 질병 치료 | 0 | 0%',
        '품목 | 회사 | 매출액\n의약품 | 다른회사 | 123',
        '품목 | 매출액 | 비율\n합계 | 의약품 | 123 | 80%',
        '[종속회사]\n품목 | 매출액\n의약품 | 123',
      ]) {
        expect(
          RegisteredBusinessEvidence.find(
            '## 2. 주요 제품 및 서비스\n$table',
            industry: 'pharma',
            code: '212',
          ),
          isNull,
          reason: table,
        );
      }
    },
  );

  test(
    'every registered code in the whole listed universe has a business group',
    () {
      final fixture = jsonDecode(
        File('test/fixtures/discovery/listed_registered_codes.json')
            .readAsStringSync(),
      ) as List;
      expect(fixture.length, 534);
      for (final row in fixture) {
        final definition = RegisteredOfferings.definition(
          row['industry'],
          row['code'],
        );
        expect(definition, isNotNull, reason: '$row');
        expect(definition!['label'], isNot(contains('분류 안된')));
        expect(
          RegisteredOfferings.role(row['industry'], definition['label']),
          isNot(startsWith('registered:')),
        );
      }
    },
  );
  test('specific codes take precedence and no unmapped sector is guessed', () {
    expect(
      RegisteredOfferings.definition('electronics', '26291')!['label'],
      '수동·연결 부품',
    );
    expect(
      RegisteredOfferings.definition('electronics', '26299')!['label'],
      '전자부품',
    );
    expect(
      RegisteredOfferings.definition('pharma', '21230')!['label'],
      '동물용 의약품',
    );
    expect(RegisteredOfferings.definition('pharma', '99999'), isNull);
  });
  test('a current explicit own statement corroborates only its registered activity', () {
    const sentence = '당사는 의약품 제조 및 판매업을 영위하는 법인입니다.';
    expect(
      RegisteredBusinessEvidence.find(
        '## 1. 사업의 개요\n$sentence',
        industry: 'pharma',
        code: '212',
      ),
      sentence,
    );
    expect(
      RegisteredBusinessEvidence.find(
        '## 1. 사업의 개요\n$sentence',
        industry: 'electronics',
        code: '262',
      ),
      isNull,
    );
  });
  test(
    'plans customers inputs competitors and subsidiary headings are rejected',
    () {
      for (final sentence in [
        '당사는 의약품을 생산할 계획입니다.',
        '당사는 의약품 업체에 기기를 공급합니다.',
        '당사는 의약품 제조용 원재료를 매입하고 있습니다.',
        '당사는 의약품 사업을 영위하지 않습니다.',
        '제약회사는 의약품 제조업을 영위합니다.',
        '[종속회사 주식회사 다른회사]\n당사는 의약품 제조업을 영위합니다.',
      ]) {
        expect(
          RegisteredBusinessEvidence.find(
            '## 1. 사업의 개요\n$sentence',
            industry: 'pharma',
            code: '212',
          ),
          isNull,
          reason: sentence,
        );
      }
    },
  );
}
