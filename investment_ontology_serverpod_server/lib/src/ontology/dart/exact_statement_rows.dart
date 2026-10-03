import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../generated/protocol.dart';
import 'public_financial_html_fetch.dart';
import 'verified_annual_source_cache.dart';

/// A source-coordinate ledger for four exact current primary statement sources.
/// Whole filing/notes and historical comparative coverage are not asserted.
final class ExactStatementRows {
  ExactStatementRows._(
    this.receipt,
    this.corpCode,
    this.year,
    this.basis,
    this.primary,
    List<Map<String, dynamic>> rows,
    List<Map<String, dynamic>> ledger,
  ) : rows = _maps(rows),
      ledger = _maps(ledger),
      coreRows = _maps(primary.rows);
  final String receipt, corpCode;
  final int year;
  final FsDiv basis;
  final PublicFinancialHtmlSource primary;
  final List<Map<String, dynamic>> rows, ledger, coreRows;
  static List<Map<String, dynamic>> _maps(List<Map<String, dynamic>> value) =>
      List.unmodifiable(value.map((m) => _freeze(m) as Map<String, dynamic>));
  static Object? _freeze(Object? value) => value is Map
      ? Map<String, dynamic>.unmodifiable(
          value.map((k, v) => MapEntry(k as String, _freeze(v))),
        )
      : value is List
      ? List.unmodifiable(value.map(_freeze))
      : value;
  static const rule = 'exact-current-primary-row-enrichment-v1';
  static bool eligible(String receipt, FsDiv basis) =>
      (const {'20250320000036', '20230321000015'}.contains(receipt) &&
          basis == FsDiv.separate) ||
      (receipt == '20220310001159' &&
          (basis == FsDiv.consolidated || basis == FsDiv.separate));

