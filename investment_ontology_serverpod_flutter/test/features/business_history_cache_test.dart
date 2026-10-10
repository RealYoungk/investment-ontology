import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_history_cache.dart';

BusinessContent body() => BusinessContent(
  bsnsYear: 2025,
  rceptNo: '20260318000999',
  title: '사업의 내용',
  sections: [],
  charCount: 0,
  years: [2025],
);
void main() {
  test(
    'three panels share five annual requests; ingest change refreshes',
    () async {
      var calls = 0;
      final cache = BusinessHistoryCache((code, year) async {
        calls++;
        return body();
      });
      await Future.wait([
        for (var panel = 0; panel < 3; panel++)
          for (var year = 2021; year <= 2025; year++)
            cache.read('01526806', year, 0),
      ]);
      expect(calls, 5);
      await cache.read('01526806', 2025, 1);
      expect(calls, 6);
    },
  );
  test('null and failed responses retry and old completions cannot erase new generation', () async {
    final old = Completer<BusinessContent?>();
    var calls = 0;
    final cache = BusinessHistoryCache((_, _) {
      calls++;
      return calls == 1 ? old.future : Future.value(body());
    });
    final first = cache.read('01526806', 2025, 0);
    final next = await cache.read('01526806', 2025, 1);
    old.complete(null);
    await first;
    expect(await cache.read('01526806', 2025, 1), same(next));
    expect(calls, 2);
    var attempt = 0;
    final retry = BusinessHistoryCache((_, _) async {
      if (++attempt == 1) throw StateError('network');
      return null;
    });
    await expectLater(retry.read('x', 2025, 0), throwsStateError);
    expect(await retry.read('x', 2025, 0), isNull);
    expect(await retry.read('x', 2025, 0), isNull);
    expect(attempt, 3);
  });
}
