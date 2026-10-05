import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/shareholder_return/shareholder_return_tab.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';

import '../support/shad_test_host.dart';

void main() {
  for (final width in [390.0, 1045.0]) {
    testWidgets(
      'null dividend values collapse and explicit zero remains at $width',
      (t) async {
        await t.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final empty = DividendEntry(
          reportId: 1,
          companyId: 1,
          bsnsYear: 2025,
          ord: 0,
          item: '주당 현금배당금(원)',
          stockKind: '보통주',
          unit: '원',
        );
        Future<void> show(DividendEntry entry) async {
          await t.pumpWidget(
            shadTestHost(
              MaterialApp(
                theme: buildAppTheme(ledgerBrand),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: ShareholderReturnTab(
                      key: UniqueKey(),
                      corpCode: 'fixture',
                      loader: (_) async => ShareholderReturn(
                        corpCode: 'fixture',
                        dividends: [entry],
                        treasury: [],
                        stockTotals: [],
                        sources: [],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
        }

        await show(empty);
        expect(find.text('한 주당 받은 현금배당'), findsNothing);
        expect(find.textContaining('공시의 빈 값은 0'), findsOneWidget);
        expect(find.textContaining('자기주식 취득·처분: 표시할'), findsOneWidget);
        expect(t.takeException(), isNull);
        await show(empty.copyWith(current: 0));
        expect(find.text('한 주당 받은 현금배당'), findsOneWidget);
        expect(find.text('0원'), findsWidgets);
        expect(t.takeException(), isNull);
      },
    );
  }
}
