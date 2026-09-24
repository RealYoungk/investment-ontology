import 'dart:async';

/// Shares only an in-flight read. Success and failure both allow a later retry.
class SingleFlight<T> {
  Future<T>? _pending;

  Future<T> run(Future<T> Function() read) {
    return _pending ??= Future<T>.sync(read)
        .whenComplete(() => _pending = null);
  }
}
