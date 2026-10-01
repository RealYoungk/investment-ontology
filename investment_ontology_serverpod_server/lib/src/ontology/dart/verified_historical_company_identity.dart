import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Receipt-bound historical cover identity; not a general alias registry.
abstract final class VerifiedHistoricalCompanyIdentity {
  static String normalize(String name) =>
      name.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s+'), '');
  static Map<String, String>? evidence({
    required String receipt,
    required String corpCode,
    required String currentName,
    required String printedName,
    required DateTime periodEnd,
    required bool consolidated,
    required Uri coverSource,
    required String coverHtml,
  }) {
    if (coverSource.toString() !=
            'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001219&dcmNo=9083870&eleId=1&offset=784&length=3924&dtd=dart3.xsd' ||
        sha256.convert(utf8.encode(coverHtml)).toString() !=
            '3cc86ccee7cd434468865a4f32e1e0f1aa57472bf8d1fc53ed796d130050fe8d' ||
        receipt != '20230321001219' ||
        corpCode != '00115694' ||
        consolidated ||
        periodEnd != DateTime.utc(2022, 12, 31) ||
        normalize(currentName) != 'DB증권' ||
        normalize(printedName) != 'DB금융투자') {
      return null;
    }
    return {
      'currentName': currentName,
      'printedHistoricalName': printedName,
      'receipt': receipt,
      'corpCode': corpCode,
      'periodEnd': '2022-12-31',
      'basis': 'OFS',
      'evidence': 'Exact official receipt/corp-bound annual cover prints DB금융투자주식회사; current official shell title DB증권',
      'coverSha256':
          '3cc86ccee7cd434468865a4f32e1e0f1aa57472bf8d1fc53ed796d130050fe8d',
    };
  }
}
