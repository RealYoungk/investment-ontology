import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Exact two own annuals; source-bound current accounts, no generic cash tolerance.
abstract final class HeungkukCurrentExactSource {
  static final List _profiles = jsonDecode(
    r'''[{"receipt": "20230316001454", "corpCode": "00103176", "year": 2022, "ruleVersion": "heungkuk-2022-own-current-cash-eight-v1", "sources": [{"label": "shell", "file": "shell.html", "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20230316001454", "sha256": "6e33d78691cc799be4dd3fc97e3f73c5640d759d7fb71ff6ff624ecba09c7cab"}, {"label": "cover", "file": "cover.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001454&dcmNo=9067589&eleId=1&offset=811&length=4018&dtd=dart3.xsd", "sha256": "d2e3f16f701c310b67d00c083eaa4c0304ae38943ce3debf1ae1a74460ebda84"}, {"label": "ofs", "file": "ofs.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001454&dcmNo=9067589&eleId=19&offset=212198&length=72349&dtd=dart3.xsd", "sha256": "904ded609ffa2c68f8a36feea9a44dfc7ae9e02d1d260951cf85d5f83681ccea"}, {"label": "notes", "file": "notes.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001454&dcmNo=9067589&eleId=20&offset=284551&length=815671&dtd=dart3.xsd", "sha256": "ffe6f5e164f0645b8a5bb8bcfcafaff94ba53100cbafb16aa8fa67fe058a7943"}], "rows": [{"index": 21, "column": 3, "label": "자 산 총 계", "printed": "13,966,098", "value": "13966098000000", "account": "assets", "kind": "BS"}, {"index": 31, "column": 3, "label": "부 채 총 계", "printed": "13,246,051", "value": "13246051000000", "account": "liabilities", "kind": "BS"}, {"index": 37, "column": 3, "label": "자 본 총 계", "printed": "720,047", "value": "720047000000", "account": "equity", "kind": "BS"}, {"index": 46, "column": 3, "label": "Ⅰ. 영업수익", "printed": "4,528,860", "value": "4528860000000", "account": "revenue", "kind": "IS"}, {"index": 75, "column": 3, "label": "Ⅲ. 영업이익", "printed": "185,978", "value": "185978000000", "account": "operatingProfit", "kind": "IS"}, {"index": 79, "column": 3, "label": "Ⅶ. 당기순이익 (대손준비금 반영 후 조정이익 당기 : 138,148 백만원 전기 : 54,202 백만원) (비상위험준비금 반영 후 조정이익 당기 : 134,462 백만원 전기 : 51,465 백만원)", "printed": "147,508", "value": "147508000000", "account": "netIncome", "kind": "IS"}, {"index": 135, "column": 3, "label": "I. 영업활동으로인한 현금흐름", "printed": "356,205", "value": "356205000000", "account": "operatingCashflow", "kind": "CF"}, {"index": 177, "column": 2, "label": "(7) 유형자산의 취득", "printed": "(7,445)", "value": "7445000000", "account": "capex", "kind": "CF"}], "cfg": {"bsAssets": 21, "bsLiabilities": 31, "bsEquity": 37, "revenue": 46, "op": 75, "ni": 79, "cost": 58, "other": 76, "pretax": 77, "tax": 78, "ceOpening": 115, "ceNi": 117, "ceOci": 118, "ceOther": [125, 126], "ceClosing": 127, "cfo": 135, "cfoComponents": [136, 137, 141, 157, 166, 167, 168, 169], "cfi": 170, "cff": 182, "fx": 190, "cashDelta": 191, "cashOpening": 192, "cashClosing": 193, "unitRows": [3, 44, 101, 133], "periodRows": [1, 42, 99, 131], "headerRows": [4, 45, 102, 134], "noteCash": 1939, "noteUnit": 1933, "noteHeader": 1934, "noteCashComponents": [1935, 1936, 1937, 1938], "noteCurrentCf": 841, "noteCurrentDeposit": 842, "noteCurrentBS": 843, "notePriorCf": 866, "notePriorDeposit": 867, "notePriorBS": 868}, "rowCount": 211, "notesRowCount": 2182, "primaryWitnesses": {"1": ["제77(당)기 2022년 12월 31일 현재"], "3": ["흥국화재해상보험주식회사", "(단위: 백만원)"], "4": ["과 목", "주석", "제77(당)기", "제76(전)기"], "6": ["1. 현금및예치금", "4,5,6,27", "64,067", "", "90,288", ""], "21": ["자 산 총 계", "", "", "13,966,098", "", "13,762,260"], "31": ["부 채 총 계", "", "", "13,246,051", "", "13,071,612"], "37": ["자 본 총 계", "", "", "720,047", "", "690,648"], "42": ["제77(당)기 2022년 01월 01일부터 2022년 12월 31일까지"], "44": ["흥국화재해상보험주식회사", "(단위: 백만원)"], "45": ["과 목", "주석", "제77(당)기", "제76(전)기"], "46": ["Ⅰ. 영업수익", "", "", "4,528,860", "", "4,514,595"], "58": ["Ⅱ. 영업비용", "", "", "4,342,882", "", "4,437,457"], "75": ["Ⅲ. 영업이익", "", "", "185,978", "", "77,138"], "76": ["Ⅳ. 영업외손익", "40", "", "790", "", "4,162"], "77": ["Ⅴ. 법인세비용차감전순이익", "", "", "186,768", "", "81,300"], "78": ["Ⅵ. 법인세비용", "41", "", "39,260", "", "19,255"], "79": ["Ⅶ. 당기순이익 (대손준비금 반영 후 조정이익 당기 : 138,148 백만원 전기 : 54,202 백만원) (비상위험준비금 반영 후 조정이익 당기 : 134,462 백만원 전기 : 51,465 백만원)", "", "", "147,508", "", "62,045"], "99": ["제77(당)기 2022년 01월 01일부터 2022년 12월 31일까지"], "101": ["흥국화재해상보험주식회사", "(단위: 백만원)"], "102": ["과목", "자본금", "신종자본증권", "기타포괄 손익누계액", "이익잉여금 (결손금)", "총계"], "115": ["Ⅲ. 2022년 1월 1일(당기초)", "325,821", "92,000", "3,830", "268,997", "690,648"], "117": ["1. 당기순이익", "-", "-", "-", "147,508", "147,508"], "118": ["2. 기타포괄손익", "-", "-", "(229,863)", "-", "(229,863)"], "125": ["(1) 신종자본증권 발행", "-", "120,000", "-", "-", "120,000"], "126": ["(2) 신종자본증권 분배금", "-", "-", "-", "(8,246)", "(8,246)"], "127": ["Ⅳ. 2022년 12월 31일(당기말)", "325,821", "212,000", "(226,033)", "408,259", "720,047"], "131": ["제77(당)기 2022년 01월 01일부터 2022년 12월 31일까지"], "133": ["흥국화재해상보험주식회사", "(단위: 백만원)"], "134": ["과 목", "주석", "제77(당)기", "제76(전)기"], "135": ["I. 영업활동으로인한 현금흐름", "", "", "356,205", "", "389,598"], "136": ["1. 법인세비용차감전순이익", "", "186,768", "", "81,300", ""], "137": ["2. 손익조정사항", "", "(415,793)", "", "(375,273)", ""], "141": ["3. 현금유출입이 없는 손익항목", "", "467,541", "", "738,604", ""], "157": ["4. 자산부채의 증감", "", "(241,086)", "", "(398,098)", ""], "166": ["5. 법인세의 부담액", "", "(5,411)", "", "(1,035)", ""], "167": ["6. 이자의 수취", "", "282,271", "", "265,230", ""], "168": ["7. 이자의 지급", "", "(19,967)", "", "(19,853)", ""], "169": ["8. 배당금의 수취", "", "101,882", "", "98,723", ""], "170": ["II. 투자활동으로 인한 현금흐름", "", "", "(417,336)", "", "(371,191)"], "177": ["(7) 유형자산의 취득", "", "(7,445)", "", "(4,844)", ""], "182": ["III. 재무활동으로 인한 현금흐름", "", "", "34,921", "", "(12,324)"], "190": ["IV. 외화표시 현금및현금성자산에 대한 환율변동효과", "", "", "(3)", "", "-"], "191": ["V. 현금및현금성자산의 증가", "", "", "(26,213)", "", "6,083"], "192": ["VI. 기초의 현금및현금성자산", "43", "", "90,275", "", "84,192"], "193": ["Ⅶ. 기말의 현금및현금성자산", "43", "", "64,062", "", "90,275"]}, "notesWitnesses": {"841": ["현금및예치금", "현금및현금성자산", "64,062", "-", "-", "64,062"], "842": ["예치금", "-", "5", "-", "5"], "843": ["소 계", "64,062", "5", "-", "64,067"], "866": ["현금및예치금", "현금및현금성자산", "90,275", "-", "-", "90,275"], "867": ["예치금", "-", "-", "13", "13"], "868": ["소 계", "90,275", "-", "13", "90,288"], "1933": ["(단위: 백만원)"], "1934": ["구분", "제77(당)기", "제76(전)기"], "1935": ["현금", "1", "1"], "1936": ["보통예금", "38,846", "39,962"], "1937": ["외화예금", "3,331", "5,874"], "1938": ["기타예금", "21,884", "44,438"], "1939": ["합 계", "64,062", "90,275"]}, "priorNoteConflict": false, "priorNoteCashDifferencePrintedMillion": 0}, {"receipt": "20220317001158", "corpCode": "00103176", "year": 2021, "ruleVersion": "heungkuk-2021-own-current-cash-eight-v1", "sources": [{"label": "shell", "file": "shell.html", "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20220317001158", "sha256": "81245b98bf5a4e932c56158964b21e3626c2c19f7b5fa52eb1639464604229fd"}, {"label": "cover", "file": "cover.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317001158&dcmNo=8473533&eleId=1&offset=808&length=4024&dtd=dart3.xsd", "sha256": "32bfd43afe94f5e74c333e6e5f3b7018f2870269aafc04e9342aacf4057aeaa8"}, {"label": "ofs", "file": "ofs.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317001158&dcmNo=8473533&eleId=19&offset=228113&length=70137&dtd=dart3.xsd", "sha256": "3feca6712e67559733fe542fc7dd1fe90f03eb940e09f5dfe94eaa4fcc01e4e4"}, {"label": "notes", "file": "notes.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317001158&dcmNo=8473533&eleId=20&offset=298254&length=796257&dtd=dart3.xsd", "sha256": "25aa092b3d2180f6946062c61e5f857aa7f910f1cca447a552998b70acd10de4"}], "rows": [{"index": 20, "column": 3, "label": "자 산 총 계", "printed": "13,762,260", "value": "13762260000000", "account": "assets", "kind": "BS"}, {"index": 30, "column": 3, "label": "부 채 총 계", "printed": "13,071,612", "value": "13071612000000", "account": "liabilities", "kind": "BS"}, {"index": 36, "column": 3, "label": "자 본 총 계", "printed": "690,648", "value": "690648000000", "account": "equity", "kind": "BS"}, {"index": 45, "column": 3, "label": "Ⅰ. 영업수익", "printed": "4,514,595", "value": "4514595000000", "account": "revenue", "kind": "IS"}, {"index": 74, "column": 3, "label": "Ⅲ. 영업이익", "printed": "77,138", "value": "77138000000", "account": "operatingProfit", "kind": "IS"}, {"index": 78, "column": 3, "label": "Ⅶ. 당기순이익 (대손준비금 반영 후 조정이익 당기 : 54,202 백만원 전기 : 13,888 백만원) (비상위험준비금 반영 후 조정이익 당기 : 51,465 백만원 전기 : 12,242 백만원)", "printed": "62,045", "value": "62045000000", "account": "netIncome", "kind": "IS"}, {"index": 133, "column": 3, "label": "I. 영업활동으로인한 현금흐름", "printed": "389,598", "value": "389598000000", "account": "operatingCashflow", "kind": "CF"}, {"index": 174, "column": 2, "label": "(7) 유형자산의 취득", "printed": "(4,844)", "value": "4844000000", "account": "capex", "kind": "CF"}], "cfg": {"bsAssets": 20, "bsLiabilities": 30, "bsEquity": 36, "revenue": 45, "op": 74, "ni": 78, "cost": 57, "other": 75, "pretax": 76, "tax": 77, "ceOpening": 114, "ceNi": 116, "ceOci": 117, "ceOther": [124], "ceClosing": 125, "cfo": 133, "cfoComponents": [134, 135, 139, 154, 163, 164, 165, 166], "cfi": 167, "cff": 178, "fx": 184, "cashDelta": 185, "cashOpening": 186, "cashClosing": 187, "unitRows": [3, 43, 100, 131], "periodRows": [1, 41, 98, 129], "headerRows": [4, 44, 101, 132], "noteCash": 1919, "noteUnit": 1913, "noteHeader": 1914, "noteCashComponents": [1915, 1916, 1917, 1918], "noteCurrentCf": 801, "noteCurrentDeposit": 802, "noteCurrentBS": 803, "notePriorCf": 826, "notePriorDeposit": 827, "notePriorBS": 828}, "rowCount": 205, "notesRowCount": 2159, "primaryWitnesses": {"1": ["제76(당)기 2021년 12월 31일 현재"], "3": ["흥국화재해상보험주식회사", "(단위: 백만원)"], "4": ["과 목", "주석", "제76(당)기", "제75(전)기"], "6": ["1. 현금및예치금", "4,5,6,27", "90,288", "", "84,197", ""], "20": ["자 산 총 계", "", "", "13,762,260", "", "13,211,184"], "30": ["부 채 총 계", "", "", "13,071,612", "", "12,487,415"], "36": ["자 본 총 계", "", "", "690,648", "", "723,769"], "41": ["제76(당)기 2021년 01월 01일부터 2021년 12월 31일까지"], "43": ["흥국화재해상보험주식회사", "(단위: 백만원)"], "44": ["과 목", "주석", "제76(당)기", "제75(전)기"], "45": ["Ⅰ. 영업수익", "", "", "4,514,595", "", "4,492,959"], "57": ["Ⅱ. 영업비용", "", "", "4,437,457", "", "4,467,052"], "74": ["Ⅲ. 영업이익", "", "", "77,138", "", "25,907"], "75": ["Ⅳ. 영업외손익", "40", "", "4,162", "", "537"], "76": ["Ⅴ. 법인세비용차감전순이익", "", "", "81,300", "", "26,444"], "77": ["Ⅵ. 법인세비용", "41", "", "19,255", "", "3,733"], "78": ["Ⅶ. 당기순이익 (대손준비금 반영 후 조정이익 당기 : 54,202 백만원 전기 : 13,888 백만원) (비상위험준비금 반영 후 조정이익 당기 : 51,465 백만원 전기 : 12,242 백만원)", "", "", "62,045", "", "22,711"], "98": ["제76(당)기 2021년 01월 01일부터 2021년 12월 31일까지"], "100": ["흥국화재해상보험주식회사", "(단위: 백만원)"], "101": ["과목", "자본금", "신종자본증권", "기타포괄 손익누계액", "이익잉여금 (결손금)", "총계"], "114": ["Ⅲ. 2021년 1월 1일(당기초)", "325,821", "92,000", "93,752", "212,196", "723,769"], "116": ["1. 당기순이익", "-", "-", "-", "62,045", "62,045"], "117": ["2. 기타포괄손익", "-", "-", "(89,922)", "-", "(89,922)"], "124": ["(1) 신종자본증권 분배금", "-", "-", "-", "(5,244)", "(5,244)"], "125": ["Ⅳ. 2021년 12월 31일(당기말)", "325,821", "92,000", "3,830", "268,997", "690,648"], "129": ["제76(당)기 2021년 01월 01일부터 2021년 12월 31일까지"], "131": ["흥국화재해상보험주식회사", "(단위: 백만원)"], "132": ["과 목", "주석", "제76(당)기", "제75(전)기"], "133": ["I. 영업활동으로인한 현금흐름", "", "", "389,598", "", "832,896"], "134": ["1. 법인세비용차감전순이익", "", "81,300", "", "26,444", ""], "135": ["2. 손익조정사항", "", "(375,273)", "", "(361,215)", ""], "139": ["3. 현금유출입이 없는 손익항목", "", "738,604", "", "778,276", ""], "154": ["4. 자산부채의 증감", "", "(398,098)", "", "37,965", ""], "163": ["5. 법인세의 부담액", "", "(1,035)", "", "(2,149)", ""], "164": ["6. 이자의 수취", "", "265,230", "", "273,834", ""], "165": ["7. 이자의 지급", "", "(19,853)", "", "(19,251)", ""], "166": ["8. 배당금의 수취", "", "98,723", "", "98,991", ""], "167": ["II. 투자활동으로 인한 현금흐름", "", "", "(371,191)", "", "(800,211)"], "174": ["(7) 유형자산의 취득", "", "(4,844)", "", "(1,758)", ""], "178": ["III. 재무활동으로 인한 현금흐름", "", "", "(12,324)", "", "(11,622)"], "184": ["IV. 외화표시 현금및현금성자산에 대한 환율변동효과", "", "", "-", "", "-"], "185": ["V. 현금및현금성자산의 증가", "", "", "6,083", "", "21,062"], "186": ["VI. 기초의 현금및현금성자산", "43", "", "84,192", "", "63,130"], "187": ["Ⅶ. 기말의 현금및현금성자산", "43", "", "90,275", "", "84,192"]}, "notesWitnesses": {"801": ["현금및예치금", "현금및현금성자산", "90,275", "-", "-", "90,275"], "802": ["예치금", "-", "-", "13", "13"], "803": ["소 계", "90,275", "-", "13", "90,288"], "826": ["현금및예치금", "현금및현금성자산", "84,192", "-", "-", "84,192"], "827": ["예치금", "-", "-", "5", "5"], "828": ["소 계", "84,192", "-", "5", "84,197"], "1913": ["(단위: 백만원)"], "1914": ["구분", "제76(당)기", "제75(전)기"], "1915": ["현금", "1", "2"], "1916": ["보통예금", "39,962", "45,082"], "1917": ["외화예금", "5,874", "5,925"], "1918": ["기타예금", "44,438", "33,184"], "1919": ["합 계", "90,275", "84,193"]}, "priorNoteConflict": true, "priorNoteCashDifferencePrintedMillion": 1}]''',
  ) as List;

