import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/watchlist/watchlist_store.dart';

WatchlistView view(String name) => WatchlistView(
  companies: [
    WatchlistCompanyView(
      corpCode: '00990001',
      name: name,
      muted: false,
      monitoringReady: false,
      active: true,
      unreadCount: 0,
    ),
  ],
  updates: [],
  limit: 3,
  paid: false,
  scanStatus: 'waiting',
  pushConfigured: false,
  workerEnabled: false,
);
void main() {
  test(
    'a late response from another account cannot expose its watchlist',
    () async {
      final a = Completer<WatchlistView>(), b = Completer<WatchlistView>();
      var calls = 0;
      final store = WatchlistStore(
        fetch: () => ++calls == 1 ? a.future : b.future,
        addCompany: (_) async {},
        removeCompany: (_) async {},
      );
      store.setOwner('a');
      store.setOwner('b');
      b.complete(view('B'));
      await Future<void>.delayed(Duration.zero);
      a.complete(view('A'));
      await Future<void>.delayed(Duration.zero);
      expect(store.view!.companies.single.name, 'B');
      store.setOwner(null);
      expect(store.view, isNull);
    },
  );
  test('a pre-write read cannot replace the result after a save', () async {
    final old = Completer<WatchlistView>();
    var calls = 0;
    final store = WatchlistStore(
      fetch: () => ++calls == 1 ? old.future : Future.value(view('new')),
      addCompany: (_) async {},
      removeCompany: (_) async {},
    );
    store.setOwner('a');
    await store.toggle('00990001');
    old.complete(view('old'));
    await Future<void>.delayed(Duration.zero);
    expect(store.view!.companies.single.name, 'new');
    expect(store.loading, isFalse);
  });
}
