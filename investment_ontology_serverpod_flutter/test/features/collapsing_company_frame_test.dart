import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/collapsing_company_frame.dart';

import '../support/shad_test_host.dart';

void main() {
  for (final width in [320.0, 390.0, 913.0, 1280.0]) {
    testWidgets(
      'compact identity stays at top and restores expanded header at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          shadTestHost(
            MaterialApp(
              theme: buildAppTheme(ledgerBrand),
              home: const Scaffold(
                body: CollapsingCompanyFrame(
                  name: '미코',
                  code: '059090',
                  navigation: Text('사업 재무 지배구조'),
                  metrics: SizedBox(height: 400, child: Text('펼친 핵심 지표')),
                  header: SizedBox(height: 600, child: Text('미코')),
                  children: [
                    SizedBox(height: 2000, child: Text('재무 본문')),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(find.text('미코').hitTestable(), findsOneWidget);
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -1400),
        );
        await tester.pumpAndSettle();
        expect(find.text('미코').hitTestable(), findsOneWidget);
        final y = tester.getTopLeft(find.text('미코').hitTestable()).dy;
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('미코').hitTestable()).dy, y);
        expect(
          find.ancestor(
            of: find.text('펼친 핵심 지표'),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'anchored identity animates without painting a second expanded title',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final title = GlobalKey();
      final cap = GlobalKey();
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: CollapsingCompanyFrame(
                name: 'SK하이닉스',
                corpCode: '00164779',
                code: '000660',
                titleAnchor: title,
                sourceAnchors: [cap],
                navigation: const Text('탭 영역'),
                header: SizedBox(
                  height: 600,
                  child: Column(
                    children: [
                      Opacity(
                        opacity: 0,
                        child: Text(
                          'SK하이닉스',
                          key: title,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                      const Spacer(),
                      Opacity(
                        opacity: 0,
                        child: Text(
                          '000660',
                          key: cap,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                children: const [SizedBox(height: 2000, child: Text('본문'))],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final flight = find.byKey(const ValueKey('company-flight-0'));
      expect(flight, findsOneWidget);
      expect(tester.widget<Text>(flight).style!.fontSize, 30);
      expect(tester.getTopLeft(find.text('탭 영역')).dy, greaterThan(600));
      final scroll = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!;
      var previousY = tester.getTopLeft(flight).dy;
      for (final offset in [100.0, 200.0, 300.0, 400.0, 500.0, 600.0]) {
        scroll.jumpTo(offset);
        await tester.pumpAndSettle();
        final y = tester.getTopLeft(flight).dy;
        expect(y, greaterThanOrEqualTo(8));
        expect(y, lessThanOrEqualTo(previousY));
        previousY = y;
      }
      scroll.jumpTo(0);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pumpAndSettle();
      final middleSize = tester.widget<Text>(flight).style!.fontSize!;
      expect(middleSize, greaterThan(16));
      expect(middleSize, lessThan(30));
      expect(tester.getTopLeft(flight).dy, greaterThanOrEqualTo(8));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(flight).style!.fontSize, 16);
      final logo = find.byKey(const ValueKey('company-flight-logo'));
      expect(logo, findsOneWidget);
      expect(tester.getTopLeft(logo).dy, 24);
      expect(tester.getSize(logo), const Size(36, 36));
      expect(
        tester.getCenter(flight).dy,
        closeTo(tester.getCenter(logo).dy, 0.1),
      );
      expect(
        tester.getBottomRight(flight).dy,
        lessThan(tester.getTopLeft(find.text('탭 영역')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
