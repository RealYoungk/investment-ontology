import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../generated/protocol.dart';

/// Request-only feed. No database writes, timer, or language-model calls.
class CompanyNewsService {
  final _pending = <String, Future<CompanyNewsFeed>>{};

  // Share concurrent requests only. Do not retain search results after delivery.
  Future<CompanyNewsFeed> read(
    String key,
    Future<CompanyNewsFeed> Function() load,
  ) {
    return _pending[key] ??= Future.sync(load).whenComplete(() {
      _pending.remove(key);
    });
  }

  static Future<List<CompanyNewsItem>> naver(
    http.Client client,
    String name,
    String id,
    String secret,
    DateTime now,
  ) async {
    final response = await client
        .get(
          Uri.https('naverapihub.apigw.ntruss.com', '/search/v1/news', {
            'query': '"$name"',
            'display': '10',
            'sort': 'date',
          }),
          headers: {
            'X-NCP-APIGW-API-KEY-ID': id,
            'X-NCP-APIGW-API-KEY': secret,
          },
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const FormatException('News API failed');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['items'] is! List) {
      throw const FormatException('Missing news items');
    }
    final result = <CompanyNewsItem>[];
    for (final raw in body['items'] as List) {
      if (raw is! Map) continue;
      final title = clean(raw['title']);
      final excerpt = clean(raw['description']);
      final url = safeUrl(raw['originallink']) ?? safeUrl(raw['link']);
      final date = parseDate(raw['pubDate']);
      if (url == null || date == null || title.isEmpty) {
        throw const FormatException('Invalid news item');
      }
      result.add(
        CompanyNewsItem(
          title: title,
          excerpt: excerpt,
          url: url,
          publishedAt: date,
          category: '',
          publisher: Uri.parse(url).host.replaceFirst('www.', ''),
          relatedUrls: [],
        ),
      );
    }
    return result;
  }

  static String clean(dynamic value) {
    if (value is! String) return '';
    return value
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAllMapped(
          RegExp(r'&(#x[0-9a-fA-F]+|#\d+|amp|lt|gt|quot|apos|nbsp);'),
          (m) {
            const entities = {
              'amp': '&',
              'lt': '<',
              'gt': '>',
              'quot': '"',
              'apos': "'",
              'nbsp': ' ',
            };
            final token = m[1]!;
            if (entities.containsKey(token)) return entities[token]!;
            final n = token.startsWith('#x')
                ? int.tryParse(token.substring(2), radix: 16)
                : int.tryParse(token.substring(1));
            return n != null &&
                    n > 0 &&
                    n <= 0x10ffff &&
                    !(n >= 0xd800 && n <= 0xdfff)
                ? String.fromCharCode(n)
                : '';
          },
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? safeUrl(dynamic value) {
    if (value is! String) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return value;
  }

  static DateTime? parseDate(dynamic value) {
    if (value is! String) return null;
    final m = RegExp(
      r'^(?:\w+,\s*)?(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) ([+-])(\d{2})(\d{2})$',
    ).firstMatch(value.trim());
    if (m == null) return null;
    final month =
        const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ].indexOf(m[2]!) +
        1;
    if (month == 0) return null;
    final day = int.parse(m[1]!), year = int.parse(m[3]!);
    final date = DateTime.utc(
      year,
      month,
      day,
      int.parse(m[4]!),
      int.parse(m[5]!),
      int.parse(m[6]!),
    );
    if (date.month != month ||
        date.day != day ||
        int.parse(m[4]!) > 23 ||
        int.parse(m[5]!) > 59 ||
        int.parse(m[6]!) > 59 ||
        int.parse(m[8]!) > 23 ||
        int.parse(m[9]!) > 59) {
      return null;
    }
    final offset = Duration(
      minutes:
          (int.parse(m[8]!) * 60 + int.parse(m[9]!)) * (m[7] == '-' ? -1 : 1),
    );
    return date.subtract(offset);
  }

  static String category(String title) {
    for (final rule in <(String, String)>[
      ('자금조달', r'전환사채|신주인수권|유상증자|자금조달'),
      ('인수·투자', r'인수|합병|지분.*취득|시설투자|증설'),
      ('수주·사업', r'수주|공급계약|납품|신제품|양산|사업진출'),
      ('실적', r'영업이익|순이익|매출|실적|흑자|적자'),
      ('주주환원', r'배당|자사주|자기주식'),
      ('주가', r'급등|급락|상한가|하한가|특징주|주가|신고가'),
    ]) {
      if (RegExp(rule.$2).hasMatch(title)) return rule.$1;
    }
    return '기업 소식';
  }

  /// Conservative clustering: preserve different numbers and correction titles.
  static List<CompanyNewsItem> organize(List<CompanyNewsItem> input) {
    final sorted = [...input]
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    final groups = <CompanyNewsItem>[];
    for (final item in sorted) {
      final match = groups
          .where((g) => g.url == item.url || similar(g, item))
          .firstOrNull;
      if (match == null) {
        groups.add(item);
      } else if (match.url != item.url &&
          !match.relatedUrls.contains(item.url)) {
        match.relatedUrls.add(item.url);
      }
    }
    groups.sort((a, b) {
      final price = (a.category == '주가' ? 1 : 0).compareTo(
        b.category == '주가' ? 1 : 0,
      );
      return price != 0 ? price : b.publishedAt.compareTo(a.publishedAt);
    });
    return groups.take(12).toList();
  }

  static bool similar(CompanyNewsItem a, CompanyNewsItem b) {
    if (a.category != b.category ||
        a.publisher == 'DART' ||
        b.publisher == 'DART' ||
        a.publishedAt.difference(b.publishedAt).inHours.abs() > 48) {
      return false;
    }
    String normalize(String s) =>
        s.replaceAll(RegExp(r'[^가-힣a-zA-Z0-9]'), '').toLowerCase();
    final x = normalize(a.title), y = normalize(b.title);
    if (x == y) return true;
    if (RegExp(r'정정|취소|철회').hasMatch(a.title + b.title)) return false;
    String nums(String s) =>
        RegExp(r'\d+(?:[.,]\d+)*').allMatches(s).map((m) => m[0]).join('|');
    if (nums(a.title) != nums(b.title) || x.length < 12 || y.length < 12) {
      return false;
    }
    Set<String> grams(String s) => {
      for (int i = 0; i < s.length - 1; i++) s.substring(i, i + 2),
    };
    final gx = grams(x), gy = grams(y);
    return gx.intersection(gy).length / gx.union(gy).length >= .85;
  }
}
