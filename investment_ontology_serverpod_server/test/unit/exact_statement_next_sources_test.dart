import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/exact_statement_rows.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:test/test.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  for (final (receipt, expectedAdditional) in [
    ('20230321000015', 115),
    ('20220310001159', 174),
  ]) {
    test(
      '$receipt OFS exact additional rows retain original coordinates',
      () async {
        final e = VerifiedAnnualSourceRegistry.find(receipt, FsDiv.separate)!;
        final result = await ExactStatementRows.prepare(
          filing(e).copyWith(separateStatus: FilingFetchStatus.stored),
          company(e),
          FsDiv.separate,
        );
        final fixture = jsonDecode(
          await File('test/fixtures/exact_statement_rows/$receipt-ofs.json')
              .readAsString(),
        ) as Map;
        expect(result.rows.length, expectedAdditional);
        expect(result.coreRows.length, 8);
        expect(
          result.ledger.where((r) => r['state'] == 'existing-core').length,
          8,
        );
        expect(result.payload['fullStatementCollected'], false);
        expect(result.payload['allStatementRowsVerified'], false);
        expect(result.payload['notesCollected'], false);
        expect(
          result.rows.every(
            (r) => r['account_id'] == null && r['fs_div'] == 'OFS',
          ),
          true,
        );
        expect(
          result.rows.any((r) => r['account_nm'].toString().contains('주당')),
          false,
        );
        expect(
          result.ledger.where((r) => r['state'] == 'nonmonetary-EPS').length,
          3,
        );
        expect(
          result.ledger.every(
            (r) =>
                r['sha256'] == fixture['bodySha256'] &&
                r['source'] == fixture['sourceURI'],
          ),
          true,
        );
        expect(
          result.rows.map((r) => r['ord']).toSet().length,
          expectedAdditional,
        );
        final actual = result.ledger
            .where(
              (r) => {'existing-core', 'current-monetary'}.contains(r['state']),
            )
            .map(
              (r) => {
                'statement': r['statement'],
                'tableIndex': r['tableIndex'],
                'rowIndex': r['rowIndex'],
                'column': (r['columns'] as List).singleWhere(
                  (c) =>
                      (r['rawRow'] as List)[c] != '' &&
                      (r['rawRow'] as List)[c] != '-',
                ),
                'printedLabel': r['printedLabel'],
                'amount': r['amount'],
              },
            )
            .toList();
        expect(actual, fixture['numericCurrentMonetaryCells']);
        BigInt? at(int table, int row, [int? col]) {
          final entry = result.ledger.firstWhere(
            (r) =>
                r['tableIndex'] == table &&
                r['rowIndex'] == row &&
                (col == null || (r['columns'] as List).contains(col)),
          );
          return entry['amount'] == null
              ? null
              : BigInt.parse(entry['amount'] as String);
        }

        for (final rawCheck in fixture['hierarchyChecks'] as List) {
          final check = rawCheck as Map;
          BigInt? target;
          var sum = BigInt.zero;
          if (check['kind'] == 'CE-component') {
            final opening = check['openingCoordinate'] as List;
            final closing = check['closingCoordinate'] as List;
            target = at(
              closing[0] as int,
              closing[1] as int,
              closing[2] as int,
            );
            final start = at(
              opening[0] as int,
              opening[1] as int,
              opening[2] as int,
            );
            // An unprinted component stays null and is never a zero fact.
            if (start == null || target == null) {
              expect(check['delta'], null);
              continue;
            }
            sum = start;
            for (final coordinate in check['movementCoordinates'] as List) {
              final value = at(
                coordinate[0] as int,
                coordinate[1] as int,
                coordinate[2] as int,
              );
              if (value != null) sum += value;
            }
          } else if (check['kind'] == 'CE-whole-row') {
            final entries = result.ledger
                .where(
                  (r) =>
                      r['tableIndex'] == check['tableIndex'] &&
                      r['rowIndex'] == check['rowIndex'],
                )
                .toList();
            target = entries.last['amount'] == null
                ? null
                : BigInt.parse(entries.last['amount'] as String);
            for (final entry in entries.take(entries.length - 1)) {
              if (entry['amount'] != null) {
                sum += BigInt.parse(entry['amount'] as String);
              }
            }
          } else {
            target = at(check['tableIndex'] as int, check['targetRow'] as int);
            for (final term in check['terms'] as List) {
              final value = at(check['tableIndex'] as int, term['row'] as int);
              if (value != null) {
                sum += value * BigInt.from(term['sign'] as int);
              }
            }
          }
          if (target == null) {
            expect(check['delta'], null);
          } else {
            expect(sum, target, reason: '$receipt $check');
          }
        }
        final ce = result.ledger.where((r) => r['statement'] == 'SCE');
        expect(
          ce.where((r) => r['valueAsOf'] == '${e.year}-01-01'),
          isNotEmpty,
        );
        expect(
          ce.where((r) => r['valueAsOf'] == '${e.year}-12-31'),
          isNotEmpty,
        );
        expect(
          result.ledger
              .where((r) => r['state'] == 'printed-unavailable')
              .every((r) => r['amount'] == null),
          true,
        );
        if (receipt == '20220310001159') {
          expect(
            result.ledger.every((r) => (r['tableIndex'] as int) < 8),
            true,
          );
          expect(
            result.ledger.every((r) => r['printedTableUnit'] == '원'),
            true,
          );
          // Own OFS acquisition detail is printed positive within an outflow group.
          expect(at(7, 75), BigInt.from(24513857308));
        }
      },
    );
  }
  test(
    'malformed comma groups and unmatched parentheses cannot become money',
    () {
      for (final printed in [
        '1,2,3',
        '2,108,790,91',
        '1234,567',
        '(1,000',
        '1,000)',
        '(1,000)junk',
        '1.0',
        '-',
        '',
      ]) {
        expect(
          () => ExactStatementRows.parsePrintedMonetaryCell(printed),
          throwsFormatException,
          reason: printed,
        );
      }
      expect(
        ExactStatementRows.parsePrintedMonetaryCell('(2,108,790,912)'),
        BigInt.from(-2108790912),
      );
      expect(
        ExactStatementRows.parsePrintedMonetaryCell('1234567'),
        BigInt.from(1234567),
      );
      expect(
        ExactStatementRows.parsePrintedMonetaryCell('1,234,567'),
        BigInt.from(1234567),
      );
    },
  );
  for (final receipt in ['20220330000851', '20240318000135']) {
    test('$receipt contradicted detail source remains unapproved', () async {
      final e = VerifiedAnnualSourceRegistry.find(receipt, FsDiv.separate)!;
      expect(ExactStatementRows.eligible(receipt, FsDiv.separate), false);
      await expectLater(
        ExactStatementRows.prepare(filing(e), company(e), FsDiv.separate),
        throwsFormatException,
      );
    });
  }
  test(
    'blocked originals retain malformed cell and exact 900000-won conflict',
    () async {
      final evidence = jsonDecode(
        await File(
          'test/fixtures/exact_statement_rows/aone-blocked-current-expansion.json',
        ).readAsString(),
      ) as Map;
      final malformed =
          ((evidence['profiles'] as List).first['currentRows'] as List)
              .singleWhere(
                (r) =>
                    r['tableIndex'] == 11 &&
                    r['rowIndex'] == 17 &&
                    (r['columns'] as List).single == 3,
              );
      expect(malformed['printedCurrentCells'], ['2,108,790,91']);
      expect(malformed['amount'], null);
      final conflict = (evidence['nonzeroHierarchy']['nonzero'] as List).single;
      expect(conflict['tableIndex'], 15);
      expect(conflict['targetRow'], 44);
      expect(conflict['delta'], '900000');
    },
  );
}
