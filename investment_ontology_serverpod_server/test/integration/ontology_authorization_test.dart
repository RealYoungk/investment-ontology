import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

/// 로그인 = 공용 데이터 읽기, 관리자 = 쓰기.
///
/// ingest · ai 엔드포인트는 이 파일에서 다루지 않는다 (따로 권한을 붙인다).
void main() {
  withServerpod('Given 온톨로지 엔드포인트 권한', (builder, endpoints) {
    final anonymous = builder.asAnonymous;
    final reader = builder.asReader;
    final admin = builder.asAdmin;

    group('when 로그인하지 않고 부르면', () {
      final calls = <String, Future<Object?> Function()>{
        'company.overview': () => endpoints.company.overview(anonymous),
        'financial.report': () => endpoints.financial.report(anonymous, 1),
        'market.industryTreemap': () =>
            endpoints.market.industryTreemap(anonymous),
        'screen.list': () => endpoints.screen.list(anonymous),
        'graph.neighborhood': () =>
            endpoints.graph.neighborhood(anonymous, '00000001'),
        'group.list': () => endpoints.group.list(anonymous),
        'disclosure.sections': () =>
            endpoints.disclosure.sections(anonymous, '00000001'),
        'governance.searchPersons': () =>
            endpoints.governance.searchPersons(anonymous, '홍길동'),
        'theme.list': () => endpoints.theme.list(anonymous),
        'theme.create': () => endpoints.theme.create(anonymous, '거부'),
        'review.checks': () => endpoints.review.checks(anonymous),
        'review.decide': () => endpoints.review.decide(anonymous, 1, true),
      };
      for (final MapEntry(key: name, value: call) in calls.entries) {
        test('then $name은 인증 필요로 거절된다', () async {
          await expectLater(
            call(),
            throwsA(isA<ServerpodUnauthenticatedException>()),
          );
        });
      }
    });

    group('when 관리자 아닌 로그인 사용자가', () {
      test('then 공용 데이터와 실측 정확도를 읽는다', () async {
        final overview = await endpoints.company.overview(reader);
        expect(overview.totalListed, 0);
        expect(await endpoints.theme.list(reader), isEmpty);
        expect(await endpoints.review.checks(reader), isEmpty);
        expect(
          await endpoints.governance.searchPersons(reader, '홍길동'),
          isEmpty,
        );
      });

      test('then 테마를 바꾸려 하면 권한 부족으로 거절되고 남는 것이 없다', () async {
        await expectLater(
          endpoints.theme.create(reader, '2차전지'),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
        await expectLater(
          endpoints.theme.delete(reader, 1),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
        await expectLater(
          endpoints.theme.addCompany(reader, 1, '00000001'),
          throwsA(isA<ServerpodInsufficientAccessException>()),
        );
        expect(await InvestmentTheme.db.count(builder.build()), 0);
      });

      test('then 검수 결정·기록과 인물 연결 끊기도 거절된다', () async {
        final denied = <Future<Object?> Function()>[
          () => endpoints.review.decide(reader, 1, true),
          () => endpoints.review.decideMany(reader, [1], true),
          () => endpoints.review.decideFact(reader, 1, true),
          () => endpoints.review.decideFactsMany(reader, [1], true),
          () => endpoints.review.recommend(
            reader,
            'fact',
            [1],
            RelationStatus.verified,
            '메모',
          ),
          () => endpoints.review.applyRecommended(reader, 'fact'),
          () => endpoints.review.recordCheck(reader, 'fact', 1, 1, 0, 'test'),
          () => endpoints.governance.rejectPersonLink(
            reader,
            '00000001',
            '홍길동',
          ),
        ];
        for (final call in denied) {
          await expectLater(
            call(),
            throwsA(isA<ServerpodInsufficientAccessException>()),
          );
        }
        expect(await ReviewCheck.db.count(builder.build()), 0);
      });
    });

    group('when 관리자가', () {
      test('then 테마를 만들고 검수 기록을 남긴다', () async {
        final theme = await endpoints.theme.create(admin, '2차전지');
        expect(theme.id, isNotNull);
        expect(
          [for (final t in await endpoints.theme.list(reader)) t.theme.name],
          ['2차전지'],
        );
        final check = await endpoints.review.recordCheck(
          admin,
          'fact',
          10,
          9,
          1,
          'test',
        );
        expect(check.correct, 9);
      });
    });
  });
}
