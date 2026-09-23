import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/data_go_kr/data_go_kr_client.dart';
import 'package:test/test.dart';

void main() {
  test(
    'DART network failures preserve the diagnosis without the key',
    () async {
      const key = 'test-dart-secret';
      final client = DartClient(
        key,
        httpClient: MockClient((request) async {
          throw http.ClientException('Failed host lookup', request.url);
        }),
      );
      addTearDown(client.close);
      await expectLater(
        client.fetchCompany('00126380'),
        throwsA(
          isA<DartApiException>()
              .having(
                (e) => e.toString(),
                'diagnosis',
                contains('Failed host lookup'),
              )
              .having((e) => e.toString(), 'secret', isNot(contains(key)))
              .having((e) => e.toString(), 'company', contains('00126380')),
        ),
      );
    },
  );

  test('market network failures remove URI-encoded and raw keys', () async {
    const key = 'test/market+key==';
    final client = DataGoKrClient(
      key,
      httpClient: MockClient((request) async {
        throw http.ClientException('Failed host lookup $key', request.url);
      }),
    );
    addTearDown(client.close);
    await expectLater(
      client.fetchStockPrices(DateTime.utc(2026, 9, 22)),
      throwsA(
        isA<DataGoKrApiException>()
            .having(
              (e) => e.toString(),
              'diagnosis',
              contains('Failed host lookup'),
            )
            .having((e) => e.toString(), 'raw secret', isNot(contains(key)))
            .having(
              (e) => e.toString(),
              'encoded secret',
              isNot(contains(Uri.encodeQueryComponent(key))),
            )
            .having((e) => e.toString(), 'date', contains('20260922')),
      ),
    );
  });
}
