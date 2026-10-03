import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'auth_test_sessions.dart';

void main() {
  withServerpod('최신본문의 정확 원접수 가족관계 지표', (anonymous, endpoints) {
    final builder = anonymous.asAdmin;
    test('확정 가족관계만 포함하며 원본문/출처를 보존하고 잘못된 경계를 제외한다', () async {
      final session = builder.build(), now = DateTime.utc(2026, 10, 2);
      final c = await Company.db.insertRow(
        session,
        Company(corpCode: '00123772', name: '부국증권', stockCode: '001270'),
      );
      final other = await Company.db.insertRow(
        session,
        Company(corpCode: '99999999', name: '미식별', stockCode: '999999'),
      );
      DartFiling filing(String r, String name) => DartFiling(
        rceptNo: r,
        corpCode: c.corpCode,
        companyId: c.id,
        reportName: name,
        bsnsYear: 2026,
        reportCode: FinancialReportCode.halfYear,
        consolidatedStatus: FilingFetchStatus.noData,
        separateStatus: FilingFetchStatus.noData,
        discoveredAt: now,
      );
      var sf = await DartFiling.db.insertRow(
        session,
        filing('20260814002623', '반기보고서 (2026.06)'),
      );
      var f = await DartFiling.db.insertRow(
        session,
        filing('20260814003889', '[첨부정정]반기보고서 (2026.06)'),
      );
      var s = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: '공식 실제 원접수 사업본문',
          reference: sf.rceptNo,
          url: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${sf.rceptNo}',
          retrievedAt: now,
        ),
      );
      var d = await DisclosureReport.db.insertRow(
        session,
        DisclosureReport(
          companyId: c.id!,
          section: DartSection.businessContent,
          rceptNo: sf.rceptNo,
          bsnsYear: 2026,
          reportCode: FinancialReportCode.halfYear,
          settlementDate: DateTime.utc(2026, 6, 30),
          rowCount: 0,
          sourceId: s.id!,
          fetchedAt: now,
        ),
      );
      var b = await BusinessDocument.db.insertRow(
        session,
        BusinessDocument(
          reportId: d.id!,
          companyId: c.id!,
          bsnsYear: 2026,
          rceptNo: sf.rceptNo,
          title: 'II. 사업의 내용',
          text: '공식 원접수 본문 보존',
          charCount: 12,
        ),
      );
      final sec = await DartFilingSection.db.insertRow(
        session,
        DartFilingSection(
          filingId: f.id!,
          companyId: c.id!,
          bsnsYear: 2026,
          yearRank: 0,
          section: DartSection.businessContent,
          tier: 2,
          status: FilingFetchStatus.stored,
        ),
      );
      Future<void> expectCount(int n) async {
        final v = await endpoints.ingest.coverage(builder);
        expect(v.companiesWithLatestBusinessText, n);
        expect(v.listedCompanies, 2, reason: '미식별 기업은 분모에 유지');
      }

      await expectCount(1);
      final bodyBefore = b.toJson(), sourceBefore = s.toJson();
      await Source.db.updateRow(
        session,
        s.copyWith(
          url:
              'https://dart.fss.or.kr/report/viewer.do?rcpNo=${sf.rceptNo}&dcmNo=1&eleId=2&offset=3&length=100&dtd=dart4.xsd',
        ),
      );
      await expectCount(1);
      await Source.db.updateRow(session, s);
      for (final bad in [
        b.copyWith(companyId: other.id!),
        b.copyWith(bsnsYear: 2025),
        b.copyWith(rceptNo: '20260814002624'),
        b.copyWith(text: ' ', charCount: 1),
        b.copyWith(charCount: 0),
      ]) {
        await BusinessDocument.db.updateRow(session, bad);
        await expectCount(0);
        await BusinessDocument.db.updateRow(session, b);
      }
      for (final bad in [
        s.copyWith(kind: SourceKind.manual),
        s.copyWith(reference: f.rceptNo),
        s.copyWith(url: 'https://example.org/?rcpNo=${sf.rceptNo}'),
      ]) {
        await Source.db.updateRow(session, bad);
        await expectCount(0);
        await Source.db.updateRow(session, s);
      }
      for (final bad in [
        d.copyWith(companyId: other.id!),
        d.copyWith(bsnsYear: 2025),
        d.copyWith(reportCode: FinancialReportCode.annual),
        d.copyWith(rceptNo: f.rceptNo),
      ]) {
        await DisclosureReport.db.updateRow(session, bad);
        await expectCount(0);
        await DisclosureReport.db.updateRow(session, d);
      }
      for (final bad in [
        sf.copyWith(corpCode: '99999999'),
        sf.copyWith(reportName: '반기보고서 (2026.03)'),
        sf.copyWith(reportName: '사업보고서 (2026.06)'),
      ]) {
        await DartFiling.db.updateRow(session, bad);
        await expectCount(0);
        await DartFiling.db.updateRow(session, sf);
      }
      await DartFiling.db.updateRow(
        session,
        f.copyWith(rceptNo: '20260814003890'),
      );
      await expectCount(0);
      await DartFiling.db.updateRow(session, f);
      await DartFilingSection.db.updateRow(
        session,
        sec.copyWith(status: FilingFetchStatus.failed),
      );
      await expectCount(0);
      await DartFilingSection.db.updateRow(session, sec);
      await expectCount(1);
      expect(
        (await BusinessDocument.db.findById(session, b.id!))!.toJson(),
        bodyBefore,
      );
      expect(
        (await Source.db.findById(session, s.id!))!.toJson(),
        sourceBefore,
      );
      // 정확 최신 접수는 고정 가족관계 목록 없이도 기존 기준으로 포함한다.
      await DartFiling.db.updateRow(
        session,
        f.copyWith(rceptNo: '20260814002622'),
      );
      await DartFilingSection.db.updateRow(
        session,
        sec.copyWith(filingId: sf.id!),
      );
      await expectCount(1);
    });
  });
}
