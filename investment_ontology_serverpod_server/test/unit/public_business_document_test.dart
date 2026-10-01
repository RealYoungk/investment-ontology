import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_business_document.dart';

const receipt = '20260814004099';
const shell = '''node1['text'] = "II. 사업의 내용";
node1['rcpNo'] = "20260814004099";node1['dcmNo'] = "11539759";
node1['eleId'] = "5";node1['offset'] = "150";node1['length'] = "4000";node1['dtd'] = "dart3.xsd";cnt++;''';
final body =
    '<p>II. 사업의 내용</p><p>1. 사업의 개요</p><p>${'웨이퍼 주변에 장착되는 부품을 생산하여 공급합니다. ' * 5}</p><table><tr><th>제품</th><th>역할</th></tr><tr><td>Focus Ring</td><td>웨이퍼 &amp; 전극 보호</td></tr></table><p>III. 재무에 관한 사항</p><p>제외될 재무</p>';
void main() {
  test('actual BGF UTF-8 viewer preserves table and subsection structure', () {
    const path = 'test/unit/fixtures/public_business/';
    final actualShell = File('${path}bgf-shell.html').readAsStringSync();
    final actualBody = File('${path}bgf-body.html').readAsStringSync();
    final uri = PublicBusinessDocument.bodyUri('20260814002421', actualShell);
    final result = PublicBusinessDocument.parse(
      '20260814002421',
      uri,
      actualBody,
    );
    expect(result.text.length, greaterThan(10000));
    expect(result.text, contains(' | '));
    expect(result.text, contains('## 1. 사업의 개요'));
  });
  test(
    'receipt-bound actual body preserves normalized table and headings',
    () async {
      final calls = <Uri>[];
      final reader = PublicBusinessDocument(
        client: MockClient((request) async {
          calls.add(request.url);
          return http.Response(
            calls.length == 1 ? shell : body,
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }),
      );
      final result = await reader.fetch(receipt);
      expect(calls.length, 2);
      expect(result.text, contains('제품 | 역할'));
      expect(result.text, contains('Focus Ring | 웨이퍼 & 전극 보호'));
      expect(result.text, contains('## 1. 사업의 개요'));
      expect(result.text, isNot(contains('제외될 재무')));
      expect(result.bodySha256.length, 64);
    },
  );
  test('missing, duplicate and previous receipt shells rejected', () {
    for (final bad in [
      'viewer shell',
      shell + shell,
      shell.replaceAll(receipt, '20260814000001'),
    ]) {
      expect(
        () => PublicBusinessDocument.bodyUri(receipt, bad),
        throwsFormatException,
      );
    }
  });
  test('shell, untrusted host and replacement character rejected', () {
    final uri = PublicBusinessDocument.bodyUri(receipt, shell);
    expect(
      () => PublicBusinessDocument.parse(receipt, uri, shell),
      throwsFormatException,
    );
    expect(
      () => PublicBusinessDocument.parse(receipt, uri, '$body\uFFFD'),
      throwsFormatException,
    );
    expect(
      () => PublicBusinessDocument.parse(
        receipt,
        Uri.parse('https://example.com/report/viewer.do?rcpNo=$receipt'),
        body,
      ),
      throwsFormatException,
    );
  });
  test('invalid receipt makes no request', () async {
    final reader = PublicBusinessDocument(
      client: MockClient((_) async => throw StateError('must not request')),
    );
    await expectLater(reader.fetch('bad'), throwsFormatException);
  });
}
