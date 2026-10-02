import 'dart:convert';

import 'package:crypto/crypto.dart';

/// A single official OFS primary layout; never a general blank-header rule.
abstract final class RedwoodsBlankHeaderSource {
  static bool eligible({
    required String receipt,
    required String corpCode,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required String term,
    required Uri source,
  }) =>
      receipt == '20250321001825' &&
      corpCode == '00990396' &&
      !consolidated &&
      start == DateTime.utc(2024) &&
      end == DateTime.utc(2024, 12, 31) &&
      term == '15' &&
      source.scheme == 'https' &&
      source.host == 'dart.fss.or.kr' &&
      !source.hasPort &&
      source.path == '/report/viewer.do' &&
      source.queryParameters['rcpNo'] == receipt &&
      source.queryParameters['dcmNo'] == '10450233' &&
      source.queryParameters['eleId'] == '21' &&
      source.queryParameters['offset'] == '633900' &&
      source.queryParameters['length'] == '51670';
  static void verifyRaw(String cover, String statement) {
    if (sha256.convert(utf8.encode(cover)).toString() !=
            '696165e71f7637724caa97c6111151161e02b825778dfe10c9e20ba00ad0925a' ||
        sha256.convert(utf8.encode(statement)).toString() !=
            'c63592b1a91cd5bf858bbcde8f9855ca971f2cb0325aa1d7037d1265f22036b4') {
      throw const FormatException('Redwoods pinned official raw SHA mismatch');
    }
  }
}
