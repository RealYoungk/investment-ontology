import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../../generated/protocol.dart';
import 'company_news_service.dart';
import 'company_news_matcher.dart';

abstract final class GoogleNewsService {
  /// Public Google News RSS; failures are handled independently of NAVER.
  static Future<List<CompanyNewsItem>> read(
    http.Client client,
    String name,
    DateTime now, {
    String? stockCode,
    String? ceoName,
  }) async {
    final response = await client
        .get(
          Uri.https('news.google.com', '/rss/search', {
            'q': '"$name" (기업 OR 주가 OR 실적 OR 인수) when:90d',
            'hl': 'ko',
            'gl': 'KR',
            'ceid': 'KR:ko',
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const FormatException('Google news failed');
    }
    final xml = XmlDocument.parse(utf8.decode(response.bodyBytes));
    if (xml.rootElement.name.local != 'rss') {
      throw const FormatException('Invalid RSS');
    }
    final result = <CompanyNewsItem>[];
    for (final item in xml.findAllElements('item').take(100)) {
      String field(String name) => item.getElement(name)?.innerText ?? '';
      final publisher = CompanyNewsService.clean(field('source'));
      var title = CompanyNewsService.clean(field('title'));
      if (publisher.isNotEmpty && title.endsWith(' - $publisher')) {
        title = title.substring(0, title.length - publisher.length - 3);
      }
      final url = CompanyNewsService.safeUrl(field('link'));
      final date = CompanyNewsService.parseDate(
        field('pubDate').replaceFirst(RegExp(r' GMT$'), ' +0000'),
      );
      if (url == null ||
          date == null ||
          date.isAfter(now.add(const Duration(days: 1))) ||
          date.isBefore(now.subtract(const Duration(days: 90)))) {
        continue;
      }
      if (!NewsCompanyMatcher.matches(
        name: name,
        title: title,
        excerpt: '',
        stockCode: stockCode,
        ceoName: ceoName,
      )) {
        continue;
      }
      result.add(
        CompanyNewsItem(
          title: title,
          excerpt: '',
          url: url,
          publishedAt: date,
          category: CompanyNewsService.category(title),
          publisher: publisher.isEmpty ? '언론사' : publisher,
          relatedUrls: [],
        ),
      );
    }
    return result;
  }
}
