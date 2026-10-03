import 'dart:convert';

import 'package:archive/archive.dart';

abstract final class CharterXml {
  /// XML issuer identity is mandatory, even though the receipt came from DART.
  static String boundDocument(List<int> bytes, String corpCode) {
    final zip = ZipDecoder().decodeBytes(bytes);
    final documents = <String>[];
    for (final file in zip.files.where(
      (f) => f.isFile && f.name.toLowerCase().endsWith('.xml'),
    )) {
      if (file.size > 8 * 1024 * 1024) {
        throw const FormatException('Oversized charter document');
      }
      final text = utf8.decode(file.content as List<int>);
      final identities = RegExp(
        r'''<COMPANY-NAME\b[^>]*\bAREGCIK\s*=\s*["'](\d{8})["']''',
        caseSensitive: false,
      ).allMatches(text).map((m) => m[1]).toSet();
      if (identities.length == 1 && identities.single == corpCode) {
        documents.add(text);
      }
    }
    if (documents.length != 1) {
      throw const FormatException('Charter XML issuer mismatch or ambiguous');
    }
    return documents.single;
  }
}
