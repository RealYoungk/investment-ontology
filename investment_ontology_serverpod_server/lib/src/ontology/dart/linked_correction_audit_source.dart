import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Exact official correction menu; the attached audit remains under its actual original receipt.
abstract final class LinkedCorrectionAuditSource {
  static const target = '20250317000968';
  static const original = '20250317000704';
  static const corp = '00963000';
  static const targetSha =
      'c8a826539faf81a8c7c7f8d3067638cb6aa1d7ca128efffced85e4fdfe7543f0';
  static const originalSha =
      '1ee71512f98bee1c42009326d7ad4290eb347c32d2b965afb9d7c7cc36dda4e5';
  static bool eligible({
    required String receipt,
    required String corpCode,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
  }) =>
      receipt == target &&
      corpCode == corp &&
      !consolidated &&
      start == DateTime.utc(2024) &&
      end == DateTime.utc(2024, 12, 31);
  static String verifyTarget(String raw) {
    if (sha256.convert(utf8.encode(raw)).toString() != targetSha ||
        !raw.contains("rcpNo=20250317000704&amp;dcmNo=10414790")) {
      throw const FormatException('Linked correction audit family changed');
    }
    return original;
  }

  static void verifyOriginal(String raw) {
    if (sha256.convert(utf8.encode(raw)).toString() != originalSha) {
      throw const FormatException('Linked correction original shell changed');
    }
  }
}
