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
    test('re-import never replaces an administrator edit, even one that '
        'kept the imported note', () async {
      await endpoints.research.importLegacy(admin);
      final imported = (await endpoints.research.get(
        admin,
        '012450',
        draft: true,
        source: true,
      ))!;
      final note = imported.revision.note;
      expect(note, isNotEmpty);
      final edited = await endpoints.research.save(
        admin,
        '012450',
        imported.revision.title,
        imported.revision.summary,
        imported.revision.ticker,
        imported.revision.market,
        '${imported.revision.content}<p>관리자가 덧붙인 문단</p>',
        'html',
        imported.revision.dataAsOf,
        imported.article.latestVersion,
        note,
      );
      expect(edited.revision.legacy, isTrue);
      await endpoints.research.publish(
        admin,
        '012450',
        edited.article.latestVersion,
        withdraw: false,
      );
      expect(await endpoints.research.importLegacy(admin), 0);
      final public = (await endpoints.research.get(
        guest,
        '012450',
        draft: false,
        source: false,
      ))!;
      expect(public.revision.version, edited.article.latestVersion);
      expect(public.revision.content, contains('관리자가 덧붙인 문단'));
    });

    test(
      're-import still repairs the rendering of an untouched import',
      () async {
        await endpoints.research.importLegacy(admin);
        final session = builder.build();
        final article = (await ResearchArticle.db.findFirstRow(
          session,
          where: (t) => t.slug.equals('012450'),
        ))!;
        final revision = (await ResearchRevision.db.findFirstRow(
          session,
          where: (t) =>
              t.articleId.equals(article.id!) &
              t.version.equals(article.latestVersion),
        ))!;
        // As if an older renderer had produced this markup.
        await ResearchRevision.db.updateRow(
          session,
          revision.copyWith(content: '<div>이전 렌더링</div>'),
        );
        expect(await endpoints.research.importLegacy(admin), 1);
        final public = (await endpoints.research.get(
          guest,
          '012450',
          draft: false,
          source: false,
        ))!;
        expect(public.revision.version, article.latestVersion + 1);
        expect(public.revision.content, isNot(contains('이전 렌더링')));
        expect(await endpoints.research.importLegacy(admin), 0);
      },
    );

    test(
      'editor notes stay in administrator source and history only',
      () async {
        await save(0);
        await endpoints.research.publish(admin, 'sample', 1, withdraw: false);
        final public = await endpoints.research.get(
          guest,
          'sample',
          draft: false,
          source: false,
        );
        expect(public!.revision.note, isEmpty);
        expect(
          (await endpoints.research.editions(guest, 'sample')).single.note,
          isEmpty,
        );
        expect(
          (await endpoints.research.list(
            guest,
            query: '',
            market: '',
            manage: false,
            savedOnly: false,
            offset: 0,
          )).single.revision.note,
          isEmpty,
        );
        expect(
          (await endpoints.research.get(
            admin,
            'sample',
            draft: true,
            source: true,
          ))!.revision.note,
          '근거 추가',
        );
        expect(
          (await endpoints.research.history(admin, 'sample')).single.note,
          '근거 추가',
        );
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

    Future<void> publishArticle(
      String slug, {
      String title = '기업 리포트',
      String summary = '핵심 관점',
      String ticker = '005930',
      String market = 'KOSPI',
      String body = '## 본문\n내용',
      DateTime? date,
    }) async {
      await endpoints.research.save(
        admin,
        slug,
        title,
        summary,
        ticker,
        market,
        body,
        'markdown',
        date ?? DateTime.utc(2026, 9, 1),
        0,
        '',
      );
      await endpoints.research.publish(admin, slug, 1, withdraw: false);
    }

    Future<List<ResearchEntry>> list(
      TestSessionBuilder who, {
      String query = '',
      String market = '',
      bool manage = false,
      bool savedOnly = false,
      String? ticker,
      int offset = 0,
    }) => endpoints.research.list(
      who,
      query: query,
      market: market,
      manage: manage,
      savedOnly: savedOnly,
      ticker: ticker,
      offset: offset,
    );

    test(
      'list pages through every published article once, newest data first',
      () async {
        // Same date for most rows: the order must still be total, or offsets
        // repeat and skip articles between pages.
        for (var i = 0; i < 35; i++) {
          await publishArticle(
            'page-$i',
            date: DateTime.utc(2026, 9, i < 5 ? 10 + i : 1),
          );
        }
        final first = await list(guest);
        final second = await list(guest, offset: first.length);
        expect(first, hasLength(30));
        expect(second, hasLength(5));
        final slugs = [...first, ...second].map((e) => e.article.slug);
        expect(slugs.toSet(), hasLength(35));
        expect(slugs.take(5), [
          'page-4',
          'page-3',
          'page-2',
          'page-1',
          'page-0',
        ]);
        final dates = [...first, ...second].map((e) => e.revision.dataAsOf);
        for (var i = 1; i < dates.length; i++) {
          expect(dates.elementAt(i).isAfter(dates.elementAt(i - 1)), isFalse);
        }
        expect(first.first.revision.dataAsOf, DateTime.utc(2026, 9, 14));
        expect(first.first.revision.dataAsOf.isUtc, isTrue);
        // Bodies and search text never travel with the list.
        expect(
          first.every(
            (e) => e.revision.content.isEmpty && e.revision.searchText.isEmpty,
          ),
          isTrue,
        );
        expect(await list(guest, offset: -5), hasLength(30));
      },
    );

    test('search matches title, ticker, summary and body of the '
        'published edition only, case-insensitively and literally', () async {
      await publishArticle(
        'hbm',
        title: 'HBM 수요와 패키징',
        ticker: '000660',
        body: '## 근거\nTSV 공정 수율이 100% 가까이 올라온다.',
      );
      await publishArticle(
        'battery',
        title: '배터리 리포트',
        summary: '북미 ESS 수주',
        ticker: '373220',
        market: 'KOSPI',
      );
      await publishArticle(
        'kosdaq',
        title: '장비 리포트',
        ticker: '240810',
        market: 'KOSDAQ',
      );
      Future<List<String>> find(String q) async =>
          (await list(guest, query: q)).map((e) => e.article.slug).toList();
      expect(await find('hbm'), ['hbm']);
      expect(await find('  000660 '), ['hbm']);
      expect(await find('ess'), ['battery']);
      expect(await find('tsv 공정'), ['hbm']);
      expect(await find('100%'), ['hbm']);
      expect(await find('%'), ['hbm']);
      expect(await find('_'), isEmpty);
      expect(await find("'; DROP TABLE research_article; --"), isEmpty);
      expect(
        (await list(guest, market: 'KOSDAQ')).map((e) => e.article.slug),
        ['kosdaq'],
      );
      expect(
        (await list(guest, ticker: '373220')).map((e) => e.article.slug),
        ['battery'],
      );
      expect(
        await list(guest, ticker: '373220', market: 'KOSDAQ'),
        isEmpty,
      );
      // A private draft on top of a published article is invisible to search
      // but is what administrators manage.
      await endpoints.research.save(
        admin,
        'battery',
        '배터리 리포트',
        '북미 ESS 수주',
        '373220',
        'KOSPI',
        '## 초안\n비공개 수치 123',
        'markdown',
        DateTime.utc(2026, 9, 2),
        1,
        '수치 갱신',
      );
      expect(await find('비공개 수치'), isEmpty);
      expect(
        (await list(admin, query: '비공개 수치', manage: true)).map(
          (e) => e.revision.version,
        ),
        [2],
      );
      expect(
        (await list(reader, query: 'ess')).single.revision.version,
        1,
      );
    });

    test('an unpublished article appears only in the admin list', () async {
      await save(0);
      expect(await list(guest), isEmpty);
      expect(await list(reader), isEmpty);
      expect(await list(admin), isEmpty);
      expect((await list(admin, manage: true)).single.article.slug, 'sample');
      await expectLater(
        list(guest, savedOnly: true),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
      await expectLater(
        list(guest, manage: true),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
    });

    test('bookmarks of a withdrawn article stay hidden until republished; '
        'another reader cannot see or remove them', () async {
      final other = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          '00000000-0000-4000-8000-000000000003',
          {},
        ),
      );
      await save(0);
      await endpoints.research.publish(admin, 'sample', 1, withdraw: false);
      await endpoints.research.bookmark(reader, 'sample', true);
      await endpoints.research.bookmark(other, 'sample', false);
      expect((await list(reader, savedOnly: true)).single.saved, isTrue);
      expect((await list(other)).single.saved, isFalse);
      expect(
        (await endpoints.research.get(
          other,
          'sample',
          draft: false,
          source: false,
        ))!.saved,
        isFalse,
      );
      await endpoints.research.publish(admin, 'sample', 1, withdraw: true);
      expect(await list(reader, savedOnly: true), isEmpty);
      await expectLater(
        endpoints.research.bookmark(reader, 'sample', true),
        throwsA(isA<IngestException>()),
      );
      await endpoints.research.publish(admin, 'sample', 1, withdraw: false);
      expect((await list(reader, savedOnly: true)).single.saved, isTrue);
    });

    test(
      'invalid body format or oversized body is a message, not a crash',
      () async {
        for (final (body, format) in [
          ('본문', 'docx'),
          ('a' * 400001, 'markdown'),
        ]) {
          await expectLater(
            endpoints.research.save(
              admin,
              'sample',
              '기업 리포트',
              '핵심',
              '005930',
              'KOSPI',
              body,
              format,
              DateTime.utc(2026, 9, 23),
              0,
              '',
            ),
            throwsA(isA<IngestException>()),
          );
        }
        expect(await endpoints.research.history(admin, 'sample'), isEmpty);
      },
    );

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
