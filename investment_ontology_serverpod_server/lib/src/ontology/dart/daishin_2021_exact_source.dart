import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Two pinned own FY2021 bases; cash plus deposit is not CF cash.
abstract final class Daishin2021ExactSource {
  static final List _profiles = jsonDecode(
    r'''[{"basis": "cfs", "rule": "daishin-2021-cfs-exact-cash-scope-eight-v1", "sources": [{"label": "shell", "file": "shell.html", "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20220516001812", "sha256": "d75e24df1980c162785f40dc17875abca930f6fea362876cef82e455469fe784"}, {"label": "cover", "file": "cover.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220516001812&dcmNo=8664820&eleId=3&offset=267417&length=4032&dtd=dart3.xsd", "sha256": "0cb333f7084941ed1c862b65b37fc3da1cd7241d5bc3396885701e46a7e90d95"}, {"label": "cfs", "file": "cfs.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220516001812&dcmNo=8664820&eleId=19&offset=1225630&length=87529&dtd=dart3.xsd", "sha256": "f7fcb555e61003197c47d13bea5333619336953e2902003390e8529960ee29ae"}, {"label": "notes", "file": "notes.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220516001812&dcmNo=8664820&eleId=20&offset=1313163&length=1545295&dtd=dart3.xsd", "sha256": "5abccce3468d8a1d445e4e01a9adf451496d702ddd67ff71d84d5c9647092c27"}], "rows": [{"index": 21, "column": 2, "kind": "BS", "label": "자 산 총 계", "printed": "22,763,241,909"}, {"index": 36, "column": 2, "kind": "BS", "label": "부 채 총 계", "printed": "20,110,035,373"}, {"index": 45, "column": 2, "kind": "BS", "label": "자 본 총 계", "printed": "2,653,206,536"}, {"index": 53, "column": 2, "kind": "CIS", "label": "Ⅰ. 영업수익", "printed": "3,635,331,998"}, {"index": 76, "column": 2, "kind": "CIS", "label": "Ⅲ. 영업손익", "printed": "885,548,890"}, {"index": 82, "column": 2, "kind": "CIS", "label": "Ⅶ. 당기연결순손익", "printed": "615,822,762"}, {"index": 141, "column": 2, "kind": "CF", "label": "Ⅰ. 영업활동으로부터의 현금흐름", "printed": "(1,402,568,980)"}, {"index": 192, "column": 1, "kind": "CF", "label": "8. 유형자산의 취득", "printed": "(22,046,693)"}], "rowCount": 218, "witnesses": {"1": ["제61(당)기 2021년 12월 31일 현재"], "3": ["대신증권주식회사와 그 종속기업", "(단위 : 천원)"], "4": ["과 목", "제61(당)기말", "제60(전)기말"], "49": ["제61(당)기 2021년 1월 1일부터 2021년 12월 31일까지"], "51": ["대신증권주식회사와 그 종속기업", "(단위 : 천원)"], "52": ["과 목", "제61(당)기", "제60(전)기"], "102": ["제61(당)기 2021년 1월 1일부터 2021년 12월 31일까지"], "104": ["대신증권주식회사와 그 종속기업", "(단위 : 천원)"], "105": ["과 목", "지배기업주주지분", "비지배지분", "총 계"], "106": ["자본금", "자 본 잉여금", "기 타 포 괄 손익누계액", "이 익 잉여금", "자본조정", "지배기업 주주지분 소계"], "137": ["제61(당)기 2021년 1월 1일부터 2021년 12월 31일까지"], "139": ["대신증권주식회사와 그 종속기업", "(단위 : 천원)"], "140": ["과 목", "제61(당)기", "제60(전)기"], "121": ["2021.1.1(당기초)", "434,867,000", "694,981,258", "138,621,949", "1,032,325,065", "(252,532,232)", "2,048,263,040", "29,105,665", "2,077,368,705"], "134": ["2021.12.31(당기말)", "434,867,000", "694,981,258", "163,528,518", "1,568,905,427", "(240,620,523)", "2,621,661,680", "31,544,856", "2,653,206,536"]}, "notesWitnesses": {"1515": ["구분", "예치기관", "당기말", "전기말"], "1516": ["현금및현금성자산", "신한은행 외", "692,899,535", "704,217,991"], "1517": ["투자자예탁금별도예치금(예금)", "한국증권금융 외", "345,829,149", "357,969,593"], "1518": ["투자자예탁금별도예치금(신탁)", "한국증권금융", "2,559,490,149", "2,616,280,330"], "1519": ["대차거래이행보증금", "한국증권금융", "-", "50,000,000"], "1520": ["선물옵션거래예치금", "Societe Generale 외", "73,798,974", "71,538,391"], "1521": ["지급준비예치금", "저축은행중앙회", "88,403,076", "72,932,544"], "1522": ["중앙회예치금", "저축은행중앙회", "85,000,000", "101,000,000"], "1523": ["유통금융차주담보금", "한국증권금융", "920,425", "-"], "1524": ["장기성예금", "국민은행 외", "214,029,503", "114,194,940"], "1525": ["특정예금", "국민은행 외", "42,000", "42,000"], "1526": ["기타예치금", "미래에셋대우", "72,513,438", "51,145,691"], "1527": ["예치금신용손실충당금", "", "(452,375)", "(187,337)"], "1528": ["합계", "", "4,132,473,874", "4,139,134,143"], "3000": ["구분", "당기말", "전기말"], "3001": ["보유현금", "41,791", "4,550"], "3002": ["보통예금", "367,145,887", "335,239,641"], "3003": ["당좌예금", "4,113,785", "5,012,085"], "3004": ["외화예금", "161,410,331", "70,981,403"], "3005": ["MMDA", "35,829,606", "142,064,681"], "3006": ["기타", "124,358,135", "150,915,631"], "3007": ["합계", "692,899,535", "704,217,991"]}, "definition": "연결현금흐름표상의 현금및현금성자산은 연결재무상태표상의 현금및예치금에서 주석7의 예치금을 차감한 금액입니다.", "equations": [{"result": ["statement", 21, 2, 1], "terms": [["statement", 36, 2, 1], ["statement", 45, 2, 1]]}, {"result": ["statement", 76, 2, 1], "terms": [["statement", 53, 2, 1], ["statement", 63, 2, -1]]}, {"result": ["statement", 80, 2, 1], "terms": [["statement", 76, 2, 1], ["statement", 77, 2, 1]]}, {"result": ["statement", 82, 2, 1], "terms": [["statement", 80, 2, 1], ["statement", 81, 2, -1]]}, {"result": ["statement", 123, 8, 1], "terms": [["statement", 82, 2, 1]]}, {"result": ["statement", 142, 1, 1], "terms": [["statement", 82, 2, 1]]}, {"result": ["statement", 134, 8, 1], "terms": [["statement", 45, 2, 1]]}, {"result": ["statement", 121, 8, 1], "terms": [["statement", 45, 4, 1]]}, {"result": ["statement", 134, 8, 1], "terms": [["statement", 121, 8, 1], ["statement", 123, 8, 1], ["statement", 124, 8, 1], ["statement", 125, 8, 1], ["statement", 126, 8, 1], ["statement", 127, 8, 1], ["statement", 128, 8, 1], ["statement", 130, 8, 1], ["statement", 131, 8, 1], ["statement", 132, 8, 1], ["statement", 133, 8, 1]]}, {"result": ["statement", 86, 2, 1], "terms": [["statement", 82, 2, 1], ["statement", 83, 2, 1]]}, {"result": ["statement", 83, 2, 1], "terms": [["statement", 124, 8, 1], ["statement", 125, 8, 1], ["statement", 126, 8, 1], ["statement", 127, 8, 1], ["statement", 128, 8, 1]]}, {"result": ["statement", 214, 2, 1], "terms": [["statement", 141, 2, 1], ["statement", 184, 2, 1], ["statement", 201, 2, 1], ["statement", 213, 2, 1]]}, {"result": ["statement", 216, 2, 1], "terms": [["statement", 215, 2, 1], ["statement", 214, 2, 1]]}, {"result": ["notes", 1528, 2, 1], "terms": [["notes", 1516, 2, 1], ["notes", 1517, 2, 1], ["notes", 1518, 2, 1], ["notes", 1519, 2, 1], ["notes", 1520, 2, 1], ["notes", 1521, 2, 1], ["notes", 1522, 2, 1], ["notes", 1523, 2, 1], ["notes", 1524, 2, 1], ["notes", 1525, 2, 1], ["notes", 1526, 2, 1], ["notes", 1527, 2, 1]]}, {"result": ["statement", 6, 2, 1], "terms": [["notes", 1528, 2, 1]]}, {"result": ["statement", 216, 2, 1], "terms": [["notes", 1516, 2, 1]]}, {"result": ["notes", 3007, 1, 1], "terms": [["notes", 3001, 1, 1], ["notes", 3002, 1, 1], ["notes", 3003, 1, 1], ["notes", 3004, 1, 1], ["notes", 3005, 1, 1], ["notes", 3006, 1, 1]]}, {"result": ["statement", 216, 2, 1], "terms": [["notes", 3007, 1, 1]]}, {"result": ["notes", 1528, 3, 1], "terms": [["notes", 1516, 3, 1], ["notes", 1517, 3, 1], ["notes", 1518, 3, 1], ["notes", 1519, 3, 1], ["notes", 1520, 3, 1], ["notes", 1521, 3, 1], ["notes", 1522, 3, 1], ["notes", 1523, 3, 1], ["notes", 1524, 3, 1], ["notes", 1525, 3, 1], ["notes", 1526, 3, 1], ["notes", 1527, 3, 1]]}, {"result": ["statement", 6, 4, 1], "terms": [["notes", 1528, 3, 1]]}, {"result": ["statement", 215, 2, 1], "terms": [["notes", 1516, 3, 1]]}, {"result": ["notes", 3007, 2, 1], "terms": [["notes", 3001, 2, 1], ["notes", 3002, 2, 1], ["notes", 3003, 2, 1], ["notes", 3004, 2, 1], ["notes", 3005, 2, 1], ["notes", 3006, 2, 1]]}, {"result": ["statement", 215, 2, 1], "terms": [["notes", 3007, 2, 1]]}], "notesScope": "cash definition and printed cash/deposit components only", "fullNotesVerified": false, "priorFactsExtracted": 0, "manifestDigest": "71448e5cc95fe129bc60ca2cd402a6ea02eb944aa4e3b78207e59cfcf3ee500d"}, {"basis": "ofs", "rule": "daishin-2021-ofs-exact-cash-scope-eight-v1", "sources": [{"label": "shell", "file": "shell.html", "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20220516001812", "sha256": "d75e24df1980c162785f40dc17875abca930f6fea362876cef82e455469fe784"}, {"label": "cover", "file": "cover.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220516001812&dcmNo=8664820&eleId=3&offset=267417&length=4032&dtd=dart3.xsd", "sha256": "0cb333f7084941ed1c862b65b37fc3da1cd7241d5bc3396885701e46a7e90d95"}, {"label": "ofs", "file": "ofs.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220516001812&dcmNo=8664820&eleId=21&offset=2858462&length=68209&dtd=dart3.xsd", "sha256": "8f601b2199394da806c8eca6bdf49b820905385083879ef33e2629b64c6f18c8"}, {"label": "notes", "file": "notes.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220516001812&dcmNo=8664820&eleId=22&offset=2926675&length=923145&dtd=dart3.xsd", "sha256": "93e48dbe09d9a1919b1d9661f906ac2fef9be757aa9ba76601a77f9ac46c309c"}], "rows": [{"index": 18, "column": 2, "kind": "BS", "label": "자 산 총 계", "printed": "15,138,810,188"}, {"index": 32, "column": 2, "kind": "BS", "label": "부 채 총 계", "printed": "13,112,533,710"}, {"index": 39, "column": 2, "kind": "BS", "label": "자 본 총 계", "printed": "2,026,276,478"}, {"index": 47, "column": 2, "kind": "CIS", "label": "Ⅰ. 영업수익", "printed": "2,432,183,746"}, {"index": 66, "column": 2, "kind": "CIS", "label": "Ⅲ. 영업이익", "printed": "281,812,111"}, {"index": 72, "column": 2, "kind": "CIS", "label": "Ⅶ. 당기순이익 (대손준비금반영후 조정이익 당 기: 178,664백만원 전기: 175,386 백만원)(주 석24)", "printed": "178,657,494"}, {"index": 117, "column": 2, "kind": "CF", "label": "Ⅰ. 영업활동으로부터의 현금흐름", "printed": "143,066,240"}, {"index": 161, "column": 1, "kind": "CF", "label": "9. 유형자산의 취득", "printed": "(20,151,542)"}], "rowCount": 180, "witnesses": {"1": ["제61(당)기 2021년 12월 31일 현재"], "3": ["대신증권주식회사", "(단위 : 천원)"], "4": ["과 목", "제61(당)기 말", "제60(전)기말"], "43": ["제61(당)기 2021년 1월 1일부터 2021년 12월 31일까지"], "45": ["대신증권주식회사", "(단위 : 천원)"], "46": ["과 목", "제61(당)기", "제60(전)기"], "85": ["제61(당)기 2021년 1월 1일부터 2021년 12월 31일까지"], "87": ["대신증권주식회사", "(단위 : 천원)"], "88": ["과 목", "자본금", "자 본 잉여금", "기 타 포 괄 손익누계액", "이 익 잉여금", "자본조정", "총 계"], "113": ["제61(당)기 2021년 1월 1일부터 2021년 12월 31일까지"], "115": ["대신증권주식회사", "(단위 : 천원)"], "116": ["과 목", "제61(당)기", "제60(전)기"], "100": ["2021.1.1(당기초)", "434,867,000", "694,981,258", "148,329,454", "872,086,492", "(247,586,480)", "1,902,677,724"], "110": ["2021.12.31(당기말)", "434,867,000", "694,981,258", "159,309,559", "970,745,247", "(233,626,586)", "2,026,276,478"]}, "notesWitnesses": {"484": ["구분", "예치기관", "당기말", "전기말"], "485": ["현금및현금성자산", "신한은행 외", "211,853,659", "344,667,583"], "486": ["투자자예탁금별도예치금(예금)", "한국증권금융 외", "345,829,149", "357,969,593"], "487": ["투자자예탁금별도예치금(신탁)", "한국증권금융", "2,559,490,149", "2,616,280,329"], "488": ["대차거래이행보증금", "한국증권금융", "-", "50,000,000"], "489": ["선물옵션거래예치금", "Societe Generale 외", "73,073,478", "70,228,311"], "490": ["유통금융차주담보금", "한국증권금융", "920,424", "-"], "491": ["장기성예금", "국민은행 외", "152,082,420", "82,082,420"], "492": ["특정예금", "국민은행 외", "35,000", "35,000"], "493": ["예치금신용손실충당금", "", "(438,438)", "(170,954)"], "494": ["합계", "", "3,342,845,841", "3,521,092,282"], "1708": ["구분", "당기말", "전기말"], "1709": ["보통예금", "5,054,915", "7,620,934"], "1710": ["당좌예금", "4,113,785", "3,616,650"], "1711": ["외화예금", "129,224,234", "62,602,326"], "1712": ["MMDA", "-", "139,800,000"], "1713": ["금융어음", "20,000,000", "10,000,000"], "1714": ["기타", "53,460,725", "121,027,673"], "1715": ["합계", "211,853,659", "344,667,583"]}, "definition": "현금흐름표상의 현금및현금성자산은 재무상태표상의 현금및예치금에서 주석6의 예치금을 차감한 금액입니다.", "equations": [{"result": ["statement", 18, 2, 1], "terms": [["statement", 32, 2, 1], ["statement", 39, 2, 1]]}, {"result": ["statement", 66, 2, 1], "terms": [["statement", 47, 2, 1], ["statement", 55, 2, -1]]}, {"result": ["statement", 70, 2, 1], "terms": [["statement", 66, 2, 1], ["statement", 67, 2, 1]]}, {"result": ["statement", 72, 2, 1], "terms": [["statement", 70, 2, 1], ["statement", 71, 2, -1]]}, {"result": ["statement", 102, 6, 1], "terms": [["statement", 72, 2, 1]]}, {"result": ["statement", 118, 1, 1], "terms": [["statement", 72, 2, 1]]}, {"result": ["statement", 110, 6, 1], "terms": [["statement", 39, 2, 1]]}, {"result": ["statement", 100, 6, 1], "terms": [["statement", 39, 4, 1]]}, {"result": ["statement", 110, 6, 1], "terms": [["statement", 100, 6, 1], ["statement", 102, 6, 1], ["statement", 103, 6, 1], ["statement", 104, 6, 1], ["statement", 105, 6, 1], ["statement", 107, 6, 1], ["statement", 108, 6, 1], ["statement", 109, 6, 1]]}, {"result": ["statement", 75, 2, 1], "terms": [["statement", 72, 2, 1], ["statement", 73, 2, 1]]}, {"result": ["statement", 73, 2, 1], "terms": [["statement", 103, 6, 1], ["statement", 104, 6, 1], ["statement", 105, 6, 1]]}, {"result": ["statement", 176, 2, 1], "terms": [["statement", 117, 2, 1], ["statement", 152, 2, 1], ["statement", 165, 2, 1], ["statement", 175, 2, 1]]}, {"result": ["statement", 178, 2, 1], "terms": [["statement", 177, 2, 1], ["statement", 176, 2, 1]]}, {"result": ["notes", 494, 2, 1], "terms": [["notes", 485, 2, 1], ["notes", 486, 2, 1], ["notes", 487, 2, 1], ["notes", 488, 2, 1], ["notes", 489, 2, 1], ["notes", 490, 2, 1], ["notes", 491, 2, 1], ["notes", 492, 2, 1], ["notes", 493, 2, 1]]}, {"result": ["statement", 6, 2, 1], "terms": [["notes", 494, 2, 1]]}, {"result": ["statement", 178, 2, 1], "terms": [["notes", 485, 2, 1]]}, {"result": ["notes", 1715, 1, 1], "terms": [["notes", 1709, 1, 1], ["notes", 1710, 1, 1], ["notes", 1711, 1, 1], ["notes", 1712, 1, 1], ["notes", 1713, 1, 1], ["notes", 1714, 1, 1]]}, {"result": ["statement", 178, 2, 1], "terms": [["notes", 1715, 1, 1]]}, {"result": ["notes", 494, 3, 1], "terms": [["notes", 485, 3, 1], ["notes", 486, 3, 1], ["notes", 487, 3, 1], ["notes", 488, 3, 1], ["notes", 489, 3, 1], ["notes", 490, 3, 1], ["notes", 491, 3, 1], ["notes", 492, 3, 1], ["notes", 493, 3, 1]]}, {"result": ["statement", 6, 4, 1], "terms": [["notes", 494, 3, 1]]}, {"result": ["statement", 177, 2, 1], "terms": [["notes", 485, 3, 1]]}, {"result": ["notes", 1715, 2, 1], "terms": [["notes", 1709, 2, 1], ["notes", 1710, 2, 1], ["notes", 1711, 2, 1], ["notes", 1712, 2, 1], ["notes", 1713, 2, 1], ["notes", 1714, 2, 1]]}, {"result": ["statement", 177, 2, 1], "terms": [["notes", 1715, 2, 1]]}], "notesScope": "cash definition and printed cash/deposit components only", "fullNotesVerified": false, "priorFactsExtracted": 0, "preservedClassificationDifferences": [{"scope": "same own notes: unrestricted cash/deposit table vs use-restriction table", "items": [{"label": "투자자예탁금별도예치금(신탁)", "period": "prior2020", "cashDetailPrinted": "2,616,280,329", "restrictionPrinted": "2,616,280,330"}, {"label": "유통금융차주담보금", "period": "current2021", "cashDetailPrinted": "920,424", "restrictionPrinted": "920,425"}], "numericCorrection": false, "wholeNotesVerified": false}], "manifestDigest": "e1b54a7d01eec3df7c9a5e104156b68258b844ae698d0cc88a75871733b90035"}]''',
  ) as List;
  static List get profiles => jsonDecode(jsonEncode(_profiles)) as List;
  static bool supports(String rule) => _profiles.any((p) => p['rule'] == rule);
  static List<Map<String, dynamic>> parse({
    required Map<String, String> raw,
    required Map<String, Uri> uris,
    required String receipt,
    required String corp,
    required DateTime start,
    required DateTime end,
    required bool consolidated,
  }) {
    final basis = consolidated ? 'cfs' : 'ofs';
    final p = _profiles.singleWhere((p) => p['basis'] == basis) as Map;
    if (receipt != '20220516001812' ||
        corp != '00110893' ||
        start != DateTime.utc(2021) ||
        end != DateTime.utc(2021, 12, 31)) {
      throw const FormatException(
        'Daishin FY2021 exact identity/period mismatch',
      );
    }
    for (final s in p['sources'] as List) {
      final label = s['label'] as String;
      if (uris[label]?.toString() != s['url'] ||
          raw[label] == null ||
          sha256.convert(utf8.encode(raw[label]!)).toString() != s['sha256']) {
        throw const FormatException(
          'Daishin FY2021 exact own URI/SHA mismatch',
        );
      }
    }
    String text(String h) => h
        .replaceAll(RegExp('<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cover = text(raw['cover']!);
    final actors = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
        .allMatches(raw['shell']!)
        .map((m) => m[1])
        .toSet();
    if (actors.length != 1 ||
        actors.single != corp ||
        !cover.contains('대신증권 주식회사') ||
        !cover.contains('2021년 01월 01일') ||
        !cover.contains('2021년 12월 31일')) {
      throw const FormatException('Daishin FY2021 own cover/actor mismatch');
    }
    List<List<String>> rows(String html) => [
      for (final tr in RegExp(
        r'<tr\b[^>]*>(.*?)</tr>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(html))
        [
          for (final c in RegExp(
            r'<t[dh]\b[^>]*>(.*?)</t[dh]>',
            caseSensitive: false,
            dotAll: true,
          ).allMatches(tr[1]!))
            text(c[1]!),
        ],
    ];
    final statement = rows(raw[basis]!);
    final notes = rows(raw['notes']!);
    if (statement.length != p['rowCount'] ||
        !text(raw['notes']!).contains(p['definition'] as String)) {
      throw const FormatException('Daishin FY2021 direct scope mismatch');
    }
    for (final item in [
      (statement, p['witnesses'] as Map),
      (notes, p['notesWitnesses'] as Map),
    ]) {
      for (final e in item.$2.entries) {
        if (item.$1[int.parse(e.key as String)].join('|') !=
            (e.value as List).join('|')) {
          throw const FormatException(
            'Daishin FY2021 printed headers/notes changed',
          );
        }
      }
    }
    BigInt money(String v) => v == '-'
        ? BigInt.zero
        : BigInt.parse(
            v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
          );
    BigInt amount(List cell) => money(
      (cell[0] == 'statement' ? statement : notes)[cell[1] as int][cell[2]
          as int],
    );
    for (final e in p['equations'] as List) {
      final sum = (e['terms'] as List).fold(
        BigInt.zero,
        (a, t) => a + amount(t) * BigInt.from(t[3] as int),
      );
      if (amount(e['result'] as List) != sum) {
        throw const FormatException(
          'Daishin FY2021 current source reconciliation conflict',
        );
      }
    }
    final result = <Map<String, dynamic>>[];
    for (final spec in p['rows'] as List) {
      final row = statement[spec['index'] as int], col = spec['column'] as int;
      if (row.first != spec['label'] || row[col] != spec['printed']) {
        throw const FormatException('Daishin FY2021 direct cell mismatch');
      }
      final printed = money(row[col]);
      final normalized = result.length == 7 ? printed.abs() : printed;
      result.add({
        'rcept_no': receipt,
        'corp_code': corp,
        'bsns_year': '2021',
        'reprt_code': '11011',
        'account_id': null,
        'account_nm': row.first,
        'account_detail': '-',
        'sj_div': spec['kind'],
        'thstrm_nm': spec['kind'] == 'BS'
            ? '2021-12-31'
            : '2021-01-01~2021-12-31',
        'thstrm_amount': (normalized * BigInt.from(1000)).toString(),
        'currency': 'KRW',
        'html_provenance': {
          'source': uris[basis].toString(),
          'sourceReceipt': receipt,
          'ruleVersion': p['rule'],
          'sourceSha256': (p['sources'] as List).singleWhere(
            (s) => s['label'] == basis,
          )['sha256'],
          'printedLabel': row.first,
          'printedAmount': row[col],
          'htmlTrIndex': spec['index'],
          'currentColumn': col,
          'unit': '천원',
          'unitMultiplier': '1000',
          'basis': basis.toUpperCase(),
          'periodStart': '2021-01-01',
          'periodEnd': '2021-12-31',
          'directCurrentCoreRows': 8,
          'priorFactsExtracted': 0,
          'fullStatementCollected': false,
          'fullNotesVerified': false,
          'cashScopeProof': {
            'notesSource': uris['notes'].toString(),
            'notesSha256': (p['sources'] as List).singleWhere(
              (s) => s['label'] == 'notes',
            )['sha256'],
            'directDefinition': p['definition'],
            'scope': p['notesScope'],
            'reconciliationUnit': '천원',
            'currentAndPriorPrintedComponentsVerified': true,
            'numericCellCorrection': false,
          },
          if (p.containsKey('preservedClassificationDifferences'))
            'preservedClassificationDifferences':
                p['preservedClassificationDifferences'],
        },
      });
    }
    return result;
  }
}
