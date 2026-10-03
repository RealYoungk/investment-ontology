import 'dart:convert';

import 'package:crypto/crypto.dart';

abstract final class DbExactIssuerIdentity {
  static const hashes = {
    'shell': '58644dd2dfb0f6ab3b607d3f7ad0366121727415b796efa74cfe2a6927c44b9e',
    'cover': 'a3186d785df89fd3d29e84bd47350f53b2e364631fd64e64e8458a3aebeb2594',
    'overview':
        'fa5f0d69cf639d774db91c9991846e0dd09f6864387488e946ea27cbd20302b8',
    'ofs': '193bde6106924754c0b80f48082e7dc84eb26505e30d43270834b708c0e93b37',
  };
  static const urls = {
    'shell': 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20220316001241',
    'cover': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220316001241&dcmNo=8467337&eleId=1&offset=792&length=4026&dtd=dart3.xsd',
    'overview': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220316001241&dcmNo=8467337&eleId=3&offset=5896&length=161362&dtd=dart3.xsd',
    'ofs': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220316001241&dcmNo=8467337&eleId=19&offset=1389667&length=79959&dtd=dart3.xsd',
  };
  static Map<String, dynamic> verify(
    Map<String, String> raw, {
    required String receipt,
    required String corp,
    required String currentName,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
  }) {
    if (receipt != '20220316001241' ||
        corp != '00115694' ||
        currentName != 'DB증권(주)' ||
        consolidated ||
        start != DateTime.utc(2021) ||
        end != DateTime.utc(2021, 12, 31) ||
        raw.length != 4 ||
        hashes.entries.any(
          (e) =>
              raw[e.key] == null ||
              sha256.convert(utf8.encode(raw[e.key]!)).toString() != e.value,
        )) {
      throw const FormatException('Invalid exact DB issuer source bundle');
    }
    return {
      'kind': 'exact-own-filing-self-declared-issuer',
      'receipt': receipt,
      'corpCode': corp,
      'currentMasterName': currentName,
      'printedCoverName': 'DB금융투자 주식회사',
      'selfDeclaredName': '디비금융투자 주식회사',
      'selfDeclaredEnglishName': 'DB Financial Investment Co., Ltd.',
      'overviewSource': urls['overview'],
      'sourceHashes': hashes,
      'globalAlias': false,
    };
  }
}
