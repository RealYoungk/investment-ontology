import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart' show Scope;
import 'package:serverpod_test/serverpod_test.dart';

import '../support/stored_industry_test_server.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/peers/all_industry_catalog.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ksic_revision.dart';

void main() {
  withIndustryServerpod('Public stored industry discovery', (
    builder,
    endpoints,
  ) {
    test(
      'latest filings, age and holding exclusions with anonymous reads',
      () async {
        final session = builder.build();
        addTearDown(session.close);
        var sequence = 0;
        Future<void> add(
          String code,
          String product, {
          int? year,
          String? industry,
        }) async {
          final company =
              await Company.db.findFirstRow(
                session,
                where: (t) => t.corpCode.equals(code),
              ) ??
              await Company.db.insertRow(
                session,
                Company(
                  corpCode: code,
                  name: code,
                  market: Market.kosdaq,
                  industryCode: industry,
                ),
              );
          final source = await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartApi,
              title: 'fixture',
              retrievedAt: DateTime.now().toUtc(),
            ),
          );
          final receipt = '${++sequence}'.padLeft(14, '0');
          final report = await DisclosureReport.db.insertRow(
            session,
            DisclosureReport(
              companyId: company.id!,
              section: DartSection.businessContent,
              rceptNo: receipt,
              bsnsYear: year ?? DateTime.now().year - 1,
              reportCode: FinancialReportCode.annual,
              rowCount: 1,
              sourceId: source.id!,
              fetchedAt: DateTime.now().toUtc(),
            ),
          );
          final text = '## 2. 주요 제품 및 서비스\n주요 제품 | 매출액\n$product | 100';
          await BusinessDocument.db.insertRow(
            session,
            BusinessDocument(
              reportId: report.id!,
              companyId: company.id!,
              bsnsYear: report.bsnsYear,
              rceptNo: receipt,
              title: '사업',
              text: text,
              charCount: text.length,
            ),
          );
        }

        await add('00000001', 'DRAM, NAND Flash');
        await add('00000002', '반도체 식각 장비');
        await add('00000002', '일반 제품');
        await add('00000003', 'DRAM', industry: '64992');
        await add('00000004', 'DRAM', year: DateTime.now().year - 4);
        // An unprepared anonymous page must never classify source documents.
        await expectLater(
          endpoints.industry.discover(builder),
          throwsA(anything),
        );
        expect(await IndustryCatalogSnapshot.db.count(session), 0);
        final prepared = await AllIndustryCatalog.rebuild(session);
        expect(prepared, isNotNull);
        final unchanged = await AllIndustryCatalog.rebuild(session);
        expect(unchanged!.computedAt, prepared!.computedAt);
        // Changing builder version invalidates durable classification even when
        // the filing text itself did not change.
        await IndustryCatalogSnapshot.db.updateRow(
          session,
          unchanged.copyWith(
            builderVersion: AllIndustryCatalog.builderVersion - 1,
          ),
        );
        final rebuiltRules = await AllIndustryCatalog.rebuild(session);
        expect(rebuiltRules!.builderVersion, AllIndustryCatalog.builderVersion);
        expect(rebuiltRules.computedAt.isAfter(unchanged.computedAt), isTrue);
        await expectLater(
          endpoints.industry.rebuild(builder),
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
        final reader = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'reader',
            {},
          ),
        );
        await expectLater(
          endpoints.industry.rebuild(reader),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
        final admin = builder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo('admin', {
            Scope.admin,
          }),
        );
        expect((await endpoints.industry.rebuild(admin)).listedCompanyCount, 4);
        final result = await endpoints.industry.discover(builder);
        expect(result.classifiedCompanyCount, 1);
        expect(result.activities.map((a) => a.corpCode).toSet(), {'00000001'});
        expect(result.activities.map((a) => a.productKey).toSet(), {
          'dram',
          'nand',
        });
        expect(result.listedCompanyCount, 4);
        final all = await endpoints.industry.browse(builder);
        expect(all.activities.map((a) => a.corpCode).toSet(), {
          '00000001',
          '00000002',
          '00000003',
          '00000004',
        });
        expect(
          all.activities.where((a) => a.classificationBasis == 'filing').length,
          2,
        );
        expect(
          all.activities
              .where((a) => a.classificationBasis == 'unclassified')
              .map((a) => a.corpCode)
              .toSet(),
          {
            '00000001',
            '00000002',
            '00000003',
            '00000004',
          },
        );
        expect(
          all.activities
              .where((a) => a.classificationBasis == 'unclassified')
              .every((a) => a.rceptNo.isEmpty),
          isTrue,
        );

        await Industry.db.insert(session, [
          Industry(code: '212', name: '의약품 제조업', level: 3, revision: 'KSIC 11'),
          Industry(
            code: '21210',
            name: '완제 의약품 제조업',
            level: 5,
            parentCode: '212',
            revision: 'KSIC 11',
          ),
        ]);
        await Company.db.insertRow(
          session,
          Company(
            corpCode: '00000005',
            name: '제약기업',
            market: Market.kospi,
            industryCode: '21210',
          ),
        );
        await KsicRevision.invalidate(session);
        // New source rows alone do not change saved public classification.
        expect(
          (await endpoints.industry.browse(builder)).listedCompanyCount,
          4,
        );
        await AllIndustryCatalog.rebuild(session);
        final updated = await endpoints.industry.browse(builder);
        final pharma = updated.activities.singleWhere(
          (a) => a.corpCode == '00000005' && a.classificationBasis == 'ksic',
        );
        expect(pharma.industryKey, 'pharma');
        expect(pharma.groupName, '완제 의약품');
        expect(pharma.classificationBasis, 'ksic');
        expect(pharma.evidence, contains('KSIC 11 21210'));
        expect(pharma.rceptNo, isEmpty);
        expect(updated.listedCompanyCount, 5);
        // Reads must still work when the source table cannot even be queried.
        await session.db.unsafeExecute(
          'ALTER TABLE business_document RENAME TO unavailable_business_document',
        );
        try {
          expect(
            (await endpoints.industry.browse(builder)).listedCompanyCount,
            5,
          );
          expect(
            (await endpoints.industry.discover(builder)).classifiedCompanyCount,
            1,
          );
        } finally {
          await session.db.unsafeExecute(
            'ALTER TABLE unavailable_business_document RENAME TO business_document',
          );
        }
        final sector = await endpoints.industry.browse(
          builder,
          industry: 'pharma',
        );
        expect(sector.activities.map((a) => a.corpCode).toSet(), {'00000005'});
        expect(sector.listedCompanyCount, 5);
        final unknown = await endpoints.industry.browse(
          builder,
          industry: 'missing',
        );
        expect(unknown.activities, isEmpty);
        // Coverage counts every company with a document, including holdings.
        // Product eligibility remains independently asserted above.
        expect(result.documentCompanyCount, 4);
        expect(
          result.activities.every(
            (a) => a.evidence == 'DRAM, NAND Flash | 100',
          ),
          isTrue,
        );
      },
    );
  });
}
