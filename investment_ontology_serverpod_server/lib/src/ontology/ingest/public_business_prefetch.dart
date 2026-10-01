import 'dart:async';
import 'dart:collection';

import '../dart/public_business_document.dart';

/// At most two reserved HTTP results. No database or ingest state is touched.
/// Results (including failures) are consumed by the coordinator in ledger order.
class PublicBusinessPrefetch {
  PublicBusinessPrefetch({
    required this.fetch,
    Duration interval = const Duration(seconds: 1),
    DateTime Function()? clock,
    Future<void> Function(Duration)? wait,
  }) : interval = interval < const Duration(seconds: 1)
           ? const Duration(seconds: 1)
           : interval,
       _clock = clock ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  final Future<PublicBusinessBody> Function(String receipt) fetch;
  final Duration interval;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _wait;
  final _results = <String, Future<_Result>>{};
  Future<void> _launchTail = Future.value();
  DateTime? _lastStart;
  bool _stopped = false;
  final _ready = Queue<Completer<bool>>();
  Completer<void> _readyChanged = Completer<void>();
  bool get isEmpty => _results.isEmpty;
  bool contains(String receipt) => _results.containsKey(receipt);

  bool reserve(String receipt) {
    if (_stopped || _results.length >= 2 || contains(receipt)) return false;
    final result = Completer<_Result>();
    _results[receipt] = result.future;
    _launchTail = _launchTail.then((_) async {
      final now = _clock();
      final start = (_lastStart ?? now).add(interval);
      if (start.isAfter(now)) await _wait(start.difference(now));
      if (_stopped) {
        result.complete(const _Result());
        return;
      }
      if (!await requestPermit() || _stopped) {
        result.complete(const _Result());
        return;
      }
      _lastStart = _clock();
      // Serialize only request starts; network latency can overlap.
      unawaited(() async {
        try {
          result.complete(_Result(body: await fetch(receipt)));
        } catch (error, stack) {
          result.complete(_Result(error: error, stack: stack));
        }
      }());
    });
    return true;
  }

  /// HTTP tasks request permission; only [take] executes the caller's DB gate.
  Future<bool> requestPermit() {
    if (_stopped) return Future.value(false);
    final permit = Completer<bool>();
    _ready.add(permit);
    _readyChanged.complete();
    _readyChanged = Completer<void>();
    return permit.future;
  }

  /// Only the sequential consumer runs [beforeStart]; HTTP tasks never query DB.
  Future<PublicBusinessBody?> take(
    String receipt, {
    Future<bool> Function()? beforeStart,
  }) async {
    final future = _results[receipt];
    if (future == null) return null;
    var done = false;
    unawaited(
      future.then((_) {
        done = true;
      }),
    );
    while (!done) {
      if (_ready.isNotEmpty) {
        final permit = _ready.removeFirst();
        final allowed = !_stopped && (await beforeStart?.call() ?? true);
        if (!allowed) stop();
        permit.complete(allowed);
      } else {
        await Future.any<void>([future.then((_) {}), _readyChanged.future]);
      }
    }
    final result = await future;
    unawaited(_results.remove(receipt));
    if (result.error != null) {
      Error.throwWithStackTrace(result.error!, result.stack!);
    }
    return result.body;
  }

  /// Pending launches stop; already-issued HTTP requests can finish but the
  /// coordinator must recheck cancellation before storing any result.
  void stop() {
    _stopped = true;
    while (_ready.isNotEmpty) {
      _ready.removeFirst().complete(false);
    }
  }
}

class _Result {
  const _Result({this.body, this.error, this.stack});
  final PublicBusinessBody? body;
  final Object? error;
  final StackTrace? stack;
}
