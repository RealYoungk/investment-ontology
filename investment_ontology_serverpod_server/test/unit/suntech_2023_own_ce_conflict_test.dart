import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/known_annual_source_conflict.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  const dir = 'test/fixtures/financial_html/known-conflicts/20240320001438';
  final proof = jsonDecode(File('$dir/proof.json').readAsStringSync()) as Map;
  final cover = File('$dir/cover.html').readAsStringSync(),
      body = File('$dir/cfs.html').readAsStringSync();
  void verify({
    String? receipt,
    String? corp,
    bool cfs = true,
    int year = 2023,
    String? content,
    Uri? uri,
  }) => KnownAnnualSourceConflicts.verify(
    receipt: receipt ?? '20240320001438',
    corpCode: corp ?? '00963000',
    consolidated: cfs,
    start: DateTime.utc(year),
    end: DateTime.utc(year, 12, 31),
    coverSource: Uri.parse(proof['cover']['url']),
    statementSource: uri ?? Uri.parse(proof['cfs']['url']),
    coverHtml: cover,
    statementHtml: content ?? body,
  );
  test('actual own CE raw roll conflict is independently typed without assigning missing unit or correcting numbers', () {
    expect(
      () => verify(),
      throwsA(
        isA<KnownAnnualSourceConflict>()
            .having(
              (e) => e.evidence['rawWholeEquityRollDifference'],
              'raw residual',
              '-50000000',
            )
            .having((e) => e.evidence['ceUnitPrinted'], 'unit missing', false)
            .having(
              (e) => e.evidence['financialFactsStored'],
              'no stored facts',
              false,
            )
            .having(
              (e) => e.evidence['printedOwnPLAndCENIAndCFNIEqual'],
              'core NI itself exact',
              true,
            ),
      ),
    );
    expect(
      () => PublicFinancialHtml.parseStandardAnnual(
        coverHtml: cover,
        statementHtml: body,
        coverSource: Uri.parse(proof['cover']['url']),
        statementSource: Uri.parse(proof['cfs']['url']),
        receipt: '20240320001438',
        corpCode: '00963000',
        companyName: '(주)썬테크',
        periodStart: DateTime.utc(2023),
        periodEnd: DateTime.utc(2023, 12, 31),
        consolidated: true,
      ),
      throwsA(isA<KnownAnnualSourceConflict>()),
    );
  });
  for (final mutation in ['receipt', 'corp', 'basis', 'year', 'bytes', 'uri']) {
    test('own bounded conflict does not classify other $mutation source', () {
      expect(
        () => verify(
          receipt: mutation == 'receipt' ? '20250317000968' : null,
          corp: mutation == 'corp' ? '00000000' : null,
          cfs: mutation != 'basis',
          year: mutation == 'year' ? 2024 : 2023,
          content: mutation == 'bytes' ? '$body ' : null,
          uri: mutation == 'uri'
              ? Uri.parse('${proof['cfs']['url']}&extra=1')
              : null,
        ),
        returnsNormally,
      );
    });
  }
}
