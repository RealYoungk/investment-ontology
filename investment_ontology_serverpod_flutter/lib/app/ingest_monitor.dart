import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../client.dart';

/// 서버의 수집 작업을 앱 전체에서 한 곳에서 지켜본다.
///
/// 수집은 버튼뿐 아니라 예약·이어받기로 서버가 스스로 시작하기도 한다. 어느 화면을 보고
/// 있든 작업이 끝나면 [dataVersion]을 올려 화면이 새 데이터를 다시 불러오게 하고,
/// 실행 중인지는 [running]으로 내비게이션에 보여준다.
class IngestMonitor {
  IngestMonitor._();

  static final instance = IngestMonitor._();

  static const kinds = [
    'company_master',
    'financial_facts',
    'financial_facts_company',
    'market_snapshot',
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
  Timer? _timer;

  void start() {
    if (_started) return;
    _started = true;
    _tick();
  }

  /// 버튼으로 수집을 시작했을 때처럼 바로 확인하고 싶을 때.
  void poke() {
    _timer?.cancel();
    _tick();
  }

  Future<void> _tick() async {
    try {
      final jobs = await Future.wait([
        for (final kind in kinds) client.ingest.latestOf(kind),
      ]);
      var finished = false;
      for (final (i, kind) in kinds.indexed) {
        final job = jobs[i];
        if (_seen.containsKey(kind) && _finishedSince(_seen[kind], job)) {
          finished = true;
        }
        _seen[kind] = job;
      }
      running.value = jobs.any((j) => j?.status == IngestStatus.running);
      if (finished) dataVersion.value++;
    } catch (_) {
      // 일시적인 연결 오류는 다음 확인에서 다시 시도.
    }
    _timer = Timer(running.value ? _runningInterval : _idleInterval, _tick);
  }

  /// 앞서 본 작업이 끝났거나, 보지 못한 사이에 다른 작업이 돌고 끝났는지.
  static bool _finishedSince(IngestJob? before, IngestJob? now) {
    if (now == null || now.status == IngestStatus.running) return false;
    if (before == null) return true;
    return before.id != now.id || before.status == IngestStatus.running;
  }
}
