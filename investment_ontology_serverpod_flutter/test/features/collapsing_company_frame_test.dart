import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/collapsing_company_frame.dart';

import '../support/shad_test_host.dart';

import 'package:investment_ontology_serverpod_flutter/design/components/components.dart';

void main() {
  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('reading bar follows scroll direction at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: CollapsingCompanyFrame(
                name: '삼기에너지솔루션즈',
                code: '419050',
                navigation: Align(
                  alignment: Alignment.centerLeft,
                  child: AppTabBar<String>(
                    fitContent: true,
                    tabs: const {
                      '사업': '사업',
                      '재무': '재무',
                      '지배구조': '지배구조',
                      '주주환원': '주주환원',
                      '소식·공시': '소식·공시',
                    },
                    value: '사업',
                    onChanged: (_) {},
                  ),
                ),
                header: SizedBox(height: 220, child: Text('기업 소개')),
                metrics: SizedBox(height: 200, child: Text('핵심 지표')),
                children: [SizedBox(height: 2400, child: Text('사업 본문'))],
              ),
            ),
          ),
        ),
      );
      expect(find.text('기업 소개').hitTestable(), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1100));
      await tester.pumpAndSettle();
      expect(find.byType(SliverAppBar), findsNothing);
      expect(find.text('사업').hitTestable(), findsNothing);
      await tester.timedDrag(
        find.byType(CustomScrollView),
        const Offset(0, 180),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();
      expect(find.text('사업').hitTestable(), findsOneWidget);
      expect(find.text('기업 소개').hitTestable(), findsNothing);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 1600));
      await tester.pumpAndSettle();
      expect(find.text('기업 소개').hitTestable(), findsOneWidget);
      expect(find.text('사업').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
