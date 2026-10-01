import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_events/company_events_section.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_events/filing_event.dart';

DartDisclosure filing(String title, int id, {String corp = '00126380'}) =>
    DartDisclosure(
      rceptNo: '20261001${id.toString().padLeft(6, '0')}',
      corpCode: corp,
      corpName: '예시기업',
      reportName: title,
      receivedDate: DateTime.utc(2026, 10, 1),
      discoveredAt: DateTime.utc(2026, 10, 1),
      filerName: '제출인',
    );
Widget app(Widget child) => MaterialApp(
  theme: buildAppTheme(ledgerBrand),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
void main() {
  test('정정·철회·결정을 보존하며 실행이나 매수로 단정하지 않는다', () {
    final cases = {
      '[기재정정]주요사항보고서(자기주식취득결정)': FilingTopic.returns,
      '임원ㆍ주요주주특정증권등소유상황보고서': FilingTopic.ownership,
      '최대주주등소유주식변동신고서': FilingTopic.ownership,
      '[철회]주요사항보고서(유상증자결정)': FilingTopic.financing,
      '주요사항보고서(회사합병결정)': FilingTopic.business,
      '주요사항보고서(소송등의제기)': FilingTopic.risk,
      '분기보고서 (2026.03)': FilingTopic.results,
      '의결권대리행사권유참고서류': FilingTopic.other,
    };
    for (final entry in cases.entries) {
      expect(FilingEvent(filing(entry.key, 1)).topic, entry.value);
    }
    expect(FilingEvent(filing(cases.keys.first, 1)).stage, '정정 공시');
    expect(FilingEvent(filing('[철회]주요사항보고서(유상증자결정)', 1)).stage, '철회 공시');
    expect(FilingEvent(filing('자기주식취득결정', 1)).stage, '결정 공시');
    expect(
      FilingEvent(filing('보고서', 1).copyWith(rceptNo: 'https://example.com'))
          .source,
      isNull,
    );
  });
  test('동일 접수번호만 중복 제거하고 정정 공시는 유지', () {
    final original = filing('사업보고서', 1);
    final corrected = filing('[기재정정]사업보고서', 2);
    expect(
      filingEvents([original, corrected, original])
          .map((e) => e.filing.rceptNo),
      [corrected.rceptNo, original.rceptNo],
    );
  });
  for (final width in [320.0, 768.0, 1280.0]) {
    testWidgets('모바일·확대 글꼴 필터와 원문 ($width)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Uri? opened;
      await tester.pumpWidget(
        app(
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1800),
              textScaler: const TextScaler.linear(1.4),
            ),
            child: CompanyEventsSection(
              corpCode: '00126380',
              loader: (_) async => [
                filing('[기재정정]자기주식취득결정', 1),
                filing('유상증자결정', 2),
              ],
              openSource: (uri) => opened = uri,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('수집된 최근 2건'), findsOneWidget);
      await tester.tap(find.text('주주환원 1'));
      await tester.pumpAndSettle();
      expect(find.text('유상증자결정'), findsNothing);
      expect(find.text('정정 공시'), findsOneWidget);
      await tester.ensureVisible(find.text('공시 원문'));
      await tester.tap(find.text('공시 원문'));
      expect(opened?.host, 'dart.fss.or.kr');
      expect(opened?.queryParameters['rcpNo'], '20261001000001');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('실패와 미수집을 구별하고 재시도', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      app(
        CompanyEventsSection(
          corpCode: '00126380',
          loader: (_) async {
            if (attempts++ == 0) throw Exception('offline');
            return [];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('공시를 불러오지 못했습니다.'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('아직 수집된 공시 이력이 없습니다.'), findsOneWidget);
    expect(find.text('공시나 기업 변화가 없다는 뜻은 아닙니다.'), findsOneWidget);
  });
  testWidgets('기업 전환 후 늦은 응답은 새 기업을 덮어쓰지 않는다', (tester) async {
    final old = Completer<List<DartDisclosure>>();
    Future<List<DartDisclosure>> loader(String code) async =>
        code == 'old' ? old.future : [filing('새 기업 분기보고서', 2)];
    await tester.pumpWidget(
      app(CompanyEventsSection(corpCode: 'old', loader: loader)),
    );
    await tester.pumpWidget(
      app(CompanyEventsSection(corpCode: 'new', loader: loader)),
    );
    await tester.pumpAndSettle();
    old.complete([filing('이전 기업 사업보고서', 1)]);
    await tester.pumpAndSettle();
    expect(find.text('새 기업 분기보고서'), findsOneWidget);
    expect(find.text('이전 기업 사업보고서'), findsNothing);
  });
  testWidgets('긴 목록은 더 보기로 확장하고 주제 전환 시 초기화', (tester) async {
    await tester.pumpWidget(
      app(
        CompanyEventsSection(
          corpCode: '00126380',
          loader: (_) async => [
            for (var i = 1; i <= 8; i++) filing('유상증자결정 $i', i),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('유상증자결정 1'), findsNothing);
    await tester.ensureVisible(find.text('공시 더 보기 · 2건 남음'));
    await tester.tap(find.text('공시 더 보기 · 2건 남음'));
    await tester.pumpAndSettle();
    expect(find.text('유상증자결정 1'), findsOneWidget);
    await tester.ensureVisible(find.text('자금조달 8'));
    await tester.tap(find.text('자금조달 8'));
    await tester.pumpAndSettle();
    expect(find.text('유상증자결정 1'), findsNothing);
  });
}
