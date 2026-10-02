import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One immutable official OFS audit document, retaining its own receipt.
/// This candidate has no runtime queue or general annual-cover exception.
abstract final class GneOwnAuditSource {
  static const receipt = '20260429001010';
  static const corp = '01188749';
  static const shellUri =
      'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260429001010';
  static const coverUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260429001010&dcmNo=11355074&eleId=2&offset=34814&length=2054&dtd=dart4.xsd';
  static const statementUri =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260429001010&dcmNo=11355074&eleId=4&offset=44211&length=229638&dtd=dart4.xsd';
  static const shellSha =
      '5a2bd4be0201430f7ca7baf961f68c55b47328c4c48340830abdf710e6962709';
  static const coverSha =
      'df7590ebfd844c8d4e20963a21f8d8011671aafd93b4f7e87fc878051d6d7d87';
  static const statementSha =
      'd9ec17630416bf4b16452eae6558e001662ce22ef139ce2a81ecdbca9e9e52c1';
  static String _sha(String raw) => sha256.convert(utf8.encode(raw)).toString();
  static String _text(String raw) => raw
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  static String _compact(String raw) => _text(raw).replaceAll(' ', '');

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
    if (sourceReceipt != receipt ||
        corpCode != corp ||
        consolidated ||
        periodStart != DateTime.utc(2025) ||
        periodEnd != DateTime.utc(2025, 12, 31) ||
        shellSource.toString() != shellUri ||
        coverSource.toString() != coverUri ||
        statementSource.toString() != statementUri ||
        _sha(shell) != shellSha ||
        _sha(cover) != coverSha ||
        _sha(statement) != statementSha) {
      throw const FormatException('GNE immutable own audit source mismatch');
    }
    final ids = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
        .allMatches(shell)
        .map((m) => m.group(1))
        .toSet();
    if (ids.length != 1 || ids.single != corp) {
      throw const FormatException('GNE own corporate shell mismatch');
    }
    final coverText = _compact(cover);
    if (!coverText.startsWith('주식회사지앤이헬스케어재무제표에대한감사보고서제12기') ||
        !coverText.contains('2025년01월01일부터2025년12월31일까지')) {
      throw const FormatException('GNE own audit cover period mismatch');
    }
    final tables = RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(statement).toList();
    for (final title in const [
      (6, '재무상태표', '2025년12월31일현재'),
      (9, '손익계산서', '2025년01월01일부터2025년12월31일까지'),
      (12, '자본변동표', '2025년01월01일부터2025년12월31일까지'),
      (15, '현금흐름표', '2025년01월01일부터2025년12월31일까지'),
    ]) {
      final start = tables[title.$1].start;
      final nearby = _compact(statement.substring(start - 1800, start));
      final heading = nearby.lastIndexOf(title.$2);
      if (heading < 0 ||
          !nearby
              .substring(heading)
              .startsWith('${title.$2}제12(당)기${title.$3}') ||
          !nearby.substring(heading).endsWith('회사명:(주)지앤이헬스케어(단위:원)')) {
        throw const FormatException('GNE direct statement title/unit mismatch');
      }
    }
    List<List<String>> rows(int index) => [
      for (final tr in RegExp(
        r'<TR\b[^>]*>(.*?)</TR>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(tables[index].group(1)!))
        [
          for (final cell in RegExp(
            r'<T[DH]\b[^>]*>(.*?)</T[DH]>',
            caseSensitive: false,
            dotAll: true,
          ).allMatches(tr.group(1)!))
            _text(cell.group(1)!),
        ],
    ];
    // Observed primary tables, excluding all later notes and parent/component rows.
    const accounts = [
      (6, 'BS', '자 산 총 계', '6973822992'),
      (6, 'BS', '부 채 총 계', '2274518676'),
      (6, 'BS', '자 본 총 계', '4699304316'),
      (9, 'CIS', 'I. 매출액', '4896995158'),
      (9, 'CIS', 'V. 영업이익(손실)', '371658968'),
      (9, 'CIS', 'X. 당기순이익(손실)', '377901260'),
      (15, 'CF', 'Ⅰ.영업활동으로 인한 현금흐름', '701750215'),
    ];
    final result = <Map<String, dynamic>>[];
    for (final a in accounts) {
      final tableRows = rows(a.$1);
      final header = tableRows.where((r) => r.isNotEmpty && r.first == '과 목');
      if (header.length != 1 || _compact(header.single[1]) != '제12(당)기') {
        throw const FormatException('GNE current whole column mismatch');
      }
      final matches = tableRows.where((r) => r.isNotEmpty && r.first == a.$3);
      if (matches.length != 1 ||
          matches.single.length != 5 ||
          matches.single[1].isNotEmpty ||
          matches.single[2].replaceAll(',', '') != a.$4) {
        throw const FormatException('GNE direct current whole amount mismatch');
      }
      result.add({
        'rcept_no': receipt,
        'corp_code': corp,
        'bsns_year': '2025',
        'reprt_code': '11011',
        'account_id': null,
        'account_nm': matches.single.first,
        'account_detail': '-',
        'sj_div': a.$2,
        'thstrm_nm': a.$2 == 'BS' ? '2025-12-31' : '2025-01-01~2025-12-31',
        'thstrm_amount': a.$4,
        'currency': 'KRW',
        'html_provenance': {
          'source': statementUri,
          'coverSource': coverUri,
          'sourceReceipt': receipt,
          'ruleVersion': 'gne-own-audit-whole7-v1',
          'sourceSha256': statementSha,
          'coverSha256': coverSha,
          'shellSha256': shellSha,
          'basis': 'OFS',
          'tableIndex': a.$1,
          'currentColumn': 2,
          'currentHeader': header.single[1],
          'printedLabel': matches.single.first,
          'printedAmount': matches.single[2],
          'unit': '원',
          'periodStart': '2025-01-01',
          'periodEnd': '2025-12-31',
        },
      });
    }
    if (BigInt.parse(accounts[0].$4) !=
        BigInt.parse(accounts[1].$4) + BigInt.parse(accounts[2].$4)) {
      throw const FormatException('GNE BS whole identity mismatch');
    }
    final ce = rows(12);
    List<String> unique(String label) {
      final found = ce.where((r) => r.isNotEmpty && r.first == label);
      if (found.length != 1 || found.single.length != 7) {
        throw const FormatException('GNE independent CE whole row mismatch');
      }
      return found.single;
    }

    unique('2025.01.01 (당기초)');
    if (unique('2025.12.31 (당기말)').last != '4,699,304,316' ||
        unique('당기순이익').last != '377,901,260' ||
        ce.first.last != '총 계') {
      throw const FormatException('GNE independent CE whole identity mismatch');
    }
    return result;
  }
}
