import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';
import 'package:investment_ontology_serverpod_flutter/features/data_sync/data_page.dart';

IngestCoverage legacy() => IngestCoverage(
  listedCompanies: 10,
  companiesWithFinancials: 5,
  filingsTotal: 10,
  filingsPending: 4,
  prioritySections: 0,
  prioritySectionsDone: 0,
  sections: 0,
  sectionsDone: 0,
  sectionsFailed: 0,
  companiesWithDisclosures: 0,
  relations: 0,
  persons: 0,
  companiesWithBusinessText: 5,
  companiesWithDigest: 0,
  dartCallsToday: 0,
  dartDailyLimit: 20000,
  dartFinancialBudget: 19000,
  dartDisclosurePriorityBudget: 9000,
);
Widget host(Widget child) => MaterialApp(
  theme: buildAppTheme(
    AppBrand(
      colors: researchDeskColors,
      shape: const AppShape(radius: 10, strokeWidth: 1),
      typography: const AppTypography(
        displayBase: TextStyle(),
        bodyBase: TextStyle(),
        numericBase: TextStyle(),
        labelBase: TextStyle(),
      ),
    ),
  ),
  home: Scaffold(
    body: SingleChildScrollView(child: SizedBox(width: 320, child: child)),
  ),
);
void main() {
  testWidgets(
    'old server nullable coverage remains pending rather than zero or fabricated latest',
    (tester) async {
      final v = legacy();
      await tester.pumpWidget(
        host(
          Column(
            children: [
              MarketCollectionStatus(coverage: v),
              BusinessCollectionStatus(coverage: v),
              FinancialCollectionStatus(coverage: v),
            ],
          ),
        ),
      );
      expect(find.text('집계 대기'), findsWidgets);
      expect(find.textContaining('최신 이후 미확보 · 집계 대기'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'actual latest dates and confirmed history stay distinct from recent unconfirmed date',
    (tester) async {
      final v = legacy().copyWith(
        marketLatestPriceDate: DateTime.utc(2026, 9, 30),
        marketLatestPriceSecurities: 2873,
        marketLatestIndexDate: DateTime.utc(2026, 9, 30),
        marketLatestIndexCount: 171,
        marketScopeStart: DateTime.utc(2021, 10, 2),
        marketScopeThrough: DateTime.utc(2026, 9, 30),
        marketExpectedWeekdays: 1303,
        marketPriceDaysStored: 1303,
        marketIndexDaysStored: 1303,
        marketHistoricalPendingDates: 0,
        marketRecentUnconfirmedDates: 1,
      );
      await tester.pumpWidget(host(MarketCollectionStatus(coverage: v)));
      expect(find.textContaining('2,873'), findsOneWidget);
      expect(find.text('지수 171개'), findsOneWidget);
      expect(find.text('100.0%'), findsNWidgets(2));
      expect(find.text('최신 이후 미확보 1일 · 원천 게시 확인 대기'), findsOneWidget);
      expect(find.textContaining('확정한 값이 아닙니다'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'body storage progress differs from exact latest receipt and financial no-data',
    (tester) async {
      final v = legacy().copyWith(
        bodyScopeTotal: 10,
        bodyScopeStored: 7,
        bodyScopePending: 2,
        bodyScopeFailed: 1,
        companiesWithLatestBusinessText: 0,
        financialStoredFilings: 7,
        financialNoDataFilings: 1,
        financialPendingFilings: 1,
        financialFailedFilings: 1,
      );
      await tester.pumpWidget(
        host(
          Column(
            children: [
              BusinessCollectionStatus(coverage: v),
              FinancialCollectionStatus(coverage: v),
            ],
          ),
        ),
      );
      expect(find.text('70.0%'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('원천 데이터 없음 1건'), findsOneWidget);
      expect(find.text('실패 보고서 1건'), findsOneWidget);
      expect(find.text('대기 본문 2건'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
