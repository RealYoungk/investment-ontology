import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/business/business_profiles.dart';
import 'package:serverpod/serverpod.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/disclosure_endpoint.dart';
import 'package:test/test.dart';

import '../support/storage_test_server.dart';

void main() {
  withStorageServerpod('Stored business understanding', (builder, endpoints) {
    late Session session;
    var seq = 0;
    Future<BusinessDocument> document(
      String code,
      String text, {
      int? year,
      Market market = Market.kosdaq,
      String? industry,
      FinancialReportCode reportCode = FinancialReportCode.annual,
      String? reportName,
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
              market: market,
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
      final receipt = '${++seq}'.padLeft(14, '0');
      final report = await DisclosureReport.db.insertRow(
        session,
        DisclosureReport(
          companyId: company.id!,
          section: DartSection.businessContent,
          rceptNo: receipt,
          bsnsYear: year ?? DateTime.now().year - 1,
          reportCode: reportCode,
          rowCount: 1,
          sourceId: source.id!,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
      if (reportName != null) {
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: receipt,
            corpCode: code,
            companyId: company.id,
            reportName: reportName,
            bsnsYear: report.bsnsYear,
            reportCode: reportCode,
            consolidatedStatus: FilingFetchStatus.pending,
            separateStatus: FilingFetchStatus.pending,
            discoveredAt: DateTime.now().toUtc(),
          ),
        );
      }
      return BusinessDocument.db.insertRow(
        session,
        BusinessDocument(
          reportId: report.id!,
          companyId: company.id!,
          bsnsYear: report.bsnsYear,
          rceptNo: receipt,
          title: '사업의 내용',
          text: text,
          charCount: text.length,
        ),
      );
    }

    const product = '## 2. 주요 제품 및 서비스\n(1) AOI\n반도체 기판 회로형성 후 결함을 검사하는 설비입니다.';
    setUp(() {
      session = builder.build();
    });
    tearDown(() async {
      await session.close();
    });
    test('backfill is idempotent and read does not write', () async {
      await document('00000001', product);
      expect(
        (await BusinessProfiles.read(session, '00000001')).status,
        'pending',
      );
      expect(await BusinessProfile.db.count(session), 0);
      expect(await BusinessProfiles.backfill(session), 1);
      expect(await BusinessProfiles.backfill(session), 0);
      final result = await BusinessProfiles.read(session, '00000001');
      expect(result.status, 'ready');
      expect(result.products.single.key, 'substrate_aoi');
      expect(result.rceptNo, isNotEmpty);
      expect(await BusinessProfile.db.count(session), 1);
    });
    test(
      'correction replaces displayed profile and old rules are hidden',
      () async {
        final old = await document('00000002', product);
        await BusinessProfiles.store(session, old);
        final newer = await document('00000002', '## 주요 제품\n설명 미지원');
        final report = (await DisclosureReport.db.findById(
          session,
          old.reportId,
        ))!;
        report.supersededById = newer.reportId;
        await DisclosureReport.db.updateRow(session, report);
        expect(
          (await BusinessProfiles.read(session, '00000002')).status,
          'pending',
        );
        await BusinessProfiles.store(session, newer);
        expect(
          (await BusinessProfiles.read(session, '00000002')).status,
          'unsupported',
        );
        final profile = (await BusinessProfile.db.findFirstRow(
          session,
          where: (t) => t.documentId.equals(newer.id!),
        ))!;
        profile.ruleVersion = -1;
        await BusinessProfile.db.updateRow(session, profile);
        expect(
          (await BusinessProfiles.read(session, '00000002')).products,
          isEmpty,
        );
        expect(await BusinessProfiles.backfill(session), 1);
      },
    );
    test('latest interim supersedes annual for product display without changing annual peers', () async {
      final y = DateTime.now().year;
      final old = await document(
        '00000006',
        product,
        year: y - 1,
        reportName: '사업보고서 (${y - 1}.12)',
      );
      await BusinessProfiles.store(session, old);
      final latest = await document(
        '00000006',
        '## 2. 주요 제품\n제품명 | 설명\n신제품 | 운영 솔루션',
        year: y,
        reportCode: FinancialReportCode.halfYear,
        reportName: '반기보고서 ($y.06)',
      );
      expect(
        (await BusinessProfiles.read(session, '00000006')).status,
        'pending',
      );
      expect(await BusinessProfiles.backfill(session), 1);
      final result = await BusinessProfiles.read(session, '00000006');
      expect(result.products.single.name, '신제품');
      expect(result.rceptNo, latest.rceptNo);
      expect(result.reportCode, FinancialReportCode.halfYear);
      expect(result.reportName, '반기보고서 ($y.06)');
    });
    test('known newer filing without a body hides old products; delayed old corrections never outrank newer periods', () async {
      final y = DateTime.now().year;
      final old = await document(
        '00000007',
        product,
        year: y - 1,
        reportName: '사업보고서 (${y - 1}.12)',
      );
      await BusinessProfiles.store(session, old);
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: '99999999999998',
          corpCode: '00000007',
          companyId: old.companyId,
          reportName: '반기보고서 ($y.06)',
          bsnsYear: y,
          reportCode: FinancialReportCode.halfYear,
          consolidatedStatus: FilingFetchStatus.pending,
          separateStatus: FilingFetchStatus.pending,
          discoveredAt: DateTime.now().toUtc(),
        ),
      );
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: '99999999999999',
          corpCode: '00000007',
          companyId: old.companyId,
          reportName: '[기재정정]사업보고서 (${y - 1}.12)',
          bsnsYear: y - 1,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.pending,
          separateStatus: FilingFetchStatus.pending,
          discoveredAt: DateTime.now().toUtc(),
        ),
      );
      final result = await BusinessProfiles.read(session, '00000007');
      expect(result.status, 'pending');
      expect(result.products, isEmpty);
      expect(result.rceptNo, '99999999999998');
      expect(await BusinessProfiles.backfill(session), 0);
    });
    test('body selection follows latest period and explicit history never falls back', () async {
      final y = DateTime.now().year;
      final annual = await document(
        '00000008',
        product,
        year: y - 1,
        reportName: '사업보고서 (${y - 1}.12)',
      );
      final half = await document(
        '00000008',
        product,
        year: y,
        reportCode: FinancialReportCode.halfYear,
        reportName: '반기보고서 ($y.06)',
      );
      final endpoint = DisclosureEndpoint();
      expect(
        (await endpoint.businessContent(session, '00000008'))?.rceptNo,
        half.rceptNo,
      );
      expect(
        (await endpoint.businessContent(
          session,
          '00000008',
          bsnsYear: y - 1,
        ))?.rceptNo,
        annual.rceptNo,
      );
      expect(
        await endpoint.businessContent(session, '00000008', bsnsYear: 2000),
        isNull,
      );
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: '99999999999997',
          corpCode: '00000008',
          companyId: half.companyId,
          reportName: '분기보고서 ($y.09)',
          bsnsYear: y,
          reportCode: FinancialReportCode.q3,
          consolidatedStatus: FilingFetchStatus.pending,
          separateStatus: FilingFetchStatus.pending,
          discoveredAt: DateTime.now().toUtc(),
        ),
      );
      final fallback = await endpoint.businessContent(session, '00000008');
      expect(fallback!.rceptNo, half.rceptNo);
      expect(fallback.title, contains('이전 저장 보고서'));
      expect(fallback.title, contains('$y.09'));
      expect(
        await endpoint.businessContent(session, '00000008', bsnsYear: y),
        isNull,
      );
      expect(
        (await endpoint.businessContent(
          session,
          '00000008',
          bsnsYear: y - 1,
        ))?.rceptNo,
        annual.rceptNo,
      );
    });
    test(
      'holding companies and stale documents cannot inherit subsidiary roles',
      () async {
        final holding = await document('00000003', product, industry: '64992');
        final stale = await document('00000004', product, year: 2001);
        await BusinessProfiles.store(session, holding);
        await BusinessProfiles.store(session, stale);
        expect(
          (await BusinessProfiles.read(session, '00000003')).products,
          isEmpty,
        );
        expect(
          (await BusinessProfiles.read(session, '00000004')).status,
          'stale',
        );
        expect(
          (await BusinessProfiles.read(session, '00000005')).status,
          'no_document',
        );
      },
    );

    test('missing latest body returns explicitly labelled stored source; requested year stays strict', () async {
      final doc = await document(
        '01999991',
        product,
        year: 2025,
        reportName: '사업보고서 (2025.12)',
      );
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          companyId: doc.companyId,
          corpCode: '01999991',
          rceptNo: '20260814009999',
          reportName: '반기보고서 (2026.06)',
          bsnsYear: 2026,
          reportCode: FinancialReportCode.halfYear,
          consolidatedStatus: FilingFetchStatus.pending,
          separateStatus: FilingFetchStatus.pending,
          discoveredAt: DateTime.now().toUtc(),
        ),
      );
      final endpoint = DisclosureEndpoint();
      final fallback = await endpoint.businessContent(session, '01999991');
      expect(fallback, isNotNull);
      expect(fallback!.bsnsYear, 2025);
      expect(fallback.rceptNo, doc.rceptNo);
      expect(fallback.title, contains('이전 저장 보고서'));
      expect(fallback.title, contains('2026.06'));
      final historical = await endpoint.businessContent(
        session,
        '01999991',
        bsnsYear: 2025,
      );
      expect(historical!.title, '사업의 내용');
      expect(
        await endpoint.businessContent(session, '01999991', bsnsYear: 2026),
        isNull,
      );
    });
  });
}
