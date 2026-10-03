import 'package:investment_ontology_serverpod_server/src/ontology/financial/hanwha_own_net_income_scope.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/located_own_current_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final profile in LocatedOwnCurrentSource.profiles) {
    final basis = profile['basis'] == 'consolidated'
        ? FsDiv.consolidated
        : FsDiv.separate;
    final e = VerifiedAnnualSourceRegistry.find(
      profile['receipt'] as String,
      basis,
    )!;
    final partial = e.ruleVersion == LocatedOwnCurrentSource.partialRule;
    final printedLoss =
        e.ruleVersion == LocatedOwnCurrentSource.printedLossRule;
    final count = partial ? 7 : 8;
    final m = jsonDecode(
      File('${e.assetDirectory}/manifest.json').readAsStringSync(),
    ) as Map;
    test(
      '${e.receipt}:${basis.name} actual normal cache finite own scope and exact provenance',
      () async {
        var reads = 0;
        final result = await VerifiedAnnualSourceCache(
          readAsset: (p) async {
            reads++;
            return File(p).readAsBytes();
          },
        ).verifyRegistered(filing(e), company(e), basis);
        expect(reads, (m['sources'] as List).length + 1);
        if (e.absenceLiteral != null) {
          expect(result.numeric, isNull);
          expect(result.absence!.evidence, e.absenceLiteral);
          expect(result.absence!.sourceReceipt, m['sourceReceipt']);
          expect(result.absence!.corpCode, e.corpCode);
          expect(
            result.absence!.issuerIdentityEvidence!['printedName'],
            m['ownCoverActor'],
          );
          expect(
            result.absence!.issuerIdentityEvidence!['targetReceipt'],
            e.receipt,
          );
          expect(
            result.absence!.issuerIdentityEvidence!['policy'],
            'exact-own-filing-series-cfs-none-v1',
          );
          expect(
            result.absence!.issuerIdentityEvidence!['ownCoverActor'],
            m['ownCoverActor'],
          );
          expect(
            result.absence!.issuerIdentityEvidence!['currentName'],
            e.companyName,
          );
          expect(
            result.absence!.issuerIdentityEvidence!['ownShellCorpProof'],
            e.corpCode,
          );
          expect(
            result.absence!.issuerIdentityEvidence!['jurirContinuityVerified'],
            'false',
          );
          expect(
            result
                .absence!
                .issuerIdentityEvidence!['operatingHistoryContinuityVerified'],
            'false',
          );
          expect(
            result.absence!.issuerIdentityEvidence!['sourceNotice'],
            contains(m['ownCoverActor'] as String),
          );
          expect(result.absence!.periodStart, e.periodStart);
          expect(result.absence!.periodEnd, e.periodEnd);
          return;
        }
        expect(result.absence, isNull);
        expect(result.numeric!.sourceReceipt, m['sourceReceipt']);
        expect(
          result.numeric!.correctionReceipt,
          m['sourceReceipt'] == e.receipt ? null : e.receipt,
        );
        expect(result.numeric!.rows, hasLength(count));
        if (partial) {
          final report = FinancialReport(
            id: 1,
            companyId: 1,
            bsnsYear: e.year,
            reportCode: FinancialReportCode.annual,
            fsDiv: basis,
            rceptNo: e.receipt,
            reportName: filing(e).reportName,
            sourceId: 1,
            fetchedAt: DateTime.utc(2026),
            factCount: 7,
          );
          final payload = <String, dynamic>{
            'action': 'verified-keyless-annual-source-after-api-noData',
            'targetReceipt': e.receipt,
            'sourceReceipt': e.receipt,
            'corpCode': e.corpCode,
            'reportName': report.reportName,
            'fsDiv': basis.name,
            'format': 'html',
            'sha256': result.numeric!.sourceDigest,
            'coreRows': 7,
            'coreRowProvenance': [
              for (final r in result.numeric!.rows)
                {
                  'account_nm': r['account_nm'],
                  'account_id': r['account_id'],
                  'thstrm_amount': r['thstrm_amount'],
                  'currency': r['currency'],
                  'html_provenance': r['html_provenance'],
                  'xbrl_provenance': r['xbrl_provenance'],
                },
            ],
          };
          expect((payload['coreRowProvenance'] as List).first.keys.toSet(), {
            'account_nm',
            'account_id',
            'thstrm_amount',
            'currency',
            'html_provenance',
            'xbrl_provenance',
          });
          Source scoped(Map value) => Source(
            kind: SourceKind.dartReport,
            reference: 'financial-api-noData-source:${e.receipt}:${basis.name}',
            url: result.numeric!.statementSource.toString(),
            title: jsonEncode(value),
            retrievedAt: DateTime.utc(2026),
          );
          expect(
            LocatedOwnCurrentSource.recordedPartialScope(
              scoped(payload),
              report,
              e.corpCode,
            ),
            true,
          );
          expect(
            LocatedOwnCurrentSource.recordedPartialScope(
              scoped({...payload, 'sha256': 'changed'}),
              report,
              e.corpCode,
            ),
            false,
          );
          if (profile['requiresBoundedUnverifiedNotes'] == true) {
            final falseClaim = jsonDecode(jsonEncode(payload)) as Map;
            falseClaim['coreRowProvenance'][0]['html_provenance']['ownNoteDisagreements'][0]['residual'] =
                0;
            expect(
              LocatedOwnCurrentSource.recordedPartialScope(
                scoped(falseClaim),
                report,
                e.corpCode,
              ),
              false,
            );
            final notesClaim = jsonDecode(jsonEncode(payload)) as Map;
            notesClaim['coreRowProvenance'][0]['html_provenance']['notesVerified'] =
                true;
            expect(
              LocatedOwnCurrentSource.recordedPartialScope(
                scoped(notesClaim),
                report,
                e.corpCode,
              ),
              false,
            );
          }
          final altered = jsonDecode(jsonEncode(payload)) as Map;
          altered['coreRowProvenance'][0]['html_provenance']['currentColumn'] =
              99;
          expect(
            LocatedOwnCurrentSource.recordedPartialScope(
              scoped(altered),
              report,
              e.corpCode,
            ),
            false,
          );
          altered['coreRowProvenance'][0]['html_provenance']['currentColumn'] =
              m['core'][0]['column'];
          altered['coreRowProvenance'][0]['thstrm_amount'] = '0';
          expect(
            LocatedOwnCurrentSource.recordedPartialScope(
              scoped(altered),
              report,
              e.corpCode,
            ),
            false,
          );
        }

        final facts = [
          for (final r in result.numeric!.rows)
            FinancialFact(
              id: int.parse(r['ord'] as String),
              reportId: 1,
              companyId: 1,
              bsnsYear: e.year,
              reportCode: FinancialReportCode.annual,
              fsDiv: basis,
              statement: r['sj_div'] == 'BS'
                  ? FinancialStatementKind.balanceSheet
                  : r['sj_div'] == 'CF'
                  ? FinancialStatementKind.cashFlow
                  : FinancialStatementKind.comprehensiveIncome,
              accountName: r['account_nm'] as String,
              ord: int.parse(r['ord'] as String),
              periodName: r['thstrm_nm'] as String,
              currency: 'KRW',
              amount: BigInt.parse(r['thstrm_amount'] as String),
              sourceId: 1,
            ),
        ];
        expect(
          FinancialAccounts.pick(
            facts,
            company: e.receipt == HanwhaOwnNetIncomeScope.receipt
                ? company(e)
                : null,
            report: e.receipt == HanwhaOwnNetIncomeScope.receipt
                ? FinancialReport(
                    id: 1,
                    companyId: 1,
                    bsnsYear: e.year,
                    reportCode: FinancialReportCode.annual,
                    fsDiv: basis,
                    rceptNo: e.receipt,
                    reportName: '사업보고서 (2022.12)',
                    sourceId: 1,
                    factCount: 8,
                    invalidAmountCount: 0,
                    fetchedAt: DateTime.utc(2026),
                  )
                : null,
            source: e.receipt == HanwhaOwnNetIncomeScope.receipt
                ? Source(
                    id: 1,
                    kind: SourceKind.dartReport,
                    reference: e.receipt,
                    url: HanwhaOwnNetIncomeScope.url,
                    title: HanwhaOwnNetIncomeScope.sourceTitle(
                      '사업보고서 (2022.12)',
                    ),
                    retrievedAt: DateTime.utc(2026),
                  )
                : null,
          ).map((l) => l.key).toSet(),
          {
            'assets',
            'liabilities',
            'equity',
            'revenue',
            'operatingIncome',
            'netIncome',
            'operatingCashFlow',
            if (!partial) 'capex',
          },
        );
        expect(
          LocatedOwnCurrentSource.storedScope(
            rows: result.numeric!.rows,
            receipt: result.numeric!.sourceReceipt,
            corp: e.corpCode,
            companyName: e.companyName,
            consolidated: basis == FsDiv.consolidated,
            source: result.numeric!.statementSource,
            digest: result.numeric!.sourceDigest,
          ),
          isNotNull,
        );
        expect(
          LocatedOwnCurrentSource.storedScope(
            rows: result.numeric!.rows,
            receipt: result.numeric!.sourceReceipt,
            corp: e.corpCode,
            companyName: e.companyName,
            consolidated: basis == FsDiv.consolidated,
            source: result.numeric!.statementSource,
            digest: 'changed',
          ),
          isNull,
        );

        if (printedLoss) {
          final changed = jsonDecode(jsonEncode(result.numeric!.rows)) as List;
          Map<String, dynamic>? scoped(List list) =>
              LocatedOwnCurrentSource.storedScope(
                rows: [for (final r in list) Map<String, dynamic>.from(r)],
                receipt: result.numeric!.sourceReceipt,
                corp: e.corpCode,
                companyName: e.companyName,
                consolidated: false,
                source: result.numeric!.statementSource,
                digest: result.numeric!.sourceDigest,
              );
          changed[4]['thstrm_amount'] = '1541424780';
          expect(scoped(changed), isNull);
          changed[4]['thstrm_amount'] = '-1541424780';
          changed[4]['html_provenance']['currentColumn'] = 99;
          expect(scoped(changed), isNull);
          changed[4]['html_provenance']['currentColumn'] =
              m['core'][4]['column'];
          changed[4]['html_provenance']['signNormalization'] = 'none';
          expect(scoped(changed), isNull);
        }
        for (var i = 0; i < count; i++) {
          final row = result.numeric!.rows[i], c = m['core'][i] as Map;
          final provenance = row['html_provenance'] as Map;
          expect(row['account_nm'], c['label']);
          expect(
            row['thstrm_amount'],
            (printedLoss &&
                        c['signNormalization'] ==
                            'explicitPrintedLossMagnitudeCorroborated'
                    ? '-'
                    : '') +
                (c['literal'] as String)
                    .replaceAll(',', '')
                    .replaceAll('(', '-')
                    .replaceAll(')', ''),
          );
          expect(row['rcept_no'], m['sourceReceipt']);
          expect(
            row['ord'],
            '${(m['tables'] as List).take(c['table'] as int).fold<int>(0, (n, t) => n + (t as List).length) + (c['row'] as int) + 1}',
          );
          expect(provenance['currentColumn'], c['column']);
          expect(provenance['tableIndex'], c['table']);
          expect(provenance['rowIndex'], c['row']);
          expect(provenance['fullStatementVerified'], false);
          expect(provenance['currentCore8'], !partial);
          if (printedLoss) {
            expect(provenance['signNormalization'], c['signNormalization']);
            expect(provenance['derivedSignedAmount'], row['thstrm_amount']);
            expect(
              provenance['ownIssuerFilingSeriesEvidence'],
              m['ownIssuerFilingSeriesEvidence'],
            );
            expect(
              provenance['sourceRawAnomalies'],
              m['unverifiedNonCoreCells'],
            );
            expect(provenance['sourceCellRewritten'], false);
            expect(provenance['printedFxDashIsNumericZero'], false);
            expect(provenance['sourceMainEquationCount'], 18);
          }
          if (partial) {
            expect(provenance['partialCore7'], true);
            expect(provenance['missingRequiredAccounts'], ['capex']);
            expect(provenance['missingAccountReasons'], {
              'capex': LocatedOwnCurrentSource.capexMissingReason,
            });
            expect(provenance['syntheticCapex'], false);
            expect(
              provenance['ownCurrentPeriodProof'],
              m['ownCurrentPeriodProof'],
            );
          }
          expect(provenance['periodStart'], m['periodStart']);
          expect(provenance['periodEnd'], m['periodEnd']);
          if (m['supportingNoteScope'] != null) {
            expect(provenance['supportingNoteScope'], m['supportingNoteScope']);
            expect(
              provenance['sourceCaptionDifference'],
              m['sourceCaptionDifference'],
            );
            expect(provenance['crossPrecisionEqualityClaim'], false);
            expect(provenance['roundingCauseInferred'], false);
            expect(provenance['notesVerified'], false);
          }
          if (profile['requiresBoundedUnverifiedNotes'] == true) {
            expect(
              provenance['supportingUnverifiedNoteSource'],
              profile['noteURI'],
            );
            expect(
              provenance['supportingUnverifiedNoteSha256'],
              profile['noteSHA'],
            );
            expect(
              provenance['ownNoteDisagreements'],
              m['ownNoteDisagreements'],
            );
            expect(
              provenance['ownNoteCrossPrecisionResiduals'],
              m['ownNoteCrossPrecisionResiduals'],
            );
            expect(provenance['independentCFNetIncomePrinted'], false);
            expect(provenance['independentCFNetIncomeExact'], false);
            expect(provenance['mainNetIncomePLCEExact'], true);
            expect(provenance['unresolvedOwnNoteDetailConflict'], true);
          }
          expect(provenance['detailEnrichmentApproved'], false);
          expect(
            provenance['sourceDetailAnomalies'],
            m['sourceDetailAnomalies'],
          );
        }
      },
    );
    test(
      '${e.receipt}:${basis.name} exact declared period accepted and other basis refused',
      () {
        expect(
          LocatedOwnCurrentSource.sourceEligible(
            receipt: e.receipt,
            corp: e.corpCode,
            basis: basis,
            start: e.periodStart,
            end: e.periodEnd,
            sourceReceipt: m['sourceReceipt'] as String,
          ),
          true,
        );
        if (profile['requiresOwnNotes'] == true || partial || printedLoss) {
          expect(
            LocatedOwnCurrentSource.sourceEligible(
              receipt: e.receipt,
              corp: e.corpCode,
              basis: basis == FsDiv.consolidated
                  ? FsDiv.separate
                  : FsDiv.consolidated,
              start: e.periodStart,
              end: e.periodEnd,
              sourceReceipt: m['sourceReceipt'] as String,
            ),
            e.receipt == '20230314000692',
          );
          expect(
            LocatedOwnCurrentSource.sourceEligible(
              receipt: e.receipt,
              corp: e.corpCode,
              basis: basis,
              start: e.periodStart.add(const Duration(days: 1)),
              end: e.periodEnd,
              sourceReceipt: m['sourceReceipt'] as String,
            ),
            false,
          );
        }
      },
    );
    if (profile['requiresOwnNotes'] == true || partial || printedLoss) {
      test(
        '${e.receipt}:${basis.name} actual cache rejects wrong period and other basis',
        () async {
          final cache = VerifiedAnnualSourceCache(
            readAsset: (p) => File(p).readAsBytes(),
          );
          await expectLater(
            cache.verifyRegistered(
              filing(e).copyWith(reportName: '사업보고서 (${e.year}.06)'),
              company(e),
              basis,
            ),
            throwsFormatException,
          );
          if (!{'20230314000692', '20230314001218'}.contains(e.receipt)) {
            await expectLater(
              cache.verifyRegistered(
                filing(e),
                company(e),
                basis == FsDiv.consolidated
                    ? FsDiv.separate
                    : FsDiv.consolidated,
              ),
              throwsFormatException,
            );
          } else {
            // Both bases have independent own packages; passing the requested
            // entry with the other basis must still reject, not another valid package.
            await expectLater(
              LocatedOwnCurrentSource.verify(
                entry: e,
                company: company(e),
                filing: filing(e),
                rawManifest: File(
                  '${VerifiedAnnualSourceRegistry.find(e.receipt, basis == FsDiv.consolidated ? FsDiv.separate : FsDiv.consolidated)!.assetDirectory}/manifest.json',
                ).readAsBytesSync(),
                read: (p) => File(p).readAsBytes(),
              ),
              throwsFormatException,
            );
          }
        },
      );
    }
    for (final f in [
      'manifest.json',
      ...(m['sources'] as List).map((s) => s['file'] as String),
    ]) {
      test('${e.receipt}:${basis.name} refuses modified $f', () async {
        final cache = VerifiedAnnualSourceCache(
          readAsset: (p) async {
            final b = await File(p).readAsBytes();
            return p.endsWith('/$f') ? [...b, 32] : b;
          },
        );
        await expectLater(
          cache.verifyRegistered(filing(e), company(e), basis),
          throwsFormatException,
        );
      });
    }
    test(
      '${e.receipt}:${basis.name} rejects wrong issuer, year and correction source',
      () {
        for (final mismatch in ['corp', 'year', 'receipt']) {
          expect(
            LocatedOwnCurrentSource.sourceEligible(
              receipt: e.receipt,
              corp: mismatch == 'corp' ? '00000000' : e.corpCode,
              basis: basis,
              start: DateTime.utc(mismatch == 'year' ? 2020 : e.year),
              end: e.periodEnd,
              sourceReceipt: mismatch == 'receipt'
                  ? '20200101000000'
                  : m['sourceReceipt'] as String,
            ),
            false,
          );
        }
      },
    );
  }
}
