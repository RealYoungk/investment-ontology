import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';
import 'package:investment_ontology_serverpod_flutter/features/research/research_editor.dart';
import 'package:investment_ontology_serverpod_flutter/features/research/research_pages.dart';

// Avoid runtime font downloading in widget tests, preserving production colors.
ThemeData get theme => buildAppTheme(
  AppBrand(
    colors: ledgerBrand.colors,
    shape: ledgerBrand.shape,
    typography: const AppTypography(
      displayBase: TextStyle(),
      bodyBase: TextStyle(),
      numericBase: TextStyle(),
      labelBase: TextStyle(),
    ),
  ),
);

typedef ListArgs = ({
  String query,
  String market,
  bool manage,
  bool savedOnly,
  String? ticker,
  int offset,
});

/// The generated endpoint with its calls answered in the test.
class FakeResearch extends EndpointResearch {
  FakeResearch() : super(Client('http://localhost:1/'));

  final lists = <ListArgs>[];
  Future<List<ResearchEntry>> Function(ListArgs args) onList = (_) async => [];
  Future<ResearchEntry?> Function(String slug, int? version) onGet = (
    slug,
    _,
  ) async => entry(0, slug: slug);
  Future<List<ResearchRevision>> Function() onEditions = () async => [];
  var saves = 0;
  final savedVersions = <int>[];
  Future<List<ResearchRevision>> Function() onHistory = () async => [];

  @override
  Future<List<ResearchEntry>> list({
    required String query,
    required String market,
    required bool manage,
    required bool savedOnly,
    String? ticker,
    required int offset,
  }) {
    final args = (
      query: query,
      market: market,
      manage: manage,
      savedOnly: savedOnly,
      ticker: ticker,
      offset: offset,
    );
    lists.add(args);
    return onList(args);
  }

  @override
  Future<ResearchEntry?> get(
    String slug, {
    required bool draft,
    required bool source,
    int? version,
  }) => onGet(slug, version);

  @override
  Future<List<ResearchRevision>> editions(String slug) => onEditions();

  @override
  Future<List<ResearchRevision>> history(String slug) => onHistory();

  @override
  Future<ResearchEntry> save(
    String slug,
    String title,
    String summary,
    String ticker,
    String market,
    String content,
    String format,
    DateTime dataAsOf,
    int expectedVersion,
    String note,
  ) async {
    saves++;
    savedVersions.add(expectedVersion);
    return entry(0, slug: slug, version: expectedVersion + 1);
  }
}

ResearchEntry entry(
  int i, {
  String? slug,
  String? title,
  int version = 1,
  String market = 'KOSPI',
}) => ResearchEntry(
  article: ResearchArticle(
    id: i,
    slug: slug ?? 'r$i',
    latestVersion: version,
    publishedVersion: version,
  ),
  revision: ResearchRevision(
    articleId: i,
    version: version,
    title: title ?? '리포트 $i',
    summary: '요약 $i',
    ticker: '005930',
    market: market,
    content: '## 본문\n내용',
    format: 'markdown',
    searchText: '',
    dataAsOf: DateTime.utc(2026, 9, 1),
    createdAt: DateTime.utc(2026, 9, 1),
    note: '',
    legacy: false,
  ),
  saved: false,
);

GoRouter routerFor(FakeResearch api, {String initial = '/research'}) =>
    GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/research',
          builder: (_, s) => Scaffold(
            body: ResearchListPage(
              research: api,
              ticker: s.uri.queryParameters['ticker'],
              query: s.uri.queryParameters['q'] ?? '',
              market: s.uri.queryParameters['market'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: '/research/:slug',
          builder: (_, s) => Scaffold(
            body: ResearchReaderPage(
              research: api,
              slug: s.pathParameters['slug']!,
            ),
          ),
        ),
        GoRoute(
          path: '/admin/research/:slug',
          onExit: (context, _) => ResearchEditorPage.confirmExit(context),
          builder: (_, s) => Scaffold(
            body: ResearchEditorPage(
              research: api,
              slug: s.pathParameters['slug']!,
            ),
          ),
        ),
        GoRoute(
          path: '/elsewhere',
          builder: (_, _) => const Scaffold(body: Text('다른 화면')),
        ),
      ],
    );

