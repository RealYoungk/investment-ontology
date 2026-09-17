import 'dart:io';

import 'package:test/test.dart';

/// `serverpod start`의 생성기가 반쯤 바뀐 파일로 돌면 엔드포인트·FutureCall 생성 코드가
/// 통째로 빠진 채 남을 수 있다. 소스에 있는 클래스가 생성 코드에 모두 있는지 확인한다.
void main() {
  final sources = Directory('lib/src')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('generated'))
      .map((f) => f.readAsStringSync())
      .join('\n');

  String lowerFirst(String s) => s[0].toLowerCase() + s.substring(1);

  test('모든 Endpoint가 서버·클라이언트 생성 코드에 있다', () {
    final endpoints = File(
      'lib/src/generated/endpoints.dart',
    ).readAsStringSync();
    final client = File(
      '../investment_ontology_serverpod_client/lib/src/protocol/client.dart',
    ).readAsStringSync();
    final names = [
      for (final m in RegExp(
        r'class (\w+)Endpoint extends Endpoint',
      ).allMatches(sources))
        m.group(1)!,
    ];
    expect(names, containsAll(['Company', 'Ingest', 'Financial', 'Market']));
    for (final name in names) {
      expect(
        endpoints,
        contains("connectors['${lowerFirst(name)}']"),
        reason: name,
      );
      expect(client, contains('class Endpoint$name '), reason: name);
    }
  });

  test('모든 FutureCall이 생성 코드에 등록되어 있다', () {
    final futureCalls = File(
      'lib/src/generated/future_calls.dart',
    ).readAsStringSync();
    final names = [
      for (final m in RegExp(
        r'class (\w+)FutureCall extends FutureCall',
      ).allMatches(sources))
        m.group(1)!,
    ];
    expect(
      names,
      containsAll(['CompanyMaster', 'FinancialFacts', 'MarketSnapshot']),
    );
    for (final name in names) {
      expect(futureCalls, contains("'${name}RunFutureCall'"), reason: name);
    }
  });
}
