import '../support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/company_header.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_metrics.dart';

import 'financial_metrics_test.dart' as fixtures;

void main() {
  for (final width in [320.0, 390.0, 768.0, 1045.0, 1440.0]) {
    testWidgets('interim growth shows its period at $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final data = fixtures.financials([
        fixtures.period(2025, FinancialReportCode.annual, [
          fixtures.line('revenue', 13312020352),
          fixtures.line('netIncome', -100),
        ]),
        fixtures.period(2026, FinancialReportCode.halfYear, [
          fixtures
              .line('revenue', 5473699582, cumulative: 12047351414)
              .copyWith(priorSameCumulativeAmount: BigInt.from(4827787392)),
          fixtures
              .line('netIncome', -50, cumulative: -100)
              .copyWith(priorSameCumulativeAmount: BigInt.from(-100)),
        ]),
      ], cap: BigInt.from(150800000000));
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompanyHeader(
                  detail: CompanyDetail(
                    company: Company(corpCode: '01829819', name: '(주)아크릴'),
                    industryPath: [],
                    changes: [],
                  ),
                  financials: data,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('149.5%'), findsOneWidget);
      expect(find.text('반기 누적 · 전년 동기 대비'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'missing metrics show reasons without dash placeholders at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final data = fixtures.financials([
          fixtures.period(2025, FinancialReportCode.annual, [
            fixtures.line('netIncome', -100),
            fixtures.line('equity', 0),
          ]),
        ], cap: BigInt.from(1000));
        await tester.pumpWidget(
          shadTestHost(
            MaterialApp(
              theme: buildAppTheme(ledgerBrand),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: CompanyHeader(
                    detail: CompanyDetail(
                      company: Company(corpCode: 'test', name: '테스트금융지주'),
                      industryPath: [],
                      changes: [],
                    ),
                    financials: data,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('PER'), findsOneWidget);
        final perCell = find
            .ancestor(
              of: find.text('PER'),
              matching: find.byType(AnimatedContainer),
            )
            .first;
        expect(
          find.descendant(of: perCell, matching: find.text('—')),
          findsNothing,
        );
        expect(find.text('시가총액'), findsOneWidget);
        for (final metric in FinancialView(
          data,
        ).metrics().where((m) => ['per', 'roe'].contains(m.key))) {
          expect(metric.derived.value, isNull);
          expect(find.text(metric.derived.missing!), findsWidgets);
        }
        expect(find.text('일부 지표 계산 불가 · 지표를 누르면 사유 확인'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
