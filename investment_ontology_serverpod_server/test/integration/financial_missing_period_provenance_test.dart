import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_period_metadata.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_source_duration.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_period_provenance.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import '../unit/financial_period_provenance_test.dart'
    show actualMetadata, originalReceipt, targetReceipt;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

class PeriodClient extends SourceClient {
  PeriodClient({
    this.beforeReturn,
    this.timeout = false,
    this.periodMismatch = false,
  });
  final bool periodMismatch;
  final bool timeout;
  final Future<void> Function()? beforeReturn;
  int metadataCalls = 0;
  @override
  Future<PublicFinancialPeriodMetadata> fetchAnnualPeriodMetadata(
    String receipt, {
    required String corpCode,
    required String companyName,
    required String targetReceipt,
    required DateTime periodEnd,
    bool halfYear = false,
  }) async {
    metadataCalls++;
    if (timeout) throw TimeoutException('explicit temporary transport failure');
    if (receipt != originalReceipt) {
      throw const FormatException(
        'Counterfactual source deliberately unproved; never emit proof',
      );
    }
    expect(receipt, originalReceipt);
    expect(corpCode, '00963000');
    expect(periodEnd, DateTime.utc(2025, 12, 31));
    final md = await actualMetadata(
      target: targetReceipt,
      changedCover: periodMismatch
          ? File(
              'test/fixtures/financial_period_metadata_suntech2025/cover.html',
            ).readAsStringSync().replaceAll('2025년 12월 31일', '2025년 06월 30일')
          : null,
    );
    await beforeReturn?.call();
    return md;
  }
}

