import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Only the two immutable own-issuer consolidated statements; not an opt-in flag.
abstract final class SamsungFireCfsSource {
  static const _profiles = {
    '20220310001159': (
      year: 2021,
      cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220310001159&dcmNo=8450801&eleId=1&offset=812&length=4017&dtd=dart3.xsd',
      body: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220310001159&dcmNo=8450801&eleId=17&offset=422472&length=145689&dtd=dart3.xsd',
      coverSha:
          'c1b7dce39f4c357f4c5462e0ae8c6198d1ff38d6befc087dd81d200a2b999c9c',
      bodySha:
          '48a5a3b134b1f86a9fe8d06322c28095d9ec497164703fcd50be06918b6badc6',
    ),
    '20230309000772': (
      year: 2022,
      cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230309000772&dcmNo=9045617&eleId=1&offset=804&length=4016&dtd=dart3.xsd',
      body: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230309000772&dcmNo=9045617&eleId=17&offset=361888&length=142757&dtd=dart3.xsd',
      coverSha:
          'aab061362165c3709952c35344299ec58ed61ea2cd7199a4473d097b840f3629',
      bodySha:
          '11753ade08bda21c48249add001cb5accb4fb56b1505631ef1a954bd2be248fc',
    ),
  };
  static bool matches({
    required String receipt,
    required String corpCode,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Uri coverSource,
    required Uri statementSource,
    required String coverHtml,
    required String statementHtml,
  }) {
    final p = _profiles[receipt];
    return p != null &&
        corpCode == '00139214' &&
        consolidated &&
        start == DateTime.utc(p.year) &&
        end == DateTime.utc(p.year, 12, 31) &&
        coverSource.toString() == p.cover &&
        statementSource.toString() == p.body &&
        sha256.convert(utf8.encode(coverHtml)).toString() == p.coverSha &&
        sha256.convert(utf8.encode(statementHtml)).toString() == p.bodySha;
  }
}
