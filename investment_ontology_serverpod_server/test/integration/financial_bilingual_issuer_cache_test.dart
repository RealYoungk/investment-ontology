import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Bilingual issuer exact source cache', (builder, endpoints) {
    test('both failed public3 independently resolve exact numeric OFS and CFS absence once', () async {
      final s = builder.asAdmin.build();
      final now = DateTime.utc(2026, 10, 3);
      await ApiCallUsage.db.insertRow(
        s,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: '2026-10-03',
          calls: 20000,
        ),
      );
      final c = await Company.db.insertRow(
        s,
        Company(
          corpCode: '01226234',
          name: '(주)와이바이오로직스',
          stockCode: '338840',
          fiscalMonth: 12,
          market: Market.kosdaq,
        ),
      );
      final f = await DartFiling.db.insertRow(
        s,
        DartFiling(
          companyId: c.id,
          corpCode: c.corpCode,
          rceptNo: '20230414002057',
          reportName: '사업보고서 (2022.12)',
          bsnsYear: 2022,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.failed,
          separateStatus: FilingFetchStatus.failed,
          attempts: 3,
          lastError: 'api-noData-annual-public:attempt=3; Exact annual legal issuer corroboration failed',
          discoveredAt: now,
        ),
      );
      Future<void> run() async {
        final job = await IngestJob.db.insertRow(
          s,
          IngestJob(
            kind: FinancialFactsSync.kind,
            status: IngestStatus.running,
            startedAt: now,
          ),
        );
        await FinancialFactsSync(
          s,
          SourceClient(),
          job.id!,
          dailyBudget: 0,
          clock: () => now,
          callInterval: Duration.zero,
        ).run();
      }

      await run();
      final stored = (await DartFiling.db.findById(s, f.id!))!;
      expect(stored.attempts, 3);
      expect(stored.lastError, contains('attempt=3'));
      expect(stored.consolidatedStatus, FilingFetchStatus.noData);
      expect(stored.separateStatus, FilingFetchStatus.stored);
      final report = (await FinancialReport.db.find(s)).single;
      expect(report.fsDiv, FsDiv.separate);
      expect(report.rceptNo, f.rceptNo);
      expect(report.bsnsYear, 2022);
      final facts = await FinancialFact.db.find(
        s,
        where: (t) => t.reportId.equals(report.id!),
      );
      expect(facts, hasLength(8));
      expect(
        {for (final r in facts) r.accountName: r.amount.toString()},
        {
          '자산총계': '29322648895',
          '부채총계': '17029482330',
          '자본총계': '12293166565',
          '매출액': '4150557898',
          '영업이익(손실)': '-18830214970',
          '당기순이익(손실)': '-18804401066',
          '영업활동으로 인한 현금흐름': '-10104924654',
          '유형자산의 취득': '-1088240488',
        },
      );
      final source = (await Source.db.findById(s, report.sourceId))!;
      expect(source.reference, f.rceptNo);
      expect(source.url, contains('dcmNo=9232198&eleId=21'));
      expect(source.title, contains('HTML'));
      final none = (await Source.db.find(
        s,
        where: (t) => t.reference.equals(
          'financial-public-basis-not-applicable:${f.rceptNo}:consolidated',
        ),
      )).single;
      expect(jsonDecode(none.title)['evidence'], '*해당사항이 없습니다.');
      final entries = VerifiedAnnualSourceRegistry.entries
          .where((e) => e.receipt == f.rceptNo)
          .toList();
      expect(entries, hasLength(2));
      for (final e in entries) {
        expect(
          await Source.db.find(
            s,
            where: (t) => t.reference.equals(e.auditReference),
          ),
          hasLength(1),
        );
      }
      final before = [
        report.toJson(),
        source.toJson(),
        none.toJson(),
        for (final r in facts) r.toJson(),
      ];
      await run();
      expect([
        (await FinancialReport.db.findById(s, report.id!))!.toJson(),
        (await Source.db.findById(s, source.id!))!.toJson(),
        (await Source.db.findById(s, none.id!))!.toJson(),
        for (final r in await FinancialFact.db.find(
          s,
          where: (t) => t.reportId.equals(report.id!),
        ))
          r.toJson(),
      ], before);
      final summary = await endpoints.financial.summary(
        builder,
        c.corpCode,
        fsDiv: FsDiv.separate,
      );
      expect(
        summary!.periods.single.lines
            .singleWhere((l) => l.key == 'revenue')
            .amount,
        BigInt.from(4150557898),
      );
      expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
    });
  });
}
