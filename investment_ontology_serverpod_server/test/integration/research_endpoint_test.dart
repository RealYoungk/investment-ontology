import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Research source and access rules', (builder, endpoints) {
    test('public missing/empty; admin import; rejected writes; reverted observation', () async {
      final session = builder.build();
      addTearDown(session.close);
      await Company.db.insertRow(
        session,
        Company(corpCode: '00999991', name: 'test', market: Market.kosdaq),
      );
      final empty = jsonDecode(
        await endpoints.research.data(
          builder.asAnonymous,
          '00999991',
          'capital',
        ),
      );
      expect(empty['state'], 'notCollected');
      await expectLater(
        endpoints.research.collect(builder.asReader, '00999991', 'capital'),
        throwsA(anything),
      );
      await expectLater(
        endpoints.research.collectBatch(
          builder.asAnonymous,
          'capital',
          afterCorpCode: '',
          limit: 3,
        ),
        throwsA(anything),
      );
      String payload(String n) => jsonEncode([
        {
          'date': '2025-01-01',
          'reporter': 'holder',
          'receipt': '20250101000001',
          'holdings': n,
          'change': '0',
        },
      ]);
      Future<int> write(String p) => endpoints.research.importFeed(
        builder.asAdmin,
        '00999991',
        'insiders',
        p,
        'Fixture',
        'https://dart.fss.or.kr',
        'isolated test',
      );
      final first = await write(payload('100'));
      expect(await write(payload('100')), first);
      final second = await write(payload('200'));
      expect(second, isNot(first));
      final third = await write(payload('100'));
      expect(third, isNot(first));
      final result = jsonDecode(
        await endpoints.research.data(
          builder.asAnonymous,
          '00999991',
          'insiders',
        ),
      );
      expect(result['rows'][0]['holdings'], '100');
      expect(result['source']['url'], 'https://dart.fss.or.kr');
      await write('[]');
      final none = jsonDecode(
        await endpoints.research.data(
          builder.asAnonymous,
          '00999991',
          'insiders',
        ),
      );
      expect(none['state'], 'ready');
      expect(none['rows'], isEmpty);
      await expectLater(
        endpoints.research.importFeed(
          builder.asReader,
          '00999991',
          'insiders',
          '[]',
          'x',
          'https://dart.fss.or.kr',
          'test',
        ),
        throwsA(anything),
      );
    });
  });
}
