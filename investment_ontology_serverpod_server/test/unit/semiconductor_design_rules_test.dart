import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/semiconductor_activity_rules.dart';

void main() {
  test('real filing supplier statements retain exact evidence and product', () {
    final rows = jsonDecode(
      File('test/fixtures/semiconductor_design_evidence.json')
          .readAsStringSync(),
    ) as List;
    for (final row in rows) {
      final activities = SemiconductorActivityRules.parse(
        row['text'],
        companyName: row['company'],
      );
      expect(
        activities.map((a) => a.product.id),
        contains(row['product']),
        reason: row['company'],
      );
      for (final a in activities) {
        expect((row['text'] as String).contains(a.evidence), isTrue);
      }
    }
  });
  test('buyers, customers, subsidiaries and plans do not establish supply', () {
    for (final sentence in [
      '당사는 반도체 설계 IP를 구매하여 제품을 개발합니다.',
      '당사는 반도체 설계 IP를 개발하지 않습니다.',
      '당사의 자회사는 반도체 디자인 솔루션을 제공합니다.',
      '당사는 반도체 디자인 솔루션을 제공할 계획입니다.',
      '당사는 반도체 제조사나 팹리스 업체로부터 후공정을 수주합니다.',
      '고객사는 반도체 설계 IP 개발 및 판매를 사업으로 합니다.',
    ]) {
      expect(
        SemiconductorActivityRules.parse('## 1. 사업의 개요\n$sentence'),
        isEmpty,
        reason: sentence,
      );
    }
  });
  test('MCU testing or distribution is not chip design', () {
    expect(
      SemiconductorActivityRules.parse(
        '## 2. 주요 제품 및 서비스\n구분 | 주요제품 | 매출액\nPKG Test | MCU | 100',
      ),
      isEmpty,
    );
  });
  test('named self statement cannot match a different company', () {
    const text = '## 1. 사업의 개요\n설계기업은 반도체 디자인하우스 전문 기업입니다.';
    expect(
      SemiconductorActivityRules.parse(text, companyName: '고객기업'),
      isEmpty,
    );
    expect(
      SemiconductorActivityRules.parse(
        '## 1. 사업의 개요\n고객기업의 공급사는 반도체 디자인 솔루션을 제공합니다.',
        companyName: '고객기업',
      ),
      isEmpty,
    );
  });
}
