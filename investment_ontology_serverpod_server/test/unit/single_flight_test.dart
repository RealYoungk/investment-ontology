import 'dart:async';

import 'package:investment_ontology_serverpod_server/src/ontology/cache/single_flight.dart';
import 'package:test/test.dart';

void main() {
  test(
    'concurrent cold reads share work, but completed results are not cached',
    () async {
      final gate = SingleFlight<int>();
      final finished = Completer<int>();
      var reads = 0;
      Future<int> read() {
        reads++;
        return finished.future;
      }

      final requests = List.generate(8, (_) => gate.run(read));
      expect(reads, 1);
      finished.complete(42);
      expect(await Future.wait(requests), everyElement(42));
      expect(
        await gate.run(() async {
          reads++;
          return 43;
        }),
        43,
      );
      expect(reads, 2);
    },
  );
  test('failed concurrent reads can be retried', () async {
    final gate = SingleFlight<int>();
    final failed = Completer<int>();
    var reads = 0;
    final requests = List.generate(
      3,
      (_) => gate.run(() {
        reads++;
        return failed.future;
      }),
    );
    final checked = requests
        .map((f) => expectLater(f, throwsStateError))
        .toList();
    failed.completeError(StateError('temporary database failure'));
    await Future.wait(checked);
    expect(reads, 1);
    expect(await gate.run(() async => 7), 7);
  });
}
