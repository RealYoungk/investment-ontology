import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/ownership_changes/ownership_changes_section.dart';

ShareholderEntry row({String kind = '보통주'}) => ShareholderEntry(
  reportId: 1,
  companyId: 1,
  bsnsYear: 2025,
  ord: 0,
  holderName: '주주',
  stockKind: kind,
  sharesBegin: BigInt.from(100),
  sharesEnd: BigInt.from(90),
  ratioEnd: 9,
  isTotal: false,
);
OwnershipSnapshot snapshot(int year, {bool collected = true}) =>
    OwnershipSnapshot(
      bsnsYear: year,
      reportCode: collected
          ? FinancialReportCode.annual
          : FinancialReportCode.halfYear,
      reportName: '$year 보고서',
      rceptNo: '',
      periodStart: DateTime.utc(year),
      periodEnd: DateTime.utc(year, collected ? 12 : 6, collected ? 31 : 30),
      collected: collected,
      shareholders: collected ? [row()] : [],
    );
void main() {
  test('legal-name variants connect but preferred shares stay separate', () {
    final a = row().copyWith(holderName: 'SK스퀘어(주)');
    final b = row(kind: '의결권 있는 주식').copyWith(holderName: 'SK스퀘어㈜');
    expect(ownershipKey(a), ownershipKey(b));
    expect(ownershipKey(a), isNot(ownershipKey(b.copyWith(stockKind: '우선주'))));
    expect(ownershipTrendSummary([20.1, null, 20.1]), contains('시작·끝 동일'));
    expect(ownershipTrendSummary([20, 21]), contains('+1.00%p'));
    expect(ownershipTrendSummary([20, null]), '20.00% → 미확보');
  });
  test('5% 미만 제외, 과거 또는 기초 5% 이상과 경계값 포함', () {
    final p = snapshot(2025);
    p.shareholders = [row().copyWith(ratioBegin: 4.0, ratioEnd: 4.99)];
    expect(isMajorHolder([p], ownershipKey(row())), isFalse);
    p.shareholders = [row().copyWith(ratioBegin: 5.0, ratioEnd: 4.0)];
    expect(isMajorHolder([p], ownershipKey(row())), isTrue);
    p.shareholders = [row().copyWith(ratioBegin: 4.0, ratioEnd: 5.0)];
    expect(isMajorHolder([p], ownershipKey(row())), isTrue);
  });

  test('stock kinds stay separate and duplicate identity stays missing', () {
    final s = snapshot(2025);
    s.shareholders = [row(), row(kind: '우선주')];
    expect(historyRow(s, ownershipKey(row()))?.stockKind, '보통주');
    s.shareholders.add(row());
    expect(historyRow(s, ownershipKey(row())), isNull);
  });
  testWidgets('five years plus missing latest interim are visible on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reports = [
      for (var y = 2021; y <= 2025; y++) snapshot(y),
      snapshot(2026, collected: false),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(ledgerBrand),
        home: Scaffold(
          body: SingleChildScrollView(
            child: OwnershipChangesSection(
              corpCode: '1',
              loader: (_) async => reports,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('· 미수집'), findsOneWidget);
    expect(find.textContaining('2026.01.01 → 2026.06.30'), findsOneWidget);
    expect(find.text('2021 결산 9.00%'), findsNothing);
    expect(find.text('주주  —'), findsOneWidget);
    await tester.tap(find.text('보유 주식 수'));
    await tester.pumpAndSettle();
    expect(find.text('2021 결산 90주'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
