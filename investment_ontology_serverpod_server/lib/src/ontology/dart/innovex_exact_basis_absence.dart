import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Two immutable own-receipt primary sections; no general table absence grammar.
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
      (receipt == '20220321000630' &&
          corp == '01353848' &&
          start == DateTime.utc(2021) &&
          end == DateTime.utc(2021, 12, 31) &&
          coverSource.toString() ==
              'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220321000630&dcmNo=8482170&eleId=1&offset=807&length=4027&dtd=dart3.xsd' &&
          sha256.convert(utf8.encode(cover)).toString() ==
              '6b6ae646ac07f9228dc540cb530cedc8b598a6e99bec531b7585c3dc262db212' &&
          statementSource.toString() ==
              'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220321000630&dcmNo=8482170&eleId=19&offset=193372&length=366&dtd=dart3.xsd' &&
          sha256.convert(utf8.encode(body)).toString() ==
              'e7de72d71d6291a2dc74082c833d0f28c413f106ed3162e3f66272ad1dc1e36d') ||
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
