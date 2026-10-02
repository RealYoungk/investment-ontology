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
  static const bonTarget = '20260804000177';
  static const bonOriginal = '20260313001347';
  static const bonTargetSha =
      '425e15ccdab67f4ba361a82917a3f54f63963c7ca36c48b560a07652fb629c1c';
  static const bonOriginalSha =
      '5c17b101d83400f61e538a5b938c5c7e7def0718b9889fe2e2d478e5c356b613';
  static const bonWitnessUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260804000177&dcmNo=11507996&eleId=23&offset=306758&length=87280&dtd=dart4.xsd';
  static String originalFor(String receipt) => receipt == target
      ? original
      : receipt == bonTarget
      ? bonOriginal
      : throw const FormatException('Unknown linked correction profile');
  static Uri? witnessUri(String receipt) =>
      receipt == bonTarget ? Uri.parse(bonWitnessUri) : null;
  static bool eligible({
    required String receipt,
    required String corpCode,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
  }) =>
      !consolidated &&
      ((receipt == target &&
              corpCode == corp &&
              start == DateTime.utc(2024) &&
              end == DateTime.utc(2024, 12, 31)) ||
          (receipt == bonTarget &&
              corpCode == '01872459' &&
              start == DateTime.utc(2025) &&
              end == DateTime.utc(2025, 12, 31)));
  static String verifyTarget(String raw, {String receipt = target}) {
    final digest = receipt == target
        ? targetSha
        : receipt == bonTarget
        ? bonTargetSha
        : null;
    final link = receipt == target
        ? 'rcpNo=20250317000704&amp;dcmNo=10414790'
        : 'rcpNo=20260313001347&amp;dcmNo=11122740';
    if (digest == null ||
        sha256.convert(utf8.encode(raw)).toString() != digest ||
        !raw.contains(link)) {
      throw const FormatException('Linked correction audit family changed');
    }
    return originalFor(receipt);
  }

  static void verifyOriginal(String raw, {String receipt = target}) {
    final digest = receipt == target
        ? originalSha
        : receipt == bonTarget
        ? bonOriginalSha
        : null;
    if (digest == null ||
        sha256.convert(utf8.encode(raw)).toString() != digest) {
      throw const FormatException('Linked correction original shell changed');
    }
  }
}
