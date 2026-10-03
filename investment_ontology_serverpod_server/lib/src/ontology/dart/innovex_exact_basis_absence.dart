import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Immutable own-receipt primary sections; no general table absence grammar.
abstract final class InnovexExactBasisAbsence {
  static const historical = <String, Map<String, Object>>{
    '20250320001369': {
      'year': 2024,
      'cover': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001369&dcmNo=10439334&eleId=1&offset=955&length=4504&dtd=dart4.xsd',
      'coverSHA':
          '0257aa67edc3db8174fc6049aa2a752f6ff4a4c1de0ce31dac751dd798fca83e',
      'body': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001369&dcmNo=10439334&eleId=19&offset=202135&length=445&dtd=dart4.xsd',
      'bodySHA':
          '133d0fd797042ecc262d10b277faa717e93c0fd0dd9f00a3712caf840d74ac64',
    },
    '20240320001279': {
      'year': 2023,
      'cover': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240320001279&dcmNo=9739334&eleId=1&offset=955&length=4031&dtd=dart4.xsd',
      'coverSHA':
          '5faa5d6b4b61e4decfc6432d9cfa753ec1401ceb99effff82dd0c91d4b871895',
      'body': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240320001279&dcmNo=9739334&eleId=19&offset=179564&length=378&dtd=dart4.xsd',
      'bodySHA':
          'e7de72d71d6291a2dc74082c833d0f28c413f106ed3162e3f66272ad1dc1e36d',
    },
    '20230321001331': {
      'year': 2022,
      'cover': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001331&dcmNo=9084601&eleId=1&offset=796&length=4028&dtd=dart3.xsd',
      'coverSHA':
          '4f45b1df2a61604e247f8c23ce221f560924b7dff91a38a977f1b050bdb90844',
      'body': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001331&dcmNo=9084601&eleId=19&offset=188238&length=366&dtd=dart3.xsd',
      'bodySHA':
          'e7de72d71d6291a2dc74082c833d0f28c413f106ed3162e3f66272ad1dc1e36d',
    },
  };
  static bool _historicalMatch(
    String receipt,
    String corp,
    DateTime start,
    DateTime end,
    Uri coverSource,
    String cover,
    Uri statementSource,
    String body,
  ) {
    final p = historical[receipt];
    if (p == null) return false;
    final year = p['year'] as int;
    return corp == '01353848' &&
        start == DateTime.utc(year) &&
        end == DateTime.utc(year, 12, 31) &&
        coverSource.toString() == p['cover'] &&
        statementSource.toString() == p['body'] &&
        sha256.convert(utf8.encode(cover)).toString() == p['coverSHA'] &&
        sha256.convert(utf8.encode(body)).toString() == p['bodySHA'];
  }

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
      _historicalMatch(
        receipt,
        corp,
        start,
        end,
        coverSource,
        cover,
        statementSource,
        body,
      ) ||
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
