import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_business_source_anchor.dart';

void main() {
  String raw(String f) =>
      File('test/fixtures/business_source_anchor/$f.html').readAsStringSync();
  Future<dynamic> verify({
    String? target,
    String? cover,
    String company = '(주)엔에스컴퍼니',
    String corp = '00929228',
  }) {
    final client = MockClient(
      (r) async => http.Response.bytes(
        utf8.encode(
          r.url.path == '/report/viewer.do'
              ? cover ?? raw('cover')
              : r.url.queryParameters['rcpNo'] == '20260324000715'
              ? target ?? raw('target')
              : raw('source'),
        ),
        200,
        request: r,
      ),
    );
    return PublicBusinessSourceAnchor.verify(
      client,
      targetReceipt: '20260324000715',
      sourceReceipt: '20260323000900',
      corpCode: corp,
      companyName: company,
      periodEnd: DateTime.utc(2025, 12, 31),
      halfYear: false,
      interval: Duration.zero,
    ).whenComplete(client.close);
  }

  test(
    'actual official correction links original exact company and cover period',
    () async {
      final result = await verify();
      expect(result.receipt, '20260323000900');
      expect(result.corpCode, '00929228');
      expect(result.periodStart, DateTime.utc(2025, 1, 1));
      expect(result.periodEnd, DateTime.utc(2025, 12, 31));
    },
  );
  test(
    'name mismatch is audited under exact official corporate identity',
    () async {
      final proof = await verify(company: '머니무브');
      expect(proof.coverNameMatches, false);
      expect(proof.observedCoverCompany, '(주)엔에스컴퍼니');
    },
  );
  test('foreign corporate identity rejects target family', () async {
    await expectLater(verify(corp: '00978075'), throwsFormatException);
  });
  test('newer same-kind family body rejects stale original', () async {
    final target = raw('target').replaceFirst(
      '</select>',
      '<option value="rcpNo=20260324000714">사업보고서</option></select>',
    );
    await expectLater(verify(target: target), throwsFormatException);
  });
  test('changed original cover closing month rejects', () async {
    await expectLater(
      verify(cover: raw('cover').replaceAll('12월 31일', '11월 30일')),
      throwsFormatException,
    );
  });
}
