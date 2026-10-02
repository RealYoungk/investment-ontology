import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/linked_correction_audit_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

DartFiling filing(AnnualSourceCacheEntry e) => DartFiling(
  id: 1,
  companyId: 1,
  corpCode: e.corpCode,
  rceptNo: e.receipt,
  bsnsYear: e.year,
  reportCode: FinancialReportCode.annual,
  reportName:
      '사업보고서 (${e.year}.${e.periodEnd.month.toString().padLeft(2, '0')})',
  consolidatedStatus: FilingFetchStatus.failed,
  separateStatus: FilingFetchStatus.failed,
  attempts: 7,
  lastError: 'api-noData-annual-public:attempt=3; previous failure',
  discoveredAt: DateTime.utc(2026),
);
Company company(AnnualSourceCacheEntry e) => Company(
  id: 1,
  corpCode: e.corpCode,
  name: e.companyName,
  stockCode: '123456',
  fiscalMonth: 12,
);
void main() {
  test('compiled receipt plus basis registry has unique audit identities', () {
    expect(VerifiedAnnualSourceRegistry.entries.length, 147);
    expect(
      VerifiedAnnualSourceRegistry.entries
          .map((e) => e.auditReference)
          .toSet()
          .length,
      VerifiedAnnualSourceRegistry.entries.length,
    );
    final gaia = VerifiedAnnualSourceRegistry.entries
        .where((e) => e.receipt == '20250331002057')
        .toList();
    expect(gaia.length, 2);
    expect(gaia.map((e) => e.basis).toSet(), FsDiv.values.toSet());
  });
  for (final e in VerifiedAnnualSourceRegistry.entries) {
    test(
      'actual packaged ${e.receipt}:${e.basis.name} validates only requested whole source',
      () async {
        final f = filing(e), before = f.toJson();
        var reads = 0;
        final cache = VerifiedAnnualSourceCache(
          readAsset: (p) async {
            reads++;
            return File(p).readAsBytes();
          },
        );
        final result = await cache.verifyRegistered(f, company(e), e.basis);
        expect(
          reads,
          4 +
              (e.requiresIssuerOverview ? 1 : 0) +
              (e.requiresOwnOfsWitness ? 1 : 0) +
              (e.ruleVersion == 'same-receipt-audit-immutable-v1' ? 1 : 0) +
              (e.ruleVersion == 'linked-correction-audit-immutable-v1' ? 2 : 0),
        );
        expect(f.toJson(), before);
        final manifest = jsonDecode(
          File('${e.assetDirectory}/manifest.json').readAsStringSync(),
        );
        expect(
          sha256
              .convert(
                File('${e.assetDirectory}/manifest.json').readAsBytesSync(),
              )
              .toString(),
          e.manifestDigest,
        );
        for (final source in manifest['sources']) {
          expect(
            sha256
                .convert(
                  File('${e.assetDirectory}/${source['file']}')
                      .readAsBytesSync(),
                )
                .toString(),
            source['sha256'],
          );
        }
        if (e.absenceLiteral != null) {
          expect(result.numeric, isNull);
          final a = result.absence!;
          expect(
            a.evidence.replaceAll(RegExp(r'\s+'), ''),
            e.absenceLiteral!.replaceAll(RegExp(r'\s+'), ''),
          );
          expect(a.sourceReceipt, e.receipt);
          expect(a.corpCode, e.corpCode);
          expect(a.periodStart, e.periodStart);
          expect(a.periodEnd, e.periodEnd);
        } else {
          expect(result.absence, isNull);
          final n = result.numeric!;
          expect(
            n.sourceReceipt,
            e.ruleVersion == 'linked-correction-audit-immutable-v1'
                ? LinkedCorrectionAuditSource.original
                : e.receipt,
          );
          expect(
            n.rows.every((row) => row['rcept_no'] == n.sourceReceipt),
            true,
          );
          if (e.ruleVersion == 'verified-current-period-whole-annual-v1') {
            final expected = jsonDecode(
              File('${e.assetDirectory}/expected-rows.json').readAsStringSync(),
            );
            expect(
              n.rows.map((r) => [r['account_nm'], r['thstrm_amount']]).toList(),
              expected,
            );
          }
          expect(
            n.rows.length,
            e.receipt == '20230315000460' ||
                    e.ruleVersion ==
                        'source-six-with-unavailable-whole-revenue-v1'
                ? 6
                : inInclusiveRange(7, 8),
          );
          expect(n.periodStart, e.periodStart);
          expect(n.periodEnd, e.periodEnd);
          expect(
            n.rows.every(
              (r) => r['account_id'] == null && r['currency'] == 'KRW',
            ),
            true,
          );
          expect(
            n.rows.every(
              (r) =>
                  (r['html_provenance'] as Map)['basis'] ==
                  (e.basis == FsDiv.consolidated ? 'CFS' : 'OFS'),
            ),
            true,
          );
          expect(
            BigInt.parse(n.rows[0]['thstrm_amount']),
            BigInt.parse(n.rows[1]['thstrm_amount']) +
                BigInt.parse(n.rows[2]['thstrm_amount']),
          );
        }
      },
    );
    for (final mutated in [
      filing(e).copyWith(corpCode: '00126380'),
      filing(e).copyWith(rceptNo: '20260101000001'),
      filing(e).copyWith(bsnsYear: e.year - 1),
      filing(e).copyWith(reportCode: FinancialReportCode.halfYear),
      filing(e).copyWith(reportName: '사업보고서 (${e.year}.06)'),
      filing(e).copyWith(lastError: 'api-noData-annual-public:attempt=2;'),
      filing(e).copyWith(lastError: 'api-noData-annual-public:attempt=4;'),
      filing(e).copyWith(
        consolidatedStatus: FilingFetchStatus.stored,
        separateStatus: FilingFetchStatus.stored,
      ),
      filing(e).copyWith(
        consolidatedStatus: FilingFetchStatus.noData,
        separateStatus: FilingFetchStatus.noData,
      ),
    ]) {
      test('exact scope rejection ${e.auditReference}:${mutated.toJson()}', () {
        expect(VerifiedAnnualSourceCache.eligibleFor(mutated, e), false);
      });
    }
    for (final label in [
      'manifest.json',
      'shell.html',
      'cover.html',
      '${e.statementLabel}.html',
      if (e.requiresIssuerOverview) 'overview.html',
      if (e.ruleVersion == 'same-receipt-audit-immutable-v1') 'auditShell.html',
    ]) {
      test(
        'altered pinned bytes ${e.receipt}:${e.basis.name}:$label reject',
        () async {
          final c = VerifiedAnnualSourceCache(
            readAsset: (p) async {
              final bytes = await File(p).readAsBytes();
              return p.endsWith(label) ? [...bytes, 32] : bytes;
            },
          );
          await expectLater(
            c.verifyRegistered(filing(e), company(e), e.basis),
            throwsFormatException,
          );
        },
      );
    }
  }
  test('caller constructed package never eligible even if metadata resembles pinned entry', () {
    final e = VerifiedAnnualSourceRegistry.entries.first;
    final submitted = AnnualSourceCacheEntry(
      receipt: e.receipt,
      corpCode: e.corpCode,
      companyName: e.companyName,
      year: e.year,
      basis: e.basis,
      assetDirectory: e.assetDirectory,
      manifestDigest: e.manifestDigest,
      ruleVersion: e.ruleVersion,
      absenceLiteral: e.absenceLiteral,
    );
    expect(VerifiedAnnualSourceCache.eligibleFor(filing(e), submitted), false);
  });
  test(
    'unknown receipt and unknown basis do not select another package',
    () async {
      final e = VerifiedAnnualSourceRegistry.entries.firstWhere(
        (e) => e.receipt == '20260323000661',
      );
      expect(
        VerifiedAnnualSourceRegistry.find(e.receipt, FsDiv.consolidated),
        isNull,
      );
      await expectLater(
        VerifiedAnnualSourceCache().verifyRegistered(
          filing(e),
          company(e),
          FsDiv.consolidated,
        ),
        throwsFormatException,
      );
    },
  );
}
