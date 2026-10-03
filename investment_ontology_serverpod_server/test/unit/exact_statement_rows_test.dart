import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/exact_statement_rows.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final (receipt, basis, count) in [
    ('20250320000036', FsDiv.separate, 116),
    ('20220310001159', FsDiv.consolidated, 204),
  ]) {
    final e = VerifiedAnnualSourceRegistry.find(receipt, basis)!;
    DartFiling stored() => filing(e).copyWith(
      consolidatedStatus: FilingFetchStatus.stored,
      separateStatus: FilingFetchStatus.stored,
    );
    test(
      '$receipt exact current rows preserve independent inventory',
      () async {
        final result = await ExactStatementRows.prepare(
          stored(),
          company(e),
          basis,
        );
        expect(result.rows.length, count);
        expect(
          result.ledger.where((r) => r['state'] == 'existing-core').length,
          8,
        );
        expect(result.rows.every((r) => r['account_id'] == null), true);
        expect(
          result.rows.where((r) => r['account_nm'].toString().contains('주당')),
          isEmpty,
        );
        expect(result.rows.where((r) => r['thstrm_amount'] == null), isEmpty);
        expect(result.payload['fullStatementCollected'], false);
        expect(result.payload['allStatementRowsVerified'], false);
        final ce = result.rows.where((r) => r['sj_div'] == 'SCE').toList();
        expect(ce.every((r) => r['account_detail'] != null), true);
        expect(
          ce.where((r) => r['account_nm'].toString().contains('전기')),
          isEmpty,
        );
        expect(result.rows.map((r) => r['ord']).toSet().length, count);
        final expected = jsonDecode(
          await File('test/fixtures/exact_statement_rows/$receipt.json')
              .readAsString(),
        ) as Map;
        final numeric = result.ledger
            .where(
              (r) => const {
                'existing-core',
                'current-monetary',
              }.contains(r['state']),
            )
            .map(
              (r) => {
                'statement': r['statement'],
                'tableIndex': r['tableIndex'],
                'rowIndex': r['rowIndex'],
                'column': (r['columns'] as List).singleWhere(
                  (col) =>
                      (r['rawRow'] as List)[col].toString().trim().isNotEmpty &&
                      (r['rawRow'] as List)[col] != '-',
                ),
                'printedLabel': r['printedLabel'],
                'amount': r['amount'],
              },
            )
            .toList();
        expect(numeric, expected['numericCurrentMonetaryCells']);
        BigInt? at(int ti, int ri, int col) {
          final row = result.ledger.firstWhere(
            (r) =>
                r['tableIndex'] == ti &&
                r['rowIndex'] == ri &&
                (r['columns'] as List).contains(col),
          );
          final printed = (row['rawRow'] as List)[col].toString().replaceAll(
            RegExp(r'\s+'),
            '',
          );
          if (printed.isEmpty || printed == '-') return null;
          return BigInt.parse(
            printed
                .replaceAll(',', '')
                .replaceAll('(', '-')
                .replaceAll(')', ''),
          );
        }

        BigInt sum(int ti, List<int> rs, int col) => rs
            .map((r) => at(ti, r, col))
            .whereType<BigInt>()
            .fold(BigInt.zero, (a, b) => a + b);
        if (basis == FsDiv.separate) {
          expect(
            result.rows.singleWhere(
              (r) => r['sj_div'] == 'BS' && r['account_nm'] == '현금및현금성자산',
            )['thstrm_amount'],
            '2536688740',
          );
          expect(
            result.rows.where((r) => r['account_nm'] == '당기손익-공정가치측정').length,
            2,
          );
          expect(
            result.ledger.any(
              (r) =>
                  r['printedLabel'].toString().contains('환율변동효과') &&
                  r['state'] == 'printed-unavailable',
            ),
            true,
          );
          expect(at(3, 2, 2)! + at(3, 9, 2)!, at(3, 15, 2));
          expect(sum(3, [3, 4, 5, 6, 7, 8], 2), at(3, 2, 2));
          expect(sum(3, [33, 34, 35, 36], 2), at(3, 37, 2));
          expect(at(7, 1, 2)! - at(7, 2, 2)!, at(7, 3, 2));
          expect(at(7, 3, 2)! - at(7, 4, 2)!, at(7, 7, 2));
          expect(at(7, 14, 2)! - at(7, 15, 2)!, at(7, 16, 2));
          expect(at(7, 16, 2)! + at(7, 17, 2)!, at(7, 20, 2));
          expect(at(15, 3, 1)! + at(15, 4, 1)! + at(15, 32, 1)!, at(15, 2, 1));
          expect(sum(15, [2, 44, 45, 46], 1), at(15, 1, 1));
          expect(sum(15, [1, 47, 56], 1), at(15, 73, 1));
          expect(at(15, 74, 1)! + at(15, 73, 1)!, at(15, 76, 1));
          for (var col = 1; col <= 5; col++) {
            // Reconcile printed numeric movements only. Missing cells remain
            // null in the ledger and are not converted into zero facts.
            expect(sum(11, [13, 14, 15, 16], col), at(11, 17, col));
          }
          for (var row = 13; row <= 17; row++) {
            expect(
              [for (var col = 1; col <= 4; col++) at(11, row, col)]
                  .whereType<BigInt>()
                  .fold(BigInt.zero, (a, b) => a + b),
              at(11, row, 5),
            );
          }
        } else {
          expect(
            result.rows.singleWhere(
              (r) =>
                  r['sj_div'] == 'CIS' &&
                  r['account_nm'].toString().contains('보험료수익'),
            )['thstrm_amount'],
            '20106066001421',
          );
          expect(
            result.rows.singleWhere(
              (r) =>
                  r['sj_div'] == 'CF' &&
                  r['account_nm'].toString().contains('환율변동효과'),
            )['thstrm_amount'],
            '51029016872',
          );
          expect(
            sum(1, [2, 3, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20], 2),
            at(1, 21, 2),
          );
          expect(sum(1, [4, 5, 6, 7, 8], 1), at(1, 3, 2));
          expect(sum(1, [35, 36, 37, 38, 39], 1), at(1, 34, 2));
          expect(at(1, 34, 2)! + at(1, 40, 2)!, at(1, 41, 2));
          expect(at(3, 1, 2)! - at(3, 22, 2)!, at(3, 43, 2));
          expect(at(3, 46, 2)! - at(3, 47, 2)!, at(3, 48, 2));
          expect(at(3, 48, 2)! + at(3, 49, 2)!, at(3, 50, 2));
          expect(at(3, 50, 2)! + at(3, 51, 2)!, at(3, 54, 2));
          expect(sum(7, [1, 60, 78, 86], 2), at(7, 87, 2));
          expect(at(7, 88, 2)! + at(7, 87, 2)!, at(7, 89, 2));
          for (var col = 1; col <= 7; col++) {
            expect(
              sum(5, [for (var row = 24; row < 34; row++) row], col),
              at(5, 34, col),
            );
          }
          for (var row = 24; row <= 34; row++) {
            expect(
              [for (var col = 1; col <= 6; col++) at(5, row, col)]
                  .whereType<BigInt>()
                  .fold(BigInt.zero, (a, b) => a + b),
              at(5, row, 7),
            );
          }
        }
        expect(
          () => result.rows.first['thstrm_amount'] = '0',
          throwsUnsupportedError,
        );
        expect(
          () => ((result.ledger.first['rawRow'] as List)[0] = 'wrong'),
          throwsUnsupportedError,
        );
        final opening = ce.where(
          (r) =>
              (r['html_provenance'] as Map)['valueAsOf'] == '${e.year}-01-01',
        );
        expect(opening, isNotEmpty);
        expect(opening.every((r) => r['thstrm_nm'] == '${e.year}-01-01'), true);
      },
    );
    for (final bad in ['issuer', 'period', 'basis', 'sha', 'notStored']) {
      test(
        '$receipt rejects ${bad == 'basis' && receipt == '20220310001159' ? 'opposite-basis source bytes' : bad}',
        () async {
          final f = stored(), c = company(e);
          if (bad == 'issuer') c.name = '다른 회사';
          if (bad == 'period') f.bsnsYear = f.bsnsYear! - 1;
          if (bad == 'notStored') {
            f.separateStatus = FilingFetchStatus.pending;
            f.consolidatedStatus = FilingFetchStatus.pending;
          }
          expect(
            () => ExactStatementRows.prepare(
              f,
              c,
              bad == 'basis'
                  ? (basis == FsDiv.separate
                        ? FsDiv.consolidated
                        : FsDiv.separate)
                  : basis,
              readAsset: (path) async {
                // Both Samsung bases now have independent approved profiles.
                // Serving CFS bytes to the OFS request must still be rejected.
                if (bad == 'basis' &&
                    receipt == '20220310001159' &&
                    path.endsWith('20220310001159-ofs/ofs.html')) {
                  return File(
                    path.replaceFirst(
                      '20220310001159-ofs/ofs.html',
                      '20220310001159-cfs/cfs.html',
                    ),
                  ).readAsBytes();
                }
                final bytes = await File(path).readAsBytes();
                return bad == 'sha' && path.endsWith('${e.statementLabel}.html')
                    ? [...bytes, 32]
                    : bytes;
              },
            ),
            throwsA(isA<FormatException>()),
          );
        },
      );
    }
  }
}
