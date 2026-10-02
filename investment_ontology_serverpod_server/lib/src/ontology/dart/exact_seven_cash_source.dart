import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Two immutable OFS sources; no label, amount or caption repair is performed.
abstract final class ExactSevenCashSource {
  static final Map<String, dynamic> _profiles = jsonDecode(
    r'''{"20230323001437": {"corp": "01363924", "name": "(주)한국미라클피플사", "coverUrl": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230323001437&dcmNo=9099217&eleId=1&offset=800&length=4032&dtd=dart3.xsd", "coverSha": "713acdb39a4248430e40c17a545040c588481f64c8f2078e7c1020347dcaf2ec", "sourceUrl": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230323001437&dcmNo=9099217&eleId=21&offset=141092&length=43326&dtd=dart3.xsd", "sourceSha": "12b509e2f5437f593b694082795a76aad3f7277c4078aa00bc495c2910113207", "digest": "d1e08fc06f798ad6577545e32d49816a938f18217327bbca2f1c70df08cf1f3a", "asset": "assets/financial_source_cache/20230323001437-ofs-exact-seven", "term": 9, "printedOwner": "주식회사 한국미라클피플사", "captions": [{"index": 0, "text": "재무상태표제9기2022년12월31일현재제8기2021년12월31일현재주식회사한국미라클피플사(단위:원)"}, {"index": 3, "text": "포괄손익계산서제9기2022년01월01일부터2022년12월31일까지제8기2021년01월01일부터2021년12월31일까지주식회사한국미라클피플사(단위:원)"}, {"index": 6, "text": "자본변동표제9기2022년01월01일부터2022년12월31일까지제8기2021년01월01일부터2021년12월31일까지주식회사한국미라클피플사(단위:원)"}, {"index": 8, "text": "현금흐름표제9기2022년01월01일부터2022년12월31일까지제8기2021년01월01일부터2021년12월31일까지주식회사한국미라클피플사(단위:원)"}], "indices": [1, 4, 7, 9], "headers": [["과 목", "주 석", "제 9(당) 기말", "제 8(전) 기말"], ["과 목", "주 석", "제 9(당) 기", "제 8(전) 기"], ["\"별첨 주석은 본 재무제표의 일부입니다.\" 과 목", "자 본 금", "자본조정", "기타포괄손익 누계액", "이익잉여금 (결손금)", "총 계"], ["\"별첨 주석은 본 재무제표의 일부입니다.\" 과 목", "주 석", "제 9(당) 기", "제 8(전) 기"]], "selected": {"assets": {"label": "자산총계", "printedLabel": "자산총계", "current": "24,129,727,023", "prior": "19,320,152,567"}, "liabilities": {"label": "부채총계", "printedLabel": "부채총계", "current": "24,570,272,946", "prior": "19,098,077,162"}, "equity": {"label": "자본총계", "printedLabel": "자본총계", "current": "(440,545,923)", "prior": "222,075,405"}, "revenue": {"label": "Ⅰ.매출액", "printedLabel": "Ⅰ. 매출액", "current": "29,945,358,559", "prior": "22,463,883,556"}, "operatingIncome": {"label": "Ⅳ.영업이익(손실)", "printedLabel": "Ⅳ. 영업이익(손실)", "current": "387,897,142", "prior": "(2,212,980,103)"}, "netIncome": {"label": "Ⅵ.당기순손실", "printedLabel": "Ⅵ. 당기순손실", "current": "(654,850,680)", "prior": "(2,947,448,446)"}, "operatingCashFlow": {"label": "Ⅰ.영업활동으로인한현금흐름", "printedLabel": "Ⅰ. 영업활동으로 인한 현금흐름", "current": "1,886,295,687", "prior": "(112,968,755)"}}, "ceOpen": "2022년01월01일(당기초)", "ceClose": "2022년12월31일(당기말)", "cePriorOpen": "2021년01월01일(전기초)", "cePriorClose": "2021년12월31일(전기말)", "ceProfit": "당기순손실", "cfProfit": "가.당기순손실", "cfOpen": "Ⅴ.기초의현금및현금성자산", "cfClose": "Ⅶ.기말의현금및현금성자산", "cfChange": "Ⅳ.현금의증가(감소)", "cfFx": "Ⅵ.외화표시현금의환율변동효과", "cfInvest": "Ⅱ.투자활동으로인한현금흐름", "cfFinance": "Ⅲ.재무활동으로인한현금흐름"}, "20230315000894": {"corp": "00162416", "name": "한양증권(주)", "coverUrl": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315000894&dcmNo=9059095&eleId=1&offset=785&length=4029&dtd=dart3.xsd", "coverSha": "4c4c2572aa92f08b9fd46476c8cec4af13f206b3ea9ab9a5b6dd4a9e5bf0cdc8", "sourceUrl": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315000894&dcmNo=9059095&eleId=19&offset=264765&length=42478&dtd=dart3.xsd", "sourceSha": "0ff1c9183cbee1f40ee7f83a3b8ce50f345de21248f05e81d2ecfabe8082e281", "digest": "2acceec4fe4bba202a473b2a7ad9a516b96cb8e122e1258b856bab3e3c8b4568", "asset": "assets/financial_source_cache/20230315000894-ofs-exact-seven", "term": 68, "printedOwner": "한양증권주식회사", "captions": [{"index": 0, "text": "재무상태표제68(당)기2022년12월31일현재제67(전)기2021년12월31일현재한양증권주식회사(단위:원)"}, {"index": 3, "text": "포괄손익계산서제68(당)기2022년1월1일부터2022년12월31일까지제67(전)기2021년1월1일부터2021년12월31일까지한양증권주식회사(단위:원)"}, {"index": 6, "text": "자본변동표제68(당)기2022년1월1일부터2022년12월31일까지제67(전)기2021년1월1일부터2021년12월31일까지한양증권주식회사(단위:원)"}, {"index": 9, "text": "현금흐름표제68(당)기2022년1월1일부터2022년12월31일까지제67(전)기2021년1월1일부터2021년12월31일까지한양증권주식회사(단위:원)"}], "indices": [1, 4, 7, 10], "headers": [["과 목", "주석", "제 68 (당) 기", "제 67 (전) 기"], ["과 목", "주 석", "제 68 (당) 기", "제 67 (전) 기"], ["과 목", "자 본 금", "자 본 잉여금", "자 본 조 정", "기타포괄손익 누계액", "이 익 잉여금", "총 계"], ["과 목", "주 석", "제 68 (당) 기", "제 67 (전) 기"]], "selected": {"assets": {"label": "자산총계", "printedLabel": "자 산 총 계", "current": "1,502,891,064,305", "prior": "1,633,398,450,357"}, "liabilities": {"label": "부채총계", "printedLabel": "부 채 총 계", "current": "1,043,504,162,865", "prior": "1,201,053,825,996"}, "equity": {"label": "자본총계", "printedLabel": "자 본 총 계", "current": "459,386,901,440", "prior": "432,344,624,361"}, "revenue": {"label": "Ⅰ.영업수익", "printedLabel": "Ⅰ.영업수익", "current": "1,117,144,964,059", "prior": "874,165,603,240"}, "operatingIncome": {"label": "Ⅲ.영업이익", "printedLabel": "Ⅲ.영업이익", "current": "37,196,834,948", "prior": "116,239,144,300"}, "netIncome": {"label": "Ⅷ.당기순이익(대손준비금반영후조정이익당기:25,894,824,085원전기:76,378,389,687원", "printedLabel": "Ⅷ.당기순이익 (대손준비금반영 후 조정이익 당 기: 25,894,824,085원 전 기: 76,378,389,687원", "current": "24,033,307,547", "prior": "79,443,581,011"}, "operatingCashFlow": {"label": "Ⅰ.영업활동으로인한현금흐름", "printedLabel": "Ⅰ.영업활동으로 인한 현금흐름", "current": "(150,348,093)", "prior": "(71,389,082,428)"}}, "ceOpen": "2022년1월1일(당기초)", "ceClose": "2022년12월31일(당기말)", "cePriorOpen": "2021년1월1일(전기초)", "cePriorClose": "2021년12월31일(전기말)", "ceProfit": "1.당기순이익", "cfProfit": "가.당기순이익", "cfOpen": "Ⅴ.기초의현금", "cfClose": "Ⅵ.기말의현금", "cfChange": "Ⅳ.현금의증가(I+II+III)", "cfFx": null, "cfInvest": "Ⅱ.투자활동으로인한현금흐름", "cfFinance": "Ⅲ.재무활동으로인한현금흐름"}}''',
  ) as Map<String, dynamic>;
  static bool eligible(String receipt) => _profiles.containsKey(receipt);
  static String compact(String v) => v.replaceAll(RegExp(r'\s+'), '');
  static List<Map<String, dynamic>> parse({
    required String receipt,
    required String corpCode,
    required String companyName,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Uri coverSource,
    required Uri statementSource,
    required String coverHtml,
    required String statementHtml,
  }) {
    void guard(bool ok, String reason) {
      if (!ok) throw FormatException('Exact seven cash source: $reason');
    }

    final p = _profiles[receipt] as Map<String, dynamic>?;
    guard(p != null, 'unknown receipt');
    final profile = p!;
    guard(
      !consolidated &&
          corpCode == profile['corp'] &&
          companyName == profile['name'] &&
          start == DateTime.utc(2022) &&
          end == DateTime.utc(2022, 12, 31) &&
          coverSource.toString() == profile['coverUrl'] &&
          statementSource.toString() == profile['sourceUrl'],
      'owner/basis/period/URI',
    );
    guard(
      sha256.convert(utf8.encode(coverHtml)).toString() ==
              profile['coverSha'] &&
          sha256.convert(utf8.encode(statementHtml)).toString() ==
              profile['sourceSha'],
      'immutable raw SHA',
    );
    final tables = RegExp(
      r'<table\b[^>]*>(.*?)</table>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(statementHtml).map((m) => m[1]!).toList();
    String text(String v) => v
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    List<List<String>> cells(int i) =>
        RegExp(r'<tr\b[^>]*>(.*?)</tr>', caseSensitive: false, dotAll: true)
            .allMatches(tables[i])
            .map(
              (tr) => RegExp(
                r'<t[dh]\b[^>]*>(.*?)</t[dh]>',
                caseSensitive: false,
                dotAll: true,
              ).allMatches(tr[1]!).map((c) => text(c[1]!)).toList(),
            )
            .where((r) => r.isNotEmpty)
            .toList();
    for (final caption in profile['captions'] as List) {
      guard(
        compact(cells(caption['index'] as int).expand((r) => r).join()) ==
            caption['text'],
        'explicit caption/term/unit/issuer',
      );
    }
    final indices = (profile['indices'] as List).cast<int>();
    final data = indices.map(cells).toList();
    for (var i = 0; i < 4; i++) {
      guard(
        data[i].first.map(compact).join('|') ==
            (profile['headers'][i] as List)
                .cast<String>()
                .map(compact)
                .join('|'),
        'current/prior/whole header',
      );
      for (final c in RegExp(
        r'<t[dh]\b([^>]*)>',
        caseSensitive: false,
      ).allMatches(tables[indices[i]])) {
        for (final span in RegExp(
          r'''(?:colspan|rowspan)\s*=\s*["']?([0-9]+)''',
          caseSensitive: false,
        ).allMatches(c[1]!)) {
          guard(span[1] == '1', 'monetary cell span');
        }
      }
    }
    List<String> unique(List<List<String>> rows, String label) {
      final m = rows.where((r) => compact(r.first) == label).toList();
      guard(m.length == 1, 'whole row missing/duplicate');
      return m.single;
    }

    BigInt money(String s) {
      guard(
        RegExp(r'^\d{1,3}(?:,\d{3})*$|^\(\d{1,3}(?:,\d{3})*\)$').hasMatch(s),
        'strict current money',
      );
      final n = BigInt.parse(
        s.replaceAll(',', '').replaceAll('(', '').replaceAll(')', ''),
      );
      return s.startsWith('(') ? -n : n;
    }

    final selected = <String, List<String>>{};
    for (final e in (profile['selected'] as Map<String, dynamic>).entries) {
      final idx = {'assets', 'liabilities', 'equity'}.contains(e.key)
          ? 0
          : e.key == 'operatingCashFlow'
          ? 3
          : 1;
      final row = unique(data[idx], e.value['label']);
      guard(
        row.length == 4 &&
            row[0] == e.value['printedLabel'] &&
            row[2] == e.value['current'] &&
            row[3] == e.value['prior'],
        'direct account/current/prior',
      );
      selected[e.key] = row;
    }
    for (final col in [2, 3]) {
      guard(
        money(selected['assets']![col]) ==
            money(selected['liabilities']![col]) +
                money(selected['equity']![col]),
        'BS equality',
      );
      guard(
        money(unique(data[0], '부채및자본총계')[col]) ==
            money(selected['assets']![col]),
        'BS whole total',
      );
    }
    final ce = data[2];
    final whole = ce.first.length - 1;
    final ceWitnesses = <Map<String, dynamic>>[];
    for (final current in [true, false]) {
      final openLabel = profile[current ? 'ceOpen' : 'cePriorOpen'] as String,
          closeLabel = profile[current ? 'ceClose' : 'cePriorClose'] as String;
      final a = ce.indexOf(unique(ce, openLabel)),
          b = ce.indexOf(unique(ce, closeLabel));
      guard(a < b, 'CE opening/closing order');
      final ni = unique(ce.sublist(a + 1, b), profile['ceProfit'] as String);
      guard(ni.length == whole + 1, 'CE whole column');
      final close = ce[b], open = ce[a], col = current ? 2 : 3;
      guard(
        money(ni[whole]) == money(selected['netIncome']![col]) &&
            money(close[whole]) == money(selected['equity']![col]),
        'CE whole NI/equity',
      );
      if (current) {
        guard(
          money(open[whole]) == money(selected['equity']![3]),
          'CE opening prior BS',
        );
      }
      ceWitnesses.add({
        'opening': open,
        'netIncome': ni,
        'closing': close,
        'wholeColumn': whole,
      });
    }
    final cf = data[3],
        cfProfit = unique(cf, profile['cfProfit'] as String),
        cfOpen = unique(cf, profile['cfOpen'] as String),
        cfClose = unique(cf, profile['cfClose'] as String),
        cfChange = unique(cf, profile['cfChange'] as String);
    for (final col in [2, 3]) {
      guard(
        money(cfProfit[col]) == money(selected['netIncome']![col]),
        'CF printed NI witness',
      );
      final flows =
          money(selected['operatingCashFlow']![col]) +
          money(unique(cf, profile['cfInvest'] as String)[col]) +
          money(unique(cf, profile['cfFinance'] as String)[col]);
      guard(flows == money(cfChange[col]), 'CF activity/change');
      final fx = profile['cfFx'] == null
          ? BigInt.zero
          : money(unique(cf, profile['cfFx'] as String)[col]);
      guard(
        money(cfOpen[col]) + flows + fx == money(cfClose[col]),
        'CF opening/closing cash',
      );
    }
    guard(money(cfOpen[2]) == money(cfClose[3]), 'CF current/prior cash');
    if (receipt == '20230323001437') {
      final cash = unique(data[0], '현금및현금성자산');
      for (final col in [2, 3]) {
        guard(money(cash[col]) == money(cfClose[col]), 'BS CF cash');
      }
    }
    guard(
      !cf.any((r) => {'유형자산취득', '유형자산의취득'}.contains(compact(r.first))),
      'unexpected optional CAPEX total',
    );
    return selected.entries
        .map(
          (e) => <String, dynamic>{
            'rcept_no': receipt,
            'corp_code': corpCode,
            'bsns_year': '2022',
            'reprt_code': '11011',
            'fs_div': 'OFS',
            'sj_div': {'assets', 'liabilities', 'equity'}.contains(e.key)
                ? 'BS'
                : e.key == 'operatingCashFlow'
                ? 'CF'
                : 'CIS',
            'account_id': null,
            'account_nm': e.value.first,
            'thstrm_amount': money(e.value[2]).toString(),
            'frmtrm_amount': money(e.value[3]).toString(),
            'currency': 'KRW',
            'html_provenance': {
              'source': statementSource.toString(),
              'receipt': receipt,
              'corpCode': corpCode,
              'basis': 'OFS',
              'periodStart': '2022-01-01',
              'periodEnd': '2022-12-31',
              'printedAccount': e.value.first,
              'printedCurrentCells': [e.value[2]],
              'printedPriorCells': [e.value[3]],
              'printedUnit': '원',
              'scale': '1',
              'statementSha256': profile['sourceSha'],
              'coverSha256': profile['coverSha'],
              'fullStatementCollected': false,
              'uncollectedOptionalAccounts': ['capex'],
              'exactSevenCash': {
                'rule': 'exact-seven-bs-ce-cash-annual-v1',
                'accountKey': e.key,
                'wholeCeWitnesses': ceWitnesses,
                'cfNetIncomeCells': cfProfit,
                'cfOpeningCashCells': cfOpen,
                'cfClosingCashCells': cfClose,
                'cashCurrentPriorChecked': true,
              },
            },
          },
        )
        .toList();
  }
}