void main() {
  withServerpod(
    'Existing Sun original stored values missing financial period provenance',
    (builder, endpoints) {
      for (final mode in [
        'normal',
        'mixed',
        'transient',
        'periodMismatch',
        'foreignOriginal',
        'wrongOriginalYear',
        'invalidSourceUrl',
        'cancel',
      ]) {
        test('$mode metadata-only repair preserves source/filing/facts and native amounts', () async {
          final session = builder.asAdmin.build();
          final now = DateTime.utc(2026, 10, 3);
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: '00963000',
              name: '(주)썬테크',
              stockCode: '217320',
              market: Market.konex,
              fiscalMonth: 12,
            ),
          );
          await ApiCallUsage.db.insertRow(
            session,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-03',
              calls: 20000,
            ),
          );
          final original = await DartFiling.db.insertRow(
            session,
            DartFiling(
              rceptNo: originalReceipt,
              corpCode: '00963000',
              companyId: company.id!,
              bsnsYear: 2025,
              reportCode: FinancialReportCode.annual,
              reportName: '사업보고서 (2025.12)',
              consolidatedStatus: FilingFetchStatus.stored,
              separateStatus: FilingFetchStatus.stored,
              attempts: 7,
              lastError: 'native old source history',
              checkedAt: now,
              discoveredAt: now,
            ),
          );
          final target = await DartFiling.db.insertRow(
            session,
            original.copyWith(
              id: null,
              rceptNo: targetReceipt,
              reportName: '[첨부정정]사업보고서 (2025.12)',
              lastError:
                  'verified-attachment-source:$targetReceipt->$originalReceipt',
            ),
          );
          if (mode == 'foreignOriginal') {
            await DartFiling.db.updateRow(
              session,
              original.copyWith(corpCode: '00000001'),
            );
          }
          if (mode == 'wrongOriginalYear') {
            await DartFiling.db.updateRow(
              session,
              original.copyWith(bsnsYear: 2024),
            );
          }
          const labels = [
            '자산총계',
            '부채총계',
            '자본총계',
            'Ⅰ. 매출액',
            '영업이익(손실)',
            'Ⅹ. 당기순이익',
            'Ⅰ.영업활동으로 인한 현금흐름',
          ];
          const values = {
            FsDiv.consolidated: [
              '22931367836',
              '19448274886',
              '3483092950',
              '21533148193',
              '-1894112357',
              '-2164078292',
              '-321548450',
            ],
            FsDiv.separate: [
              '14131185071',
              '10897617782',
              '3233567289',
              '16401666683',
              '28804006',
              '-1757381648',
              '695607919',
            ],
          };
          final reports = <FinancialReport>[];
          for (final basis in FsDiv.values) {
            final cfs = basis == FsDiv.consolidated;
            final url =
                'https://dart.fss.or.kr/report/viewer.do?rcpNo=$originalReceipt&dcmNo=11133658&eleId=${cfs ? 19 : 21}&offset=${cfs ? 329146 : 518605}&length=${cfs ? 114169 : 97424}&dtd=dart4.xsd';
            final source = await Source.db.insertRow(
              session,
              Source(
                kind: SourceKind.dartReport,
                reference: originalReceipt,
                url: mode == 'invalidSourceUrl'
                    ? 'https://foreign.example/source'
                    : url,
                title:
                    'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공) · 사업보고서 (2025.12) · ${cfs ? '연결' : '별도'} · SHA256:${cfs ? '0c14657d943c27f7ff6e8644f935808ec2d07f5cfd8cedcbffc19affd02af613' : '687f01a94500e3dc6f7aa304be1cdfc0d4ab74e29afc4218f4f9cbc10200cea9'}',
                retrievedAt: now,
              ),
            );
            final report = await FinancialReport.db.insertRow(
              session,
              FinancialReport(
                companyId: company.id!,
                rceptNo: originalReceipt,
                bsnsYear: 2025,
                reportCode: FinancialReportCode.annual,
                reportName: '사업보고서 (2025.12)',
                fsDiv: basis,
                sourceId: source.id!,
                factCount: 7,
                fetchedAt: now,
              ),
            );
            reports.add(report);
            for (var i = 0; i < 7; i++) {
              await FinancialFact.db.insertRow(
                session,
                FinancialFact(
                  reportId: report.id!,
                  companyId: company.id!,
                  bsnsYear: 2025,
                  reportCode: FinancialReportCode.annual,
                  fsDiv: basis,
                  sourceId: source.id!,
                  statement: i < 3
                      ? FinancialStatementKind.balanceSheet
                      : i == 6
                      ? FinancialStatementKind.cashFlow
                      : FinancialStatementKind.comprehensiveIncome,
                  accountId: null,
                  accountName: (!cfs && i == 4) ? '영업이익' : labels[i],
                  amount: BigInt.parse(values[basis]![i]),
                  periodName: i < 3 ? '2025-12-31' : '2025-01-01~2025-12-31',
                  currency: 'KRW',
                ),
              );
            }
          }
          if (mode == 'mixed') {
            const deniedReceipt = '20260317000809';
            await DartFiling.db.insertRow(
              session,
              original.copyWith(id: null, rceptNo: deniedReceipt),
            );
            final deniedSource = await Source.db.insertRow(
              session,
              Source(
                kind: SourceKind.dartReport,
                reference: deniedReceipt,
                title: 'DART 원문 HTML 부분 핵심계정(counterfactual denied source)',
                url:
                    'https://dart.fss.or.kr/report/viewer.do?rcpNo=$deniedReceipt',
                retrievedAt: now,
              ),
            );
            final deniedReport = await FinancialReport.db.insertRow(
              session,
              reports.first.copyWith(
                id: null,
                rceptNo: deniedReceipt,
                sourceId: deniedSource.id!,
                factCount: 1,
              ),
            );
            await FinancialFact.db.insertRow(
              session,
              FinancialFact(
                companyId: company.id!,
                reportId: deniedReport.id!,
                bsnsYear: 2025,
                reportCode: FinancialReportCode.annual,
                fsDiv: deniedReport.fsDiv,
                sourceId: deniedSource.id!,
                statement: FinancialStatementKind.balanceSheet,
                accountName:
                    'explicit counterfactual retained row, no source approval',
                amount: BigInt.one,
              ),
            );
          }
          final originalRows = jsonEncode(
            (await DartFiling.db.find(session)).map((v) => v.toJson()).toList(),
          );
          final factRows = jsonEncode(
            (await FinancialFact.db.find(session))
                .map((v) => v.toJson())
                .toList(),
          );
          final reportRows = jsonEncode(
            (await FinancialReport.db.find(session))
                .map((v) => v.toJson())
                .toList(),
          );
          final sourceRows = (await Source.db.find(session))
              .map((v) => v.toJson())
              .toList();
          expect(
            (await FinancialSourceDuration.load(session)).blockedReportIds,
            containsAll(reports.map((r) => r.id!)),
          );
          var currentJob = 0;
          final client = PeriodClient(
            timeout: mode == 'transient',
            periodMismatch: mode == 'periodMismatch',
            beforeReturn: mode == 'cancel'
                ? () async {
                    final j = (await IngestJob.db.findById(
                      session,
                      currentJob,
                    ))!;
                    await IngestJob.db.updateRow(
                      session,
                      j.copyWith(status: IngestStatus.cancelled),
                    );
                  }
                : null,
          );
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          currentJob = job.id!;
          final scheduled = <DateTime>[];
          await FinancialFactsSync(
            session,
            client,
            job.id!,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
            scheduleResume: (at) async {
              scheduled.add(at);
            },
          ).run();
          final anchors = await Source.db.find(
            session,
            where: (t) => t.reference.like('financial-source-period-anchor:%'),
          );
          if (mode == 'normal' || mode == 'mixed') {
            expect(client.metadataCalls, mode == 'mixed' ? 2 : 1);
            expect(anchors, hasLength(1));
            expect(
              jsonDecode(anchors.single.title)['sha256'],
              'ae7a3929f5d453d3446b7731e93983bb34cbbc4798f9d169e138690e79c0bcde',
            );
            final durations = await FinancialSourceDuration.load(session);
            if (mode == 'mixed') {
              expect(durations.blockedReportIds, hasLength(1));
            } else {
              expect(durations.blockedReportIds, isEmpty);
            }
            expect(durations.ranges.values.every((r) => !r.isShort), true);
            final next = await IngestJob.db.insertRow(
              session,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now,
              ),
            );
            final nextClient = PeriodClient();
            await FinancialFactsSync(
              session,
              nextClient,
              next.id!,
              dailyBudget: 0,
              clock: () => now,
              callInterval: Duration.zero,
            ).run();
            expect(nextClient.metadataCalls, 0);
            expect(
              await Source.db.count(
                session,
                where: (t) =>
                    t.reference.like('financial-source-period-anchor:%'),
              ),
              1,
            );
          } else {
            expect(anchors, isEmpty);
            expect(
              client.metadataCalls,
              mode == 'cancel' ||
                      mode == 'transient' ||
                      mode == 'periodMismatch'
                  ? 1
                  : 0,
            );
          }
          if (mode == 'periodMismatch') {
            final outcome = (await IngestJob.db.findById(session, currentJob))!;
            expect(outcome.status, IngestStatus.failed);
            expect(outcome.message, contains('공식 표지 종료일과 저장 보고기간 불일치'));
            expect(outcome.message, contains('기간 증빙 미확정'));
            expect(outcome.message, isNot(contains('법인·기간/출처 URI 충돌')));
            expect(scheduled, isEmpty);
            // Counterfactual changed-date bytes must NEVER become an approved
            // Source/SHA or metadata anchor. Another normal early run is held.
            final again = await IngestJob.db.insertRow(
              session,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now.add(const Duration(minutes: 1)),
              ),
            );
            final reread = PeriodClient(periodMismatch: true);
            final againSchedule = <DateTime>[];
            await FinancialFactsSync(
              session,
              reread,
              again.id!,
              dailyBudget: 0,
              clock: () => now.add(const Duration(minutes: 1)),
              callInterval: Duration.zero,
              scheduleResume: (at) async {
                againSchedule.add(at);
              },
            ).run();
            expect(reread.metadataCalls, 0);
            expect(againSchedule, isEmpty);
            expect(
              await Source.db.count(
                session,
                where: (t) =>
                    t.reference.like('financial-source-period-anchor:%'),
              ),
              0,
            );
          }
          if (mode == 'transient') {
            expect(scheduled, [now.add(const Duration(minutes: 15))]);
            final retry = await IngestJob.db.insertRow(
              session,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now.add(const Duration(minutes: 15)),
              ),
            );
            final recovered = PeriodClient();
            await FinancialFactsSync(
              session,
              recovered,
              retry.id!,
              dailyBudget: 0,
              clock: () => now.add(const Duration(minutes: 15)),
              callInterval: Duration.zero,
            ).run();
            expect(recovered.metadataCalls, 1);
            expect(
              await Source.db.count(
                session,
                where: (t) =>
                    t.reference.like('financial-source-period-anchor:%'),
              ),
              1,
            );
            expect(
              (await FinancialSourceDuration.load(session)).blockedReportIds,
              isEmpty,
            );
          }
          expect(
            jsonEncode(
              (await DartFiling.db.find(session))
                  .map((v) => v.toJson())
                  .toList(),
            ),
            originalRows,
          );
          expect(
            jsonEncode(
              (await FinancialFact.db.find(session))
                  .map((v) => v.toJson())
                  .toList(),
            ),
            factRows,
          );
          expect(
            jsonEncode(
              (await FinancialReport.db.find(session))
                  .map((v) => v.toJson())
                  .toList(),
            ),
            reportRows,
          );
          for (final old in sourceRows) {
            expect(
              (await Source.db.findById(session, old['id'] as int))!.toJson(),
              old,
            );
          }
          expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
          expect(client.calls, 0);
          if (mode == 'cancel') {
            final cancelledJob = (await IngestJob.db.findById(
              session,
              currentJob,
            ))!;
            // IngestJobs.save deliberately preserves a cancellation observed in
            // the DB. It must not overwrite that message to force a cursor write.
            expect(
              cancelledJob.message?.contains(MetadataProgress.marker) ?? false,
              false,
            );
            final cancelledSnapshot = jsonEncode(cancelledJob.toJson());
            expect(
              (await IngestJob.db.findById(session, job.id!))!.status,
              IngestStatus.cancelled,
            );
            expect(scheduled, isEmpty);
            final manual = await IngestJob.db.insertRow(
              session,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now.add(const Duration(minutes: 1)),
              ),
            );
            final manualClient = PeriodClient();
            await FinancialFactsSync(
              session,
              manualClient,
              manual.id!,
              dailyBudget: 0,
              clock: () => now.add(const Duration(minutes: 1)),
              callInterval: Duration.zero,
            ).run();
            expect(
              manualClient.metadataCalls,
              1,
              reason: 'a cancelled unanchored read may be reread on an explicitly new run',
            );
            expect(
              await Source.db.count(
                session,
                where: (t) =>
                    t.reference.like('financial-source-period-anchor:%'),
              ),
              1,
            );
            expect(
              jsonEncode(
                (await IngestJob.db.findById(session, currentJob))!.toJson(),
              ),
              cancelledSnapshot,
            );
            expect(
              jsonEncode(
                (await FinancialFact.db.find(session))
                    .map((v) => v.toJson())
                    .toList(),
              ),
              factRows,
            );
          }
          expect(
            (await DartFiling.db.findById(session, target.id!))!.attempts,
            7,
          );
        });
      }
    },
  );
}
