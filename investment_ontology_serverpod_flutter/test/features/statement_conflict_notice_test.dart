import '../support/shad_test_host.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/statement_conflict_notice.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/statement_availability_notice.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/financial_section.dart';

final sources = Directory('test/fixtures/statement_conflicts')
    .listSync()
    .whereType<File>()
    .map(
      (f) => Source.fromJson(
        jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
      ),
    )
    .toList();
void main() {
  test('seven finite current conflict proofs client DTO and forged witness rejection', () {
    expect(sources, hasLength(7));
    for (final s in sources) {
      final data = jsonDecode(s.title) as Map;
      final corp = data['corpCode'] as String;
      expect(StatementConflictNotice.evidence(s, corp), isNotNull);
      expect(StatementConflictNotice.evidence(s, '00000000'), isNull);
      for (final field in [
        'fullStatementCollected',
        'collectionComplete',
        'notesVerified',
        'noData',
        'financialFactsStored',
      ]) {
        final m = jsonDecode(s.title) as Map;
        (m['evidence'] as Map)[field] = true;
        expect(
          StatementConflictNotice.evidence(
            s.copyWith(title: jsonEncode(m)),
            corp,
          ),
          isNull,
          reason: field,
        );
      }
      for (final field in [
        'statementSha256',
        'statementSource',
        'reason',
        'periodEnd',
      ]) {
        final m = jsonDecode(s.title) as Map;
        (m['evidence'] as Map)[field] = 'foreign';
        expect(
          StatementConflictNotice.evidence(
            s.copyWith(title: jsonEncode(m)),
            corp,
          ),
          isNull,
          reason: field,
        );
      }
      expect(
        StatementConflictNotice.evidence(
          s.copyWith(reference: 'foreign'),
          corp,
        ),
        isNull,
      );
      expect(
        StatementConflictNotice.evidence(
          s.copyWith(kind: SourceKind.manual),
          corp,
        ),
        isNull,
      );
      for (final list in [
        <Source>[s],
        <Source>[],
        null,
      ]) {
        final dto = CompanyFinancials(
          corpCode: corp,
          availableFsDivs: [],
          periods: [],
          filingCount: 1,
          pendingFilingCount: 1,
          statementAvailabilitySources: list,
        );
        final back = CompanyFinancials.fromJson(
          jsonDecode(jsonEncode(dto.toJson())) as Map<String, dynamic>,
        );
        expect(
          back.statementAvailabilitySources?.map((s) => s.toJson()).toList(),
          list?.map((s) => s.toJson()).toList(),
        );
      }
    }
  });
  testWidgets(
    '320px source conflict distinguishes original confirmed failure and opens exact original',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = sources.firstWhere(
        (s) => jsonDecode(s.title)['corpCode'] == '00233653',
      );
      Uri? opened;
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: StatementAvailabilityNotice(
                  corpCode: '00233653',
                  sources: [s],
                  onOpen: (uri) => opened = uri,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('수집 실패로 남아'), findsOneWidget);
      expect(find.textContaining('당기 재무제표가 원문에서 제시되지'), findsNothing);
      await tester.tap(find.textContaining('원문 충돌 근거'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('공식 재무제표 원문'));
      await tester.tap(find.text('공식 재무제표 원문'));
      expect(opened.toString(), s.url);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: FinancialSection(
                  corpCode: '00233653',
                  dataVersion: 0,
                  initialData: CompanyFinancials(
                    corpCode: '00233653',
                    availableFsDivs: [],
                    periods: [],
                    filingCount: 1,
                    pendingFilingCount: 1,
                    statementAvailabilitySources: [s],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('공식 원문을 확인했지만 당기 수치·기간 표기의 충돌로 재무 숫자를 저장하지 않았습니다.'),
        findsOneWidget,
      );
      expect(find.textContaining('건을 아직 받지 않았습니다'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
