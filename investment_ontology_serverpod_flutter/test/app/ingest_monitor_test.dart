import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/app/ingest_monitor.dart';

/// 서버 대신 응답을 쥐고 있다가 테스트가 고른 순서로 돌려준다.
class _FakeServer {
  final calls = <Completer<List<IngestJob>>>[];

  Future<List<IngestJob>> fetch(List<String> kinds) {
    final c = Completer<List<IngestJob>>();
    calls.add(c);
    return c.future;
  }
}

IngestJob _job(int id, IngestStatus status) => IngestJob(
  id: id,
  kind: 'financial_facts',
  status: status,
  startedAt: DateTime.utc(2026, 9, 22),
);

void main() {
  testWidgets('DB 전용 종목 재연결 완료도 공통 데이터 버전을 갱신한다', (tester) async {
    final server = _FakeServer();
    final monitor = IngestMonitor.test(
      fetch: (kinds) {
        expect(kinds, contains('market_security_relink'));
        return server.fetch(kinds);
      },
    );
    monitor.start();
    server.calls[0].complete([
      _job(91, IngestStatus.running).copyWith(kind: 'market_security_relink'),
    ]);
    await tester.pump();
    expect(monitor.running.value, isTrue);
    monitor.poke();
    server.calls[1].complete([
      _job(91, IngestStatus.succeeded).copyWith(kind: 'market_security_relink'),
    ]);
    await tester.pump();
    expect(monitor.dataVersion.value, 1);
    expect(monitor.running.value, isFalse);
    monitor.dispose();
  });

  // testWidgets의 가짜 시계로 3초·15초 타이머를 기다리지 않고 넘긴다.
  testWidgets('겹친 확인이 거꾸로 돌아오면 옛 응답은 버린다', (tester) async {
    final server = _FakeServer();
    final monitor = IngestMonitor.test(fetch: server.fetch);

    monitor.start();
    expect(server.calls, hasLength(1));
    server.calls[0].complete([_job(1, IngestStatus.running)]);
    await tester.pump();
    expect(monitor.running.value, isTrue);
    expect(monitor.dataVersion.value, 0);

    // 버튼을 두 번 눌러 확인이 겹친다: 1이 먼저 나갔고 2가 나중에 나갔다.
    monitor.poke();
    monitor.poke();
    expect(server.calls, hasLength(3));

    // 나중 확인(2)이 먼저 돌아온다: 작업이 끝났다.
    server.calls[2].complete([_job(1, IngestStatus.succeeded)]);
    await tester.pump();
    expect(monitor.running.value, isFalse);
    expect(monitor.dataVersion.value, 1);

    // 먼저 나간 확인(1)이 늦게 돌아온다: 아직 돌던 때의 모습이다.
    server.calls[1].complete([_job(1, IngestStatus.running)]);
    await tester.pump();
    expect(monitor.running.value, isFalse, reason: '옛 응답이 running을 되돌림');
    expect(monitor.dataVersion.value, 1);

    // 옛 응답은 타이머도 걸지 않는다: 도는 중 간격(3초)에는 아무도 묻지 않는다.
    await tester.pump(const Duration(seconds: 3));
    expect(server.calls, hasLength(3));

    // 쉬는 중 간격(15초)에 다음 확인. 같은 완료를 다시 보아도 두 번 세지 않는다.
    await tester.pump(const Duration(seconds: 12));
    expect(server.calls, hasLength(4));
    server.calls[3].complete([_job(1, IngestStatus.succeeded)]);
    await tester.pump();
    expect(monitor.running.value, isFalse);
    expect(monitor.dataVersion.value, 1, reason: '같은 완료를 두 번 셈');

    monitor.dispose();
  });

  testWidgets('일시적인 오류 뒤에는 다음 간격에 다시 묻는다', (tester) async {
    final server = _FakeServer();
    final monitor = IngestMonitor.test(fetch: server.fetch);

    monitor.start();
    server.calls[0].completeError(StateError('연결 끊김'));
    await tester.pump();
    expect(monitor.running.value, isFalse);
    expect(monitor.dataVersion.value, 0);

    // 오류가 나도 타이머가 걸려 15초 뒤 다시 묻는다.
    await tester.pump(const Duration(seconds: 15));
    expect(server.calls, hasLength(2));
    server.calls[1].complete([_job(7, IngestStatus.running)]);
    await tester.pump();
    expect(monitor.running.value, isTrue);

    // 겹친 확인에서 나중 것이 오류로 끝나도 다시 시도하고,
    // 늦게 온 먼저 것의 응답은 여전히 버린다.
    monitor.poke();
    monitor.poke();
    expect(server.calls, hasLength(4));
    server.calls[3].completeError(StateError('연결 끊김'));
    await tester.pump();
    server.calls[2].complete([_job(7, IngestStatus.succeeded)]);
    await tester.pump();
    expect(monitor.running.value, isTrue, reason: '옛 응답이 상태를 바꿈');
    expect(monitor.dataVersion.value, 0);

    // 오류 때의 running(도는 중)에 맞춰 3초 뒤 다시 묻고, 이번엔 끝난 것을 센다.
    await tester.pump(const Duration(seconds: 3));
    expect(server.calls, hasLength(5));
    server.calls[4].complete([_job(7, IngestStatus.succeeded)]);
    await tester.pump();
    expect(monitor.running.value, isFalse);
    expect(monitor.dataVersion.value, 1);

    monitor.dispose();
  });

  testWidgets('dispose 뒤에 돌아온 응답과 타이머는 아무것도 하지 않는다', (tester) async {
    final server = _FakeServer();
    final monitor = IngestMonitor.test(fetch: server.fetch);

    monitor.start();
    server.calls[0].complete(const []);
    await tester.pump();
    monitor.poke();
    monitor.dispose();

    server.calls[1].complete([_job(1, IngestStatus.running)]);
    await tester.pump(const Duration(seconds: 30));
    expect(server.calls, hasLength(2));
    monitor.poke();
    expect(server.calls, hasLength(2));
  });
  testWidgets('로그아웃 중단은 진행 응답을 버리고 다음 로그인에서 다시 시작한다', (tester) async {
    final server = _FakeServer();
    final monitor = IngestMonitor.test(fetch: server.fetch);
    monitor.start();
    monitor.stop();
    server.calls.single.complete([_job(1, IngestStatus.running)]);
    await tester.pump(const Duration(seconds: 30));
    expect(monitor.running.value, isFalse);
    expect(server.calls, hasLength(1));
    monitor.poke();
    expect(server.calls, hasLength(1));
    monitor.start();
    expect(server.calls, hasLength(2));
    server.calls.last.complete([_job(2, IngestStatus.running)]);
    await tester.pump();
    expect(monitor.running.value, isTrue);
    monitor.dispose();
  });
}
