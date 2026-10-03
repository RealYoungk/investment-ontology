import '../support/shad_test_host.dart';

import 'package:investment_ontology_serverpod_flutter/features/financials/financial_section.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/statement_availability_notice.dart';

Source source(bool cfs) => Source(
  id: cfs ? 1 : 2,
  kind: SourceKind.dartReport,
  reference:
      'financial-source-not-presented:20260324000091:${cfs ? 'consolidated' : 'separate'}',
  url: jsonDecode(
    File('test/fixtures/statement_availability/${cfs ? 'cfs' : 'ofs'}.json')
        .readAsStringSync(),
  )['evidence']['statementSource'],
  retrievedAt: DateTime.utc(2026),
  title: File(
    'test/fixtures/statement_availability/${cfs ? 'cfs' : 'ofs'}.json',
  ).readAsStringSync(),
);
void main() {
  test(
    'generated client optional Source list roundtrips nonempty/empty/null',
    () {
      for (final sources in <List<Source>?>[
        null,
        [],
        [source(true), source(false)],
      ]) {
        final dto = CompanyFinancials(
          corpCode: '00442455',
          availableFsDivs: [],
          periods: [],
          filingCount: 1,
          pendingFilingCount: 1,
          statementAvailabilitySources: sources,
        );
        final copy = CompanyFinancials.fromJson(
          jsonDecode(jsonEncode(dto.toJson())) as Map<String, dynamic>,
        );
        expect(copy.statementAvailabilitySources?.length, sources?.length);
        if (sources?.isNotEmpty ?? false) {
          expect(
            copy.statementAvailabilitySources!.first.title,
            sources!.first.title,
          );
        }
      }
    },
  );

  test('unknown foreign/complete/zero-fill proof never becomes availability notice', () {
    for (final cfs in [true, false]) {
      final s = source(cfs);
      expect(StatementAvailabilityNotice.evidence(s, '00442455'), isNotNull);
      expect(StatementAvailabilityNotice.evidence(s, '00000000'), isNull);
      for (final field in [
        'collectionComplete',
        'basisNotApplicable',
        'financialFactsStored',
        'notesVerified',
        'fullStatementCollected',
      ]) {
        final j = jsonDecode(s.title);
        j['evidence'][field] = true;
        expect(
          StatementAvailabilityNotice.evidence(
            s.copyWith(title: jsonEncode(j)),
            '00442455',
          ),
          isNull,
        );
      }
      for (final field in [
        'receipt',
        'corpCode',
        'periodEnd',
        'statementSha256',
      ]) {
        final j = jsonDecode(s.title);
        j['evidence'][field] = 'foreign';
        expect(
          StatementAvailabilityNotice.evidence(
            s.copyWith(title: jsonEncode(j)),
            '00442455',
          ),
          isNull,
        );
      }
      expect(
        StatementAvailabilityNotice.evidence(
          s.copyWith(url: 'https://example.com'),
          '00442455',
        ),
        isNull,
      );
    }
  });
  testWidgets(
    'source-confirmed unsubmitted empty view does not imply undownloaded body',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final data = CompanyFinancials(
        corpCode: '00442455',
        availableFsDivs: [],
        periods: [],
        filingCount: 1,
        pendingFilingCount: 1,
        statementAvailabilitySources: [source(true), source(false)],
      );
      await t.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FinancialSection(
                    corpCode: '00442455',
                    initialData: data,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('공식 원문을 확인했지만 해당 기간의 당기 재무 숫자는 제시되지 않았습니다.'),
        findsOneWidget,
      );
      expect(find.textContaining('건을 아직 받지'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    '320px failed current notice wraps, preserves missing semantics and exposes exact official links',
    (t) async {
      await t.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final opened = <Uri>[];
      await t.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StatementAvailabilityNotice(
                    corpCode: '00442455',
                    sources: [source(true), source(false)],
                    onOpen: opened.add,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('2025년 연결·별도 당기 재무제표'), findsOneWidget);
      expect(find.textContaining('수집 실패'), findsOneWidget);
      expect(find.textContaining('0으로 채우지 않습니다'), findsOneWidget);
      final box = t.renderObject<RenderBox>(find.textContaining('수집 실패'));
      expect(box.size.width, lessThanOrEqualTo(288));
      expect(box.size.height, greaterThan(40));
      await t.tap(find.text('연결 미제시 근거 · 출처 #1'));
      await t.pumpAndSettle();
      await t.tap(find.text('공식 감사첨부').first);
      await t.pump();
      expect(opened.single.toString(), contains('dcmNo=11171059'));
      expect(t.takeException(), isNull);
    },
  );
}
