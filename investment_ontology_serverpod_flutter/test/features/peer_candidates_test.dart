import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/screen/peer_candidates_panel.dart';

PeerCandidates fixture(String anchor) => PeerCandidates(
  status: 'ready',
  anchorName: anchor,
  signals: [PeerSignal(key: 'substrate', label: '기판 검사', evidence: '원문 기준기업')],
  bsnsYear: 2025,
  rceptNo: '20260319000682',
  ruleVersion: 3,
  items: [
    PeerCandidate(
      corpCode: '00000002',
      name: '비교후보',
      tier: 'product',
      reasons: ['기판 검사'],
      differences: ['매출 구성·고객 일치 미확인'],
      signals: [
        PeerSignal(key: 'substrate', label: '기판 검사', evidence: '원문 후보기업'),
      ],
      bsnsYear: 2025,
      rceptNo: '20260318001550',
    ),
  ],
);
void main() {
  Future<void> pump(
    WidgetTester tester,
    List<String> codes,
    Future<PeerCandidates> Function(String) load, {
    ValueChanged<String>? add,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(ledgerBrand),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PeerCandidatesPanel(
              codes: codes,
              loadCandidates: load,
              onAdd: add ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('mobile add and folded provenance', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? added;
    await pump(
      tester,
      ['00000001'],
      (code) async => fixture(code),
      add: (code) => added = code,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('원문 후보기업'), findsNothing);
    await tester.tap(find.text('추가'));
    expect(added, '00000002');
    await tester.tap(find.byTooltip('비교 이유 보기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('원문 후보기업'), findsNothing);
    await tester.tap(find.text('공시 근거 보기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('원문 후보기업'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('four company limit and selected candidate prevent additions', (
    tester,
  ) async {
    var count = 0;
    await pump(
      tester,
      ['1', '2', '3', '4'],
      (code) async => fixture(code),
      add: (_) => count++,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('추가'));
    expect(count, 0);
    await pump(
      tester,
      ['1', '00000002'],
      (code) async => fixture(code),
      add: (_) => count++,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('추가됨'));
    expect(count, 0);
  });
  testWidgets('out-of-order loads preserve new anchor', (tester) async {
    final first = Completer<PeerCandidates>();
    await pump(tester, ['1'], (_) => first.future);
    await pump(tester, ['2'], (_) async => fixture('new'));
    await tester.pumpAndSettle();
    first.complete(fixture('old'));
    await tester.pumpAndSettle();
    expect(find.text('new와 비교'), findsOneWidget);
    expect(find.text('old와 비교'), findsNothing);
  });
  testWidgets('unsupported state has no arbitrary peers', (tester) async {
    await pump(
      tester,
      ['1'],
      (_) async => PeerCandidates(
        status: 'unsupported',
        anchorName: '기업',
        signals: [],
        ruleVersion: 3,
        items: [],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('확인하지 못했습니다'), findsOneWidget);
    expect(find.text('추가'), findsNothing);
  });
}
