import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

final industryDiscoveryCache = IndustryDiscoveryCache();

/// Reuse the universe across page visits, including concurrent requests.
/// The app-wide ingest monitor invalidates it when shared data changes.
class IndustryDiscoveryCache {
  final _entries = <String, IndustryDiscoveryCacheEntry>{};

  Future<IndustryDiscovery> read(
    String industry,
    int version,
    Future<IndustryDiscovery> Function() fetch,
  ) => (_entries[industry] ??= IndustryDiscoveryCacheEntry()).read(
    version,
    fetch,
  );
}

class IndustryDiscoveryCacheEntry {
  int? _version;
  Future<IndustryDiscovery>? _pending;
  DateTime? _loadedAt;

  Future<IndustryDiscovery> read(
    int version,
    Future<IndustryDiscovery> Function() fetch,
  ) {
    if (_version == version &&
        _pending != null &&
        DateTime.now().difference(_loadedAt!).inMinutes < 5) {
      return _pending!;
    }
    _version = version;
    _loadedAt = DateTime.now();
    final pending = Future<IndustryDiscovery>.sync(fetch);
    _pending = pending;
    // Failed reads are retryable. Do not clear a newer version's request.
    pending.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        if (identical(_pending, pending)) _pending = null;
      },
    );
    return pending;
  }
}
