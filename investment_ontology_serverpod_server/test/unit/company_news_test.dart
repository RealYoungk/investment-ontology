import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/news/company_news_service.dart';

CompanyNewsItem item(
  String title,
  String url, {
  String publisher = 'example.com',
}) => CompanyNewsItem(
  title: title,
  excerpt: '',
  url: url,
  publishedAt: DateTime.utc(2026, 9, 29),
  category: CompanyNewsService.category(title),
  publisher: publisher,
  relatedUrls: [],
);
CompanyNewsFeed feed(DateTime now, {String status = 'ok'}) => CompanyNewsFeed(
  items: [],
  fetchedAt: now,
  newsStatus: status,
  filingStatus: 'ok',
);
void main() {
  test(
    'Naver sends server credentials and parses safe original excerpts',
    () async {
      final client = MockClient((request) async {
        expect(request.headers['X-NCP-APIGW-API-KEY-ID'], 'test-id');
        expect(request.url.queryParameters['sort'], 'date');
        return http.Response(
          jsonEncode({
            'items': [
              {
                'title': '<b>성호전자</b> 공급계약 &amp; 양산',
                'description': '성호전자 &#34;신제품&#34;',
                'originallink': 'https://example.com/a?utm_source=x',
                'pubDate': 'Tue, 29 Sep 2026 09:00:00 +0900',
              },
              {
                'title': '다른 기업 뉴스',
                'description': '관련 없음',
                'link': 'https://example.com/b',
                'pubDate': 'Tue, 29 Sep 2026 09:00:00 +0900',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final items = await CompanyNewsService.naver(
        client,
        '성호전자',
        'test-id',
        'test-secret',
        DateTime.utc(2026, 9, 30),
      );
      expect(items, hasLength(2));
      expect(items.first.title, '성호전자 공급계약 & 양산');
      expect(items.first.publishedAt, DateTime.utc(2026, 9, 29));
      expect(items.first.excerpt, '성호전자 "신제품"');
      expect(items.first.url, contains('utm_source'));
      expect(items.last.title, '다른 기업 뉴스');
    },
  );
  test(
    'malformed search result fails instead of silently changing results',
    () async {
      await expectLater(
        CompanyNewsService.naver(
          MockClient(
            (_) async => http.Response(
              jsonEncode({
                'items': [
                  {
                    'title': 'test',
                    'link': 'javascript:alert(1)',
                    'pubDate': 'bad',
                  },
                ],
              }),
              200,
            ),
          ),
          'test',
          'id',
          'secret',
          DateTime.now(),
        ),
        throwsFormatException,
      );
    },
  );
  test('provider errors are failures rather than empty results', () async {
    await expectLater(
      CompanyNewsService.naver(
        MockClient((_) async => http.Response('{}', 403)),
        '성호전자',
        'id',
        'secret',
        DateTime.now(),
      ),
      throwsFormatException,
    );
  });
  test(
    'dedup preserves different amounts, corrections and distinct filings',
    () {
      final result = CompanyNewsService.organize([
        item('성호전자 100억원 공급계약', 'https://a.com/1'),
        item('성호전자 100억원 공급계약', 'https://b.com/1'),
        item('성호전자 200억원 공급계약', 'https://a.com/2'),
        item('성호전자 100억원 공급계약 정정', 'https://a.com/3'),
        item('전환사채권발행결정', 'https://dart.fss.or.kr/1', publisher: 'DART'),
        item('전환사채권발행결정', 'https://dart.fss.or.kr/2', publisher: 'DART'),
      ]);
      expect(result, hasLength(5));
      expect(result.first.relatedUrls, ['https://b.com/1']);
    },
  );
  test(
    'concurrent requests share a call but sequential requests refetch',
    () async {
      final service = CompanyNewsService();
      var calls = 0;
      final pending = Completer<CompanyNewsFeed>();
      Future<CompanyNewsFeed> load() {
        calls++;
        return pending.future;
      }

      final a = service.read('a', load), b = service.read('a', load);
      pending.complete(feed(DateTime.utc(2026)));
      await Future.wait([a, b]);
      expect(calls, 1);
      await service.read('a', load);
      expect(calls, 2);
    },
  );
}
