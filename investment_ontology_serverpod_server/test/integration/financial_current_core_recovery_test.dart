import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_xbrl.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_current_core_recovery.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class SunCurrentClient extends DartClient {
  SunCurrentClient({this.failSource = false})
    : super(
        'test',
        httpClient: MockClient(
          (r) async => http.Response('{"status":"013","message":"empty"}', 200),
        ),
      );
  final bool failSource;
  int apiRequests = 0;
  int publicRequests = 0;
  @override
  Future<List<Map<String, dynamic>>?> fetchFinancialStatements({
    required String corpCode,
    required int bsnsYear,
    required String reportCode,
    required String fsDiv,
  }) async {
    apiRequests++;
    throw StateError('API must not repeat');
  }

  @override
  Future<({List<int> zip, Uri source})> fetchPublicAnnualXbrl(
    String receipt,
  ) async {
    publicRequests++;
    if (failSource) {
      throw const FormatException('unverified source');
    }
    return (
      zip: File('test/fixtures/financial_xbrl/sunjin_20250318001380.zip')
          .readAsBytesSync(),
      source: Uri.parse(
        'https://dart.fss.or.kr/pdf/download/ifrs.do?rcp_no=$receipt&dcm_no=10425343&lang=ko',
      ),
    );
  }
}

void main() {
  withServerpod(
    'Preserve legacy comparison facts while appending verified current core',
    (builder, endpoints) {
      late Session session;
      late Company company;
      late DartFiling filing;
      late FinancialReport report;
      late Source source;
      late List<Map<String, dynamic>> rows;
      final uri = Uri.parse(
        'https://dart.fss.or.kr/pdf/download/ifrs.do?rcp_no=20250318001380&dcm_no=10425343&lang=ko',
      );
      const digest =
          'ff901a73e9e9c5b92778c649ced8d02c1be4a09fbcc8b18f6b073a2cfc0e6c3c';
      setUp(() async {
        session = builder.asAdmin.build();
        company = await Company.db.insertRow(
          session,
          Company(corpCode: '00855093', name: '선진', stockCode: '136490'),
        );
        filing = await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: '20250318001380',
            corpCode: company.corpCode,
            companyId: company.id,
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            reportName: '사업보고서 (2024.12)',
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            discoveredAt: DateTime.utc(2025, 3, 18),
          ),
        );
        source = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            reference: filing.rceptNo,
            title: 'DART 전체 재무제표 (fnlttSinglAcntAll)',
            url: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20250318001380',
            retrievedAt: DateTime.utc(2025, 3, 18),
          ),
        );
        report = await FinancialReport.db.insertRow(
          session,
          FinancialReport(
            companyId: company.id!,
            rceptNo: filing.rceptNo,
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            reportName: filing.reportName,
            fsDiv: FsDiv.separate,
            sourceId: source.id!,
            factCount: 1,
            fetchedAt: DateTime.utc(2025, 3, 18),
          ),
        );
        rows = PublicFinancialXbrl.parse(
          File('test/fixtures/financial_xbrl/sunjin_20250318001380.zip')
              .readAsBytesSync(),
          receipt: filing.rceptNo,
          corpCode: company.corpCode,
          bsnsYear: 2024,
          periodEnd: DateTime.utc(2024, 12, 31),
          consolidated: false,
        );
        await FinancialFact.db.insert(
          session,
          FinancialRows.toFacts(
            [
              {
                ...rows.first,
                'thstrm_amount': '-',
                'frmtrm_amount': '12345',
                'frmtrm_nm': '2023',
              },
            ],
            reportId: report.id!,
            companyId: company.id!,
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            fsDiv: FsDiv.separate,
            sourceId: source.id!,
          ).facts,
        );
      });
      Future<bool> repair({
        List<Map<String, dynamic>>? fresh,
        Uri? sourceUri,
      }) => FinancialCurrentCoreRecovery.append(
        session,
        report: report,
        filing: filing,
        company: company,
        div: FsDiv.separate,
        rows: fresh ?? rows,
        source: sourceUri ?? uri,
        digest: digest,
      );
      test('Actual seven current rows append; every legacy fact and Source preserved; retry is idempotent', () async {
        final before = (await FinancialFact.db.find(
          session,
          where: (t) => t.reportId.equals(report.id!),
        )).single;
        expect(await repair(), true);
        final after = await FinancialReport.db.findById(session, report.id!);
        expect(after!.sourceId, isNot(source.id));
        expect(after.factCount, 8);
        final legacy = await FinancialFact.db.findById(session, before.id!);
        expect(legacy!.toJson(), before.toJson());
        final fresh = await FinancialFact.db.find(
          session,
          where: (t) =>
              t.reportId.equals(report.id!) & t.sourceId.equals(after.sourceId),
        );
        expect(fresh.length, 7);
        expect(fresh.every((f) => f.amount != null), true);
        final primary = await Source.db.findById(session, after.sourceId);
        expect(primary!.reference, filing.rceptNo);
        expect(primary.title, startsWith('DART 원문 XBRL 당기 핵심계정 복구'));
        expect(primary.title, contains('7계정 밖 미복구'));
        expect(await repair(), true);
        expect(
          await FinancialFact.db.count(
            session,
            where: (t) => t.reportId.equals(report.id!),
          ),
          8,
        );
        expect(
          (await Source.db.findById(session, source.id!))!.toJson(),
          source.toJson(),
        );
      });
      for (final mutation in [
        'USD',
        'wrong-period',
        'wrong-receipt',
        'conflict',
      ]) {
        test('Reject $mutation without touching legacy values', () async {
          final bad = [for (final r in rows) Map<String, dynamic>.from(r)];
          if (mutation == 'USD') {
            bad.first['currency'] = 'USD';
          }
          if (mutation == 'wrong-period') {
            bad.first['thstrm_nm'] = '2023-01-01~2024-12-31';
          }
          if (mutation == 'wrong-receipt') {
            bad.first['rcept_no'] = '20250318000001';
          }
          if (mutation == 'conflict') {
            bad.singleWhere(
              (r) => r['account_id'] == 'ifrs-full_Assets',
            )['thstrm_amount'] = '1';
          }
          expect(await repair(fresh: bad), false);
          expect(
            await FinancialFact.db.count(
              session,
              where: (t) => t.reportId.equals(report.id!),
            ),
            1,
          );
          expect(
            (await FinancialReport.db.findById(session, report.id!))!.sourceId,
            source.id,
          );
        });
      }
      test('Normal ingestion recovers exhausted source-proved basis with API budget zero; subsequent run does not fetch again', () async {
        await DartFiling.db.updateRow(
          session,
          filing.copyWith(
            consolidatedStatus: FilingFetchStatus.noData,
            separateStatus: FilingFetchStatus.failed,
            attempts: 3,
            lastError: 'storedCurrentAmountsMissing: source current absent',
          ),
        );
        final reader = SunCurrentClient();
        Future<void> run() async {
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: DateTime.utc(2026, 10, 2),
            ),
          );
          await FinancialFactsSync(
            session,
            reader,
            job.id!,
            dailyBudget: 0,
            corpCode: company.corpCode,
            clock: () => DateTime.utc(2026, 10, 2),
          ).run();
        }

        await run();
        expect(
          (await DartFiling.db.findById(session, filing.id!))!.separateStatus,
          FilingFetchStatus.stored,
        );
        expect(reader.apiRequests, 0);
        expect(reader.publicRequests, 1);
        expect(
          await FinancialFact.db.count(
            session,
            where: (t) => t.reportId.equals(report.id!),
          ),
          8,
        );
        await run();
        expect(reader.publicRequests, 1);
        expect(reader.apiRequests, 0);
      });
      test('One-off exhausted recovery failure remains finite and preserves legacy facts', () async {
        await DartFiling.db.updateRow(
          session,
          filing.copyWith(
            consolidatedStatus: FilingFetchStatus.noData,
            separateStatus: FilingFetchStatus.failed,
            attempts: 3,
            lastError: 'storedCurrentAmountsMissing: source current absent',
          ),
        );
        final reader = SunCurrentClient(failSource: true);
        Future<void> run() async {
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: DateTime.utc(2026, 10, 2),
            ),
          );
          await FinancialFactsSync(
            session,
            reader,
            job.id!,
            dailyBudget: 0,
            corpCode: company.corpCode,
            clock: () => DateTime.utc(2026, 10, 2),
            callInterval: Duration.zero,
          ).run();
        }

        await run();
        final target = (await DartFiling.db.findById(session, filing.id!))!;
        expect(target.separateStatus, FilingFetchStatus.failed);
        expect(target.attempts, 4);
        await run();
        expect(reader.publicRequests, 1);
        expect(reader.apiRequests, 0);
        expect(
          await FinancialFact.db.count(
            session,
            where: (t) => t.reportId.equals(report.id!),
          ),
          1,
        );
        expect(
          (await FinancialReport.db.findById(session, report.id!))!.sourceId,
          source.id,
        );
      });
      test('Existing current values prevent replacement', () async {
        final old = (await FinancialFact.db.find(
          session,
          where: (t) => t.reportId.equals(report.id!),
        )).single;
        await FinancialFact.db.updateRow(
          session,
          old.copyWith(amount: BigInt.one),
        );
        expect(await repair(), false);
        expect(
          await FinancialFact.db.count(
            session,
            where: (t) => t.reportId.equals(report.id!),
          ),
          1,
        );
      });
    },
  );
}
