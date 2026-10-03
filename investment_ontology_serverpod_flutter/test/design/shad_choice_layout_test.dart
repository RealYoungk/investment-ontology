import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/toggle_group.dart';

import '../support/shad_test_host.dart';

void main() {
  testWidgets('market choices share a row and retain required selection', (
    tester,
  ) async {
    var selected = 'all';
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: StatefulBuilder(
                builder: (context, setState) => AppToggleGroup<String>(
                  label: '시장',
                  options: const {
                    'all': '전체',
                    'kospi': 'KOSPI',
                    'kosdaq': 'KOSDAQ',
                  },
                  value: selected,
                  onChanged: (v) => setState(() => selected = v),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('전체')).dy,
      tester.getTopLeft(find.text('KOSPI')).dy,
    );
    expect(
      tester.getTopLeft(find.text('전체')).dy,
      tester.getTopLeft(find.text('KOSDAQ')).dy,
    );
    await tester.tap(find.text('KOSPI'));
    await tester.pump();
    expect(selected, 'kospi');
    await tester.tap(find.text('KOSPI'));
    await tester.pump();
    expect(selected, 'kospi');
    expect(tester.takeException(), isNull);
  });
}