  static Future<ExactStatementRows> prepare(
    DartFiling filing,
    Company company,
    FsDiv basis, {
    Future<List<int>> Function(String)? readAsset,
  }) async {
    if (!eligible(filing.rceptNo, basis)) {
      throw const FormatException('Unapproved exact row source');
    }
    final primary = await VerifiedAnnualSourceCache(readAsset: readAsset)
        .verifyExistingRows(filing, company, basis);
    final aone = filing.rceptNo != '20220310001159';
    final samsungSeparate = !aone && basis == FsDiv.separate;
    final expectedSha = switch (filing.rceptNo) {
      '20230321000015' =>
        '076f4b6fdde741e5532978dd718877fc76f4a5259a176f2eeffe29e70fe9748a',
      '20250320000036' =>
        '3d6e6c42e2ca18af9e0bdc9c141c659ed6b5ebcbb0afd6b3a02f41024a91d117',
      '20220310001159' when samsungSeparate =>
        '05d682e305415fba8d7a09d782d3a9185b93417db830a59bf0f03cb652138aa2',
      '20220310001159' =>
        '48a5a3b134b1f86a9fe8d06322c28095d9ec497164703fcd50be06918b6badc6',
      _ => throw const FormatException('Unapproved exact row digest'),
    };
    if (sha256.convert(utf8.encode(primary.statementHtml)).toString() !=
        expectedSha) {
      throw const FormatException('Exact row body digest mismatch');
    }
    final tables =
        RegExp(r'<table\b[^>]*>([\s\S]*?)</table>', caseSensitive: false)
            .allMatches(primary.statementHtml)
            .map(
              (t) => RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
                  .allMatches(t[1]!)
                  .map(
                    (r) => RegExp(
                      r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
                      caseSensitive: false,
                    ).allMatches(r[1]!).map((c) => _text(c[1]!)).toList(),
                  )
                  .toList(),
            )
            .toList();
    if (tables.length !=
        (aone
            ? 16
            : samsungSeparate
            ? 10
            : 8)) {
      throw const FormatException('Exact row table layout mismatch');
    }
    final mappings = switch (filing.rceptNo) {
      '20230321000015' => [
        ('BS', 3, 1, 46, [2]),
        ('CIS', 7, 1, 25, [2]),
        ('SCE', 11, 15, 22, [1, 2, 3, 4, 5]),
        ('CF', 15, 1, 80, [1]),
      ],
      '20250320000036' => [
        ('BS', 3, 1, 39, [2]),
        ('CIS', 7, 1, 24, [2]),
        ('SCE', 11, 13, 18, [1, 2, 3, 4, 5]),
        ('CF', 15, 1, 77, [1]),
      ],
      '20220310001159' when samsungSeparate => [
        ('BS', 1, 1, 40, [1, 2]),
        ('CIS', 3, 1, 56, [1, 2]),
        ('SCE', 5, 19, 28, [1, 2, 3, 4, 5, 6]),
        ('CF', 7, 1, 88, [1, 2]),
      ],
      '20220310001159' => [
        ('BS', 1, 1, 43, [1, 2]),
        ('CIS', 3, 1, 69, [1, 2]),
        ('SCE', 5, 24, 35, [1, 2, 3, 4, 5, 6, 7]),
        ('CF', 7, 1, 90, [1, 2]),
      ],
      _ => throw const FormatException('Unapproved exact row mapping'),
    };
    final rows = <Map<String, dynamic>>[], ledger = <Map<String, dynamic>>[];
    final consumedCore = <int>{};
    final from = '${filing.bsnsYear}-01-01', to = '${filing.bsnsYear}-12-31';
    for (final (kind, ti, first, end, columns) in mappings) {
      final table = tables[ti];
      if (table.length != end) {
        throw const FormatException('Exact row count changed');
      }
      final details = aone || samsungSeparate
          ? table.first.skip(1).toList()
          : [
              for (var col = 1; col <= 7; col++)
                col <= 5
                    ? '${table[0][1]} > ${table[1][col - 1]}'
                    : table[0][col == 6 ? 2 : 3],
            ];
      for (var ri = first; ri < end; ri++) {
        final raw = table[ri];
        final label = raw.first;
        final selected = [for (final col in columns) raw[col]];
        final eps = kind == 'CIS' && label.contains('주당');
        // Each CE component is a separate directly printed coordinate.
        final groups = kind == 'SCE'
            ? [
                for (final col in columns) [col],
              ]
            : [columns];
        for (final group in groups) {
          final cells = [for (final col in group) raw[col]];
          final values = cells.where((s) => s.isNotEmpty && s != '-').toList();
          final entry = <String, dynamic>{
            'statement': kind,
            'tableIndex': ti,
            'rowIndex': ri,
            'columns': group,
            'printedLabel': label,
            'rawRow': raw,
            'currentHeader': table.first,
            'printedCurrentCells': cells,
            'basis': basis.name,
            'periodStart': from,
            'periodEnd': to,
            'unit': eps ? null : '원',
            'printedTableUnit': '원',
            'printedUnitEvidence': tables[ti - 1].last.last,
            if (eps) 'nonMonetaryReason': '주당이익 행: 금액 fact 제외; 별도 단위 추정 없음',
            'source': primary.statementSource.toString(),
            'sha256': expectedSha,
            if (kind == 'SCE') 'component': details[group.single - 1],
            if (kind == 'SCE' && (ri == first || ri == end - 1))
              'valueAsOf': ri == first ? from : to,
          };
          ledger.add(entry);
          if (eps) {
            entry['state'] = 'nonmonetary-EPS';
            continue;
          }
          if (values.isEmpty) {
            entry['state'] = cells.any((s) => s == '-')
                ? 'printed-unavailable'
                : 'empty';
            entry['amount'] = null;
            continue;
          }
          if (values.length != 1) {
            throw const FormatException('Ambiguous exact current cell group');
          }
          final value = parsePrintedMonetaryCell(values.single);
          entry['amount'] = value.toString();
          final matches = [
            for (var i = 0; i < primary.rows.length; i++)
              if (primary.rows[i]['sj_div'] == kind &&
                  _compact(primary.rows[i]['account_nm'].toString()) ==
                      _compact(label) &&
                  primary.rows[i]['thstrm_amount'] == value.toString())
                i,
          ];
          if (matches.length > 1 ||
              (matches.isNotEmpty && !consumedCore.add(matches.single))) {
            throw const FormatException('Core coordinate duplicated');
          }
          if (matches.isNotEmpty) {
            entry['state'] = 'existing-core';
            continue;
          }
          entry['state'] = 'current-monetary';
          rows.add({
            'rcept_no': filing.rceptNo,
            'corp_code': company.corpCode,
            'bsns_year': '${filing.bsnsYear}',
            'reprt_code': '11011',
            'fs_div': basis == FsDiv.separate ? 'OFS' : 'CFS',
            'sj_div': kind,
            'account_id': null,
            'account_nm': label,
            'account_detail': kind == 'SCE' ? details[group.single - 1] : null,
            'ord': ti * 100000 + ri * 100 + group.first,
            'thstrm_nm': kind == 'BS'
                ? to
                : kind == 'SCE' && ri == first
                ? from
                : kind == 'SCE' && ri == end - 1
                ? to
                : '$from~$to',
            'thstrm_amount': value.toString(),
            'currency': 'KRW',
            'html_provenance': entry,
          });
        }
        // Preserve all raw cells, including note columns and comparisons, in
        // the coordinate ledger; only the proved current groups are monetary.
        if (selected.isEmpty) throw const FormatException('No current cells');
      }
    }
    if (consumedCore.length != primary.rows.length ||
        primary.rows.length != 8) {
      throw const FormatException(
        'Exact enrichment did not preserve all core rows',
      );
    }
    return ExactStatementRows._(
      filing.rceptNo,
      company.corpCode,
      filing.bsnsYear!,
      basis,
      primary,
      rows,
      ledger,
    );
  }

  Map<String, dynamic> get payload => {
    'rule': rule,
    'receipt': receipt,
    'corpCode': corpCode,
    'year': year,
    'basis': basis.name,
    'source': primary.statementSource.toString(),
    'sha256': primary.sourceDigest,
    'coreRowCount': coreRows.length,
    'additionalMonetaryFacts': rows.length,
    'periodScope': 'current annual primary statements only',
    'fullStatementCollected': false,
    'allStatementRowsVerified': false,
    'notesCollected': false,
    'BSHeaderTermConflict': receipt == '20250320000036',
    'ledger': ledger,
  };
  static String _compact(String s) => s.replaceAll(RegExp(r'\s+'), '');
  static String _text(String html) => html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Parses an explicitly printed integer; malformed grouping is never repaired.
  static BigInt parsePrintedMonetaryCell(String s) {
    s = _compact(s);
    if (!RegExp(
      r'^(?:-?(?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)|\((?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)\))$',
    ).hasMatch(s)) {
      throw const FormatException('Unprinted exact monetary amount');
    }
    return BigInt.parse(
      s.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
    );
  }
}
