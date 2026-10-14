import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/investment_facts.dart';
import 'package:test/test.dart';

const annual = '''
(시설투자 현황)
| (단위 : 억원)
구 분 | 내 용 | 투자기간 | 대상자산 | 투자액
DS 부문 | 신ㆍ증설, 보완 등 | 2025.01~2025.12 | 건물ㆍ설비 등 | 474,764
SDC | 신ㆍ증설, 보완 등 | 2025.01~2025.12 | 건물ㆍ설비 등 | 27,970
기 타 | 신ㆍ증설, 보완 등 | 2025.01~2025.12 | 건물ㆍ설비 등 | 21,225
합 계 | 526,511
## 4. 매출 및 수주상황
''';
void main() {
  test(
    'actual Samsung annual table preserves units, dates and exact evidence',
    () {
      final rows = InvestmentFacts.parse(
        annual,
        periodEnd: DateTime.utc(2025, 12, 31),
      );
      expect(rows.map((r) => r.value), [474764, 27970, 21225, 526511]);
      expect(rows.map((r) => r.label), [
        'DS 부문 시설투자',
        'SDC 시설투자',
        '기타 시설투자',
        '시설투자 합계',
      ]);
      for (final r in rows) {
        expect(r.unit, '억원');
        expect(r.asOf, DateTime.utc(2025, 12, 31));
        expect(annual, contains(r.evidence));
      }
    },
  );
  test('a discrepancy printed in the official table is flagged, not silently repaired', () {
    final rows = InvestmentFacts.parse(
      annual,
      periodEnd: DateTime.utc(2025, 12, 31),
    );
    expect(rows.every((r) => !r.reconciled), isTrue);
    expect(rows.last.value, 526511);
    expect(rows.take(3).fold(0.0, (v, r) => v + r.value), 523959);
  });
  test('Samsung division renaming continues the same series without relabeling other issuers', () {
    final old = annual.replaceAll('DS 부문', '반도체 사업').replaceAll('SDC', 'DP 사업');
    expect(
      InvestmentFacts.parse(
        old,
        periodEnd: DateTime.utc(2025, 12, 31),
        owner: '삼성전자',
      ).take(2).map((r) => r.label),
      ['DS 부문 시설투자', 'SDC 시설투자'],
    );
    expect(
      InvestmentFacts.parse(
        old,
        periodEnd: DateTime.utc(2025, 12, 31),
        owner: '다른회사',
      ).first.label,
      '반도체 사업 시설투자',
    );
  });
  test('half-year investments stay cumulative half-year values', () {
    final half = annual
        .replaceAll('2025.01~2025.12', '2026.01~2026.06')
        .replaceAll('474,764', '256,030')
        .replaceAll('27,970', '13,346')
        .replaceAll('21,225', '10,488')
        .replaceAll('526,511', '279,864');
    final rows = InvestmentFacts.parse(
      half,
      periodEnd: DateTime.utc(2026, 6, 30),
    );
    expect(rows.last.value, 279864);
    expect(rows.last.asOf, DateTime.utc(2026, 6, 30));
    expect(rows.every((r) => r.reconciled), isTrue);
    expect(
      InvestmentFacts.parse(half, periodEnd: DateTime.utc(2026, 12, 31)),
      isEmpty,
    );
  });
  test('planned/future/unknown units and incomplete tables are rejected', () {
    for (final text in [
      annual.replaceAll('시설투자 현황', '시설투자 계획'),
      annual.replaceAll('억원', '대'),
      annual.replaceAll('| (단위 : 억원)', ''),
      annual.replaceAll('27,970', '-'),
      annual.replaceAll('27,970', '27,9727,970'),
      annual.replaceAll('27,970', '27,97'),
      annual.replaceAll('합 계 | 526,511', ''),
      annual.replaceAll('2025.01~2025.12', '2026.01~2026.12'),
      annual.replaceAll('2025.01~2025.12', '2024.01~2025.12'),
      '[다른기업]\n$annual',
    ]) {
      expect(
        InvestmentFacts.parse(
          text,
          periodEnd: DateTime.utc(2025, 12, 31),
          owner: '삼성전자',
          otherCompanies: {'다른기업'},
        ),
        isEmpty,
        reason: text,
      );
    }
  });
  test(
    'prose rounded total is suppressed only with matching exact source table',
    () {
      final f = DocumentFact(
        companyId: 1,
        documentId: 1,
        bsnsYear: 2025,
        kind: DocumentFactKind.investmentActual,
        label: '시설투자 (DS·SDC)',
        value: 52.7,
        unit: '조원',
        asOf: DateTime.utc(2025, 12, 31),
        evidence: '',
        extractedBy: RelationOrigin.ai,
        status: RelationStatus.verified,
        createdAt: DateTime.utc(2026),
      );
      final exact = f.copyWith(
        label: '시설투자 합계',
        value: 526511,
        unit: '억원',
        extractedBy: RelationOrigin.api,
      );
      expect(InvestmentFacts.redundantRoundedTotal(f, [exact]), isTrue);
      expect(
        InvestmentFacts.redundantRoundedTotal(f, [
          exact.copyWith(documentId: 2),
        ]),
        isFalse,
      );
      expect(
        InvestmentFacts.redundantRoundedTotal(f, [
          exact.copyWith(value: 500000),
        ]),
        isFalse,
      );
    },
  );
}
