import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_half_basis_absence.dart';

String fixture(String n) =>
    File('test/fixtures/financial_html/duksan-half-cfs-absence/$n.html')
        .readAsStringSync();
Future<VerifiedHalfBasisAbsence> actual({
  String? body,
  String? cover,
  String? shell,
  String corp = '00960623',
  Future<bool> Function()? cancelled,
  void Function(int)? onGet,
}) {
  var count = 0;
  return VerifiedHalfBasisAbsence.fetch(
    MockClient((r) async {
      onGet?.call(++count);
      final n = r.url.path == '/dsaf001/main.do'
          ? 'shell'
          : r.url.queryParameters['eleId'] == '1'
          ? 'cover'
          : 'cfs';
      return http.Response.bytes(
        utf8.encode(
          n == 'shell'
              ? shell ?? fixture(n)
              : n == 'cover'
              ? cover ?? fixture(n)
              : body ?? fixture(n),
        ),
        200,
        request: r,
      );
    }),
    targetReceipt: '20260813000889',
    targetCorpCode: corp,
    companyName: '덕산넵코어스(주)',
    cancelled: cancelled ?? () => Future.value(false),
    interval: Duration.zero,
  );
}

void main() {
  test('actual half CFS literal has bound cover period and independent body SHA with no amounts', () async {
    final p = await actual();
    expect(p.cover.periodStart, DateTime.utc(2026));
    expect(p.cover.periodEnd, DateTime.utc(2026, 6, 30));
    expect(p.statementSha256, VerifiedHalfBasisAbsence.bodySha);
    expect(p.statementSource.queryParameters['eleId'], '19');
  });
  test('wrong corporation blocks all requests', () async {
    var count = 0;
    await expectLater(
      actual(corp: '00000001', onGet: (_) => count++),
      throwsFormatException,
    );
    expect(count, 0);
  });
  test('wrong shell corporation rejects', () async {
    await expectLater(
      actual(shell: fixture('shell').replaceAll('00960623', '00000001')),
      throwsFormatException,
    );
  });
  test('wrong explicit half cover period rejects', () async {
    await expectLater(
      actual(cover: fixture('cover').replaceAll('2026년', '2025년')),
      throwsFormatException,
    );
  });
  test('CFS node cannot be relabeled from OFS', () async {
    await expectLater(
      actual(shell: fixture('shell').replaceAll('2. 연결재무제표', '4. 재무제표')),
      throwsFormatException,
    );
  });
  for (final extra in [
    '<TABLE><TR><TD>10</TD></TR></TABLE>',
    '<SCRIPT>1</SCRIPT>',
    '<P>단, 연결대상 종속회사가 있습니다.</P>',
  ]) {
    test('literal plus contradictory content rejects $extra', () async {
      await expectLater(
        actual(body: fixture('cfs').replaceFirst('</BODY>', '$extra</BODY>')),
        throwsFormatException,
      );
    });
  }
  test('cancel before first GET makes zero requests', () async {
    var count = 0;
    await expectLater(
      actual(cancelled: () => Future.value(true), onGet: (_) => count++),
      throwsA(isA<VerifiedHalfBasisCancelled>()),
    );
    expect(count, 0);
  });
  test('cancel after shell stops cover and CFS requests', () async {
    var count = 0;
    await expectLater(
      actual(cancelled: () => Future.value(count > 0), onGet: (_) => count++),
      throwsA(isA<VerifiedHalfBasisCancelled>()),
    );
    expect(count, 1);
  });
}
