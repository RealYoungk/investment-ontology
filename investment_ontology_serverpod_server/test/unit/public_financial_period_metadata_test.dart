import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_period_metadata.dart';

void main() {
  final shell = File('test/fixtures/financial_period_metadata/shell.html')
      .readAsStringSync();
  final cover = File('test/fixtures/financial_period_metadata/cover.html')
      .readAsStringSync();
  Future<PublicFinancialPeriodMetadata> fetch({
    String? shellOverride,
    String? coverOverride,
    String corp = '01036446',
    String target = '20260318001250',
    DateTime? end,
  }) => PublicFinancialPeriodMetadata.fetch(
    MockClient(
      (r) async => http.Response(
        r.url.path.contains('viewer')
            ? coverOverride ?? cover
            : shellOverride ?? shell,
        200,
        request: r,
        headers: {'content-type': 'text/html; charset=utf-8'},
      ),
    ),
    receipt: '20260318001250',
    corpCode: corp,
    companyName: '옛회사명과다른현재이름',
    targetReceipt: target,
    periodEnd: end ?? DateTime.utc(2025, 12, 31),
    interval: Duration.zero,
  );
  test('actual official shell and cover bind annual source period independently of current company name', () async {
    final metadata = await fetch();
    expect(metadata.periodStart, DateTime.utc(2025, 1, 1));
    expect(metadata.periodEnd, DateTime.utc(2025, 12, 31));
    expect(metadata.coverSource.queryParameters['rcpNo'], '20260318001250');
    expect(metadata.digest, matches(r'^[a-f0-9]{64}$'));
  });
  test(
    'wrong corporate identifier rejects without trusting printed company name',
    () async {
      await expectLater(fetch(corp: '00000001'), throwsFormatException);
    },
  );
  test(
    'same-year other closing month is a distinct source period mismatch',
    () async {
      await expectLater(
        fetch(end: DateTime.utc(2025, 6, 30)),
        throwsA(isA<PublicFinancialMetadataPeriodMismatch>()),
      );
    },
  );
  test('malformed empty shell and ambiguous cover are not validated period mismatch', () async {
    await expectLater(
      fetch(shellOverride: 'error'),
      throwsA(
        isA<FormatException>().having(
          (e) => e is PublicFinancialMetadataPeriodMismatch,
          'actual mismatch',
          false,
        ),
      ),
    );
    await expectLater(
      fetch(coverOverride: '$cover$cover'),
      throwsFormatException,
    );
  });
  test(
    'explicit bound original option permits period-only verification',
    () async {
      final targetShell = File(
        'test/fixtures/financial_period_metadata/target-shell.html',
      ).readAsStringSync();
      final result = await PublicFinancialPeriodMetadata.fetch(
        MockClient(
          (r) async => http.Response(
            r.url.path.contains('viewer')
                ? cover
                : r.url.queryParameters['rcpNo'] == '20260319000602'
                ? targetShell
                : shell,
            200,
            request: r,
            headers: {'content-type': 'text/html; charset=utf-8'},
          ),
        ),
        receipt: '20260318001250',
        targetReceipt: '20260319000602',
        corpCode: '01036446',
        companyName: '서연이화',
        periodEnd: DateTime.utc(2025, 12, 31),
        interval: Duration.zero,
      );
      expect(result.receipt, '20260318001250');
    },
  );
  test('actual half-year cover and linked target bind the original six-month reporting period', () async {
    final halfShell = File(
      'test/fixtures/financial_period_metadata/half-shell.html',
    ).readAsStringSync();
    final halfCover = File(
      'test/fixtures/financial_period_metadata/half-cover.html',
    ).readAsStringSync();
    final halfTarget = File(
      'test/fixtures/financial_period_metadata/half-target-shell.html',
    ).readAsStringSync();
    Future<PublicFinancialPeriodMetadata> run(bool halfYear) =>
        PublicFinancialPeriodMetadata.fetch(
          MockClient(
            (r) async => http.Response(
              r.url.path.contains('viewer')
                  ? halfCover
                  : r.url.queryParameters['rcpNo'] == '20260814003889'
                  ? halfTarget
                  : halfShell,
              200,
              request: r,
              headers: {'content-type': 'text/html; charset=utf-8'},
            ),
          ),
          receipt: '20260814002623',
          targetReceipt: '20260814003889',
          corpCode: '00123772',
          companyName: '부국증권',
          periodEnd: DateTime.utc(2026, 6, 30),
          halfYear: halfYear,
          interval: Duration.zero,
        );
    final result = await run(true);
    expect(result.periodStart, DateTime.utc(2026, 1, 1));
    expect(result.periodEnd, DateTime.utc(2026, 6, 30));
    await expectLater(run(false), throwsFormatException);
  });
  test(
    'unlinked target correction cannot adopt a same-month original',
    () async {
      await expectLater(fetch(target: '20260319000602'), throwsFormatException);
    },
  );
}
