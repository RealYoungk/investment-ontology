import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One immutable own-receipt primary section; no general table absence grammar.
abstract final class InnovexExactBasisAbsence {
  static bool matches({
    required String receipt,
    required String corp,
    required DateTime start,
    required DateTime end,
    required Uri coverSource,
    required String cover,
    required Uri statementSource,
    required String body,
  }) =>
      receipt == '20260331004637' &&
      corp == '01353848' &&
      start == DateTime.utc(2025) &&
      end == DateTime.utc(2025, 12, 31) &&
      coverSource.toString() ==
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260331004637&dcmNo=11214858&eleId=1&offset=966&length=4501&dtd=dart4.xsd' &&
      sha256.convert(utf8.encode(cover)).toString() ==
          '8ec3dd27078969973fe62845b9f1291c356e7eaf55fcd5329283cf47d5d31f13' &&
      statementSource.toString() ==
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260331004637&dcmNo=11214858&eleId=19&offset=185321&length=445&dtd=dart4.xsd' &&
      sha256.convert(utf8.encode(body)).toString() ==
          '133d0fd797042ecc262d10b277faa717e93c0fd0dd9f00a3712caf840d74ac64';
}
