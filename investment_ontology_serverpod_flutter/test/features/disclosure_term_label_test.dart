import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/disclosure_term_label.dart';

import '../support/shad_test_host.dart';

void main() {
  for (final width in [320.0, 893.0]) {
    testWidgets('tap beside the term reveals its own explanation at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: const Scaffold(
              body: Center(child: DisclosureTermLabel('금리스왑 · KRW')),
            ),
          ),
        ),
      );
      final explanation = disclosureTermHelp('금리스왑 · KRW')!;
      expect(find.text(explanation), findsNothing);
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.text(explanation), findsOneWidget);
      expect(explanation, contains('고정금리와 변동금리'));
      expect(tester.takeException(), isNull);
    });
  }
  test('unknown terms do not receive invented explanations', () {
    expect(disclosureTermHelp('품목'), isNull);
    expect(
      disclosureTermHelp('미결제 약정계약금액 (천원)'),
      contains('손실액이나 실제 지급액과 다릅니다'),
    );
  });
}
