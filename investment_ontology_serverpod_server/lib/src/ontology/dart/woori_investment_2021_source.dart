import 'dart:convert';

import 'package:crypto/crypto.dart';

abstract final class WooriInvestment2021Source {
  static const receipt = '20220715000446';
  static const corp = '00231664';
  static const rule = 'woori-investment-2021-whole7-v1';
  static final List<dynamic> _profiles = jsonDecode(
    r'''[{"basis":"cfs","sources":[{"label":"shell","file":"shell.html","url":"https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20220715000446","sha256":"068408136e62d677a4ecb4acc00b771faee9acd71e483d053970cd8882771674"},{"label":"cover","file":"cover.html","url":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220715000446&dcmNo=8736849&eleId=3&offset=9861&length=4036&dtd=dart3.xsd","sha256":"c1d7749d7bc2c8b26d471ffe71704774d59806a51795f2a59a7af1032822e975"},{"label":"cfs","file":"cfs.html","url":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220715000446&dcmNo=8736849&eleId=19&offset=174946&length=61519&dtd=dart3.xsd","sha256":"4c5fc3012af0c2b5fd7bf48b1bfa921f50d80d45a73e5334c42f0f7797490128"}],"rows":[{"table":1,"key":"assets","label":"자산총계","value":"922989936891"},{"table":1,"key":"liabilities","label":"부채총계","value":"195094672278"},{"table":1,"key":"equity","label":"자본총계","value":"727895264613"},{"table":3,"key":"revenue","label":"I.영업수익","value":"824156954553"},{"table":3,"key":"operating","label":"III.영업이익","value":"792614757750"},{"table":3,"key":"profit","label":"VII.당기순이익","value":"619422529993"},{"table":7,"key":"cfo","label":"I.영업활동으로인한순현금흐름","value":"17600248788"}]},{"basis":"ofs","sources":[{"label":"shell","file":"shell.html","url":"https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20220715000446","sha256":"068408136e62d677a4ecb4acc00b771faee9acd71e483d053970cd8882771674"},{"label":"cover","file":"cover.html","url":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220715000446&dcmNo=8736849&eleId=3&offset=9861&length=4036&dtd=dart3.xsd","sha256":"c1d7749d7bc2c8b26d471ffe71704774d59806a51795f2a59a7af1032822e975"},{"label":"ofs","file":"ofs.html","url":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220715000446&dcmNo=8736849&eleId=21&offset=689805&length=56024&dtd=dart3.xsd","sha256":"474695664a66d22af81dfd008309e5f7625cf432ad22fed9856bc3f6c380cb5d"}],"rows":[{"table":1,"key":"assets","label":"자산총계","value":"919280938907"},{"table":1,"key":"liabilities","label":"부채총계","value":"191490588322"},{"table":1,"key":"equity","label":"자본총계","value":"727790350585"},{"table":3,"key":"revenue","label":"I.영업수익","value":"811879819525"},{"table":3,"key":"operating","label":"III.영업이익","value":"793507225421"},{"table":3,"key":"profit","label":"VII.당기순이익","value":"620087515295"},{"table":7,"key":"cfo","label":"I.영업활동으로인한순현금흐름","value":"2577554687"}]}]''',
  );
  static String _text(String s) => s
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  static String _compact(String s) => _text(s).replaceAll(' ', '');
  static List<Map<String, dynamic>> parse({
    required String shell,
    required String cover,
    required String statement,
    required Uri shellSource,
    required Uri coverSource,
    required Uri statementSource,
    required String sourceReceipt,
    required String corpCode,
    required DateTime periodStart,
    required DateTime periodEnd,
    required bool consolidated,
  }) {
    final p = _profiles[consolidated ? 0 : 1] as Map;
    final sources = p['sources'] as List;
    final raw = [shell, cover, statement],
        uris = [shellSource, coverSource, statementSource];
    if (sourceReceipt != receipt ||
        corpCode != corp ||
        periodStart != DateTime.utc(2021) ||
        periodEnd != DateTime.utc(2021, 12, 31)) {
      throw const FormatException('Woori exact period identity mismatch');
    }
    for (var i = 0; i < 3; i++) {
      if (uris[i].toString() != sources[i]['url'] ||
          sha256.convert(utf8.encode(raw[i])).toString() !=
              sources[i]['sha256']) {
        throw const FormatException('Woori immutable raw URI/SHA mismatch');
      }
    }
    final ids = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
        .allMatches(shell)
        .map((m) => m.group(1))
        .toSet();
    if (ids.length != 1 ||
        ids.single != corp ||
        !_compact(cover).contains('2021년01월01일부터2021년12월31일까지')) {
      throw const FormatException('Woori official cover/corp mismatch');
    }
    final ts = RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(statement).toList();
    List<List<String>> rows(int n) => [
      for (final tr in RegExp(
        r'<TR\b[^>]*>(.*?)</TR>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(ts[n].group(1)!))
        [
          for (final c in RegExp(
            r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
            caseSensitive: false,
            dotAll: true,
          ).allMatches(tr.group(1)!))
            _text(c.group(1)!),
        ],
    ];
    for (final index in [1, 3, 5, 7]) {
      final before = _compact(
        statement.substring(
          index == 1 ? 0 : ts[index - 2].end,
          ts[index].start,
        ),
      );
      if (!before.contains('(단위:원)') ||
          !before.contains('우리기술투자주식회사') ||
          !before.contains('제26(당)기')) {
        throw const FormatException('Woori four-table title/unit mismatch');
      }
    }
    final result = <Map<String, dynamic>>[];
    for (final a in p['rows'] as List) {
      final index = a['table'] as int;
      final rs = rows(index);
      if (_compact(rs.first.first) != '과목' ||
          _compact(rs.first[1]) != '제26(당)기') {
        throw const FormatException('Woori current column mismatch');
      }
      final matches = rs.where(
        (r) => r.isNotEmpty && _compact(r.first) == a['label'],
      );
      if (matches.length != 1 ||
          matches.single.length != 4 ||
          matches.single[1].replaceAll(',', '') != a['value']) {
        throw const FormatException('Woori direct whole row mismatch');
      }
      final r = matches.single;
      result.add({
        'rcept_no': receipt,
        'corp_code': corp,
        'bsns_year': '2021',
        'reprt_code': '11011',
        'account_id': null,
        'account_nm': r.first,
        'account_detail': '-',
        'sj_div': index == 1
            ? 'BS'
            : index == 3
            ? 'CIS'
            : 'CF',
        'thstrm_nm': index == 1 ? '2021-12-31' : '2021-01-01~2021-12-31',
        'thstrm_amount': a['value'],
        'currency': 'KRW',
        'html_provenance': {
          'source': statementSource.toString(),
          'coverSource': coverSource.toString(),
          'sourceReceipt': receipt,
          'ruleVersion': rule,
          'sourceSha256': sources[2]['sha256'],
          'coverSha256': sources[1]['sha256'],
          'shellSha256': sources[0]['sha256'],
          'basis': consolidated ? 'CFS' : 'OFS',
          'tableIndex': index,
          'currentColumn': 1,
          'currentHeader': rs.first[1],
          'printedLabel': r.first,
          'printedAmount': r[1],
          'unit': '원',
          'periodStart': '2021-01-01',
          'periodEnd': '2021-12-31',
          'fullStatementCollected': false,
          'uncollectedOptionalAccounts': ['capex'],
        },
      });
    }
    BigInt value(int n) => BigInt.parse(result[n]['thstrm_amount'] as String);
    if (value(0) != value(1) + value(2)) {
      throw const FormatException('Woori BS identity mismatch');
    }
    final ce = rows(5);
    if (_compact(ce.first.last) != '총계') {
      throw const FormatException('Woori whole CE column missing');
    }
    final start = ce.indexWhere(
      (r) =>
          r.isNotEmpty &&
          _compact(r.first) ==
              (consolidated ? '2021.1.1(당기초)' : '2021.01.01(당기초)'),
    );
    final end = ce.indexWhere(
      (r) => r.isNotEmpty && _compact(r.first) == '2021.12.31(당기말)',
    );
    final profit = ce
        .sublist(start + 1, end)
        .where((r) => r.isNotEmpty && _compact(r.first) == '당기순이익');
    if (start < 0 ||
        end <= start ||
        profit.length != 1 ||
        profit.single.last.replaceAll(',', '') != value(5).toString() ||
        ce[end].last.replaceAll(',', '') != value(2).toString()) {
      throw const FormatException('Woori whole CE proof mismatch');
    }
    final cf = rows(7);
    List<String> unique(String label) =>
        cf.singleWhere((r) => r.isNotEmpty && _compact(r.first) == label);
    BigInt money(String s) => BigInt.parse(
      s.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
    );
    final investing = money(unique('II.투자활동으로인한현금흐름')[1]);
    final financing = money(unique('III.재무활동으로인한현금흐름')[1]);
    final fx = unique('IV.현금및현금성자산의환율변동효과')[1];
    final increase = money(unique('V.현금및현금성자산의증가(감소)(I+II+III+IV)')[1]);
    final opening = money(unique('VI.기초의현금및현금성자산')[1]);
    final closing = money(unique('VII.기말의현금및현금성자산')[1]);
    final bsCash = rows(1)
        .singleWhere((r) => r.isNotEmpty && _compact(r.first) == '1.현금및현금성자산');
    final activity = value(6) + investing + financing;
    if ((consolidated ? activity + money(fx) : activity) != increase ||
        (!consolidated && fx != '-') ||
        opening + increase != closing ||
        money(bsCash[1]) != closing ||
        money(bsCash[2]) != opening) {
      throw const FormatException('Woori direct cash rollforward mismatch');
    }
    for (final r in result) {
      (r['html_provenance'] as Map)['wholeCEProof'] = {
        'wholeNetIncome': value(5).toString(),
        'closingEquity': value(2).toString(),
      };
      (r['html_provenance'] as Map)['cashRollforward'] = {
        'opening': opening.toString(),
        'increase': increase.toString(),
        'closing': closing.toString(),
        'printedFx': fx,
        'fxAmountAvailable': consolidated,
        'threeActivitySum': activity.toString(),
        'bsCurrentPriorCashMatched': true,
      };
    }
    return result;
  }
}
