import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_table_history.dart';

BusinessTableMeasure value(String unit) => BusinessTableMeasure(
  label: '부품 (KG당)',
  metric: '가격',
  period: '제24기',
  value: 147443,
  unit: unit,
);
void main() {
  test(
    'bank metrics retain a shared period while their meanings stay separate',
    () {
      expect(
        businessTablePeriodKey('제66기 반기 · 평균잔액'),
        businessTablePeriodKey('제66기 반기 · 이자율'),
      );
      expect(
        businessTablePeriodKey('제66기 반기 · 평균잔액'),
        isNot(businessTablePeriodKey('제65기 · 평균잔액')),
      );
    },
  );
  test(
    'scale conflict differs from genuinely different measurement denominators',
    () {
      expect(conflictingPriceUnit(value('백만원'), [value('원')]), isTrue);
      expect(conflictingPriceUnit(value('천원/kg'), [value('천원/m')]), isFalse);
      expect(
        conflictingPriceUnit(value('원'), [value('원').copyWith(value: 100)]),
        isFalse,
      );
    },
  );
  test('axis never labels bare second quarter as cumulative half year', () {
    expect(businessHistoryAxisLabel(2026, '제28기 2분기매입액'), '26.2Q');
    expect(businessHistoryAxisLabel(2026, '2026 반기'), '26.1H');
    expect(businessHistoryAxisLabel(2025, '제27기'), '25년');
  });
}