  static bool supports(String rule) =>
      _profiles.any((p) => p['ruleVersion'] == rule);
  static List<Map<String, dynamic>> parse({
    required Map<String, String> raw,
    required Map<String, Uri> uris,
    required String receipt,
    required String corp,
    required DateTime start,
    required DateTime end,
    required bool consolidated,
  }) {
    final matches = _profiles.where((p) => p['receipt'] == receipt).toList();
    if (matches.length != 1) {
      throw const FormatException('Heungkuk unapproved receipt');
    }
    final p = matches.single as Map,
        year = p['year'] as int,
        c = p['cfg'] as Map;
    if (corp != '00103176' ||
        consolidated ||
        start != DateTime.utc(year) ||
        end != DateTime.utc(year, 12, 31)) {
      throw const FormatException('Heungkuk exact own period/basis mismatch');
    }
    for (final source in p['sources'] as List) {
      final label = source['label'] as String;
      if (uris[label]?.toString() != source['url'] ||
          raw[label] == null ||
          sha256.convert(utf8.encode(raw[label]!)).toString() !=
              source['sha256']) {
        throw const FormatException('Heungkuk exact URI/original SHA mismatch');
      }
    }
    String text(String h) => h
        .replaceAll(RegExp('<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    List<List<String>> rows(String body) => [
      for (final tr in RegExp(
        r'<tr\b[^>]*>(.*?)</tr>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(body))
        [
          for (final cell in RegExp(
            r'<t[dh]\b[^>]*>(.*?)</t[dh]>',
            caseSensitive: false,
            dotAll: true,
          ).allMatches(tr.group(1)!))
            text(cell.group(1)!),
        ],
    ];
    final r = rows(raw['ofs']!), n = rows(raw['notes']!);
    if (r.length != p['rowCount'] || n.length != p['notesRowCount']) {
      throw const FormatException('Heungkuk exact row count changed');
    }
    for (final entry in (p['primaryWitnesses'] as Map).entries) {
      if (jsonEncode(r[int.parse(entry.key as String)]) !=
          jsonEncode(entry.value)) {
        throw FormatException(
          'Heungkuk current primary witness changed ${entry.key}: ${r[int.parse(entry.key as String)]} expected ${entry.value}',
        );
      }
    }
    for (final entry in (p['notesWitnesses'] as Map).entries) {
      if (jsonEncode(n[int.parse(entry.key as String)]) !=
          jsonEncode(entry.value)) {
        throw FormatException(
          'Heungkuk selected note witness changed ${entry.key}: ${n[int.parse(entry.key as String)]} expected ${entry.value}',
        );
      }
    }
    final ownIds = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
        .allMatches(raw['shell']!)
        .map((m) => m.group(1))
        .toSet();
    if (ownIds.length != 1 ||
        ownIds.single != corp ||
        !text(raw['cover']!).contains('흥국화재해상보험')) {
      throw const FormatException('Heungkuk own legal issuer mismatch');
    }
    BigInt money(String s) => s == '-'
        ? BigInt.zero
        : BigInt.parse(
            s.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
          );
    BigInt a(String key, [int col = 3]) => money(r[c[key] as int][col]);
    BigInt na(String key, int col) => money(n[c[key] as int][col]);
    BigInt sum(List indexes, int col, List<List<String>> table) => indexes
        .map((i) => money(table[i as int][col]))
        .fold(BigInt.zero, (a, b) => a + b);
    final ceChanges = [c['ceNi'], c['ceOci'], ...c['ceOther'] as List];
    final cfActivities = [c['cfo'], c['cfi'], c['cff'], c['fx']];
    if (a('bsAssets') != a('bsLiabilities') + a('bsEquity') ||
        a('revenue') - a('cost') != a('op') ||
        a('op') + a('other') != a('pretax') ||
        a('pretax') - a('tax') != a('ni') ||
        a('ceNi', 5) != a('ni') ||
        a('ceOpening', 5) + sum(ceChanges, 5, r) != a('ceClosing', 5) ||
        a('ceClosing', 5) != a('bsEquity') ||
        a('ceOpening', 5) != a('bsEquity', 5) ||
        money(r[(c['cfoComponents'] as List).first as int][2]) != a('pretax') ||
        sum(c['cfoComponents'] as List, 2, r) != a('cfo') ||
        sum(cfActivities, 3, r) != a('cashDelta') ||
        a('cashOpening') + a('cashDelta') != a('cashClosing')) {
      throw const FormatException(
        'Heungkuk current BS PL CE CF consistency conflict',
      );
    }
    final currentCf = na('noteCurrentCf', 2),
        priorCf = na('notePriorCf', 2),
        currentDeposit = money(n[c['noteCurrentDeposit'] as int].last),
        priorDeposit = money(n[c['notePriorDeposit'] as int].last);
    if (currentCf != a('cashClosing') ||
        priorCf != a('cashOpening') ||
        currentCf + currentDeposit != money(r[6][2]) ||
        priorCf + priorDeposit != money(r[6][4]) ||
        na('noteCurrentBS', 4) != money(r[6][2]) ||
        na('notePriorBS', 4) != money(r[6][4]) ||
        na('noteCash', 1) != currentCf ||
        sum(c['noteCashComponents'] as List, 1, n) != currentCf ||
        na('noteCash', 2) - priorCf !=
            BigInt.from(p['priorNoteCashDifferencePrintedMillion'] as int) ||
        sum(c['noteCashComponents'] as List, 2, n) != na('noteCash', 2)) {
      throw const FormatException(
        'Heungkuk exact own cash/deposit scope conflict',
      );
    }
    final result = <Map<String, dynamic>>[];
    for (final spec in p['rows'] as List) {
      final row = r[spec['index'] as int], column = spec['column'] as int;
      var amount = money(row[column]);
      if (spec['account'] == 'capex') {
        amount = amount.abs();
      }
      amount *= BigInt.from(1000000);
      if (amount.toString() != spec['value']) {
        throw const FormatException(
          'Heungkuk printed current amount scale conflict',
        );
      }
      result.add({
        'rcept_no': receipt,
        'corp_code': corp,
        'bsns_year': '$year',
        'reprt_code': '11011',
        'account_id': null,
        'account_nm': row.first,
        'account_detail': '-',
        'sj_div': spec['kind'],
        'thstrm_nm': spec['kind'] == 'BS'
            ? '$year-12-31'
            : '$year-01-01~$year-12-31',
        'thstrm_amount': amount.toString(),
        'currency': 'KRW',
        'html_provenance': {
          'source': uris['ofs'].toString(),
          'sourceReceipt': receipt,
          'ruleVersion': p['ruleVersion'],
          'sourceSha256': (p['sources'] as List).singleWhere(
            (s) => s['label'] == 'ofs',
          )['sha256'],
          'printedLabel': row.first,
          'printedAmount': row[column],
          'htmlTrIndex': spec['index'],
          'currentColumn': column,
          'unit': '백만원',
          'unitMultiplier': '1000000',
          'basis': 'OFS',
          'periodStart': '$year-01-01',
          'periodEnd': '$year-12-31',
          'partialCore8': true,
          'fullStatementCollected': false,
          'fullStatementVerified': false,
          'allStatementRowsVerified': false,
          'notesVerified': false,
          'notesReadScopeComplete': false,
          'numericCellCorrection': false,
          'coreAmountsConflicting': false,
          'netIncomeWitness': 'Current whole PL NI equals CE total NI; CF starts from printed pretax profit, not NI',
          'cfProfitBasis': 'printedPretaxProfit',
          'printedCFPretaxProfit': money(
            r[(c['cfoComponents'] as List).first as int][2],
          ).toString(),
          'capexOutflowNormalized': spec['account'] == 'capex',
          'cashScopeProof': {
            'notesSource': uris['notes'].toString(),
            'notesSha256': (p['sources'] as List).singleWhere(
              (s) => s['label'] == 'notes',
            )['sha256'],
            'scope': 'Exact current cash/deposit rows and independent prior fair-value rows only; not whole notes',
            'currentCFCashPrinted': currentCf.toString(),
            'currentDepositPrinted': currentDeposit.toString(),
            'currentBSCashAndDepositPrinted': money(r[6][2]).toString(),
            'priorCFCashPrinted': priorCf.toString(),
            'priorDepositPrinted': priorDeposit.toString(),
            'priorBSCashAndDepositPrinted': money(r[6][4]).toString(),
            'unit': '백만원',
            'priorNote43CashConflict': p['priorNoteConflict'],
            'priorNote43CashPrinted': na('noteCash', 2).toString(),
            'priorNote43DifferencePrintedMillion':
                p['priorNoteCashDifferencePrintedMillion'],
            'independentPriorFairValueCashPrinted': priorCf.toString(),
            'numericCellCorrection': false,
            'genericRoundingTolerance': false,
            'selectedRawNoteWitnesses': [
              for (final witness in (p['notesWitnesses'] as Map).entries)
                {
                  'htmlTrIndex': int.parse(witness.key as String),
                  'printedCells': witness.value,
                },
            ],
          },
        },
      });
    }
    return result;
  }
}
