import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/business/business_product_rules.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/business/current_product_rows.dart';

void main() {
  test(
    'MiCo and Samsung latest filing snapshots retain evidence and purposes',
    () {
      for (final code in ['00366942', '00126380']) {
        final fixture = jsonDecode(
          File('test/fixtures/business_products/$code.json').readAsStringSync(),
        ) as Map;
        final text = fixture['text'] as String;
        final products = BusinessProductRules.parse(text);
        expect(products.length, greaterThanOrEqualTo(2));
        expect(products.every((p) => text.contains(p.evidence)), isTrue);
        expect(products.any((p) => p.name.contains('내부거래')), isFalse);
        if (code == '00366942') {
          expect(
            products.where((p) => p.role.isNotEmpty).length,
            greaterThanOrEqualTo(2),
          );
          expect(products.first.role, contains('lifetime 향상'));
        }
      }
    },
  );

  test('two-row period headers preserve the printed product purpose column', () {
    const text =
        '## 2. 주요 제품 및 서비스\n사업부문 | 매출유형 | 품목 | 구체적 용도 | 제28기 2분기 | 제27기\n매출액 | 비율 | 매출액 | 비율\n반도체 | 제품 | Heater, ESC | 반도체 장비 부품 | 100 | 50% | 200 | 60%';
    final products = CurrentProductRows.parse(text);
    expect(products.single.name, 'Heater, ESC');
    expect(products.single.role, '반도체 장비 부품');
    expect(text.contains(products.single.evidence), isTrue);
  });

  test('printed purpose headers supply explanations without inference', () {
    for (final header in ['주요 용도', '용도', '기능', '제품 특성', '특징']) {
      final text = '## 2. 주요 제품 및 서비스\n제품명 | $header\n검사기 | 표면 결함 검사';
      final products = CurrentProductRows.parse(text);
      expect(products.single.role, '표면 결함 검사');
      expect(text.contains(products.single.evidence), isTrue);
    }
  });
  test('one printed product family does not become duplicate catalog cards', () {
    const text =
        '## 2. 주요 제품 및 서비스\n부문 | 주요 제품 | 매출액\nDS | DRAM, NAND Flash | 100\n기타 | 부문간 내부거래 제거 등 | -10';
    final products = BusinessProductRules.parse(text);
    expect(products.map((p) => p.name), ['DRAM, NAND Flash']);
  });

  test(
    'family/detail columns keep printed names and safely carry merged families',
    () {
      const text = '''## 2. 주요 제품 및 서비스
제품군 | 세부제품 | 설명
조나단 | GPUBase | GPU 자원 관리
ModelBase | AI 전주기 자동화
AgentBase | AI 에이전트 솔루션
나디아 | 코어 | 의료정보시스템
에스더 | AI 기반 디지털의료기기
[디지털의료기기 파이프라인]
제품명 | 질환 | 협력기관 | 비고
에스더 인펙스 | 감염병 | 병원 | 탐색 단계
더마 에이전트 | 피부염 | 병원 | 개발 단계
## 3. 원재료
제품명 | 설명
타사 장비 | 구매한 장비''';
      final products = BusinessProductRules.parse(text);
      expect(products.map((p) => p.name), [
        '조나단 · GPUBase',
        '조나단 · ModelBase',
        '조나단 · AgentBase',
        '나디아 · 코어',
        '나디아 · 에스더',
      ]);
      expect(products.every((p) => text.contains(p.evidence)), isTrue);
    },
  );
  test('development, competitors, subsidiaries and unrelated tables never become own products', () {
    for (final text in [
      '## 2. 주요 제품\n[신약 파이프라인]\n제품명 | 단계\n후보A | 임상 1상',
      '## 2. 주요 제품\n제품명 | 설명\n경쟁사 장비 | 검사 장비',
      '## 2. 주요 제품\n제품명 | 설명\n자회사 제품 | 자동화',
      '## 5. 시장 현황\n제품명 | 설명\n맥주 | 판매',
      '## 2. 주요 제품\n제품명 | 설명\n품목A | 개발 예정',
    ]) {
      expect(CurrentProductRows.parse(text), isEmpty, reason: text);
    }
  });
  test('numeric totals, ragged rows and prices cannot introduce current products', () {
    const text =
        '## 2. 주요 제품\n품목 | 매출액\n맥주 | 123\n합계 | 123\n가격 변동\n제품명 | 가격\n100 | 200';
    expect(CurrentProductRows.parse(text).map((p) => p.name), ['맥주']);
  });
  final path = Platform.environment['BUSINESS_SOURCE_JSON'];
  test(
    'Acryl public filing main offerings win over the pipeline',
    () {
      final data = jsonDecode(File(path!).readAsStringSync());
      final text = (data['sections'] as List)
          .map((s) => '## ${s['title']}\n${s['text']}')
          .join('\n');
      final products = BusinessProductRules.parse(text);
      expect(
        products.map((p) => p.name),
        containsAll([
          '조나단 · GPUBase',
          '조나단 · ModelBase',
          '조나단 · AgentBase',
          '나디아 · 코어',
          '나디아 · 에스더',
        ]),
      );
      expect(
        products.any((p) => p.name.contains('인펙스') || p.name.contains('더마')),
        isFalse,
      );
      expect(products.every((p) => text.contains(p.evidence)), isTrue);
    },
    skip: path == null
        ? 'Set BUSINESS_SOURCE_JSON to an explicit public filing snapshot'
        : false,
  );
}
