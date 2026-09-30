import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/adaptive_detail.dart';

void main() {
  testWidgets('sheet scrolls long content without scrolling the page', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final page = ScrollController();
    addTearDown(page.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(ledgerBrand),
        home: Scaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              controller: page,
              child: Column(
                children: [
                  TextButton(
                    onPressed: () => showAdaptiveDetail(
                      context: context,
                      builder: (_) => Column(
                        children: [
                          for (var i = 0; i < 40; i++)
                            SizedBox(height: 70, child: Text('detail $i')),
                        ],
                      ),
                    ),
                    child: const Text('open'),
                  ),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final sheet = find.byType(SingleChildScrollView).last;
    await tester.drag(sheet, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.drag(sheet, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SingleChildScrollView>(sheet).controller!.offset,
      greaterThan(0),
    );
    expect(page.offset, 0);
    expect(tester.takeException(), isNull);
  });
}
