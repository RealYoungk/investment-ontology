import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/pureun_six_core_profile.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_source_duration.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_facts_sync_test.dart' show AnnualNoDataClient;
import 'test_tools/serverpod_test_tools.dart';

class PureunClient extends AnnualNoDataClient {
  @override
  Future<PublicFinancialHtmlSource> fetchAnnualHtml(
    String receipt, {
    required String reportName,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) async {
    attemptedReceipts.add(receipt);
    if (consolidated) {
      throw const FormatException('CFS not supported by verified OFS profile');
    }
    return PublicFinancialHtmlSource(
      sourceReceipt: receipt,
      correctionReceipt: null,
      correctionSource: null,
      coverHtml: File('test/fixtures/financial_html/pureun-six-core/cover.html')
          .readAsStringSync(),
      coverSource: Uri.parse(PureunSixCoreProfile.coverUri),
      statementHtml: File(
        'test/fixtures/financial_html/pureun-six-core/ofs.html',
      ).readAsStringSync(),
      statementSource: Uri.parse(PureunSixCoreProfile.statementUri),
      periodStart: DateTime.utc(2022, 1, 1),
      periodEnd: periodEnd,
      rows: const [],
    );
  }
}

void main() {
  withServerpod('푸른 exact partial six normal ingestion', (builder, endpoints) {
    for (final publicAttempt in [1, 3]) {
      test(
        'public$publicAttempt API0 preserves independent CFS source status and stores exact OFS6 with partial audit and public summary',
        () async {
          final s = builder.build();
          try {
            final now = DateTime.utc(2026, 10, 2);
            final c = await Company.db.insertRow(
              s,
              Company(
                corpCode: PureunSixCoreProfile.corpCode,
                name: '(주)푸른저축은행',
                market: Market.kospi,
                stockCode: '007330',
                fiscalMonth: 12,
              ),
            );
            final f = await DartFiling.db.insertRow(
              s,
              DartFiling(
                rceptNo: PureunSixCoreProfile.receipt,
                corpCode: c.corpCode,
                companyId: c.id,
                reportName: '사업보고서 (2022.12)',
                bsnsYear: 2022,
                reportCode: FinancialReportCode.annual,
                consolidatedStatus: FilingFetchStatus.failed,
                separateStatus: FilingFetchStatus.failed,
                attempts: 3,
                lastError:
                    'api-noData-annual-public:attempt=$publicAttempt; verified parser failure',
                discoveredAt: now,
              ),
            );
            final job = await IngestJob.db.insertRow(
              s,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now,
              ),
            );
            final client = PureunClient();
            await FinancialFactsSync(
              s,
              client,
              job.id!,
              dailyBudget: 0,
              clock: () => now,
              callInterval: Duration.zero,
            ).run();
            expect(client.financialRequests, 0);
            final filing = (await DartFiling.db.findById(s, f.id!))!;
            expect(filing.attempts, publicAttempt == 3 ? 3 : 4);
            expect(filing.separateStatus, FilingFetchStatus.stored);
            expect(
              filing.consolidatedStatus,
              publicAttempt == 3
                  ? FilingFetchStatus.noData
                  : FilingFetchStatus.failed,
            );
            final cfsProofs = await Source.db.find(
              s,
              where: (t) => t.reference.equals(
                'financial-public-basis-not-applicable:${PureunSixCoreProfile.receipt}:consolidated',
              ),
            );
            expect(cfsProofs, hasLength(publicAttempt == 3 ? 1 : 0));
            if (publicAttempt == 3) {
              expect(
                cfsProofs.single.url,
                'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315000460&dcmNo=9057394&eleId=17&offset=137261&length=142&dtd=dart3.xsd',
              );
              expect(jsonDecode(cfsProofs.single.title)['sha256'], isNotEmpty);
            }
            expect(
              filing.lastError,
              contains('attempt=${publicAttempt == 3 ? 3 : 2}'),
            );
            final report = (await FinancialReport.db.find(s)).single;
            expect(report.factCount, 6);
            expect(report.fsDiv, FsDiv.separate);
            final source = (await Source.db.findById(s, report.sourceId))!;
            expect(source.title, startsWith(PureunSixCoreProfile.title));
            expect(source.reference, PureunSixCoreProfile.receipt);
            expect(source.url, PureunSixCoreProfile.statementUri);
            final audit = (await Source.db.find(
              s,
              where: (t) => t.reference.equals(
                'financial-api-noData-source:${PureunSixCoreProfile.receipt}:separate',
              ),
            )).single;
            final evidence = jsonDecode(audit.title) as Map;
            expect(evidence['coreRows'], 6);
            expect(evidence['missingRequiredAccounts'], ['revenue']);
            expect(evidence['uncollectedOptionalAccounts'], ['capex']);
            expect(
              PureunSixCoreProfile.storedProof(
                evidence['coreRowProvenance'],
                sourceDigest: evidence['sha256'],
                sourceUrl: source.url!,
                companyCode: c.corpCode,
                targetReceipt: report.rceptNo,
                basis: report.fsDiv.name,
                year: report.bsnsYear,
                reportName: report.reportName,
              ),
              isTrue,
            );
            final duration = FinancialSourceDuration.validate(
              report: report,
              company: c,
              reportSource: source,
              audit: audit,
            );
            expect(duration?.days, 365);
            final facts = await FinancialFact.db.find(
              s,
              where: (t) => t.reportId.equals(report.id!),
            );
            expect(facts, hasLength(6));
            final picked = FinancialAccounts.pick(facts);
            expect(
              picked.any((p) => p.key == 'revenue' || p.key == 'capex'),
              isFalse,
            );
            expect(
              picked.singleWhere((p) => p.key == 'netIncome').amount,
              BigInt.parse('20081583946'),
            );
            final summary = await endpoints.financial.summary(
              builder,
              c.corpCode,
              fsDiv: FsDiv.separate,
            );
            expect(summary, isNotNull);
            final lines = summary!.periods.single.lines;
            expect(
              lines.singleWhere((l) => l.key == 'netIncome').amount,
              BigInt.parse('20081583946'),
            );
            expect(
              lines.any((l) => l.key == 'revenue' || l.key == 'capex'),
              isFalse,
            );
            final security = await Security.db.insertRow(
              s,
              Security(
                isinCode: 'KR7007330004',
                shortCode: '007330',
                name: c.name,
                market: Market.kospi,
                companyId: c.id,
                lastSeenDate: now,
              ),
            );
            await MarketSnapshot.db.insertRow(
              s,
              MarketSnapshot(
                securityId: security.id!,
                baseDate: now,
                marketCap: BigInt.parse('1000000000000'),
                closePrice: BigInt.from(10000),
                sourceId: source.id!,
              ),
            );
            await MarketSnapshotDay.db.insertRow(
              s,
              MarketSnapshotDay(
                baseDate: now,
                rowCount: 1,
                sourceId: source.id,
                fetchedAt: now,
              ),
            );
            final page = await endpoints.screen.list(
              builder,
              corpCodes: [c.corpCode],
            );
            final item = page.items.single;
            expect(item.revenue, isNull);
            expect(item.operatingMargin, isNull);
            expect(item.revenueGrowth, isNull);
            expect(item.fcfYield, isNull);
          } finally {
            await s.close();
          }
        },
      );
    }
  });
}
