import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_business_document.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/public_business_prefetch.dart';
import 'package:test/test.dart';

import 'public_business_document_test.dart' as source show receipt, shell;

PublicBusinessBody body(String receipt) => PublicBusinessBody(
  receipt: receipt,
  title: '사업의 내용',
  text: '실제 사업 설명',
  sourceUri: Uri.parse(
    'https://dart.fss.or.kr/report/viewer.do?rcpNo=$receipt',
  ),
  bodySha256: 'fixture',
);

void main() {
  test(
    'native shell and body GETs are gated by the sequential consumer',
    () async {
      var calls = 0;
      final reader = PublicBusinessDocument(
        client: MockClient((request) async {
          calls++;
          return http.Response(
            source.shell,
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }),
      );
      late PublicBusinessPrefetch pool;
      pool = PublicBusinessPrefetch(
        fetch: (receipt) => reader.fetchWithGate(receipt, pool.requestPermit),
        wait: (_) async {},
      );
      pool.reserve(source.receipt);
      var gates = 0;
      await expectLater(
        pool.take(source.receipt, beforeStart: () async => ++gates < 3),
        throwsA(isA<PublicBusinessFetchCancelled>()),
      );
      expect(calls, 1);
      expect(gates, 3);
    },
  );

  test('consumer gate stops GETs when cancelled during pacing', () async {
    var calls = 0;
    final pool = PublicBusinessPrefetch(
      fetch: (receipt) async {
        calls++;
        return body(receipt);
      },
      wait: (_) async {},
    );
    pool.reserve('first');
    pool.reserve('second');
    expect(await pool.take('first', beforeStart: () async => false), isNull);
    expect(await pool.take('second'), isNull);
    expect(calls, 0);
  });

  test(
    'native HTTP stop between shell and body issues no further GET',
    () async {
      var calls = 0;
      late PublicBusinessDocument reader;
      reader = PublicBusinessDocument(
        client: MockClient((request) async {
          calls++;
          reader.stop();
          return http.Response('cancelled shell', 200);
        }),
      );
      await expectLater(
        reader.fetch('20260310000001'),
        throwsA(isA<PublicBusinessFetchCancelled>()),
      );
      expect(calls, 1);
      await expectLater(
        reader.fetch('20260310000002'),
        throwsA(isA<PublicBusinessFetchCancelled>()),
      );
      expect(calls, 1);
    },
  );

  test('two HTTP slots overlap, paced starts, completion order does not change consumption', () async {
    var now = DateTime.utc(2026);
    final starts = <DateTime>[];
    final jobs = <String, Completer<PublicBusinessBody>>{};
    final pool = PublicBusinessPrefetch(
      fetch: (receipt) {
        starts.add(now);
        return (jobs[receipt] = Completer()).future;
      },
      clock: () => now,
      wait: (duration) async {
        now = now.add(duration);
      },
    );
    expect(pool.reserve('first'), isTrue);
    expect(pool.reserve('second'), isTrue);
    expect(pool.reserve('third'), isFalse);
    var firstDone = false;
    final first = pool.take('first').then((value) {
      firstDone = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(starts.length, 2);
    expect(starts[1].difference(starts[0]), const Duration(seconds: 1));
    jobs['second']!.complete(body('second'));
    await Future<void>.delayed(Duration.zero);
    expect(firstDone, isFalse);
    expect(pool.reserve('third'), isFalse);
    jobs['first']!.complete(body('first'));
    expect((await first)!.receipt, 'first');
    expect((await pool.take('second'))!.receipt, 'second');
    expect(pool.reserve('third'), isTrue);
    pool.stop();
    expect(await pool.take('third'), isNull);
  });

  test('observed cancellation prevents delayed launches; errors are held until consumed', () async {
    final delay = Completer<void>();
    var calls = 0;
    final pool = PublicBusinessPrefetch(
      fetch: (receipt) async {
        calls++;
        throw StateError('failure');
      },
      wait: (_) => delay.future,
    );
    pool.reserve('cancelled');
    pool.stop();
    delay.complete();
    expect(await pool.take('cancelled'), isNull);
    expect(calls, 0);
    final errorPool = PublicBusinessPrefetch(
      fetch: (receipt) async {
        throw StateError('verified transport failure');
      },
      wait: (_) async {},
    );
    errorPool.reserve('error');
    await Future<void>.delayed(Duration.zero);
    await expectLater(errorPool.take('error'), throwsStateError);
  });
}
