import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_flutter/features/investment_notes/investment_note_page.dart';
import 'package:investment_ontology_serverpod_flutter/features/investment_notes/investment_notes_page.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/app_auth.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/app_viewer.dart';

import '../support/shad_test_host.dart';
import 'home_page_test.dart' show theme;

Map<String, dynamic> note({bool locked = false}) => {
  'id': 1,
  'tier': 'watchlist',
  'title': '기술 검증과 투자 관점',
  'introduction': '무료 기업 소개',
  'corpCode': '00123456',
  'author': '알파인더',
  'publishedAt': '2026-10-05T00:00:00Z',
  'dataAsOf': '2026-10-05T00:00:00Z',
  'locked': locked,
  if (!locked)
    'sections': [
      {
        'heading': '핵심 근거',
        'text': '회원 전용 분석 SECRET',
        'sourceIds': ['p'],
      },
    ],
  if (!locked)
    'sources': [
      {
        'id': 'p',
        'title': '긴 논문 제목 ${List.filled(8, '네트워크 차별성').join(' ')}',
        'url': 'https://example.com/paper',
        'kind': 'paper',
      },
    ],
};
Future<void> pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    shadTestHost(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AppAuth.viewer.value = null);
  tearDown(() => AppAuth.viewer.value = null);
  testWidgets(
    'anonymous introduction and membership action render without member body',
    (tester) async {
      await pump(
        tester,
        InvestmentNotePage(
          articleId: 1,
          load: (_, _) async => note(locked: true),
        ),
      );
      expect(find.text('무료 기업 소개'), findsOneWidget);
      expect(find.textContaining('SECRET'), findsNothing);
      expect(find.text('멤버십 확인하기'), findsOneWidget);
      expect(find.text('이미 회원이라면 로그인'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'logout clears body immediately and stale member response cannot restore it',
    (tester) async {
      AppAuth.viewer.value = const AppViewer(
        userId: 'member',
        isAdmin: false,
        isAdFree: true,
      );
      final stale = Completer<Map<String, dynamic>?>();
      var calls = 0;
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: InvestmentNotePage(
                articleId: 1,
                load: (_, _) {
                  calls++;
                  return calls == 1
                      ? stale.future
                      : Future.value(note(locked: true));
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      AppAuth.viewer.value = null;
      await tester.pumpAndSettle();
      stale.complete(note());
      await tester.pumpAndSettle();
      expect(find.textContaining('SECRET'), findsNothing);
      expect(find.text('멤버십 확인하기'), findsOneWidget);
    },
  );
  testWidgets('account transition discards an already rendered member body', (
    tester,
  ) async {
    AppAuth.viewer.value = const AppViewer(
      userId: 'member',
      isAdmin: false,
      isAdFree: true,
    );
    await pump(
      tester,
      InvestmentNotePage(
        articleId: 1,
        load: (_, _) async => note(locked: AppAuth.viewer.value == null),
      ),
    );
    expect(find.textContaining('SECRET'), findsOneWidget);
    AppAuth.viewer.value = null;
    await tester.pump();
    expect(find.textContaining('SECRET'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('멤버십 확인하기'), findsOneWidget);
  });
  testWidgets(
    '320px member reading with long source titles has no layout exception',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(
        tester,
        InvestmentNotePage(articleId: 1, load: (_, _) async => note()),
      );
      expect(find.textContaining('SECRET'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('관심기업으로 모니터링'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'empty publication and failed request are distinct and retry works',
    (tester) async {
      var attempt = 0;
      await pump(
        tester,
        InvestmentNotesPage(
          load: (_, _) async {
            if (attempt++ == 0) throw StateError('failed');
            return [];
          },
        ),
      );
      expect(find.text('투자 관점을 불러오지 못했습니다.'), findsOneWidget);
      expect(find.text('아직 공개된 투자 관점이 없습니다.'), findsNothing);
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('아직 공개된 투자 관점이 없습니다.'), findsOneWidget);
    },
  );
  testWidgets(
    'follow-up opens prior article and list back retains current position',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/insights/2',
        routes: [
          GoRoute(
            path: '/insights/:id',
            builder: (_, state) => InvestmentNotePage(
              articleId: int.parse(state.pathParameters['id']!),
              load: (id, _) async => {
                ...note(),
                'id': id,
                'title': id == 2 ? '후속 관점' : '원글',
                if (id == 2) 'previousArticleId': 1,
              },
            ),
          ),
          GoRoute(path: '/insights', builder: (_, _) => const Text('목록')),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        shadTestHost(MaterialApp.router(theme: theme, routerConfig: router)),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('이전 투자 관점 읽기'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('이전 투자 관점 읽기'));
      await tester.pumpAndSettle();
      expect(find.text('원글'), findsOneWidget);
      await tester.tap(find.text('투자 관점 목록으로'));
      await tester.pumpAndSettle();
      expect(find.text('후속 관점'), findsOneWidget);
    },
  );
}
