import '../support/shad_test_host.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/company_news_section.dart';

CompanyNewsFeed feed(String title, {String status = 'ok'}) => CompanyNewsFeed(
  fetchedAt: DateTime.utc(2026, 9, 30),
  newsStatus: status,
  filingStatus: 'ok',
  items: title.isEmpty
      ? []
      : [
          CompanyNewsItem(
            title: title,
            excerpt: '기사에서 제공한 검색 요약입니다.',
            url: 'https://example.com/news',
            publishedAt: DateTime.utc(2026, 9, 29),
            category: '수주·사업',
            publisher: 'example.com',
            relatedUrls: [],
          ),
        ],
);
Widget app(String code, CompanyNewsLoader loader) => MaterialApp(
  theme: buildAppTheme(ledgerBrand),
  home: Scaffold(
    body: SingleChildScrollView(
      child: CompanyNewsSection(corpCode: code, loader: loader),
    ),
  ),
);
void main() {
  testWidgets(
    'summary contains two headlines and one filing without detail controls',
    (tester) async {
      final result = feed('뉴스');
      result.items = [
        for (var i = 0; i < 5; i++) itemForSummary('뉴스$i', '언론사'),
        itemForSummary('최신공시', 'DART'),
      ];
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompanyNewsSection(
                  corpCode: 'test',
                  compact: true,
                  loader: (_) async => result,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('뉴스0'), findsOneWidget);
      expect(find.text('뉴스2'), findsNothing);
      expect(find.text('최신공시'), findsOneWidget);
      expect(find.text('소식 더 보기'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('DART titles without excerpts occupy visible row height', (
    tester,
  ) async {
    final result = feed('임원 주요주주 소유상황보고서');
    result.items.single.excerpt = '';
    result.items.single.publisher = 'DART';
    await tester.pumpWidget(shadTestHost(app('00366942', (_) async => result)));
    await tester.pumpAndSettle();
    final title = find.text('임원 주요주주 소유상황보고서');
    expect(title, findsOneWidget);
    expect(tester.getSize(title).height, greaterThan(10));
    expect(tester.hitTestOnBinding(tester.getCenter(title)).path, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('뉴스 다섯 건도 더보기 후 다시 접을 수 있다', (tester) async {
    final result = feed('기사 1');
    result.items = List.generate(
      5,
      (i) => CompanyNewsItem(
        title: '기사 ${i + 1}',
        excerpt: '요약',
        url: 'https://example.com/$i',
        publishedAt: DateTime.utc(2026, 9, 30),
        category: '',
        publisher: 'example.com',
        relatedUrls: [],
      ),
    );
    await tester.pumpWidget(shadTestHost(app('a', (_) async => result)));
    await tester.pumpAndSettle();
    expect(find.text('기사 5'), findsNothing);
    await tester.ensureVisible(find.text('소식 더 보기'));
    await tester.tap(find.text('소식 더 보기'));
    await tester.pumpAndSettle();
    expect(find.text('기사 5'), findsOneWidget);
    await tester.ensureVisible(find.text('간략히 보기'));
    await tester.tap(find.text('간략히 보기'));
    await tester.pumpAndSettle();
    expect(find.text('기사 5'), findsNothing);
  });
  for (final width in [320.0, 1280.0]) {
    testWidgets('compact feed expands without overflow at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        shadTestHost(app('00317210', (_) async => feed('성호전자 광통신 장비 공급계약 소식'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('기사에서 제공한 검색 요약입니다.'), findsNothing);
      await tester.tap(find.text('성호전자 광통신 장비 공급계약 소식'));
      await tester.pumpAndSettle();
      expect(find.text('기사에서 제공한 검색 요약입니다.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('old company response cannot overwrite new company', (
    tester,
  ) async {
    final a = Completer<CompanyNewsFeed>(), b = Completer<CompanyNewsFeed>();
    Future<CompanyNewsFeed> load(String code) =>
        code == 'a' ? a.future : b.future;
    await tester.pumpWidget(shadTestHost(app('a', load)));
    expect(find.text('최근 소식을 불러오는 중…'), findsOneWidget);
    await tester.pumpWidget(shadTestHost(app('b', load)));
    b.complete(feed('새 회사 소식'));
    await tester.pumpAndSettle();
    a.complete(feed('이전 회사 소식'));
    await tester.pumpAndSettle();
    expect(find.text('새 회사 소식'), findsOneWidget);
    expect(find.text('이전 회사 소식'), findsNothing);
  });
  testWidgets('empty, partial and failure states differ', (tester) async {
    await tester.pumpWidget(shadTestHost(app('a', (_) async => feed(''))));
    await tester.pumpAndSettle();
    expect(find.text('검색된 뉴스와 최근 공시가 없습니다.'), findsOneWidget);
    await tester.pumpWidget(
      shadTestHost(
        app('b', (_) async => feed('공시 소식', status: 'notConfigured')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('뉴스 연결 준비 중'), findsOneWidget);
    expect(find.text('공시 소식'), findsOneWidget);
    await tester.pumpWidget(
      shadTestHost(app('c', (_) async => throw Exception('offline'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsOneWidget);
  });
}

CompanyNewsItem itemForSummary(String title, String publisher) =>
    CompanyNewsItem(
      title: title,
      excerpt: '요약문',
      url: 'https://example.com/$title',
      publishedAt: DateTime.utc(2026, 10, 7),
      category: '',
      publisher: publisher,
      relatedUrls: [],
    );
