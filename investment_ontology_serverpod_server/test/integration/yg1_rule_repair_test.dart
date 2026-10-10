import 'dart:io';

import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_test/serverpod_test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/ingest_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/disclosure_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/business/business_profiles.dart';

import '../support/storage_test_server.dart';

void main() {
  withStorageServerpod('YG1 source repair', (builder, _) {
    test('admin replay restores five annual years, latest interim and product cache', () async {
      final session = builder.build();
      addTearDown(session.close);
      final admin = builder
          .copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              '00000000-0000-4000-8000-000000000001',
              {Scope.admin},
            ),
          )
          .build();
      addTearDown(admin.close);
      final company = await Company.db.insertRow(
        session,
        Company(
          corpCode: '00139719',
          name: '와이지-원',
          market: Market.kosdaq,
          industryCode: '25934',
        ),
      );
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: '공시 본문 fixture',
          retrievedAt: DateTime.now().toUtc(),
        ),
      );
      for (var year = 2021; year <= 2026; year++) {
        final half = year == 2026;
        final report = await DisclosureReport.db.insertRow(
          session,
          DisclosureReport(
            companyId: company.id!,
            section: DartSection.businessContent,
            rceptNo: '${year}0814002362',
            bsnsYear: year,
            reportCode: half
                ? FinancialReportCode.halfYear
                : FinancialReportCode.annual,
            settlementDate: half
                ? DateTime.utc(year, 6, 30)
                : DateTime.utc(year, 12, 31),
            rowCount: 1,
            sourceId: source.id!,
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
        final text = File(
          'test/fixtures/business_tables/yg1-$year-${half ? 'half' : 'annual'}.txt',
        ).readAsStringSync();
        await BusinessDocument.db.insertRow(
          session,
          BusinessDocument(
            reportId: report.id!,
            companyId: company.id!,
            bsnsYear: year,
            rceptNo: report.rceptNo,
            title: '사업의 내용',
            text: text,
            charCount: text.length,
          ),
        );
      }
      // A damaged older source cannot prevent healthy years from replaying.
      final damagedReport = await DisclosureReport.db.insertRow(
        session,
        DisclosureReport(
          companyId: company.id!,
          section: DartSection.businessContent,
          rceptNo: '20210301000001',
          bsnsYear: 2020,
          reportCode: FinancialReportCode.annual,
          settlementDate: DateTime.utc(2020, 12, 31),
          rowCount: 1,
          sourceId: source.id!,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
      await BusinessDocument.db.insertRow(
        session,
        BusinessDocument(
          reportId: damagedReport.id!,
          companyId: company.id!,
          bsnsYear: 2020,
          rceptNo: damagedReport.rceptNo,
          title: '사업의 내용',
          text: '손상된 원문 \uFFFD',
          charCount: 8,
        ),
      );
      final endpoint = IngestEndpoint();
      // A missing requested year must not silently return the latest filing.
      expect(
        await DisclosureEndpoint().table(
          session,
          '00139719',
          DartSection.businessContent,
          bsnsYear: 2019,
        ),
        isNull,
      );
      await expectLater(
        endpoint.rebuildProductionFacts(session, corpCode: '00139719'),
        throwsA(isA<NotAuthorizedException>()),
      );
      final replay = await endpoint.rebuildProductionFacts(
        admin,
        corpCode: '00139719',
      );
      expect(replay, contains('인코딩 손상 1건 재수집 대기'));
      final profile = await BusinessProfiles.read(session, '00139719');
      expect(profile.status, 'ready');
      expect(profile.products, hasLength(4));
      final trends = await DisclosureEndpoint().factTrends(session, '00139719');
      final revenues = trends
          .where((f) => f.kind == DocumentFactKind.segmentRevenue)
          .toList();
      expect(revenues, hasLength(24));
      for (var year = 2021; year <= 2026; year++) {
        expect(revenues.where((f) => f.asOf!.year == year), hasLength(4));
      }
      final current = trends
          .where((f) => f.asOf == DateTime.utc(2026, 6, 30))
          .toList();
      expect(
        current
            .singleWhere(
              (f) =>
                  f.kind == DocumentFactKind.segmentRevenue && f.label == '제품',
            )
            .value,
        362480,
      );
      expect(
        current
            .where((f) => f.kind == DocumentFactKind.utilization)
            .map((f) => f.value),
        containsAll([68.06, 37.93]),
      );
      expect(
        current
            .where((f) => f.kind == DocumentFactKind.capacity)
            .every((f) => f.unit == '1,000pcs'),
        isTrue,
      );
      final count = await DocumentFact.db.count(session);
      final replayAgain = await endpoint.rebuildProductionFacts(
        admin,
        corpCode: '00139719',
      );
      expect(replayAgain, contains('인코딩 손상 1건 재수집 대기'));
      expect(await DocumentFact.db.count(session), count);
      expect(await BusinessProfile.db.count(session), 6);
    });
  });
}
