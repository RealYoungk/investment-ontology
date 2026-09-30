import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:cp949_codec/cp949_codec.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_text_repair.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Investment history', (anonymous, endpoints) {
    late Session session;
    late Company company, other;
    late Source source;
    late BusinessDocument annual, half, otherDocument;

    String table(String period) =>
        '''
(시설투자 현황)
(단위 : 억원)
구 분 | 내 용 | 투자기간 | 대상자산 | 투자액
DS 부문 | 증설 | $period | 설비 | 70
SDC | 증설 | $period | 설비 | 30
합 계 | 100''';

    Future<BusinessDocument> doc(
      Company owner,
      int year,
      FinancialReportCode code,
      DateTime? date,
      String text,
      String ref,
    ) async {
      final report = await DisclosureReport.db.insertRow(
        session,
        DisclosureReport(
          companyId: owner.id!,
          section: DartSection.businessContent,
          rceptNo: ref,
          bsnsYear: year,
          reportCode: code,
          settlementDate: date,
          rowCount: 0,
          sourceId: source.id!,
          fetchedAt: DateTime.utc(2026),
        ),
      );
      return BusinessDocument.db.insertRow(
        session,
        BusinessDocument(
          reportId: report.id!,
          companyId: owner.id!,
          bsnsYear: year,
          rceptNo: ref,
          title: 'II. 사업의 내용',
          text: text,
          charCount: text.length,
        ),
      );
    }

    setUp(() async {
      session = anonymous.asAdmin.build();
      company = await Company.db.insertRow(
        session,
        Company(corpCode: '11111111', name: '첫기업', market: Market.kospi),
      );
      other = await Company.db.insertRow(
        session,
        Company(corpCode: '22222222', name: '다른기업', market: Market.kospi),
      );
      source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartApi,
          title: '공시 원문',
          retrievedAt: DateTime.utc(2026),
        ),
      );
      annual = await doc(
        company,
        2025,
        FinancialReportCode.annual,
        DateTime.utc(2025, 12, 31),
        table('2025.01~2025.12'),
        '20260301000001',
      );
      half = await doc(
        company,
        2026,
        FinancialReportCode.halfYear,
        DateTime.utc(2026, 6, 30),
        table('2026.01~2026.06'),
        '20260801000001',
      );
      otherDocument = await doc(
        other,
        2025,
        FinancialReportCode.annual,
        DateTime.utc(2025, 12, 31),
        table('2025.01~2025.12'),
        '20260301000002',
      );
    });

    test('GigaVis order balance is restored from stored text with its source and period', () async {
      const text =
          '(단위 : 백만원)\n품목 | 당기수주 | 납품액 | 수주잔고\n반도체 기판 검사 및 수리장비 | 55,735 | 42,169 | 13,566';
      await BusinessDocument.db.updateRow(
        session,
        annual.copyWith(text: text, charCount: text.length),
      );
      await endpoints.ingest.rebuildProductionFacts(
        anonymous.asAdmin,
        corpCode: company.corpCode,
      );
      final facts = await endpoints.disclosure.factTrends(
        anonymous.asReader,
        company.corpCode,
      );
      final backlog = facts
          .where((f) => f.kind == DocumentFactKind.orderBacklog)
          .single;
      expect(backlog.value, 13566);
      expect(backlog.unit, '백만원');
      expect(backlog.asOf, DateTime.utc(2025, 12, 31));
      expect(backlog.sourceId, source.id);
      expect(text, contains(backlog.evidence));
    });
    test('targeted admin replay stores source-linked annual and half-year facts, is idempotent and leaves other firms untouched', () async {
      await endpoints.ingest.rebuildProductionFacts(
        anonymous.asAdmin,
        corpCode: company.corpCode,
      );
      final first = await endpoints.disclosure.factTrends(
        anonymous.asReader,
        company.corpCode,
      );
      expect(first, hasLength(6));
      expect(
        first.where((f) => f.asOf == DateTime.utc(2025, 12, 31)),
        hasLength(3),
      );
      expect(
        first.where((f) => f.asOf == DateTime.utc(2026, 6, 30)),
        hasLength(3),
      );
      for (final fact in first) {
        expect(fact.sourceId, source.id);
        expect(fact.status, RelationStatus.verified);
        expect(fact.unit, '억원');
        expect(
          (fact.documentId == annual.id ? annual : half).text,
          contains(fact.evidence),
        );
      }
      expect(
        await DocumentFact.db.find(
          session,
          where: (t) => t.documentId.equals(otherDocument.id!),
        ),
        isEmpty,
      );
      await endpoints.ingest.rebuildProductionFacts(
        anonymous.asAdmin,
        corpCode: company.corpCode,
      );
      final second = await endpoints.disclosure.factTrends(
        anonymous.asReader,
        company.corpCode,
      );
      expect(
        second.map((f) => '${f.label}|${f.value}|${f.asOf}'),
        first.map((f) => '${f.label}|${f.value}|${f.asOf}'),
      );
      await expectLater(
        endpoints.ingest.rebuildProductionFacts(
          anonymous.asReader,
          corpCode: company.corpCode,
        ),
        throwsA(anything),
      );
      await expectLater(
        endpoints.ingest.rebuildProductionFacts(
          anonymous.asAnonymous,
          corpCode: company.corpCode,
        ),
        throwsA(anything),
      );
    });

    test(
      'period metadata excludes superseded reports and unknown interim dates',
      () async {
        final unknown = await doc(
          company,
          2026,
          FinancialReportCode.q3,
          null,
          '정보',
          '20261101000001',
        );
        final old = (await DisclosureReport.db.findById(
          session,
          annual.reportId,
        ))!;
        await DisclosureReport.db.updateRow(
          session,
          old.copyWith(supersededById: half.reportId),
        );
        final periods = await endpoints.disclosure.factPeriods(
          anonymous.asReader,
          company.corpCode,
        );
        expect(periods.map((p) => p.documentId), [half.id]);
        expect(periods.map((p) => p.documentId), isNot(contains(unknown.id)));
      },
    );

    test('malformed legacy text is recovered from exact filing once and preserves source identity', () async {
      final broken = await doc(
        company,
        2021,
        FinancialReportCode.annual,
        DateTime.utc(2021, 12, 31),
        '깨진 \uFFFD 원문',
        '20220301000001',
      );
      final xml =
          '<?xml version="1.0" encoding="utf-8"?><DOCUMENT><TITLE AASSOCNOTE="D-0-2-0-0">II. 사업의 내용</TITLE><P>시설투자 현황</P><TITLE AASSOCNOTE="D-0-3-0-0">III. 재무</TITLE></DOCUMENT>';
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes(
            '${broken.rceptNo}.xml',
            const CP949Codec().encode(xml),
          ),
        );
      var calls = 0;
      Future<List<int>?> fetch(String ref) async {
        calls++;
        expect(ref, broken.rceptNo);
        return ZipEncoder().encodeBytes(archive);
      }

      expect(await BusinessTextRepair.repair(session, broken, fetch), isTrue);
      final recovered = (await BusinessDocument.db.findById(
        session,
        broken.id!,
      ))!;
      expect(recovered.text, '시설투자 현황');
      expect(recovered.reportId, broken.reportId);
      expect(
        await BusinessTextRepair.repair(session, recovered, fetch),
        isFalse,
      );
      expect(calls, 1);
      final badArchive = Archive()
        ..addFile(ArchiveFile.bytes('bad.xml', utf8.encode('잘못된 파일')));
      final bad = await doc(
        company,
        2020,
        FinancialReportCode.annual,
        DateTime.utc(2020, 12, 31),
        '\uFFFD 원문',
        '20210301000001',
      );
      expect(
        await BusinessTextRepair.repair(
          session,
          bad,
          (_) => Future.value(ZipEncoder().encodeBytes(badArchive)),
        ),
        isFalse,
      );
      expect(
        (await BusinessDocument.db.findById(session, bad.id!))!.text,
        bad.text,
      );
    });
  });
}
