import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/screen/screen_filter.dart';
import 'package:investment_ontology_serverpod_flutter/features/screen/screen_presets.dart';
import 'package:shad/shad.dart';

import 'screen_experience_test.dart' as support;

void main() {
  ScreenPreset card(String id) => screenPresets.singleWhere((p) => p.id == id);

  test('AND uses stricter overlapping bounds and restores remaining cards', () {
    var f = card('value').toggle(const ScreenFilter());
    f = card('profit').toggle(f);
    f = card('low-debt').toggle(f);
    expect(f.perMax, 12);
    expect(f.roeMin, 10);
    expect(f.marginMin, 10);
    expect(f.debtMax, 50);
    f = ScreenFilter.fromQuery(Uri.parse(f.location).queryParameters);
    expect(card('value').matches(f), isTrue);
    expect(card('profit').matches(f), isTrue);
    f = card('value').toggle(f);
    expect(f.perMax, isNull);
    expect(f.roeMin, 10);
    f = card('profit').toggle(f);
    expect(f.roeMin, 5);
    expect(f.marginMin, isNull);
    f = card('low-debt').toggle(f);
    expect(f.hasCondition, isFalse);
    expect(f.presetIds, isEmpty);

    f = card('asset-value').toggle(card('value').toggle(const ScreenFilter()));
    expect(f.perMax, 12);
    expect(f.roeMin, 10);
    f = card('value').toggle(f);
    expect(f.perMax, 15);
    expect(f.roeMin, 5);
  });

  testWidgets(
    'multi-select survives URL restore and empty results; deselect restores bounds',
    (tester) async {
      final router = await support.pumpScreen(
        tester,
        (f, {offset = 0, limit = 10}) async => support.result(0),
        edit: false,
      );
      await support.preset(tester, '이익 대비 저렴한 주식');
      await support.preset(tester, '돈 잘 버는 회사');
      var q = router.routeInformationProvider.value.uri.queryParameters;
      expect(q['per'], '12');
      expect(q['margin'], '10');
      expect(q['presets'], 'profit,value');
      for (final id in ['value', 'profit']) {
        expect(
          tester.widget<ShadButton>(find.byKey(ValueKey('preset-$id'))).variant,
          ShadButtonVariant.primary,
        );
      }
      router.go(router.routeInformationProvider.value.uri.toString());
      await tester.pumpAndSettle();
      await support.preset(tester, '이익 대비 저렴한 주식');
      q = router.routeInformationProvider.value.uri.queryParameters;
      expect(q['per'], isNull);
      expect(q['roe'], '10');
      expect(q['margin'], '10');
      await support.preset(tester, '돈 잘 버는 회사');
      expect(
        router.routeInformationProvider.value.uri.queryParameters,
        isEmpty,
      );
    },
  );
}
