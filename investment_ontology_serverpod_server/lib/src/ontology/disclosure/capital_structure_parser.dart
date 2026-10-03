import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:cp949_codec/cp949_codec.dart';
import 'package:crypto/crypto.dart';

/// Reads only explicitly headed issuer capital tables. No prose inference.
abstract final class CapitalStructureParser {
  static const version = 3;
  static String plain(String s) => s
      .replaceAll(RegExp(r'<BR\s*/?>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (m) => String.fromCharCode(int.parse(m[1]!)),
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  static String compact(String s) => s.replaceAll(RegExp(r'\s+'), '');
  static String? integer(String s) {
    final v = s.replaceAll(',', '').trim();
    return RegExp(r'^\d+$').hasMatch(v) ? v : null;
  }

  static String? date(String s) {
    final m = RegExp(r'(\d{4})[.년/-]\s*(\d{1,2})[.월/-]\s*(\d{1,2})')
        .firstMatch(s);
    if (m == null) return null;
    final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
    final value = DateTime.utc(y, mo, d);
    if (value.year != y || value.month != mo || value.day != d) return null;
    return value.toIso8601String().substring(0, 10);
  }

  static List<List<String>> grid(String table) {
    final rows = <List<String>>[];
    final pending = <int, ({String value, int left})>{};
    for (final tr in RegExp(
      r'<TR\b[^>]*>(.*?)</TR>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(table)) {
      final row = <int, String>{};
      for (final e in pending.entries.toList()) {
        row[e.key] = e.value.value;
        if (e.value.left == 1) {
          pending.remove(e.key);
        } else {
          pending[e.key] = (value: e.value.value, left: e.value.left - 1);
        }
      }
      var col = 0;
      for (final cell in RegExp(
        r'<(TD|TH|TE|TU)\b([^>]*)>(.*?)</\1>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(tr[1]!)) {
        while (row.containsKey(col)) {
          col++;
        }
        int span(String attr) =>
            int.tryParse(
              RegExp(
                    '$attr\\s*=\\s*["\']?(\\d+)',
                    caseSensitive: false,
                  ).firstMatch(cell[2]!)?[1] ??
                  '',
            ) ??
            1;
        final across = span('colspan'), down = span('rowspan');
        if (across < 1 || down < 1 || across > 40 || down > 100) {
          throw const FormatException('Invalid capital table span');
        }
        final value = plain(cell[3]!);
        for (var i = 0; i < across; i++) {
          if (row.containsKey(col + i)) {
            throw const FormatException('Overlapping capital cells');
          }
          row[col + i] = value;
          if (down > 1) pending[col + i] = (value: value, left: down - 1);
        }
        col += across;
      }
      if (row.isNotEmpty) {
        rows.add([
          for (var i = 0; i <= row.keys.reduce((a, b) => a > b ? a : b); i++)
            row[i] ?? '',
        ]);
      }
    }
    return rows;
  }

  static String fromZip(List<int> zip, String receipt, String companyName) {
    final archive = ZipDecoder().decodeBytes(zip);
    final candidates = <({String name, String xml})>[];
    for (final f in archive.files) {
      if (!f.isFile || !f.name.toLowerCase().endsWith('.xml')) continue;
      String xml;
      try {
        xml = utf8.decode(f.content);
      } on FormatException {
        xml = const CP949Codec().decode(f.content);
      }
      if (xml.contains('\uFFFD')) continue;
      if (!RegExp(
        r'<DOCUMENT-NAME[^>]*>\s*(사업|반기|분기)보고서',
        dotAll: true,
      ).hasMatch(xml)) {
        continue;
      }
      final name = RegExp(
        r'<COMPANY-NAME\b[^>]*>(.*?)</COMPANY-NAME>',
        dotAll: true,
      ).firstMatch(xml);
      String normalized(String s) =>
          compact(plain(s)).replaceAll(RegExp(r'주식회사|\(주\)|㈜'), '');
      if (name == null || normalized(name[1]!) != normalized(companyName)) {
        continue;
      }
      candidates.add((name: f.name, xml: xml));
    }
    final exact = candidates
        .where((f) => f.name.split('/').last == '$receipt.xml')
        .toList();
    if (exact.length == 1) return exact.single.xml;
    if (candidates.length != 1) {
      throw const FormatException(
        'Issuer capital document ambiguous or absent',
      );
    }
    return candidates.single.xml;
  }

  static Map<String, dynamic> parse(
    String document, {
    required String receipt,
    required String periodEnd,
    required String companyName,
  }) {
    final tables = RegExp(
      r'<TABLE\b[^>]*>.*?</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(document).toList();
    final entries = <Map<String, dynamic>>[], stocks = <Map<String, dynamic>>[];
    final states = <String, String>{
      for (final k in ['CB', 'BW', 'EB']) k: 'missing',
    };
    final balanceStates = <String, String>{
      for (final k in ['CB', 'BW', 'EB']) k: 'missing',
    };
    final seen = <String>{};
    String? heading;
    String? stockDate;
    var cursor = 0, context = '';
    final titles = RegExp(r'미상환\s*(전환사채|신주인수권부사채|교환사채)(?:\s*등)?\s*발행\s*현황');
    void inspect(String text) {
      final matches = titles.allMatches(text).toList();
      for (var i = 0; i < matches.length; i++) {
        final match = matches[i];
        heading = switch (match[1]) {
          '전환사채' => 'CB',
          '신주인수권부사채' => 'BW',
          _ => 'EB',
        };
        context = text.substring(
          match.start,
          i + 1 < matches.length ? matches[i + 1].start : text.length,
        );
        final tail = context.substring(match.end - match.start);
        if (RegExp(r'해당\s*사항(?:이)?\s*없|해당\s*없|발행한\s*사실이\s*없').hasMatch(tail)) {
          states[heading!] = 'none';
        }
      }
    }

    for (final table in tables) {
      final before = plain(document.substring(cursor, table.start));
      inspect(before);
      stockDate = date(before) ?? stockDate;
      cursor = table.end;
      final g = grid(table.group(0)!);
      if (g.isEmpty) continue;
      final flat = g.map((r) => r.join(' ')).join(' ');
      inspect(flat);
      if (g.length <= 2 && flat.contains('기준일')) stockDate = date(flat);
      // Snapshot denominator, from the very same document and table period.
      final issuedRow = g
          .where(
            (r) => r.any(
              (c) =>
                  compact(c).contains('발행주식의총수') &&
                  !compact(c).contains('현재까지'),
            ),
          )
          .firstOrNull;
      if (issuedRow != null && stockDate == periodEnd) {
        final kinds = g
            .where(
              (r) => r.any(
                (c) => RegExp(r'^(보통주식?|우선주식?|종류주식|합계)$').hasMatch(compact(c)),
              ),
            )
            .firstOrNull;
        if (kinds != null && kinds.length == issuedRow.length) {
          for (var col = 0; col < kinds.length; col++) {
            final kind = compact(kinds[col]);
            if (!RegExp(r'^(보통주식?|우선주식?|종류주식|합계)$').hasMatch(kind)) continue;
            String? value(String label) => g
                .where((r) => r.any((c) => compact(c).contains(label)))
                .firstOrNull
                ?.elementAtOrNull(col);
            stocks.add({
              'kind': kind,
              'issued': integer(issuedRow[col]),
              'authorized': integer(value('발행할주식의총수') ?? ''),
              'treasury': integer(value('자기주식수') ?? ''),
            });
          }
        }
      }
      if (heading == null) continue;
      // Unit/date-only table belongs to the following capital table.
      if (!flat.contains('가능주식') && !flat.contains('대상주식수')) {
        if (g.length <= 2 && flat.contains('단위')) {
          context += ' $flat';
        } else if (flat.contains('해당사항')) {
          inspect('$context $flat');
        }
        continue;
      }
      final key = heading!;
      final sharePattern = RegExp(
        r'(전환가능주식수|행사가능주식수|신주인수권행사가능주식수|교환가능주식수|교환대상주식수)',
      );
      final headerEnd = g.indexWhere(
        (r) => r.any((v) => sharePattern.hasMatch(compact(v))),
      );
      if (headerEnd < 0) continue;
      final width = g[headerEnd].length;
      final headers = [
        for (var col = 0; col < width; col++)
          g
              .take(headerEnd + 1)
              .map((r) => r.elementAtOrNull(col) ?? '')
              .toSet()
              .join(' '),
      ];
      int index(bool Function(String) p) {
        final matches = [
          for (var i = 0; i < headers.length; i++)
            if (p(compact(headers[i]))) i,
        ];
        return matches.length == 1 ? matches.single : -1;
      }

      final sharesCol = index((v) => sharePattern.hasMatch(v));
      final balanceCol = index(
        (v) =>
            v.contains('미상환') &&
            (v.contains('권면') || v.contains('잔액') || v.contains('총액')),
      );
      final priceCol = index((v) => RegExp(r'전환가액|행사가액|행사가격|교환가액').hasMatch(v));
      final kindCol = index((v) => v.contains('주식의종류') || v.contains('대상주식종류'));
      final seriesCol = index((v) => v.contains('회차'));
      final issueCol = index((v) => v.contains('발행일') && !v.contains('발행일정'));
      final maturityCol = index((v) => v.contains('만기일'));
      final periodCol = index(
        (v) =>
            v.contains('청구가능기간') ||
            v.contains('행사가능기간') ||
            v.contains('행사기간') ||
            v.contains('청구기간'),
      );
      final ratioCol = index((v) => RegExp(r'전환비율|행사비율|교환비율').hasMatch(v));
      final moneyUnit = RegExp(r'단위\s*[:：]\s*(백만원|천원|원)')
          .firstMatch(context)?[1];
      final asOf = date(context);
      if (asOf != periodEnd ||
          !context.contains('주') ||
          sharesCol < 0 ||
          balanceCol < 0 ||
          kindCol < 0) {
        states[key] = 'partial';
        balanceStates[key] = 'partial';
        heading = null;
        continue;
      }
      var rows = 0, invalid = false, invalidBalance = moneyUnit == null;
      for (final r in g.skip(headerEnd + 1)) {
        if (r.length != width) {
          invalid = true;
          invalidBalance = true;
          continue;
        }
        if (r.any((v) => RegExp(r'^(합계|총계)$').hasMatch(compact(v)))) continue;
        final qty = integer(r[sharesCol]), balance = integer(r[balanceCol]);
        if (qty == null || balance == null) {
          invalid = true;
          invalidBalance = true;
          continue;
        }
        final series = seriesCol < 0 ? r.first : r[seriesCol];
        final identity = '$key|${compact(series)}';
        if (!seen.add(identity)) {
          invalid = true;
          invalidBalance = true;
          continue;
        }
        final price = priceCol < 0 ? null : integer(r[priceCol]);
        final scale = switch (moneyUnit) {
          '백만원' => 1000000,
          '천원' => 1000,
          '원' => 1,
          _ => null,
        };
        var validation = 'unverified';
        final ratio = ratioCol < 0 ? null : integer(r[ratioCol]);
        if (scale != null &&
            price != null &&
            ratio != null &&
            BigInt.parse(price) > BigInt.zero) {
          final expected =
              BigInt.parse(balance) *
              BigInt.from(scale) *
              BigInt.parse(ratio) ~/
              (BigInt.parse(price) * BigInt.from(100));
          validation = (expected - BigInt.parse(qty)).abs() <= BigInt.one
              ? 'verified'
              : 'mismatch';
        } else if (BigInt.parse(qty) == BigInt.zero &&
            BigInt.parse(balance) == BigInt.zero) {
          validation = 'verified';
        }
        if (validation != 'verified') invalid = true;
        entries.add({
          'type': key,
          'series': series,
          'issueDate': issueCol < 0 ? null : date(r[issueCol]),
          'maturityDate': maturityCol < 0 ? null : date(r[maturityCol]),
          'stockKind': r[kindCol],
          'balance': balance,
          'unit': moneyUnit,
          'price': price,
          'shares': qty,
          'exercisePeriod': periodCol < 0 ? null : r[periodCol],
          'validation': validation,
          'balanceValidation': moneyUnit == null ? 'unverified' : 'verified',
          'asOf': asOf,
          'evidence': r.join(' | '),
        });
        rows++;
      }
      states[key] = rows == 0 || invalid || states[key] == 'partial'
          ? 'partial'
          : 'verified';
      balanceStates[key] = rows == 0 || invalidBalance ? 'partial' : 'verified';
      heading = null;
    }
    inspect(plain(document.substring(cursor)));
    // Duplicate tables or contradictory absence cannot produce a complete sum.
    for (final key in states.keys) {
      if (states[key] == 'none' && entries.any((e) => e['type'] == key)) {
        states[key] = 'partial';
        balanceStates[key] = 'partial';
      }
      if (states[key] == 'none') balanceStates[key] = 'none';
      if (states[key] == 'partial' && balanceStates[key] == 'missing') {
        balanceStates[key] = 'partial';
      }
    }
    final uniqueStocks = <String, Map<String, dynamic>>{};
    for (final s in stocks) {
      if (uniqueStocks.containsKey(s['kind'])) {
        uniqueStocks.clear();
        break;
      }
      uniqueStocks[s['kind'] as String] = s;
    }
    return {
      'version': version,
      'receipt': receipt,
      'periodEnd': periodEnd,
      'companyName': companyName,
      'states': states,
      'balanceStates': balanceStates,
      'entries': entries,
      'stocks': uniqueStocks.values.toList(),
      'bodySha256': sha256.convert(utf8.encode(document)).toString(),
    };
  }
}
