import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../client.dart';

/// 종류별 마지막 수집 작업을 묻는 한 번의 왕복 (`ingest.latestOfKinds`).
typedef IngestJobsFetch = Future<List<IngestJob>> Function(List<String> kinds);

/// 서버의 수집 작업을 앱 전체에서 한 곳에서 지켜본다.
///
/// 수집은 버튼뿐 아니라 예약·이어받기로 서버가 스스로 시작하기도 한다. 어느 화면을 보고
/// 있든 작업이 끝나면 [dataVersion]을 올려 화면이 새 데이터를 다시 불러오게 하고,
/// 실행 중인지는 [running]으로 내비게이션에 보여준다.
class IngestMonitor {
  IngestMonitor._({IngestJobsFetch? fetch}) : _fetch = fetch ?? _fromServer;

  /// 테스트에서 서버 대신 응답을 쥐고 있을 때.
  @visibleForTesting
  IngestMonitor.test({required IngestJobsFetch fetch}) : this._(fetch: fetch);

  static final instance = IngestMonitor._();

  static Future<List<IngestJob>> _fromServer(List<String> kinds) =>
      client.ingest.latestOfKinds(kinds);

  final IngestJobsFetch _fetch;

  static const kinds = [
    'company_master',
    'financial_facts',
    'financial_facts_company',
    'market_snapshot',
    'business_documents',
    'disclosures',
    'disclosures_company',
    'ai_extraction',
  ];

  static const _runningInterval = Duration(seconds: 3);
  static const _idleInterval = Duration(seconds: 15);

  /// 수집이 끝날 때마다 1씩 오른다.
  final dataVersion = ValueNotifier<int>(0);

  /// 실행 중인 수집이 하나라도 있는지.
  final running = ValueNotifier<bool>(false);

  /// 종류별로 마지막으로 본 작업.
  final _seen = <String, IngestJob?>{};
  bool _started = false;
  bool _disposed = false;
  Timer? _timer;

  /// 도는 중인 확인의 번호. 새 확인이 시작되면 앞의 응답은 늦게 와도 버린다
  /// (poke를 여러 번 누르면 확인이 겹치고, 응답이 시작 순서대로 온다는 보장이 없다).
  int _run = 0;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _tick();
  }

  /// 버튼으로 수집을 시작했을 때처럼 바로 확인하고 싶을 때.
  void poke() {
    if (_disposed || !_started) return;
    _timer?.cancel();
    _tick();
  }

  /// 로그아웃하면 조회를 중단하고 이전 사용자의 수집 상태를 버린다.
  void stop() {
    _started = false;
    _run++;
    _timer?.cancel();
    _timer = null;
    _seen.clear();
    running.value = false;
  }

  /// 타이머를 멈추고, 도는 중인 확인의 응답은 버린다. 앱 전체의 [instance]는
  /// 앱과 수명이 같으므로 부르지 않는다 (테스트에서 만든 것을 정리할 때).
  @visibleForTesting
  void dispose() {
    _disposed = true;
    _run++;
    _timer?.cancel();
    _timer = null;
    dataVersion.dispose();
    running.dispose();
  }

  Future<void> _tick() async {
    final run = ++_run;
    List<IngestJob>? found;
    try {
      // 종류마다 따로 묻지 않고 한 번에 (15초마다 도는 확인이다).
      found = await _fetch(kinds);
    } catch (_) {
      // 일시적인 연결 오류는 다음 확인에서 다시 시도.
    }
    // 뒤에 시작한 확인이 있으면 이 응답은 옛것이다. 상태를 건드리기 전에 버려야
    // running이 되돌아가거나 같은 완료로 dataVersion이 두 번 오르지 않는다.
    if (run != _run || _disposed) return;
    if (found != null) _apply(found);
    _timer?.cancel();
    _timer = Timer(running.value ? _runningInterval : _idleInterval, _tick);
  }

  void _apply(List<IngestJob> found) {
    final byKind = {for (final j in found) j.kind: j};
    var finished = false;
    for (final kind in kinds) {
      final job = byKind[kind];
      if (_seen.containsKey(kind) && _finishedSince(_seen[kind], job)) {
        finished = true;
      }
      _seen[kind] = job;
    }
    running.value = found.any((j) => j.status == IngestStatus.running);
    if (finished) dataVersion.value++;
  }

  /// 앞서 본 작업이 끝났거나, 보지 못한 사이에 다른 작업이 돌고 끝났는지.
  static bool _finishedSince(IngestJob? before, IngestJob? now) {
    if (now == null || now.status == IngestStatus.running) return false;
    if (before == null) return true;
    return before.id != now.id || before.status == IngestStatus.running;
  }
}
