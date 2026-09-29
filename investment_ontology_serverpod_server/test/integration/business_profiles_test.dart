import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/business/business_profiles.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Stored business understanding', (builder, endpoints) {
    late Session session;
    var seq = 0;
    Future<BusinessDocument> document(
      String code,
      String text, {
      int? year,
      Market market = Market.kosdaq,
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
          reportCode: FinancialReportCode.annual,
          rowCount: 1,
          sourceId: source.id!,
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
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
  });
}
