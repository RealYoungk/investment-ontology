import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/charts/app_sparkline.dart';

void main() {
  testWidgets(
    'flat, missing and isolated observations retain named chart semantics',
    (t) async {
      final handle = t.ensureSemantics();

      for (final values in <List<double?>>[
        [4, 4, 4],
        [null, null],
        [4, null, 5],
        [double.nan, 4],
      ]) {
        await t.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 150,
                child: AppSparkline(
                  values: values,
                  color: Colors.blue,
                  description: '국채 수익률 · 합성 추이',
                ),
              ),
            ),
          ),
        );
        expect(find.bySemanticsLabel('국채 수익률 · 합성 추이'), findsOneWidget);
        expect(t.takeException(), isNull);
      }
      handle.dispose();
    },
  );
}
