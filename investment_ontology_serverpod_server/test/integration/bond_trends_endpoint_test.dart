import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/capital_structure_store.dart';
import 'package:test/test.dart';

import 'bond_test_tools.dart';

void main() {
  withBondServerpod('bond trends access and correction binding', (
    builder,
    endpoints,
  ) {
    test('public read is stored-only; collection rejects anonymous and ordinary accounts', () async {
      expect(
        jsonDecode(
          await endpoints.bond.trends(builder.asAnonymous, '00000001'),
        )['state'],
        'noCompany',
      );
      await expectLater(
        endpoints.bond.collect(builder.asAnonymous, '00000001'),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
      await expectLater(
        endpoints.bond.collect(builder.asReader, '00000001'),
        throwsA(isA<ServerpodInsufficientAccessException>()),
      );
      expect(await ResearchSnapshot.db.count(builder.build()), 0);
    });
    test('latest uncollected correction never falls back to an older collected receipt', () async {
      final session = builder.build();
      final company = await Company.db.insertRow(
        session,
        Company(corpCode: '00000001', name: '테스트', stockCode: '000001'),
      );
      for (final receipt in ['20260301000001', '20260401000001']) {
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: receipt,
            corpCode: company.corpCode,
            companyId: company.id!,
            reportName: '사업보고서 (2025.12)',
            reportCode: FinancialReportCode.annual,
            bsnsYear: 2025,
            consolidatedStatus: FilingFetchStatus.pending,
            separateStatus: FilingFetchStatus.pending,
            discoveredAt: DateTime.utc(2026),
          ),
        );
      }
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: 'source',
          reference: '20260301000001',
          retrievedAt: DateTime.utc(2026),
        ),
      );
      await ResearchSnapshot.db.insertRow(
        session,
        ResearchSnapshot(
          companyId: company.id!,
          kind: 'capitalStructure',
          provider: 'DART',
          sourceId: source.id!,
          digest: 'test',
          createdAt: DateTime.utc(2026),
          payload: jsonEncode({
            'version': 2,
            'companyName': company.name,
            'receipt': '20260301000001',
            'periodEnd': '2025-12-31',
            'balanceStates': {'CB': 'none'},
            'entries': [],
          }),
        ),
      );
      final feed = jsonDecode(
        await endpoints.bond.trends(builder.asAnonymous, company.corpCode),
      );
      expect(feed['points'].single['receipt'], '20260401000001');
      expect(feed['points'].single['balanceWon'], isNull);
      expect(feed['points'].single['state'], 'notCollected');
      expect(
        await ResearchSnapshot.db.count(session),
        1,
        reason: 'read must never acquire or mutate',
      );
    });
    test('official source fixtures pass through snapshot storage and public read without invented causes', () async {
      final session = builder.build();
      final company = await Company.db.insertRow(
        session,
        Company(corpCode: '00147082', name: '재영솔루텍(주)', stockCode: '049630'),
      );
      final manifest = (jsonDecode(
        File('test/fixtures/bond_trends/manifest.json').readAsStringSync(),
      ) as List).cast<Map<String, dynamic>>();
      for (final entry in manifest) {
        final year = int.parse(entry['periodEnd'].substring(0, 4));
        final filing = await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: entry['receipt'],
            corpCode: company.corpCode,
            companyId: company.id!,
            reportName: '사업보고서 ($year.12)',
            reportCode: FinancialReportCode.annual,
            bsnsYear: year,
            consolidatedStatus: FilingFetchStatus.pending,
            separateStatus: FilingFetchStatus.pending,
            discoveredAt: DateTime.utc(2026),
          ),
        );
        await CapitalStructureStore.save(
          session,
          company,
          filing,
          File('test/fixtures/bond_trends/${entry['file']}').readAsStringSync(),
          urls: (entry['sourceUrls'] as List).cast<String>(),
        );
      }
      final feed = jsonDecode(
        await endpoints.bond.trends(builder.asAnonymous, company.corpCode),
      );
      expect(feed['state'], 'ready');
      expect(feed['collectedPeriods'], 2);
      expect(feed['points'].last['balanceWon'], '22700000000');
      expect(feed['points'].last['netDecreaseWon'], '2300000000');
      expect(feed['changes'].first['confirmedConversionWon'], isNull);
      expect(await ResearchSnapshot.db.count(session), 2);
      expect(await Source.db.count(session), 2);
    });
  });
}
