import '../support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/data_sync/widgets/schedule_board.dart';

void main() {
  final now = DateTime.utc(2026, 10, 3);
  Widget page(IngestStatus status, {VoidCallback? cancel}) => MaterialApp(
    theme: buildAppTheme(ledgerBrand),
    home: Scaffold(
      body: MarketSecurityRelinkStatus(
        now: now,
        onCancel: cancel,
        entry: IngestScheduleEntry(
          kind: 'market_security_relink',
          label: '기존 종목 재연결',
          timing: '기업 기본정보 변경 후',
          resuming: true,
          lastJob: IngestJob(
            id: 1,
            kind: 'market_security_relink',
            status: status,
            startedAt: now,
            updated: 2,
            message: status == IngestStatus.running
                ? '시장 작업 종료 후 기존 종목 재연결 대기'
                : '기존 종목 2개 재연결 · 시세 API 호출 없음',
          ),
        ),
      ),
    ),
  );
  testWidgets('대기 작업은 시세와 구분하며 정상 취소 콜백을 제공한다', (tester) async {
    var cancelled = 0;
    await tester.pumpWidget(
      shadTestHost(page(IngestStatus.running, cancel: () => cancelled++)),
    );
    expect(find.text('기존 종목 재연결 · 시세 API 호출 없음'), findsOneWidget);
    expect(find.text('시장 작업 종료 후 기존 종목 재연결 대기'), findsOneWidget);
    await tester.tap(find.text('재연결 중단'));
    expect(cancelled, 1);
    expect(find.text('최근 수집 완료'), findsNothing);
  });
  testWidgets('완료는 시세 완료로 표시하지 않고 취소 버튼을 숨긴다', (tester) async {
    await tester.pumpWidget(
      shadTestHost(page(IngestStatus.succeeded)),
    );
    expect(find.text('기존 종목 재연결 완료'), findsOneWidget);
    expect(find.text('기존 종목 2개 재연결 · 시세 API 호출 없음'), findsOneWidget);
    expect(find.text('최근 수집 완료'), findsNothing);
    expect(find.text('재연결 중단'), findsNothing);
  });
}
