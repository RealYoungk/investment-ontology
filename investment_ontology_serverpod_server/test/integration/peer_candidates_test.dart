import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/peer_catalog.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/peer_rules.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Precomputed peers', (builder, endpoints) {
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

    const product = '## 2. 주요 제품 및 서비스\n반도체 기판 AOI 검사장비';
    setUp(() {
      session = builder.build();
    });
    tearDown(() async {
      await session.close();
    });
    test(
      'backfill idempotent; candidate excludes self and exposes source',
      () async {
        await document('00000001', product);
        final candidate = await document('00000002', '$product\nSMT AOI 검사장비');
        expect(await PeerProfiles.backfill(session), 2);
        expect(await PeerProfiles.backfill(session), 0);
        final result = await PeerProfiles.candidates(session, '00000001');
        expect(result.status, 'ready');
        expect(result.items.single.corpCode, '00000002');
        expect(result.items.single.rceptNo, candidate.rceptNo);
        expect(
          result.items.single.differences,
          contains('후보 기업 공시: SMT·실장 검사'),
        );
      },
    );
    test('latest missing profile never falls back to older product; unsupported new filing replaces it', () async {
      await document('00000001', product);
      await document('00000002', product);
      await PeerProfiles.backfill(session);
      final newer = await document('00000002', '## 2. 주요 제품 및 서비스\n일반 제품');
      expect(
        (await PeerProfiles.candidates(session, '00000001')).items,
        isEmpty,
      );
      await PeerProfiles.store(session, newer);
      expect(
        (await PeerProfiles.candidates(session, '00000001')).items,
        isEmpty,
      );
      expect(
        (await PeerProfiles.candidates(session, '00000002')).status,
        'unsupported',
      );
    });
    test(
      'superseded, stale, unlisted, holding and incompatible products excluded',
      () async {
        await document('00000001', product);
        final superseded = await document('00000002', product);
        final report = (await DisclosureReport.db.findById(
          session,
          superseded.reportId,
        ))!;
        await DisclosureReport.db.updateRow(
          session,
          report.copyWith(supersededById: report.id),
        );
        await document('00000003', product, year: DateTime.now().year - 3);
        await document('00000004', product, market: Market.other);
        await document('00000005', product, industry: '64992');
        await document('00000006', '## 2. 주요 제품 및 서비스\nSMT AOI 검사장비');
        await PeerProfiles.backfill(session);
        expect(
          (await PeerProfiles.candidates(session, '00000001')).items,
          isEmpty,
        );
      },
    );
    test('old rule version suppressed until reprocessed', () async {
      final doc = await document('00000001', product);
      await PeerProfiles.store(session, doc);
      final p = (await PeerProfile.db.findFirstRow(session))!;
      await PeerProfile.db.updateRow(
        session,
        p.copyWith(ruleVersion: PeerRules.version - 1),
      );
      expect(
        (await PeerProfiles.candidates(session, '00000001')).status,
        'pending',
      );
      expect(await PeerProfiles.backfill(session), 1);
      expect(
        (await PeerProfiles.candidates(session, '00000001')).status,
        'empty',
      );
    });
    test(
      'product focus changes candidates without mixing different businesses',
      () async {
        String products(String label) =>
            '## 2. 주요 제품\n주요 제품 | 매출액\n$label | 100';
        await document('00000001', products('DRAM, NAND'), industry: '261');
        await document('00000002', products('DRAM'), industry: '261');
        await document('00000003', products('NAND'), industry: '261');
        await PeerProfiles.backfill(session);
        expect(
          (await PeerProfiles.candidates(
            session,
            '00000001',
          )).items.map((c) => c.corpCode),
          ['00000002'],
        );
        expect(
          (await PeerProfiles.candidates(
            session,
            '00000001',
            focusKey: 'product/nand',
          )).items.map((c) => c.corpCode),
          ['00000003'],
        );
      },
    );

    test('invalid corp code rejected', () async {
      expect(
        () => PeerProfiles.candidates(session, "' OR true"),
        throwsArgumentError,
      );
    });
  });
}
