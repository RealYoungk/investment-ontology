import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_period_provenance.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_period_metadata.dart';

const originalReceipt = '20260317000808';
const targetReceipt = '20260318000344';
const fixtureDir = 'test/fixtures/financial_period_metadata_suntech2025';
Future<PublicFinancialPeriodMetadata> actualMetadata({
  String? target,
  String? changedShell,
  String? changedCover,
  String? changedTarget,
}) async {
  final shell =
      changedShell ?? File('$fixtureDir/shell.html').readAsStringSync();
  final cover =
      changedCover ?? File('$fixtureDir/cover.html').readAsStringSync();
  final targetShell =
      changedTarget ?? File('$fixtureDir/target-shell.html').readAsStringSync();
  final client = MockClient((r) async {
    final body = r.url.path == '/report/viewer.do'
        ? cover
        : r.url.queryParameters['rcpNo'] == targetReceipt
        ? targetShell
        : shell;
    return http.Response.bytes(utf8.encode(body), 200, request: r);
  });
  try {
    return await PublicFinancialPeriodMetadata.fetch(
      client,
      receipt: originalReceipt,
      corpCode: '00963000',
      companyName: '(주)썬테크',
      targetReceipt: target ?? targetReceipt,
      periodEnd: DateTime.utc(2025, 12, 31),
      interval: Duration.zero,
    );
  } finally {
    client.close();
  }
}

void main() {
  test('metadata progress is exact scope-bound tuple, with retained retry class and time', () {
    final at = DateTime.utc(2026, 10, 3, 15, 10);
    final p = MetadataProgress(
      'scope-A',
      8,
      '20260317000808',
      false,
      true,
      transient: true,
      retryAt: at,
    );
    final decoded = MetadataProgress.read(
      'human explanation${p.suffix}',
      'scope-A',
    )!;
    expect(decoded.after(8, '20260317000809'), true);
    expect(decoded.after(8, '20260317000808'), false);
    expect(decoded.after(7, '20260318000344'), false);
    expect(decoded.after(9, '20200101000000'), true);
    expect(decoded.transient, true);
    expect(decoded.retryAt, at);
    expect(MetadataProgress.read(p.suffix, 'scope-B'), isNull);
    expect(
      MetadataProgress.read(
        '${MetadataProgress.marker}scope-A:invalid',
        'scope-A',
      ),
      isNull,
    );
  });

  final original = DartFiling(
    rceptNo: originalReceipt,
    corpCode: '00963000',
    companyId: 1,
    reportName: '사업보고서 (2025.12)',
    bsnsYear: 2025,
    reportCode: FinancialReportCode.annual,
    discoveredAt: DateTime.utc(2026),
    consolidatedStatus: FilingFetchStatus.stored,
    separateStatus: FilingFetchStatus.stored,
  );
  final target = original.copyWith(
    rceptNo: targetReceipt,
    reportName: '[첨부정정]사업보고서 (2025.12)',
  );
  test('exact existing original ownership and closing period preserve native ledger metadata', () {
    expect(FinancialPeriodProvenance.originalMatches(original, target), true);
    for (final bad in [
      original.copyWith(companyId: 2),
      original.copyWith(corpCode: '00000001'),
      original.copyWith(bsnsYear: 2024),
      original.copyWith(reportCode: FinancialReportCode.halfYear),
      original.copyWith(reportName: '사업보고서 (2025.06)'),
    ]) {
      expect(FinancialPeriodProvenance.originalMatches(bad, target), false);
    }
  });
  test('stored HTML and XBRL URI must bind own source receipt', () {
    expect(
      FinancialPeriodProvenance.sourceUriMatches(
        'https://dart.fss.or.kr/report/viewer.do?rcpNo=$originalReceipt',
        originalReceipt,
      ),
      true,
    );
    expect(
      FinancialPeriodProvenance.sourceUriMatches(
        'https://dart.fss.or.kr/pdf/download/ifrs.do?rcp_no=$originalReceipt',
        originalReceipt,
      ),
      true,
    );
    for (final url in [
      null,
      'http://dart.fss.or.kr/report/viewer.do?rcpNo=$originalReceipt',
      'https://evil.example/report/viewer.do?rcpNo=$originalReceipt',
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=$targetReceipt',
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=$originalReceipt&rcpNo=$originalReceipt',
    ]) {
      expect(
        FinancialPeriodProvenance.sourceUriMatches(url, originalReceipt),
        false,
      );
    }
  });
  test('real Sun original and correction family yield exact annual cover dates and compound digest', () async {
    final md = await actualMetadata();
    expect(md.periodStart, DateTime.utc(2025));
    expect(md.periodEnd, DateTime.utc(2025, 12, 31));
    expect(
      md.digest,
      'ae7a3929f5d453d3446b7731e93983bb34cbbc4798f9d169e138690e79c0bcde',
    );
    expect((await actualMetadata(target: originalReceipt)).digest, md.digest);
  });
  test('foreign own shell or missing target family or changed current period rejects', () async {
    final shell = File('$fixtureDir/shell.html').readAsStringSync();
    final cover = File('$fixtureDir/cover.html').readAsStringSync();
    final target = File('$fixtureDir/target-shell.html').readAsStringSync();
    await expectLater(
      actualMetadata(changedShell: shell.replaceAll('00963000', '00000001')),
      throwsFormatException,
    );
    await expectLater(
      actualMetadata(
        changedTarget: target.replaceAll(
          'rcpNo=$originalReceipt',
          'rcpNo=20260317000000',
        ),
      ),
      throwsFormatException,
    );
    await expectLater(
      actualMetadata(
        changedCover: cover.replaceAll('2025년 12월 31일', '2025년 06월 30일'),
      ),
      throwsA(isA<PublicFinancialMetadataPeriodMismatch>()),
    );
  });
}
