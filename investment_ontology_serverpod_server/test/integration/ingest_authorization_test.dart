import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given ingest and AI authorization', (builder, endpoints) {
    final reader = builder.asReader;
    test('anonymous reads are rejected', () async {
      await expectLater(
        endpoints.ingest.latest(builder.asAnonymous),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
      await expectLater(
        endpoints.ai.status(builder.asAnonymous),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
    });
    test('collection status and AI operations are admin-only', () async {
      for (final call in <Future<Object?> Function()>[
        () => endpoints.ingest.latest(reader),
        () => endpoints.ingest.coverage(reader),
        () => endpoints.ingest.schedule(reader),
        () => endpoints.ai.status(reader),
      ]) {
        await expectLater(
          call(),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
      }
    });
    final mutations = <String, Future<Object?> Function()>{
      'master': () => endpoints.ingest.startCompanyMaster(reader),
      'financials': () => endpoints.ingest.startFinancials(reader),
      'disclosures': () => endpoints.ingest.startDisclosures(reader),
      'business bodies': () => endpoints.ingest.startBusinessDocuments(reader),
      'market': () => endpoints.ingest.startMarketSnapshot(reader),
      'cancel': () => endpoints.ingest.cancel(reader, 1),
      'rebuild links': () => endpoints.ingest.rebuildDisclosureLinks(reader),
      'rebuild facts': () => endpoints.ingest.rebuildProductionFacts(reader),
      'AI extract': () => endpoints.ai.extractCompany(reader, '00000001'),
      'AI batch': () => endpoints.ai.startBatch(reader),
      'AI submit': () => endpoints.ai.submit(reader, 1, '{}'),
      'AI digest': () => endpoints.ai.submitDigest(reader, 1, '{}'),
      'AI facts': () => endpoints.ai.submitFacts(reader, 1, '{}'),
    };
    for (final entry in mutations.entries) {
      test('reader denied ${entry.key} before API or DB work', () async {
        await expectLater(
          entry.value(),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
      });
    }
    test(
      'admin passes mutation authorization without triggering external calls',
      () async {
        expect(await endpoints.ingest.cancel(builder.asAdmin, -1), isNull);
      },
    );
  });
}
