import 'package:flutter/foundation.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../../client.dart';
import '../auth/app_auth.dart';

/// One account-scoped source for the page and every save button. Epoch checks
/// prevent a prior account's slow response from replacing the current account.
class WatchlistStore extends ChangeNotifier {
  WatchlistStore({
    required this.fetch,
    required this.addCompany,
    required this.removeCompany,
  });
  final Future<WatchlistView> Function() fetch;
  final Future<void> Function(String) addCompany;
  final Future<void> Function(String) removeCompany;
  static final instance = _create();
  static WatchlistStore _create() {
    final store = WatchlistStore(
      fetch: () => client.watchlist.mine(),
      addCompany: (code) => client.watchlist.add(code),
      removeCompany: (code) => client.watchlist.remove(code),
    );
    void sync() => store.setOwner(AppAuth.viewer.value?.userId);
    AppAuth.viewer.addListener(sync);
    sync();
    return store;
  }

  String? owner;
  WatchlistView? view;
  String? error;
  bool loading = false;
  final busyCodes = <String>{};
  int _epoch = 0;
  int _read = 0;
  bool contains(String code) =>
      view?.companies.any((c) => c.corpCode == code) ?? false;
  void setOwner(String? value) {
    if (owner == value) return;
    owner = value;
    view = null;
    error = null;
    loading = false;
    busyCodes.clear();
    _epoch++;
    notifyListeners();
    if (value != null) refresh();
  }

  Future<void> refresh() async {
    if (owner == null) return;
    final epoch = _epoch;
    final read = ++_read;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final next = await fetch();
      if (epoch == _epoch && read == _read) view = next;
    } catch (_) {
      if (epoch == _epoch && read == _read) {
        error = '관심종목을 불러오지 못했습니다. 다시 시도해 주세요.';
      }
    } finally {
      if (epoch == _epoch && read == _read) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> toggle(String code) async {
    if (owner == null || busyCodes.contains(code)) return;
    final epoch = _epoch;
    busyCodes.add(code);
    notifyListeners();
    try {
      if (contains(code)) {
        await removeCompany(code);
      } else {
        await addCompany(code);
      }
      if (epoch == _epoch) {
        // A refresh that began before the write must not leave stale save state.
        final read = ++_read;
        loading = false;
        final next = await fetch();
        if (epoch == _epoch && read == _read) view = next;
      }
    } finally {
      if (epoch == _epoch) {
        busyCodes.remove(code);
        notifyListeners();
      }
    }
  }
}
