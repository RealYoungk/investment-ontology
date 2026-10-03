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
    if (receipt == '20220329001197' &&
        corpCode == '01118643' &&
        periodEnd == DateTime.utc(2021, 12, 31) &&
        normalize(currentName) == '솔루믹스' &&
        normalize(printedName) == '로보쓰리' &&
        coverSource.toString() ==
            'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220329001197&dcmNo=8514239&eleId=3&offset=24923&length=4004&dtd=dart3.xsd' &&
        sha256.convert(utf8.encode(coverHtml)).toString() ==
            'cbbd67fb9cb6378c14c955c8959d2fd76ac6222f6983c685ea7ab37568d99357') {
      return {
        'currentName': currentName,
        'printedHistoricalName': printedName,
        'receipt': receipt,
        'corpCode': corpCode,
        'periodEnd': '2021-12-31',
        'basis': consolidated ? 'CFS' : 'OFS',
        'evidence': '2023.03.31 Robo3→Robo3 AI & Robotics; 2024.03.27→Robo3 AI; 2026.03.30→Solumix. Actual official final change notice read, no proposed-vote substitution.',
        'coverSha256':
            'cbbd67fb9cb6378c14c955c8959d2fd76ac6222f6983c685ea7ab37568d99357',
        'historicalOwnShellSha256':
            '88625eb0bdef0f62a8c32df0c9dc718ba1f8215eedba3a4405c832f96beeb377',
        'legalNameEvidenceSource': 'https://kind.krx.co.kr/external/2026/03/30/001272/20260330003364/33013.htm',
        'legalNameEvidenceSha256':
            '9cec3f5c7ae448095c373189612fde0d7127eee025f2924a064343b5d88c80f6',
        'numericApproval': 'false',
      };
    }
    if (receipt == '20220321000965' &&
        corpCode == '01267958' &&
        periodEnd == DateTime.utc(2021, 12, 31) &&
        normalize(currentName) == '프로티아' &&
        normalize(printedName) == '프로테옴텍' &&
        coverSource.toString() ==
            'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220321000965&dcmNo=8484101&eleId=1&offset=797&length=4078&dtd=dart3.xsd' &&
        sha256.convert(utf8.encode(coverHtml)).toString() ==
            '4a3355b27eeca7a1e56350bdeb0565f61b5486b1c9bceefcdc507d4d118ab3a3') {
      return {
        'currentName': currentName,
        'printedHistoricalName': printedName,
        'receipt': receipt,
        'corpCode': corpCode,
        'periodEnd': '2021-12-31',
        'basis': consolidated ? 'CFS' : 'OFS',
        'evidence': 'Official change listing explicitly prints Proteometech→Protia, listing date2023-11-15; own historical DART shell has exactcorp01267958.',
        'coverSha256':
            '4a3355b27eeca7a1e56350bdeb0565f61b5486b1c9bceefcdc507d4d118ab3a3',
        'historicalOwnShellSha256':
            'da6b0accb8b3df3d584b028438baa5347f9ab16b78f0347cb71d919ed5a3d7f0',
        'legalNameEvidenceSource': 'https://kind.krx.co.kr/external/2023/11/10/000765/20231110001790/70765.htm',
        'legalNameEvidenceSha256':
            '0593f8582101e41e127067476f2f6f02d8191ef9d797c16e8348471a455dcaa5',
        'numericApproval': 'false',
      };
    }
    if (receipt == '20230328000161' &&
        corpCode == '01315042' &&
        periodEnd == DateTime.utc(2022, 12, 31) &&
        normalize(currentName) == '시선에이아이' &&
        normalize(printedName) == '씨유박스' &&
        consolidated &&
        coverSource.toString() ==
            'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230328000161&dcmNo=9107520&eleId=3&offset=68972&length=4035&dtd=dart3.xsd' &&
        sha256.convert(utf8.encode(coverHtml)).toString() ==
            '4b07b798a585689b102478a7fe0173c66227c46964887de59b92dd39fd154d20') {
      return {
        'currentName': currentName,
        'printedHistoricalName': printedName,
        'receipt': receipt,
        'corpCode': corpCode,
        'periodEnd': '2022-12-31',
        'basis': consolidated ? 'CFS' : 'OFS',
        'evidence': 'Official change notice explicitly prints CUBOX→SECERN AI, shareholder meeting2025-03-26; own historical DART shell has exactcorp01315042.',
        'coverSha256':
            '4b07b798a585689b102478a7fe0173c66227c46964887de59b92dd39fd154d20',
        'historicalOwnShellSha256':
            '4eb0888dd921cd86c226e37c8f6845bdebbf305d9da3b192bb410f1e7e98a1c0',
        'legalNameEvidenceSource': 'https://kind.krx.co.kr/external/2025/03/26/000453/20250227001255/70659.htm',
        'legalNameEvidenceSha256':
            'dfdb7ddf7159555fbeb1d8d6a8d0b0602c0c7d992d97710a9702473fac62553d',
        'numericApproval': 'false',
      };
    }
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
