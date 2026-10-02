import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Exact published title tables; approval prose is never a statement heading.
abstract final class ItcenPrimaryTitleSource {
  static bool eligible({
    required String receipt,
    required String corpCode,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required String term,
    required Uri source,
  }) =>
      receipt == '20230317000589' &&
      corpCode == '01113499' &&
      !consolidated &&
      start == DateTime.utc(2022) &&
      end == DateTime.utc(2022, 12, 31) &&
      term == '12' &&
      source.scheme == 'https' &&
      source.host == 'dart.fss.or.kr' &&
      !source.hasPort &&
      source.path == '/report/viewer.do' &&
      source.queryParameters['rcpNo'] == receipt &&
      source.queryParameters['dcmNo'] == '9069985' &&
      source.queryParameters['eleId'] == '21' &&
      source.queryParameters['offset'] == '500047' &&
      source.queryParameters['length'] == '45711';
  static void verifyRaw(String cover, String statement) {
    if (sha256.convert(utf8.encode(cover)).toString() !=
            '7ac6cb9a408ce4a99571b42209e598828d6c41b67e3a6bac29b782886dde72b5' ||
        sha256.convert(utf8.encode(statement)).toString() !=
            '8d36e4ac98eb0a6da4353da24b4fc1cdcacd19badaf1cb5990303584d18e531c') {
      throw const FormatException('ITcen pinned official raw SHA mismatch');
    }
  }

  static String compact(String text) => text
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll(RegExp(r'\s+'), '');
  static String primaryPrefix(String before, String kind) {
    final headings = {
      '재무상태표': 'BS',
      '포괄손익계산서': 'CIS',
      '자본변동표': 'CE',
      '현금흐름표': 'CF',
    };
    int? at;
    String? actual;
    for (final table in RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(before)) {
      final first = RegExp(
        r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(table[1]!);
      final h = first == null ? null : headings[compact(first[1]!)];
      if (h != null) {
        at = table.start;
        actual = h;
      }
    }
    if (at == null || actual != kind) {
      throw const FormatException('ITcen direct primary title table missing');
    }
    return compact(before.substring(at));
  }
}
