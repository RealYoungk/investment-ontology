import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/shareholder_rights/shareholder_rights_card.dart';

void main() {
  final fixture = jsonEncode({
    'state': 'ready',
    'historyState': 'ready',
    'reportName': '반기보고서 (2026.06)',
    'history': {
      'history': [
        {'date': '2026-03-18', 'content': '이사 임기 조문 정비', 'reason': '조문 정비'},
      ],
    },
    'proposal': {
      'meetingDate': '2026-03-18',
      'sourceUrl': 'https://images.samsung.com/notice.pdf',
      'sourcePages': [37, 38, 39],
      'changes': [
        {
          'topic': '이사회 견제',
          'title': '이사 임기: 3년 고정 → 최대 3년',
          'beforeShort': '임기는 3년',
          'afterShort': '임기는 3년 이내',
          'before': '제25조 임기는 3년으로 한다.',
          'after': '제25조 임기는 3년을 초과하지 못한다.',
          'reason': '임기 조문 정비',
          'meaning': '3년보다 짧은 임기도 정할 수 있습니다.',
        },
      ],
    },
  });
  testWidgets('안내문 대신 변경 전후·의미와 원문을 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(ledgerBrand),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShareholderRightsCard(
              corpCode: '00126380',
              load: (_) async => fixture,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('임기는 3년'), findsOneWidget);
    expect(find.text('임기는 3년 이내'), findsOneWidget);
    expect(find.text('3년보다 짧은 임기도 정할 수 있습니다.'), findsOneWidget);
    await tester.tap(find.text('변경 전후 원문 · 변경 사유'));
    await tester.pumpAndSettle();
    expect(find.text('제25조 임기는 3년으로 한다.'), findsOneWidget);
    expect(find.text('제25조 임기는 3년을 초과하지 못한다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('390px에서 비교를 세로로 표시하고 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(ledgerBrand),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShareholderRightsCard(
              corpCode: '00126380',
              load: (_) async => fixture,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('임기는 3년 이내')).dy,
      greaterThan(tester.getTopLeft(find.text('임기는 3년')).dy),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('DART HTML 비교표와 부분 확보 상태를 PDF 페이지 없이 표시한다', (tester) async {
    final data = jsonDecode(fixture) as Map<String, dynamic>;
    final proposal = data['proposal'] as Map<String, dynamic>;
    proposal.remove('sourcePages');
    proposal.remove('meetingDate');
    proposal['filingDate'] = '2026-09-17';
    proposal['sourceUrl'] =
        'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260917000001';
    data['noticeState'] = 'partial';
    data['noticeCount'] = 2;
    data['inspectedCount'] = 1;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(ledgerBrand),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShareholderRightsCard(
              corpCode: '00159218',
              load: (_) async => jsonEncode(data),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('최근 1년 소집공고 · 1/2건 확인'), findsOneWidget);
    expect(find.textContaining('2026-09-17 소집공고 개정안'), findsOneWidget);
    expect(find.textContaining('신구조문 대비표 · DART 원문'), findsOneWidget);
    expect(find.textContaining('변경이 없다는 뜻은 아닙니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
