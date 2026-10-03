import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Four complete own CFS paragraphs; no generalized absence phrase grammar.
abstract final class OwnParagraphCfsAbsence {
  static final profiles = (jsonDecode(r'''[
  {
    "receipt": "20230315000894",
    "corp": "00162416",
    "year": 2022,
    "cover": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315000894&dcmNo=9059095&eleId=1&offset=785&length=4029&dtd=dart3.xsd",
    "coverSHA": "4c4c2572aa92f08b9fd46476c8cec4af13f206b3ea9ab9a5b6dd4a9e5bf0cdc8",
    "body": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315000894&dcmNo=9059095&eleId=17&offset=264476&length=139&dtd=dart3.xsd",
    "bodySHA": "9ee0d787dc2ad6d41da7b1109a7fd3e9397b97e573a21de9b32f968391e1cfe2",
    "issuer": "한양증권주식회사",
    "evidence": "- 해당사항 없음 -"
  },
  {
    "receipt": "20220315001266",
    "corp": "00162416",
    "year": 2021,
    "cover": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220315001266&dcmNo=8462555&eleId=1&offset=779&length=4029&dtd=dart3.xsd",
    "coverSHA": "cf242a467c53988c5f040d125e7a559f7e0463988e48e990931e2036c5961cd2",
    "body": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220315001266&dcmNo=8462555&eleId=17&offset=291183&length=130&dtd=dart3.xsd",
    "bodySHA": "283b55f1ac335ae51236582d4a8f8af950f722290eaaac9147e6e2f3912e3aef",
    "issuer": "한양증권주식회사",
    "evidence": "- 해당사항 없음 -"
  },
  {
    "receipt": "20220322001090",
    "corp": "01023822",
    "year": 2021,
    "cover": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220322001090&dcmNo=8493406&eleId=3&offset=62502&length=4036&dtd=dart3.xsd",
    "coverSHA": "b78a96c11d83a6444724062589c330652d9c745536ecd5c48c276be8af868058",
    "body": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220322001090&dcmNo=8493406&eleId=21&offset=234899&length=149&dtd=dart3.xsd",
    "bodySHA": "2bf98686981732719946a412799230aee4b9429c6fc20fcb737b11f602ee8391",
    "issuer": "주식회사메디젠휴먼케어",
    "evidence": "당기 연결대상 종속회사의 폐업으로 해당사항 없습니다."
  },
  {
    "receipt": "20250321001155",
    "corp": "01680131",
    "year": 2024,
    "cover": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20250321001155&dcmNo=10446634&eleId=1&offset=957&length=4522&dtd=dart4.xsd",
    "coverSHA": "9199e01dfabc60d516b2a25284251a5519098bb6565349b8898d21de69089521",
    "body": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20250321001155&dcmNo=10446634&eleId=19&offset=281452&length=299&dtd=dart4.xsd",
    "bodySHA": "07513e54895f549cb619ae80d32df9429a2abdb7a307e4a0d385de3894c9f621",
    "issuer": "주식회사아이오바이오",
    "evidence": "당사는 현재 일반기업회계기준 결산법인으로 연결대상 종속회사가 없습니다. 세부사항은 재무제표 주석 21. 특수관계자 거래를 참조하십시오."
  }
]''') as List).cast<Map<String, dynamic>>();
  static String compact(String v) =>
      v.replaceAll(RegExp(r'<[^>]*>|&nbsp;|\s'), '');
  static String? evidence({
    required String receipt,
    required String corp,
    required DateTime start,
    required DateTime end,
    required Uri coverSource,
    required String cover,
    required Uri statementSource,
    required String body,
  }) {
    final choices = profiles
        .where((p) => p['receipt'] == receipt && p['corp'] == corp)
        .toList();
    if (choices.length != 1) {
      return null;
    }
    final p = choices.single, year = p['year'] as int;
    if (start != DateTime.utc(year) ||
        end != DateTime.utc(year, 12, 31) ||
        coverSource.toString() != p['cover'] ||
        statementSource.toString() != p['body'] ||
        sha256.convert(utf8.encode(cover)).toString() != p['coverSHA'] ||
        sha256.convert(utf8.encode(body)).toString() != p['bodySHA'] ||
        !compact(cover).contains(p['issuer'] as String) ||
        compact(body) != "2.연결재무제표${compact(p['evidence'] as String)}") {
      return null;
    }
    return p['evidence'] as String;
  }
}
