import 'dart:convert';
import 'dart:io';

import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_xbrl.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_half_basis_absence.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_jobs.dart';

import '../unit/verified_half_basis_absence_test.dart' as source;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class ClassificationClient extends DartClient {
  ClassificationClient({this.fail = false, this.onGet, this.cancelledOverride})
    : super(
        'synthetic',
        httpClient: MockClient(
          (r) async => throw StateError('No external/API request'),
        ),
      );
  final bool fail;
  final void Function(int)? onGet;
  final Future<bool> Function()? cancelledOverride;
  int classifications = 0;
  @override
  Future<VerifiedHalfBasisAbsence> classifyVerifiedHalfBasisAbsence({
    required String receipt,
    required String corpCode,
    required String companyName,
    required Future<bool> Function() cancelled,
  }) {
    classifications++;
    return source.actual(
      body: fail
          ? source
                .fixture('cfs')
                .replaceFirst('해당사항 없음.', '해당사항 없음. 단, 표가 있습니다.')
          : null,
      cancelled: cancelledOverride ?? cancelled,
      onGet: onGet,
    );
  }
}

void main() {
  withServerpod('One-time exhausted half basis classification', (
    builder,
    endpoints,
  ) {
    for (final mode in [
      'success',
      'proof-failure',
      'cancel-after-get',
      'already-cancelled',
      'wrong-OFS',
    ]) {
      test(
        'actual source preserved without numeric attempt reset $mode',
        () async {
          final s = builder.asAdmin.build();
          try {
            final c = await Company.db.insertRow(
              s,
              Company(
                corpCode: '00960623',
                name: '덕산넵코어스(주)',
                stockCode: '266690',
                market: Market.kosdaq,
                fiscalMonth: 12,
              ),
            );
            final original = await Source.db.insertRow(
              s,
              Source(
                kind: SourceKind.dartReport,
                reference: '20260813000889',
                url: 'https://dart.fss.or.kr/pdf/download/ifrs.do?rcp_no=20260813000889&dcm_no=11523776&lang=ko',
                retrievedAt: DateTime.utc(2026),
                title: 'actual stored OFS source',
              ),
            );
            final r = await FinancialReport.db.insertRow(
              s,
              FinancialReport(
                id: 115176,
                companyId: c.id!,
                rceptNo: '20260813000889',
                bsnsYear: 2026,
                reportCode: FinancialReportCode.halfYear,
                fsDiv: FsDiv.separate,
                reportName: '반기보고서 (2026.06)',
                sourceId: original.id!,
                factCount: 7,
                fetchedAt: DateTime.utc(2026),
              ),
            );
            final zip = File(
              'test/fixtures/financial_html/duksan-half-cfs-absence/cookie-referer-xbrl.zip',
            ).readAsBytesSync();
            final rows = PublicFinancialXbrl.parseHalfYear(
              zip,
              receipt: r.rceptNo,
              corpCode: c.corpCode,
              bsnsYear: 2026,
              periodEnd: DateTime.utc(2026, 6, 30),
              consolidated: false,
              sourceUri: Uri.parse(original.url!),
            );
            final facts = FinancialRows.toFacts(
              rows,
              reportId: r.id!,
              companyId: c.id!,
              bsnsYear: 2026,
              reportCode: FinancialReportCode.halfYear,
              fsDiv: FsDiv.separate,
              sourceId: original.id!,
            ).facts;
            if (mode == 'wrong-OFS') facts.first.amount = BigInt.one;
            await FinancialFact.db.insert(s, facts);
            final reportBefore = jsonEncode(r.toJson());
            final sourceBefore = jsonEncode(original.toJson());
            final before = (await FinancialFact.db.find(s))
                .map((f) => jsonEncode(f.toJson()))
                .toList();
            final f = await DartFiling.db.insertRow(
              s,
              DartFiling(
                rceptNo: r.rceptNo,
                companyId: c.id,
                corpCode: c.corpCode,
                bsnsYear: 2026,
                reportCode: FinancialReportCode.halfYear,
                reportName: r.reportName,
                discoveredAt: DateTime.utc(2026),
                consolidatedStatus: FilingFetchStatus.failed,
                separateStatus: FilingFetchStatus.stored,
                lastError: 'pending-half-exact-xbrl:attempt=3; consolidated: Half-year core account missing or ambiguous',
              ),
            );
            Future<IngestJob> job() => IngestJob.db.insertRow(
              s,
              IngestJob(
                kind: FinancialFactsSync.companyKind,
                status: IngestStatus.running,
                startedAt: DateTime.now().toUtc(),
              ),
            );
            final j = await job();
            if (mode == 'already-cancelled') await IngestJobs.cancel(s, j.id!);
            var observedGets = 0;
            final client = ClassificationClient(
              fail: mode == 'proof-failure',
              onGet: (_) {
                observedGets++;
              },
              cancelledOverride: mode == 'cancel-after-get'
                  ? () async {
                      if (observedGets > 0) await IngestJobs.cancel(s, j.id!);
                      return IngestJobs.isCancelled(s, j.id!);
                    }
                  : null,
            );
            await FinancialFactsSync(
              s,
              client,
              j.id!,
              dailyBudget: 0,
              corpCode: c.corpCode,
              callInterval: Duration.zero,
            ).run();
            final current = (await DartFiling.db.findById(s, f.id!))!;
            expect(current.separateStatus, FilingFetchStatus.stored);
            expect(current.attempts, 0);
            expect(
              current.lastError,
              contains('pending-half-exact-xbrl:attempt=3'),
            );
            expect(client.calls, 0);
            expect(
              (await FinancialFact.db.find(s))
                  .map((f) => jsonEncode(f.toJson()))
                  .toList(),
              before,
            );
            expect(
              jsonEncode((await Source.db.findById(s, original.id!))!.toJson()),
              sourceBefore,
            );
            expect(
              jsonEncode(
                (await FinancialReport.db.findById(s, r.id!))!.toJson(),
              ),
              reportBefore,
            );
            expect(await FinancialReport.db.count(s), 1);
            if (mode == 'success') {
              expect(current.consolidatedStatus, FilingFetchStatus.noData);
              expect(current.lastError, startsWith('연결 원문 명시 비적용 확인 완료'));
              final audit = (await Source.db.find(s)).singleWhere(
                (x) => x.reference == 'financial-public-half-basis-not-applicable:20260813000889:CFS',
              );
              expect(audit.url, contains('eleId=19'));
              expect(
                jsonDecode(audit.title)['sha256'],
                VerifiedHalfBasisAbsence.bodySha,
              );
            } else {
              expect(current.consolidatedStatus, FilingFetchStatus.failed);
            }
            final expectedRequests =
                ['wrong-OFS', 'already-cancelled'].contains(mode) ? 0 : 1;
            expect(client.classifications, expectedRequests);
            final classifications = await Source.db.find(
              s,
              where: (t) => t.reference.equals(
                'financial-public-half-basis-classification-attempt:20260813000889:CFS',
              ),
            );
            expect(
              classifications.length,
              ['wrong-OFS', 'already-cancelled'].contains(mode) ? 0 : 1,
            );
            final j2 = await job();
            await FinancialFactsSync(
              s,
              client,
              j2.id!,
              dailyBudget: 0,
              corpCode: c.corpCode,
              callInterval: Duration.zero,
            ).run();
            // A pre-cancelled run records no attempt; the following live run can classify.
            if (mode != 'already-cancelled') {
              expect(client.classifications, expectedRequests);
            }
          } finally {
            await s.close();
          }
        },
      );
    }
  });
}
