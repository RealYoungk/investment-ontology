import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/financial_endpoint.dart';

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/located_own_current_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Located own finite current8 and explicit CFS absence', (
    builder,
    endpoints,
  ) {
    for (final receipt
        in LocatedOwnCurrentSource.profiles
            .map((p) => p['receipt'] as String)
            .toSet()) {
      test('$receipt normal queue exact own source correction API0 replay', () async {
        final session = builder.asAdmin.build(),
            now = DateTime.utc(2026, 10, 3);
        final profiles = LocatedOwnCurrentSource.profiles
            .where((p) => p['receipt'] == receipt)
            .toList();
        final firstProfile = profiles.first as Map;
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: firstProfile['corp'],
            name: firstProfile['name'],
            stockCode: '123456',
            fiscalMonth: firstProfile['receipt'] == '20220615000399' ? 3 : 12,
            market: Market.konex,
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
        final correction = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            reference: receipt,
            title: 'Original correction evidence preserved',
            url: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt',
            retrievedAt: now,
          ),
        );
        final correctionBefore = correction.toJson();
        final filing = await DartFiling.db.insertRow(
          session,
          DartFiling(
            companyId: company.id!,
            corpCode: company.corpCode,
            rceptNo: receipt,
            bsnsYear: firstProfile['year'],
            reportCode: FinancialReportCode.annual,
            reportName:
                '사업보고서 (${firstProfile['year']}.${firstProfile['receipt'] == '20220615000399' ? '03' : '12'})',
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            attempts: 7,
            lastError: 'api-noData-annual-public:attempt=3; source verification failed',
            discoveredAt: now,
          ),
        );
        Future<IngestJob> run() async {
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          final client = SourceClient();
          await FinancialFactsSync(
            session,
            client,
            job.id!,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
            sourceCache: VerifiedAnnualSourceCache(
              readAsset: (p) => File(p).readAsBytes(),
            ),
          ).run();
          expect(client.calls, 0);
          expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
          return (await IngestJob.db.findById(session, job.id!))!;
        }

        final first = await run();
        final legacyCorasol = receipt == '20240704000080';
        final numericCount = profiles
            .where(
              (p) =>
                  p['rule'] == LocatedOwnCurrentSource.rule ||
                  p['rule'] == LocatedOwnCurrentSource.partialRule ||
                  p['rule'] == LocatedOwnCurrentSource.printedLossRule,
            )
            .length;
        expect(first.updated, numericCount + (legacyCorasol ? 1 : 0));
        final actual = (await DartFiling.db.findById(session, filing.id!))!;
        for (final basis in FsDiv.values) {
          final matched = profiles
              .where((p) => p['basis'] == basis.name)
              .toList();
          final expected = matched.isEmpty
              ? legacyCorasol && basis == FsDiv.separate
                    ? FilingFetchStatus.stored
                    : FilingFetchStatus.failed
              : matched.single['rule'] == 'located-own-explicit-cfs-absence-v1'
              ? FilingFetchStatus.noData
              : FilingFetchStatus.stored;
          expect(
            basis == FsDiv.consolidated
                ? actual.consolidatedStatus
                : actual.separateStatus,
            expected,
          );
        }
        if (profiles.length == 1 && !legacyCorasol) {
          expect(first.status, IngestStatus.failed);
        }
        final reports = await FinancialReport.db.find(session);
        expect(reports, hasLength(numericCount + (legacyCorasol ? 1 : 0)));
        expect(
          await FinancialFact.db.count(session),
          profiles
                  .where(
                    (p) => p['rule'] != LocatedOwnCurrentSource.absenceRule,
                  )
                  .fold<int>(
                    0,
                    (n, p) =>
                        n +
                        (p['rule'] == LocatedOwnCurrentSource.partialRule
                            ? 7
                            : 8),
                  ) +
              (legacyCorasol ? 7 : 0),
        );
        for (final profile in profiles) {
          final basis = profile['basis'] == 'consolidated'
              ? FsDiv.consolidated
              : FsDiv.separate;
          final entry = VerifiedAnnualSourceRegistry.find(receipt, basis)!;
          final manifest = jsonDecode(
            File('${entry.assetDirectory}/manifest.json').readAsStringSync(),
          ) as Map;
          if (entry.absenceLiteral != null) {
            final source = (await Source.db.find(session)).singleWhere(
              (s) =>
                  s.reference ==
                  'financial-public-basis-not-applicable:$receipt:${basis.name}',
            );
            final payload = jsonDecode(source.title) as Map;
            expect(payload['receipt'], manifest['sourceReceipt']);
            expect(payload['corpCode'], company.corpCode);
            expect(payload['evidence'], entry.absenceLiteral);
            expect(
              payload['historicalCompanyIdentity']['printedName'],
              manifest['ownCoverActor'],
            );
            expect(
              payload['historicalCompanyIdentity']['targetReceipt'],
              receipt,
            );
            expect(
              payload['historicalCompanyIdentity']['policy'],
              'exact-own-filing-series-cfs-none-v1',
            );
            expect(
              payload['historicalCompanyIdentity']['ownCoverActor'],
              manifest['ownCoverActor'],
            );
            expect(
              payload['historicalCompanyIdentity']['currentName'],
              company.name,
            );
            expect(
              payload['historicalCompanyIdentity']['ownShellCorpProof'],
              company.corpCode,
            );
            expect(
              payload['identityScope'],
              'official-DART-filing-series-only',
            );
            expect(payload['numericFactsCollected'], 0);
            expect(payload['coreFinancialsVerified'], false);
            expect(payload['fullFinancialsVerified'], false);
            expect(payload['jurirContinuityVerified'], false);
            expect(payload['operatingHistoryContinuityVerified'], false);
            expect(
              payload['note'],
              contains(manifest['ownCoverActor'] as String),
            );
            expect(
              source.url,
              (manifest['sources'] as List).singleWhere(
                (s) => s['label'] == 'cfs',
              )['url'],
            );
            expect(payload['periodStart'], entry.periodStart.toIso8601String());
            expect(payload['periodEnd'], entry.periodEnd.toIso8601String());
            continue;
          }
          final report = reports.singleWhere((r) => r.fsDiv == basis);
          expect(report.rceptNo, manifest['sourceReceipt']);
          final printedLoss =
              entry.ruleVersion == LocatedOwnCurrentSource.printedLossRule;
          final partial =
              entry.ruleVersion == LocatedOwnCurrentSource.partialRule;
          final count = partial ? 7 : 8;
          expect(report.factCount, count);
          final detail = (await endpoints.financial.report(
            builder,
            report.id!,
          ))!;
          expect(detail.facts, hasLength(count));
          final source = (await Source.db.findById(session, report.sourceId))!;
          final payload = jsonDecode(source.title.split(' · ').last) as Map;
          expect(payload['targetReceipt'], receipt);
          expect(payload['sourceReceipt'], manifest['sourceReceipt']);
          expect(payload['coreRows'], count);
          if (partial) {
            final scopeSource = (await Source.db.findFirstRow(
              session,
              where: (s) => s.reference.equals(
                'financial-api-noData-source:$receipt:${basis.name}',
              ),
            ))!;
            expect(
              FinancialEndpoint.validPartialScopeSource(
                scopeSource,
                report,
                company.corpCode,
              ),
              true,
            );
            expect(detail.sources!.map((s) => s.id), contains(scopeSource.id));
            expect(
              FinancialEndpoint.validPartialScopeSource(
                scopeSource.copyWith(
                  title: scopeSource.title.replaceFirst('원', '천원'),
                ),
                report,
                company.corpCode,
              ),
              false,
            );
          }
          if (partial) {
            expect(payload['partialCore7'], true);
            expect(payload['currentCore8'], false);
            expect(payload['missingRequiredAccounts'], ['capex']);
            expect(payload['missingAccountReasons'], {
              'capex': LocatedOwnCurrentSource.capexMissingReason,
            });
            expect(
              detail.facts.where((f) => f.accountName.contains('유형자산의취득')),
              isEmpty,
            );
          }
          final core = manifest['core'] as List;
          for (var i = 0; i < core.length; i++) {
            final c = core[i] as Map;
            final ord =
                (manifest['tables'] as List)
                    .take(c['table'] as int)
                    .fold<int>(0, (n, t) => n + (t as List).length) +
                (c['row'] as int) +
                1;
            final fact = detail.facts.singleWhere((f) => f.ord == ord);
            expect(fact.accountName, c['label']);
            expect(
              fact.amount,
              BigInt.parse(
                (printedLoss &&
                            c['signNormalization'] ==
                                'explicitPrintedLossMagnitudeCorroborated'
                        ? '-'
                        : '') +
                    (c['literal'] as String)
                        .replaceAll(',', '')
                        .replaceAll('(', '-')
                        .replaceAll(')', ''),
              ),
            );
            expect(fact.sourceId, source.id);
            expect(fact.accountId, isNull);
            expect(fact.fsDiv, basis);
            final provenance =
                payload['coreRowProvenance'][i]['html_provenance'] as Map;
            expect(provenance['printedAmount'], c['literal']);
            expect(provenance['tableIndex'], c['table']);
            expect(provenance['rowIndex'], c['row']);
            expect(provenance['fullStatementVerified'], false);
            expect(provenance['detailEnrichmentApproved'], false);
            expect(provenance['currentCore8'], !partial);
            if (printedLoss) {
              expect(provenance['signNormalization'], c['signNormalization']);
              expect(provenance['derivedSignedAmount'], fact.amount.toString());
              expect(provenance['sourceCellRewritten'], false);
              expect(
                provenance['ownIssuerFilingSeriesEvidence'],
                manifest['ownIssuerFilingSeriesEvidence'],
              );
              expect(
                provenance['sourceRawAnomalies'],
                manifest['unverifiedNonCoreCells'],
              );
              expect(provenance['printedFxDashIsNumericZero'], false);
              expect(provenance['sourceMainEquationCount'], 18);
            }
            if (partial) {
              expect(provenance['coreAccountsProvided'], 7);
              expect(provenance['missingRequiredAccounts'], ['capex']);
              expect(provenance['missingAccountReasons'], {
                'capex': LocatedOwnCurrentSource.capexMissingReason,
              });
              expect(
                provenance['ownCurrentPeriodProof'],
                manifest['ownCurrentPeriodProof'],
              );
              expect(provenance['syntheticCapex'], false);
            }
            expect(provenance['periodStart'], manifest['periodStart']);
            expect(provenance['periodEnd'], manifest['periodEnd']);
            if (manifest['supportingNoteScope'] != null) {
              expect(
                provenance['supportingNoteScope'],
                manifest['supportingNoteScope'],
              );
              expect(
                provenance['sourceCaptionDifference'],
                manifest['sourceCaptionDifference'],
              );
              expect(provenance['roundingCauseInferred'], false);
              expect(provenance['notesVerified'], false);
            }
            expect(
              provenance['sourceDetailAnomalies'],
              manifest['sourceDetailAnomalies'],
            );
          }
          final summary = (await endpoints.financial.summary(
            builder,
            company.corpCode,
            fsDiv: basis,
          ))!;
          if (firstProfile['receipt'] == '20220615000399') {
            expect(
              summary.periods.single.periodName,
              '2021.04.01 ~ 2022.03.31 (365일)',
            );
          }
          expect(summary.periods.single.lines.map((l) => l.key).toSet(), {
            'assets',
            'liabilities',
            'equity',
            'revenue',
            'operatingIncome',
            'netIncome',
            'operatingCashFlow',
            if (!partial) 'capex',
          });
        }
        if (legacyCorasol) {
          final report = reports.singleWhere((r) => r.fsDiv == FsDiv.separate);
          expect(report.rceptNo, receipt);
          expect(report.factCount, 7);
          final detail = (await endpoints.financial.report(
            builder,
            report.id!,
          ))!;
          const printed = <String, String>{
            '자산총계': '42035972141',
            '부채총계': '25700060987',
            '자본총계': '16335911154',
            'Ⅰ. 매출액': '17372009452',
            'Ⅴ. 영업이익': '-2628301836',
            'Ⅹ. 당기순이익': '-2795459101',
            'Ⅰ. 영업활동으로 인한 현금흐름': '-1897300484',
          };
          expect(detail.facts, hasLength(7));
          for (final e in printed.entries) {
            final f = detail.facts.singleWhere((f) => f.accountName == e.key);
            expect(f.amount, BigInt.parse(e.value));
            expect(f.sourceId, report.sourceId);
            expect(f.fsDiv, FsDiv.separate);
          }
          final e = VerifiedAnnualSourceRegistry.find(receipt, FsDiv.separate)!;
          expect(e.ruleVersion, 'dated-current-column-whole-equity-v1');
          final own = jsonDecode(
            File('${e.assetDirectory}/manifest.json').readAsStringSync(),
          ) as Map;
          final source = (await Source.db.findById(session, report.sourceId))!;
          expect(
            source.url,
            (own['sources'] as List).singleWhere(
              (s) => s['label'] == 'ofs',
            )['url'],
          );
          final summary = (await endpoints.financial.summary(
            builder,
            company.corpCode,
            fsDiv: FsDiv.separate,
          ))!;
          if (firstProfile['receipt'] == '20220615000399') {
            expect(
              summary.periods.single.periodName,
              '2021.04.01 ~ 2022.03.31 (365일)',
            );
          }
          expect(summary.periods.single.lines.map((l) => l.key).toSet(), {
            'assets',
            'liabilities',
            'equity',
            'revenue',
            'operatingIncome',
            'netIncome',
            'operatingCashFlow',
          });
        }
        expect(
          (await Source.db.findById(session, correction.id!))!.toJson(),
          correctionBefore,
        );
        final factsBefore = (await FinancialFact.db.find(session))
            .map((f) => f.toJson())
            .toList();
        final sourcesBefore = (await Source.db.find(session))
            .map((s) => s.toJson())
            .toList();
        final replay = await run();
        expect(replay.updated, 0);
        expect(replay.status, first.status);
        expect(
          (await FinancialFact.db.find(session))
              .map((f) => f.toJson())
              .toList(),
          factsBefore,
        );
        expect(
          (await Source.db.find(session)).map((s) => s.toJson()).toList(),
          sourcesBefore,
        );
      });
    }
  });
}