Future<GoRouter> pump(
  WidgetTester tester,
  FakeResearch api, {
  String initial = '/research',
  Size size = const Size(1280, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = routerFor(api, initial: initial);
  await tester.pumpWidget(
    MaterialApp.router(theme: theme, routerConfig: router),
  );
  await tester.pump();
  return router;
}

void main() {
  test(
    'server refusals read as what happened, not as a connection problem',
    () {
      expect(researchError(ServerpodClientForbidden()), '이 화면을 볼 권한이 없습니다.');
      expect(researchError(ServerpodClientUnauthorized()), contains('로그인'));
      expect(
        researchError(ServerpodClientUnknownHttpException('too large', 413)),
        contains('본문이 너무 큽니다'),
      );
      expect(researchError(IngestException(message: '서버 안내')), '서버 안내');
      expect(researchError(StateError('x')), contains('연결'));
    },
  );

  testWidgets('search and market go into the address and a late answer to an '
      'older search never replaces the newer one', (tester) async {
    final api = FakeResearch();
    final pending = <String, Completer<List<ResearchEntry>>>{};
    api.onList = (a) => (pending[a.query] = Completer()).future;
    final router = await pump(tester, api);

    await tester.enterText(find.byType(TextField), '반도체');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(
      router.state.uri.toString(),
      '/research?q=%EB%B0%98%EB%8F%84%EC%B2%B4',
    );
    expect(api.lists.last.query, '반도체');

    pending['반도체']!.complete([entry(1, title: '새 검색 결과')]);
    await tester.pump();
    pending['']!.complete([entry(2, title: '처음 목록')]);
    await tester.pump();
    expect(find.text('새 검색 결과'), findsOneWidget);
    expect(find.text('처음 목록'), findsNothing);

    await tester.tap(find.text('KOSDAQ'));
    await tester.pump();
    expect(router.state.uri.queryParameters, {
      'q': '반도체',
      'market': 'KOSDAQ',
    });
    expect(api.lists.last.market, 'KOSDAQ');
    expect(api.lists.last.query, '반도체');
  });

  testWidgets('a failed load shows one error with a retry, not "no results"', (
    tester,
  ) async {
    final api = FakeResearch();
    var fail = true;
    api.onList = (_) async {
      if (fail) throw ServerpodClientInternalServerError();
      return [entry(1)];
    };
    await pump(tester, api);
    await tester.pump();
    expect(find.text('연결을 확인하고 다시 시도해주세요.'), findsOneWidget);
    expect(find.textContaining('리포트가 없습니다'), findsNothing);
    expect(find.text('리포트 더 보기'), findsNothing);
    fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    await tester.pump();
    expect(find.text('리포트 1'), findsOneWidget);
    expect(find.text('연결을 확인하고 다시 시도해주세요.'), findsNothing);
  });

  testWidgets('coming back from an article keeps every loaded page', (
    tester,
  ) async {
    final api = FakeResearch();
    api.onList = (a) async => [
      for (var i = a.offset; i < 35 && i < a.offset + researchPageSize; i++)
        entry(i),
    ];
    await pump(tester, api);
    await tester.pump();
    final page = find
        .descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('리포트 더 보기'),
      400,
      scrollable: page,
    );
    await tester.tap(find.text('리포트 더 보기'));
    await tester.pump();
    await tester.pump();
    expect(find.text('리포트 34'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('리포트 0'),
      -400,
      scrollable: page,
    );
    await tester.tap(find.text('리포트 0'));
    await tester.pumpAndSettle();
    expect(find.text('리포트 목록'), findsOneWidget);
    api.lists.clear();
    await tester.tap(find.text('리포트 목록'));
    await tester.pumpAndSettle();
    expect(api.lists.map((a) => a.offset), [0, 30]);
    expect(find.text('리포트 34'), findsOneWidget);
    expect(find.text('리포트 더 보기'), findsNothing);
  });

  testWidgets('an article still opens when its edition list fails', (
    tester,
  ) async {
    final api = FakeResearch()
      ..onEditions = () async => throw ServerpodClientInternalServerError();
    await pump(tester, api, initial: '/research/simmtech');
    await tester.pumpAndSettle();
    expect(find.text('저장'), findsOneWidget);
    expect(find.text('연결을 확인하고 다시 시도해주세요.'), findsNothing);
  });

  testWidgets('a forbidden article explains why and can be retried', (
    tester,
  ) async {
    final api = FakeResearch();
    var forbidden = true;
    api.onGet = (slug, _) async {
      if (forbidden) throw ServerpodClientForbidden();
      return entry(0, slug: slug);
    };
    await pump(tester, api, initial: '/research/private');
    await tester.pumpAndSettle();
    expect(find.text('이 화면을 볼 권한이 없습니다.'), findsOneWidget);
    forbidden = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('저장'), findsOneWidget);
  });

  testWidgets('a missing public article says so without an error retry', (
    tester,
  ) async {
    final api = FakeResearch()..onGet = (_, _) async => null;
    await pump(tester, api, initial: '/research/gone');
    await tester.pumpAndSettle();
    expect(find.text('공개된 리포트가 없습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
    expect(find.text('리포트 둘러보기'), findsOneWidget);
  });

  testWidgets('changing only the market still asks before leaving the editor', (
    tester,
  ) async {
    final api = FakeResearch();
    final router = await pump(tester, api, initial: '/admin/research/r0');
    await tester.pumpAndSettle();
    await tester.tap(find.text('KOSPI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KOSDAQ').last);
    await tester.pumpAndSettle();
    expect(ResearchEditorPage.hasUnsavedChanges, isTrue);

    router.go('/elsewhere');
    await tester.pumpAndSettle();
    expect(find.text('저장하지 않은 변경이 있습니다.'), findsOneWidget);
    await tester.tap(find.text('계속 편집'));
    await tester.pumpAndSettle();
    expect(find.text('다른 화면'), findsNothing);

    router.go('/elsewhere');
    await tester.pumpAndSettle();
    await tester.tap(find.text('변경 버리기'));
    await tester.pumpAndSettle();
    expect(find.text('다른 화면'), findsOneWidget);
    expect(ResearchEditorPage.hasUnsavedChanges, isFalse);
  });

  testWidgets(
    'successful save survives history failure and advances the next version',
    (tester) async {
      final api = FakeResearch();
      var historyCalls = 0;
      api.onHistory = () async {
        if (++historyCalls > 1) throw Exception('history offline');
        return [];
      };
      await pump(tester, api, initial: '/admin/research/r0');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('제목')), '수정한 제목');
      await tester.tap(find.text('초안 저장'));
      await tester.pumpAndSettle();
      expect(ResearchEditorPage.hasUnsavedChanges, isFalse);
      expect(find.text('연결을 확인하고 다시 시도해주세요.'), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('제목')), '두 번째 수정');
      await tester.tap(find.text('초안 저장'));
      await tester.pumpAndSettle();
      expect(api.savedVersions, [1, 2]);
      expect(ResearchEditorPage.hasUnsavedChanges, isFalse);
    },
  );

  testWidgets('a body over the request limit is refused before sending', (
    tester,
  ) async {
    final api = FakeResearch();
    await pump(tester, api, initial: '/admin/research/new');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('본문')),
      '가' * (ResearchEditorPage.maxBodyBytes ~/ 3 + 1),
    );
    await tester.tap(find.text('초안 저장'));
    await tester.pumpAndSettle();
    expect(api.saves, 0);
    expect(find.textContaining('본문이 너무 큽니다'), findsOneWidget);
    ResearchEditorPage.hasUnsavedChanges = false;
  });

  testWidgets('an unknown editor address becomes a new article there', (
    tester,
  ) async {
    final api = FakeResearch()..onGet = (_, _) async => null;
    await pump(tester, api, initial: '/admin/research/typo-slug');
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 없는 리포트입니다'), findsOneWidget);
    expect(find.text('typo-slug'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('제목')), '제목');
    expect(ResearchEditorPage.hasUnsavedChanges, isTrue);
    ResearchEditorPage.hasUnsavedChanges = false;
  });

  testWidgets('list and article toolbar fit a 390px phone', (tester) async {
    final api = FakeResearch();
    api.onList = (_) async => [
      entry(1, title: '아주 긴 제목의 리포트가 모바일 화면에서도 넘치지 않고 여러 줄로 감싸지는지 확인합니다'),
    ];
    api.onGet = (slug, _) async => entry(0, slug: slug, version: 2);
    api.onEditions = () async => [
      entry(0, version: 2).revision,
      entry(0, version: 1).revision,
    ];
    final router = await pump(tester, api, size: const Size(390, 844));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    router.go('/research/long');
    await tester.pumpAndSettle();
    expect(find.text('v2 · 2026.09.01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
