import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_business_source_anchor.dart';

String familyFixture(String key, String name) =>
    File('test/fixtures/business_family_discovery/$key/$name.html')
        .readAsStringSync();
http.Client familyClient(
  String key,
  String target, {
  String? shell,
  String? cover,
}) => MockClient(
  (r) async => http.Response.bytes(
    utf8.encode(
      r.url.path == '/report/viewer.do'
          ? cover ?? familyFixture(key, 'cover')
          : r.url.queryParameters['rcpNo'] == target
          ? shell ?? familyFixture(key, 'target-shell')
          : familyFixture(key, 'shell'),
    ),
    200,
    request: r,
  ),
);
void main() {
  for (final e in [
    ('kbank', '20230331004542', '20230331004538', '01203312', '㈜케이뱅크'),
    ('tilon', '20230323001121', '20230323000812', '00976615', '주식회사 틸론'),
  ]) {
    test('actual family chooses latest verified source ${e.$1}', () async {
      final client = familyClient(e.$1, e.$2);
      try {
        final p = await PublicBusinessSourceAnchor.discover(
          client,
          targetReceipt: e.$2,
          corpCode: e.$4,
          companyName: e.$5,
          periodEnd: DateTime.utc(2022, 12, 31),
          halfYear: false,
          interval: Duration.zero,
        );
        expect(p.receipt, e.$3);
        expect(p.periodStart, DateTime.utc(2022));
        expect(p.periodEnd, DateTime.utc(2022, 12, 31));
      } finally {
        client.close();
      }
    });
  }
  test('wrong source corporation rejects', () async {
    final c = familyClient('kbank', '20230331004542');
    try {
      await expectLater(
        PublicBusinessSourceAnchor.discover(
          c,
          targetReceipt: '20230331004542',
          corpCode: '99999999',
          companyName: '㈜케이뱅크',
          periodEnd: DateTime.utc(2022, 12, 31),
          halfYear: false,
          interval: Duration.zero,
        ),
        throwsFormatException,
      );
    } finally {
      c.close();
    }
  });
  test('wrong requested closing period rejects', () async {
    final c = familyClient('kbank', '20230331004542');
    try {
      await expectLater(
        PublicBusinessSourceAnchor.discover(
          c,
          targetReceipt: '20230331004542',
          corpCode: '01203312',
          companyName: '㈜케이뱅크',
          periodEnd: DateTime.utc(2022, 6, 30),
          halfYear: false,
          interval: Duration.zero,
        ),
        throwsFormatException,
      );
    } finally {
      c.close();
    }
  });
}
