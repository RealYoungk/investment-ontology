import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Receipt-bound historical cover identity; not a general alias registry.
abstract final class VerifiedHistoricalCompanyIdentity {
  static const skConsolidatedUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001633&dcmNo=10440936&eleId=19&offset=204119&length=101809&dtd=dart4.xsd';
  static const skConsolidatedSha =
      '463c1dea92866224008c5e4f8bb8745e8defd3266c49c5902db423f8194f9a54';
  static bool boundSkConsolidated(Uri source, String body) =>
      source.toString() == skConsolidatedUri &&
      sha256.convert(utf8.encode(body)).toString() == skConsolidatedSha;
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
    if (receipt == '20250320001633' &&
        corpCode == '01188730' &&
        periodEnd == DateTime.utc(2024, 12, 31) &&
        normalize(currentName) == 'SK시그넷' &&
        normalize(printedName) == '에스케이시그넷' &&
        coverSource.toString() ==
            'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001633&dcmNo=10440936&eleId=1&offset=958&length=4511&dtd=dart4.xsd' &&
        sha256.convert(utf8.encode(coverHtml)).toString() ==
            '397be826b3698513bf845fe91851584fc70520480c1763c9638c778c9e40d3b6') {
      return {
        'currentName': currentName,
        'printedHistoricalName': printedName,
        'receipt': receipt,
        'corpCode': corpCode,
        'periodEnd': '2024-12-31',
        'basis': consolidated ? 'CFS' : 'OFS',
        'evidence': 'Same official report explicitly declares 에스케이시그넷 주식회사(영문명: SK Signet Inc.); declared official domain identifies SK시그넷(주). Exact receipt only, no general transliteration.',
        'coverSha256':
            '397be826b3698513bf845fe91851584fc70520480c1763c9638c778c9e40d3b6',
        if (consolidated) 'financialStatementSource': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001633&dcmNo=10440936&eleId=19&offset=204119&length=101809&dtd=dart4.xsd',
        if (consolidated) 'financialStatementSha256': '463c1dea92866224008c5e4f8bb8745e8defd3266c49c5902db423f8194f9a54',
        'legalNameEvidenceSource': "https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001633&dcmNo=10440936&eleId=4&offset=6152&length=10028&dtd=dart4.xsd",
        'legalNameEvidenceSha256':
            "01c75ae88aca78256aaa4a2924ef89cd0673a908d0bc4d80c2523a7452d59a90",
      };
    }
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
