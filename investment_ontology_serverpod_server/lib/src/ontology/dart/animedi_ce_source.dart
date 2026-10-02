import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Two pinned OFS sources. Only nonnumeric CE separator cells are excluded
/// from the interpretation grid; original bytes and Source SHA stay unchanged.
abstract final class AnimediCeSource {
  static const profiles = <String, Map<String, String>>{
    '20240320000248': {
      'year': '2023',
      'cover': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240320000248&dcmNo=9733583&eleId=1&offset=955&length=4005&dtd=dart4.xsd',
      'statement': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240320000248&dcmNo=9733583&eleId=21&offset=270347&length=66053&dtd=dart4.xsd',
      'coverSHA':
          '3a0342c6358530706c42aca0582e0de9b1a0c0a979f06aade8cca432e310b525',
      'statementSHA':
          '70fa1a56d3c220edbd5f0ee7cb5d5db5b6dc69d482605ecf9b8f3a98f77f628c',
    },
    '20230323000586': {
      'year': '2022',
      'cover': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230323000586&dcmNo=9094927&eleId=1&offset=815&length=4034&dtd=dart3.xsd',
      'statement': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230323000586&dcmNo=9094927&eleId=21&offset=253919&length=67454&dtd=dart3.xsd',
      'coverSHA':
          '22f8dc95c169929dd843fa69ddf6b4e5b0a7e5a41aa5d7c7d3c703615c1851bd',
      'statementSHA':
          '3dd48711cce059e53b3aa369cf58a90a067af4ed34237fdce00d13e61e38da89',
    },
  };
  static String compact(String s) =>
      s.replaceAll(RegExp(r'<[^>]+>|&nbsp;|\s'), '');
  static Map<String, dynamic> verify({
    required String receipt,
    required String corp,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Uri coverSource,
    required Uri statementSource,
    required String cover,
    required String statement,
  }) {
    final p = profiles[receipt];
    if (p == null ||
        corp != '01507810' ||
        consolidated ||
        start != DateTime.utc(int.parse(p['year']!)) ||
        end != DateTime.utc(int.parse(p['year']!), 12, 31) ||
        coverSource.toString() != p['cover'] ||
        statementSource.toString() != p['statement'] ||
        sha256.convert(utf8.encode(cover)).toString() != p['coverSHA'] ||
        sha256.convert(utf8.encode(statement)).toString() !=
            p['statementSHA']) {
      throw const FormatException('Animedi exact original source mismatch');
    }
    final year = int.parse(p['year']!), proofs = <Map<String, dynamic>>[];
    for (final table in RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(statement)) {
      final prefix = compact(statement.substring(0, table.start));
      final ce = prefix.lastIndexOf('자본변동표');
      if (ce < 0 ||
          ['재무상태표', '손익계산서', '현금흐름표'].any((x) => prefix.lastIndexOf(x) > ce)) {
        continue;
      }
      final first = RegExp(
        r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(table[1]!);
      if (first == null || compact(first[1]!) != '과목') continue;
      final local = prefix.substring(ce);
      final term = year - 2015;
      if (!local.contains('제$term기$year년1월1일부터$year년12월31일까지') ||
          !local.endsWith('(단위:원)')) {
        throw const FormatException(
          'Animedi CE printed current period/unit mismatch',
        );
      }
      final rows = <List<String>>[];
      var excluded = 0;
      for (final row in RegExp(
        r'<TR\b[^>]*>(.*?)</TR>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(table[1]!)) {
        final cells = RegExp(
          r'<T[DH]\b([^>]*)>(.*?)</T[DH]>',
          caseSensitive: false,
          dotAll: true,
        ).allMatches(row[1]!).toList();
        if (cells.length == 1 &&
            RegExp(
              r'''colspan=['"]7['"]''',
              caseSensitive: false,
            ).hasMatch(cells.single[1]!)) {
          if (!{
                '총포괄손익:',
                '자본에직접반영된소유주와의거래:',
              }.contains(compact(cells.single[2]!)) ||
              RegExp(
                r'rowspan',
                caseSensitive: false,
              ).hasMatch(cells.single[1]!)) {
            throw const FormatException(
              'Animedi separator is not literal nonnumeric CE',
            );
          }
          excluded++;
          continue;
        }
        if (cells.any(
          (x) =>
              RegExp(r'colspan|rowspan', caseSensitive: false).hasMatch(x[1]!),
        )) {
          throw const FormatException('Animedi CE numeric span not supported');
        }
        rows.add(cells.map((x) => compact(x[2]!)).toList());
      }
      if (rows.isEmpty) continue;
      if (rows.first.join('|') != '과목|자본금|자본잉여금|자본조정|기타포괄손익누계액|결손금|합계' ||
          excluded != 6) {
        throw const FormatException(
          'Animedi CE exact header/separators mismatch',
        );
      }
      int unique(String label) {
        final found = [
          for (var i = 1; i < rows.length; i++)
            if (rows[i].first == label) i,
        ];
        if (found.length != 1) {
          throw const FormatException('Animedi CE actual date ambiguous');
        }
        return found.single;
      }

      final opening = unique('$year년1월1일'), closing = unique('$year년12월31일');
      final losses = [
        for (var i = opening + 1; i < closing; i++)
          if (rows[i].first == '당기순손실') i,
      ];
      if (opening >= closing || losses.length != 1) {
        throw const FormatException(
          'Animedi CE current whole profit ambiguous',
        );
      }
      String whole(int i) {
        final r = rows[i];
        if (r.length != 7 || !RegExp(r'^\(?[0-9,]+\)?$').hasMatch(r[6])) {
          throw const FormatException('Animedi whole value missing');
        }
        return BigInt.parse(
          r[6].replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
        ).toString();
      }

      proofs.add({
        'mode': 'animedi-exact-ce-separator-v1',
        'source': statementSource.toString(),
        'sourceSHA': p['statementSHA'],
        'receipt': receipt,
        'corpCode': corp,
        'periodStart': '$year-01-01',
        'periodEnd': '$year-12-31',
        'unit': '원',
        'wholeTotalColumn': 6,
        'literalSeparatorRowsExcluded': excluded,
        'originalRawUnchanged': true,
        'closingEquity': whole(closing),
        'currentProfit': whole(losses.single),
      });
    }
    if (proofs.length != 1) {
      throw const FormatException('Animedi unique whole CE absent');
    }
    return proofs.single;
  }
}
