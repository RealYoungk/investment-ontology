import 'dart:async';

import 'package:fake_async/fake_async.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/network/resilient_client.dart';

void main() {
  test('An uncompleted read terminates and ignores a late response', () {
    fakeAsync((time) {
      final pending = <Completer<int>>[];
      Object? failure;
      int? value;
      ReadRetry.run(
        'company.overview',
        () {
          final request = Completer<int>();
          pending.add(request);
          return request.future;
        },
        wait: (_) async {},
        jitter: (_) => 0,
      ).then<void>(
        (result) {
          value = result;
        },
        onError: (Object error) {
          failure = error;
        },
      );
      time.elapse(const Duration(seconds: 45));
      time.flushMicrotasks();
      expect(pending.length, 3);
      expect(failure, isA<TimeoutException>());
      pending.first.complete(999);
      time.flushMicrotasks();
      expect(value, isNull);
    });
  });
  test('Transient read recovers with bounded backoff', () async {
    var calls = 0;
    final delays = <Duration>[];
    final result = await ReadRetry.run(
      'company.overview',
      () async {
        if (++calls < 3) throw const ServerpodClientNetworkException('offline');
        return 7;
      },
      wait: (d) async {
        delays.add(d);
      },
      jitter: (_) => 0,
    );
    expect(result, 7);
    expect(calls, 3);
    expect(delays, [
      const Duration(milliseconds: 500),
      const Duration(milliseconds: 1500),
    ]);
  });
  test('Persistent timeout stops after three attempts', () async {
    var calls = 0;
    await expectLater(
      ReadRetry.run(
        'macro.overview',
        () async {
          calls++;
          throw TimeoutException('timeout');
        },
        wait: (_) async {},
        jitter: (_) => 0,
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(calls, 3);
  });
  test('Mutations and unknown methods never retry', () async {
    for (final method in [
      'membership.completeCheckout',
      'watchlist.add',
      'theme.create',
      'unknown.list',
    ]) {
      var calls = 0;
      await expectLater(
        ReadRetry.run(method, () async {
          calls++;
          throw const ServerpodClientNetworkException('lost response');
        }, wait: (_) async {}),
        throwsA(isA<ServerpodClientNetworkException>()),
      );
      expect(calls, 1);
    }
  });
  test('Permission and application errors never retry; gateways do', () async {
    for (final error in [
      ServerpodClientUnauthorized(),
      ServerpodClientForbidden(),
      ServerpodClientInternalServerError(),
      StateError('bad data'),
    ]) {
      var calls = 0;
      await expectLater(
        ReadRetry.run('company.overview', () async {
          calls++;
          throw error;
        }, wait: (_) async {}),
        throwsA(same(error)),
      );
      expect(calls, 1);
    }
    for (final code in [502, 503, 504]) {
      expect(
        ReadRetry.transient(ServerpodClientUnknownHttpException('', code)),
        isTrue,
      );
    }
  });
}
