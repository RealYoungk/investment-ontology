import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/exact_statement_rows.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/exact_current_row_profiles.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';

import 'verified_annual_source_registry_test.dart' as fixture;

void main() {
  final independent = jsonDecode(
    File('test/fixtures/exact_statement_rows/next-five-current-row-proofs.json')
        .readAsStringSync(),
  ) as List;
  for (final witness in independent.cast<Map>()) {
    final basis = FsDiv.values.singleWhere((b) => b.name == witness['basis']);
    final entry = VerifiedAnnualSourceRegistry.find(
      witness['receipt'] as String,
      basis,
    )!;
    final f = fixture
        .filing(entry)
        .copyWith(
          consolidatedStatus: FilingFetchStatus.stored,
          separateStatus: FilingFetchStatus.stored,
        );
    test(
      '${entry.receipt}:${basis.name} independent current cells and physical ord',
      () async {
        final result = await ExactStatementRows.prepare(
          f,
          fixture.company(entry),
          basis,
        );
        expect(result.coreRows, witness['coreRows']);
        expect(
          result.rows,
          hasLength(witness['additionalMonetaryFacts'] as int),
        );
        expect(result.ledger, hasLength((witness['ledger'] as List).length));
        for (var i = 0; i < result.ledger.length; i++) {
          final actual = result.ledger[i],
              expected = (witness['ledger'] as List)[i] as Map;
          for (final key in [
            'statement',
            'tableIndex',
            'rowIndex',
            'columns',
            'printedLabel',
            'rawRow',
            'currentHeader',
            'printedCurrentCells',
            'state',
            'basis',
            'periodStart',
            'periodEnd',
            'unit',
            'printedUnitEvidence',
            'source',
            'sha256',
          ]) {
            if (key == 'currentHeader') {
              String text(String s) => s.replaceAll(RegExp(r'\s+'), '');
              expect(
                (actual[key] as List).cast<String>().map(text).toList(),
                (expected[key] as List).cast<String>().map(text).toList(),
                reason: '$i exact header words, HTML BR whitespace',
              );
            } else {
              expect(actual[key], expected[key], reason: '$i $key');
            }
          }
          expect(actual['amount'], expected['amount'], reason: '$i amount');
          if (expected['valueAsOf'] != null)
            expect(actual['valueAsOf'], expected['valueAsOf']);
        }
        final converted = FinancialRows.toFacts(
          result.rows,
          reportId: 1,
          companyId: 1,
          bsnsYear: entry.year,
          reportCode: FinancialReportCode.annual,
          fsDiv: basis,
          sourceId: 1,
        );
        expect(converted.invalidAmounts, 0);
        expect(converted.skippedRows, 0);
        expect(converted.facts, hasLength(result.rows.length));
        expect(converted.facts.every((f) => f.ord != null), true);
        expect(
          converted.facts.map((f) => f.ord).toSet(),
          hasLength(result.rows.length),
        );
        for (var i = 0; i < converted.facts.length; i++) {
          expect(
            converted.facts[i].amount.toString(),
            result.rows[i]['thstrm_amount'],
          );
          expect(converted.facts[i].ord.toString(), result.rows[i]['ord']);
          expect(converted.facts[i].accountId, null);
          expect(converted.facts[i].priorAmount, null);
          expect(converted.facts[i].fsDiv, basis);
        }
        expect(result.payload['fullStatementCollected'], false);
        expect(result.payload['notesCollected'], false);
      },
    );
    test(
      '${entry.receipt}:${basis.name} every printed current hierarchy equation independently rechecks',
      () async {
        final result = await ExactStatementRows.prepare(
          f,
          fixture.company(entry),
          basis,
        );
        for (final check in (witness['checks'] as List).cast<Map>()) {
          var residual = BigInt.zero;
          for (final term in (check['terms'] as List).cast<Map>()) {
            final coordinate = (term['coordinate'] as List).cast<int>();
            final cell = result.ledger.singleWhere(
              (r) =>
                  r['tableIndex'] == coordinate[0] &&
                  r['rowIndex'] == coordinate[1] &&
                  (r['columns'] as List).contains(coordinate[2]),
            );
            expect(cell['printedCurrentCells'], contains(term['raw']));
            expect(cell['amount'], term['amount']);
            if (cell['amount'] != null)
              residual +=
                  BigInt.parse(cell['amount'] as String) *
                  BigInt.from(term['coefficient'] as int);
          }
          expect(residual, BigInt.zero, reason: check['name'] as String);
          expect(check['residual'], '0');
        }
      },
    );
    test(
      '${entry.receipt}:${basis.name} rejected identity and altered original digest',
      () async {
        await expectLater(
          ExactStatementRows.prepare(
            f.copyWith(bsnsYear: entry.year - 1),
            fixture.company(entry),
            basis,
          ),
          throwsFormatException,
        );
        await expectLater(
          ExactStatementRows.prepare(
            f,
            fixture.company(entry),
            basis,
            readAsset: (path) async {
              final bytes = await File(path).readAsBytes();
              return path.endsWith('manifest.json') ? bytes : [...bytes, 32];
            },
          ),
          throwsFormatException,
        );
        final other = basis == FsDiv.separate
            ? FsDiv.consolidated
            : FsDiv.separate;
        expect(ExactCurrentRowProfiles.find(entry.receipt, other), null);
        await expectLater(
          ExactStatementRows.prepare(f, fixture.company(entry), other),
          throwsFormatException,
        );
      },
    );
  }
  test(
    'original excluded coordinates retain exact source proof without repair',
    () async {
      final excluded = jsonDecode(
        File(
          'test/fixtures/exact_statement_rows/next-current-row-exclusions.json',
        ).readAsStringSync(),
      ) as List;
      for (final proof in excluded.cast<Map>()) {
        final basis = FsDiv.values.singleWhere((b) => b.name == proof['basis']);
        expect(
          ExactStatementRows.eligible(proof['receipt'] as String, basis),
          false,
        );
        final entry = VerifiedAnnualSourceRegistry.find(
          proof['receipt'] as String,
          basis,
        )!;
        final manifest = jsonDecode(
          File('${entry.assetDirectory}/manifest.json').readAsStringSync(),
        ) as Map;
        final source = (manifest['sources'] as List).cast<Map>().singleWhere(
          (s) => s['url'] == proof['URI'],
        );
        final bytes = await File('${entry.assetDirectory}/${source['file']}')
            .readAsBytes();
        expect(sha256.convert(bytes).toString(), proof['SHA256']);
        expect(proof['fullStatementCollected'], false);
        if (proof['receipt'] == '20260323001088') {
          expect(((proof['proof'] as List).first as Map)['raw'], '(주석18)');
          expect(
            () => ExactStatementRows.parsePrintedMonetaryCell('(주석18)'),
            throwsFormatException,
          );
          expect(proof['subtotalResidualExcludingInvalidCell'], '333333');
        }
        if (proof['receipt'] == '20250321001653')
          expect(
            proof['printedCfCapitalIncreaseVersusCeIncreaseResidual'],
            '4000',
          );
      }
      for (final receipt in ['20220330000851', '20240318000135']) {
        for (final basis in FsDiv.values) {
          expect(ExactStatementRows.eligible(receipt, basis), false);
        }
      }
    },
  );
}
