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
        expect(result.numeric!.rows, hasLength(8));
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
              amount: BigInt.parse(r['thstrm_amount'] as String),
              sourceId: 1,
            ),
        ];
        expect(FinancialAccounts.pick(facts).map((l) => l.key).toSet(), {
          'assets',
          'liabilities',
          'equity',
          'revenue',
          'operatingIncome',
          'netIncome',
          'operatingCashFlow',
          'capex',
        });
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

        for (var i = 0; i < 8; i++) {
          final row = result.numeric!.rows[i], c = m['core'][i] as Map;
          final provenance = row['html_provenance'] as Map;
          expect(row['account_nm'], c['label']);
          expect(
            row['thstrm_amount'],
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
        if (profile['requiresOwnNotes'] == true) {
          expect(
            LocatedOwnCurrentSource.sourceEligible(
              receipt: e.receipt,
              corp: e.corpCode,
              basis: FsDiv.consolidated,
              start: e.periodStart,
              end: e.periodEnd,
              sourceReceipt: m['sourceReceipt'] as String,
            ),
            false,
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
    if (profile['requiresOwnNotes'] == true) {
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
          await expectLater(
            cache.verifyRegistered(filing(e), company(e), FsDiv.consolidated),
            throwsFormatException,
          );
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
