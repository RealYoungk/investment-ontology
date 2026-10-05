import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Authored content only. Source links are retained, never fetched at import.
abstract final class InvestmentNoteContent {
  static const format = 'investment-note-v1';

  static Map<String, dynamic> parse(String payload) {
    if (utf8.encode(payload).length > 350000) {
      throw const FormatException('콘텐츠는 350KB 이하로 입력하세요.');
    }
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
      throw const FormatException('콘텐츠 형식은 schemaVersion 1이어야 합니다.');
    }
    String field(Map<String, dynamic> row, String key, int max) {
      final value = row[key];
      if (value is! String || value.trim().isEmpty || value.length > max) {
        throw FormatException('$key 값이 없거나 너무 깁니다.');
      }
      return value.trim();
    }

    final corpCode = field(decoded, 'corpCode', 8);
    if (!RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw const FormatException('기업코드 오류');
    }
    final tier = decoded['tier'];
    if (tier != 'watchlist' && tier != 'topPick') {
      throw const FormatException('관심종목 또는 탑픽 등급을 지정하세요.');
    }
    final asOf = DateTime.tryParse(field(decoded, 'dataAsOf', 40));
    if (asOf == null) throw const FormatException('자료 기준일 오류');
    final previous = decoded['previousArticleId'];
    if (previous != null && (previous is! int || previous <= 0)) {
      throw const FormatException('후속 글 연결 오류');
    }
    final rawSources = decoded['sources'];
    if (rawSources is! List || rawSources.isEmpty || rawSources.length > 40) {
      throw const FormatException('근거 자료를 1~40개 연결하세요.');
    }
    final ids = <String>{};
    final sources = <Map<String, dynamic>>[];
    for (final raw in rawSources) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('근거 자료 형식 오류');
      }
      final id = field(raw, 'id', 40);
      final url = field(raw, 'url', 2000);
      final uri = Uri.tryParse(url);
      if (!ids.add(id) ||
          uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw const FormatException('중복 근거 또는 HTTPS 링크 오류');
      }
      final kind = field(raw, 'kind', 20);
      if (!{'paper', 'filing', 'company', 'other'}.contains(kind)) {
        throw const FormatException('근거 종류 오류');
      }
      sources.add({
        'id': id,
        'title': field(raw, 'title', 200),
        'url': url,
        'kind': kind,
      });
    }
    final rawSections = decoded['sections'];
    if (rawSections is! List ||
        rawSections.isEmpty ||
        rawSections.length > 20) {
      throw const FormatException('본문을 1~20개 절로 작성하세요.');
    }
    final sections = <Map<String, dynamic>>[];
    for (final raw in rawSections) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('본문 절 형식 오류');
      }
      final refs = raw['sourceIds'];
      if (refs is! List ||
          refs.any((id) => id is! String || !ids.contains(id))) {
        throw const FormatException('본문의 근거 연결 오류');
      }
      sections.add({
        'heading': field(raw, 'heading', 120),
        'text': field(raw, 'text', 50000),
        'sourceIds': refs.toSet().toList(),
      });
    }
    return {
      'schemaVersion': 1,
      'corpCode': corpCode,
      'tier': tier,
      'author': field(decoded, 'author', 80),
      'title': field(decoded, 'title', 180),
      'introduction': field(decoded, 'introduction', 5000),
      'dataAsOf': asOf.toUtc().toIso8601String(),
      'previousArticleId': previous,
      'sources': sources,
      'sections': sections,
    };
  }

  static String digest(int articleId, int version, String content) =>
      sha256.convert(utf8.encode('$articleId:$version:$content')).toString();

  /// Build an explicit allowlist: restricted sections/sources never leave server.
  static Map<String, dynamic> readerView(
    Map<String, dynamic> content, {
    required bool member,
    required int id,
    required DateTime publishedAt,
    required String companyName,
  }) {
    final hidden = !member && content['tier'] == 'topPick';
    return {
      'id': id,
      'tier': content['tier'],
      'publishedAt': publishedAt.toIso8601String(),
      'locked': !member,
      'title': hidden ? '멤버십 탑픽' : content['title'],
      'introduction': hidden
          ? '작성자가 선정한 기업과 상세 투자 관점을 멤버십에서 확인하세요.'
          : content['introduction'],
      if (!hidden) ...{
        'corpCode': content['corpCode'],
        'companyName': companyName,
        'author': content['author'],
        'dataAsOf': content['dataAsOf'],
        'previousArticleId': content['previousArticleId'],
      },
      if (member) ...{
        'sections': content['sections'],
        'sources': content['sources'],
      },
    };
  }
}
