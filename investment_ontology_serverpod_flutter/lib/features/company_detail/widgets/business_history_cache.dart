import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

typedef BusinessHistoryFetch = Future<BusinessContent?> Function(String, int);

/// Shares only public source requests across panels. Missing/error results are
/// retried; a new filing or ingest version invalidates the whole generation.
class BusinessHistoryCache {
  BusinessHistoryCache(this.fetch);
  final BusinessHistoryFetch fetch;
  final _pending = <(String, int), Future<BusinessContent?>>{};
  Object? _generation;

  Future<BusinessContent?> read(String code, int year, Object generation) {
    if (_generation != generation) {
      _pending.clear();
      _generation = generation;
    }
    final key = (code, year);
    final existing = _pending[key];
    if (existing != null) return existing;
    // Bound retained documents while preserving concurrent requests per company.
    if (_pending.length >= 40) _pending.remove(_pending.keys.first);
    late Future<BusinessContent?> request;
    request = Future.sync(() => fetch(code, year)).then(
      (result) {
        if (result == null && identical(_pending[key], request)) {
          _pending.remove(key);
        }
        return result;
      },
      onError: (Object error, StackTrace stack) {
        if (identical(_pending[key], request)) _pending.remove(key);
        Error.throwWithStackTrace(error, stack);
      },
    );
    _pending[key] = request;
    return request;
  }
}
