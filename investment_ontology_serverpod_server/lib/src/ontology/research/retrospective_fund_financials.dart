import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'retrospective_fund_contract.dart';

abstract final class RetrospectiveFundFinancials {
  static bool supports(Map document) =>
      RetrospectiveFundContract.supports(document);
  static void verifyPdf(List<int> raw) {
    if (raw.length < 5 ||
        raw.length > 20 * 1024 * 1024 ||
        utf8.decode(raw.take(5).toList()) != '%PDF-' ||
        sha256.convert(raw).toString() !=
            RetrospectiveFundContract.data['metadata']['sha256']) {
      throw const FormatException(
        'Exact original corrected prospectus required',
      );
    }
  }

  static List<Map<String, dynamic>> parse(List<int> raw) {
    if (raw.length > 4 * 1024 * 1024 ||
        sha256.convert(raw).toString() !=
            RetrospectiveFundContract.data['textSha256']) {
      throw const FormatException(
        'Exact full original extracted text required',
      );
    }
    final pages = utf8.decode(raw).split('\f');
    for (final p in RetrospectiveFundContract.data['profiles'] as List) {
      for (final c in (p['cells'] as Map).values) {
        final lines = pages[(c['pageOrdinal'] as int) - 1].split('\n');
        if (lines[(c['lineOrdinal'] as int) - 1] != c['rawLine']) {
          throw const FormatException(
            'Immutable physical-page/line binding failed',
          );
        }
        final span = c['characterSpan'];
        if (span != null &&
            (c['rawLine'] as String).substring(span[0], span[1]) !=
                c['printedAmount']) {
          throw const FormatException(
            'Exact printed source token coordinate failed',
          );
        }
      }
    }
    return RetrospectiveFundContract.build();
  }
}
