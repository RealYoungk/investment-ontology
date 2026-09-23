import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Research publishing', (builder, endpoints) {
    final admin = builder.asAdmin;
    final guest = builder.asAnonymous;
    final reader = builder.asReader;
    Future<ResearchEntry> save(
      int version, {
      String body = '## 투자 관점\n매출과 현금흐름을 확인합니다.',
    }) => endpoints.research.save(
      admin,
      'sample',
      '기업 리포트',
      '현금흐름은 회복되고 있을까?',
      '005930',
      'KOSPI',
      body,
      'markdown',
      DateTime.utc(2026, 9, 23),
      version,
      '근거 추가',
    );
    test(
      'drafts stay private; edits never change the published edition',
      () async {
        final draft = await save(0);
        expect(draft.revision.content, startsWith('## 투자 관점'));
        expect(draft.revision.dataAsOf, DateTime.utc(2026, 9, 23));
        expect(
          await endpoints.research.get(
            guest,
            'sample',
            draft: false,
            source: false,
          ),
          isNull,
        );
        expect(
          await endpoints.research.list(
            guest,
            query: '',
            market: '',
            manage: false,
            savedOnly: false,
            offset: 0,
          ),
          isEmpty,
        );
        await endpoints.research.publish(admin, 'sample', 1, withdraw: false);
        await save(1, body: '아직 공개하지 않은 비밀 초안');
        final public = await endpoints.research.get(
          guest,
          'sample',
          draft: false,
          source: false,
        );
        expect(public!.revision.version, 1);
        expect(public.revision.content, isNot(contains('비밀')));
        expect(
          await endpoints.research.list(
            guest,
            query: '비밀',
            market: '',
            manage: false,
            savedOnly: false,
            offset: 0,
          ),
          isEmpty,
        );
        expect(
          (await endpoints.research.get(
            admin,
            'sample',
            draft: true,
            source: false,
          ))!.revision.version,
          2,
        );
      },
    );
    test(
      'non-admin cannot read source, history or change publications',
      () async {
        await save(0);
        for (final call in <Future<Object?> Function()>[
          () => endpoints.research.get(
            reader,
            'sample',
            draft: true,
            source: false,
          ),
          () => endpoints.research.get(
            reader,
            'sample',
            source: true,
            draft: false,
          ),
          () => endpoints.research.get(
            reader,
            'sample',
            version: 1,
            draft: false,
            source: false,
          ),
          () => endpoints.research.list(
            reader,
            manage: true,
            query: '',
            market: '',
            savedOnly: false,
            offset: 0,
          ),
          () => endpoints.research.history(reader, 'sample'),
          () =>
              endpoints.research.publish(reader, 'sample', 1, withdraw: false),
          () => endpoints.research.importLegacy(reader),
          () => endpoints.research.save(
            reader,
            'sample',
            'no',
            'no',
            '005930',
            'KOSPI',
            'no',
            'markdown',
            DateTime.utc(2026),
            1,
            '',
          ),
        ]) {
          await expectLater(
            call(),
            throwsA(isA<ServerpodInsufficientAccessException>()),
          );
        }
      },
    );
    test(
      'legacy import is repeatable without creating duplicate editions',
      () async {
        final count = await endpoints.research.importLegacy(admin);
        expect(count, greaterThan(0));
        expect(await endpoints.research.importLegacy(admin), 0);
        final entry = await endpoints.research.get(
          guest,
          '012450',
          draft: false,
          source: false,
        );
        expect(entry!.revision.legacy, isTrue);
        expect(entry.revision.content, contains('report-paragraph'));
        expect(entry.revision.dataAsOf, DateTime.utc(2026, 7, 20));
      },
    );
    test('stale edits and stale publication are rejected', () async {
      await save(0);
      await save(1);
      await expectLater(save(1), throwsA(isA<IngestException>()));
      await expectLater(
        endpoints.research.publish(admin, 'sample', 1, withdraw: false),
        throwsA(isA<IngestException>()),
      );
      expect((await endpoints.research.history(admin, 'sample')).length, 2);
    });
    test(
      'withdraw keeps editions; previous source can be restored as a new draft',
      () async {
        await save(0);
        await endpoints.research.publish(admin, 'sample', 1, withdraw: false);
        final old = (await endpoints.research.get(
          admin,
          'sample',
          version: 1,
          source: true,
          draft: false,
        ))!;
        await save(1, body: '새 내용');
        await save(2, body: old.revision.content);
        await endpoints.research.publish(admin, 'sample', 3, withdraw: false);
        expect(
          (await endpoints.research.get(
            guest,
            'sample',
            draft: false,
            source: false,
          ))!.revision.content,
          contains('현금흐름'),
        );
        await endpoints.research.publish(admin, 'sample', 3, withdraw: true);
        expect(
          await endpoints.research.get(
            guest,
            'sample',
            draft: false,
            source: false,
          ),
          isNull,
        );
        expect((await endpoints.research.history(admin, 'sample')).length, 3);
      },
    );
    test('public history contains only published editions and withdrawal hides all', () async {
      await save(0);
      await endpoints.research.publish(admin, 'sample', 1, withdraw: false);
      await save(1, body: '두 번째 발행본');
      await endpoints.research.publish(admin, 'sample', 2, withdraw: false);
      await save(2, body: '미발행 내용');
      final editions = await endpoints.research.editions(guest, 'sample');
      expect(editions.map((r) => r.version), [2, 1]);
      expect(editions.every((r) => r.content.isEmpty), isTrue);
      expect(
        (await endpoints.research.get(
          guest,
          'sample',
          draft: false,
          source: false,
          version: 1,
        ))!.revision.content,
        contains('현금흐름'),
      );
      await expectLater(
        endpoints.research.get(
          guest,
          'sample',
          draft: false,
          source: false,
          version: 3,
        ),
        throwsA(isA<ServerpodInsufficientAccessException>()),
      );
      await endpoints.research.publish(admin, 'sample', 3, withdraw: true);
      expect(await endpoints.research.editions(guest, 'sample'), isEmpty);
      await expectLater(
        endpoints.research.get(
          guest,
          'sample',
          draft: false,
          source: false,
          version: 1,
        ),
        throwsA(isA<ServerpodInsufficientAccessException>()),
      );
    });

    test(
      'saved articles belong only to their user; guest cannot save',
      () async {
        await save(0);
        await endpoints.research.publish(admin, 'sample', 1, withdraw: false);
        await expectLater(
          endpoints.research.bookmark(guest, 'sample', true),
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
        await endpoints.research.bookmark(reader, 'sample', true);
        await endpoints.research.bookmark(reader, 'sample', true);
        expect(
          (await endpoints.research.list(
            reader,
            savedOnly: true,
            query: '',
            market: '',
            manage: false,
            offset: 0,
          )).length,
          1,
        );
        expect(
          await endpoints.research.list(
            admin,
            savedOnly: true,
            query: '',
            market: '',
            manage: false,
            offset: 0,
          ),
          isEmpty,
        );
        await endpoints.research.bookmark(reader, 'sample', false);
        expect(
          await endpoints.research.list(
            reader,
            savedOnly: true,
            query: '',
            market: '',
            manage: false,
            offset: 0,
          ),
          isEmpty,
        );
      },
    );
  });
}
