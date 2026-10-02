import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'linked_correction_audit_source.dart';
import 'same_receipt_audit_source.dart';

/// One immutable correction/audit pair. Only seven primary current rows match;
/// this is not a claim that all corrected statement or note values are equal.
abstract final class BonLinkedAuditCurrentProof {
  static const targetSha =
      '1d6c98634e35ce0e727de9573c60e6570d83a9f07dd2e48dd1557895158810dd';
  static String compact(String s) =>
      s.replaceAll(RegExp(r'<[^>]*>|\s+|&nbsp;'), '');
  static Map<String, dynamic> verify({
    required String targetReceipt,
    required String sourceReceipt,
    required String corpCode,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Uri source,
    required String sourceBody,
    required Uri targetSource,
    required String targetBody,
    required List<Map<String, dynamic>> rows,
  }) {
    final p = SameReceiptAuditSource
        .profiles[LinkedCorrectionAuditSource.bonOriginal]!;
    void guard(bool ok, String reason) {
      if (!ok) {
        throw FormatException('Bon linked current proof: $reason');
      }
    }

    guard(
      targetReceipt == LinkedCorrectionAuditSource.bonTarget &&
          sourceReceipt == LinkedCorrectionAuditSource.bonOriginal &&
          corpCode == '01872459' &&
          !consolidated &&
          start == DateTime.utc(2025) &&
          end == DateTime.utc(2025, 12, 31),
      'identity/period/basis',
    );
    guard(
      source.toString() == p.statement &&
          targetSource.toString() == LinkedCorrectionAuditSource.bonWitnessUri,
      'actual source URI',
    );
    List<List<List<String>>> tables(String raw) =>
        RegExp(r'<table\b[^>]*>[\s\S]*?</table>', caseSensitive: false)
            .allMatches(raw)
            .map(
              (t) => RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
                  .allMatches(t[0]!)
                  .map(
                    (r) => RegExp(
                      r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
                      caseSensitive: false,
                    ).allMatches(r[1]!).map((c) => compact(c[1]!)).toList(),
                  )
                  .toList(),
            )
            .toList();
    final audit = tables(sourceBody), target = tables(targetBody);
    guard(audit.length > 15 && target.length > 10, 'primary tables missing');
    BigInt money(String text) {
      guard(
        RegExp(r'^(?:[0-9]+(?:,[0-9]{3})*|\([0-9]+(?:,[0-9]{3})*\))$')
            .hasMatch(text),
        'direct monetary cell',
      );
      return BigInt.parse(
        text.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    List<String> one(List<List<String>> table, String label) {
      final matches = table
          .where((r) => r.isNotEmpty && r.first == label)
          .toList();
      guard(matches.length == 1, 'direct row ambiguous: $label');
      return matches.single;
    }

    BigInt current(List<List<String>> table, String label) {
      final r = one(table, label);
      guard(
        r.length == 5 && r[1].isEmpty && r[3].isEmpty,
        'whole current monetary column',
      );
      return money(r[2]);
    }

    final specs = [
      ('assets', 6, 1, '자산총계', '자산총계'),
      ('liabilities', 6, 1, '부채총계', '부채총계'),
      ('equity', 6, 1, '자본총계', '자본총계'),
      ('revenue', 9, 4, '매출액', '매출액'),
      ('operating', 9, 4, '영업이익(손실)', '영업이익'),
      ('profit', 9, 4, '당기순이익(손실)', '당기순이익'),
      ('cfo', 15, 10, '영업활동으로인한현금흐름', '영업활동으로인한현금흐름'),
    ];
    final values = <String, BigInt>{};
    final printed = <Map<String, dynamic>>[];
    for (final spec in specs) {
      final value = current(audit[spec.$2], spec.$4);
      guard(
        value == current(target[spec.$3], spec.$5),
        'current target ${spec.$1} conflict',
      );
      values[spec.$1] = value;
      printed.add({
        'account': spec.$1,
        'auditRow': one(audit[spec.$2], spec.$4),
        'targetRow': one(target[spec.$3], spec.$5),
        'currentAmount': value.toString(),
      });
    }
    guard(
      values['assets'] == values['liabilities']! + values['equity']!,
      'BS identity',
    );
    guard(rows.length == 7, 'only seven direct accounts');
    for (final spec in specs) {
      final matches = rows
          .where((r) => compact(r['account_nm'] as String) == spec.$4)
          .toList();
      guard(
        matches.length == 1 &&
            matches.single['thstrm_amount'] == values[spec.$1].toString() &&
            matches.single['rcept_no'] == sourceReceipt &&
            (matches.single['html_provenance'] as Map)['basis'] == 'OFS' &&
            (matches.single['html_provenance'] as Map)['source'] ==
                source.toString() &&
            (matches.single['html_provenance'] as Map)['periodStart'] ==
                '2025-01-01' &&
            (matches.single['html_provenance'] as Map)['periodEnd'] ==
                '2025-12-31' &&
            matches.single['currency'] == 'KRW' &&
            matches.single['account_id'] == null,
        'parsed current/source metadata',
      );
    }
    final ce = audit[12];
    guard(
      ce.first.join('|') == '과목|자본금|자본잉여금|자본조정|이익잉여금|총계',
      'CE whole hierarchy',
    );
    final opening = ce.indexWhere(
          (r) => r.isNotEmpty && r.first == '2025.1.1(당기초)',
        ),
        closing = ce.indexWhere(
          (r) => r.isNotEmpty && r.first == '2025.12.31(당기말)',
        );
    guard(opening >= 0 && closing > opening, 'actual CE annual date');
    final nets = ce
        .sublist(opening + 1, closing)
        .where((r) => r.isNotEmpty && r.first == '당기순이익(손실)')
        .toList();
    guard(
      nets.length == 1 &&
          nets.single.length == 6 &&
          nets.single.sublist(1, 4).every((v) => v == '-') &&
          money(nets.single.last) == values['profit'] &&
          nets.single[4] == nets.single.last,
      'CE/CIS whole profit',
    );
    final endRow = one(ce, '2025.12.31(당기말)');
    guard(
      endRow.length == 6 && money(endRow.last) == values['equity'],
      'CE/BS whole equity',
    );
    guard(
      endRow
              .sublist(1, 5)
              .fold<BigInt>(
                BigInt.zero,
                (a, s) => a + (s == '-' ? BigInt.zero : money(s)),
              ) ==
          money(endRow.last),
      'CE components',
    );
    final begin = current(audit[15], '기초의현금'),
        finish = current(audit[15], '기말의현금'),
        change = current(audit[15], '현금의증가(감소)');
    final cash = one(audit[6], '현금및현금성자산');
    guard(
      cash.length == 5 &&
          cash[2].isEmpty &&
          cash[4].isEmpty &&
          money(cash[1]) == finish &&
          money(cash[3]) == begin &&
          begin + change == finish,
      'CF/BS cash rollforward',
    );
    guard(
      values['cfo']! +
              current(audit[15], '투자활동으로인한현금흐름') +
              current(audit[15], '재무활동으로인한현금흐름') ==
          change,
      'whole CF activity rollforward',
    );
    guard(
      sha256.convert(utf8.encode(sourceBody)).toString() == p.statementSha &&
          sha256.convert(utf8.encode(targetBody)).toString() == targetSha,
      'immutable raw digests',
    );
    return {
      'policy': 'bon-linked-audit-target-seven-direct-rows-v1',
      'targetReceipt': targetReceipt,
      'sourceReceipt': sourceReceipt,
      'targetSource': targetSource.toString(),
      'actualAuditSource': source.toString(),
      'targetSha256': targetSha,
      'sourceSha256': p.statementSha,
      'periodStart': '2025-01-01',
      'periodEnd': '2025-12-31',
      'basis': 'OFS',
      'matchingDirectAccounts': printed,
      'cePrintedStart': '2025.1.1(당기초)',
      'cePrintedEnd': '2025.12.31(당기말)',
      'allStatementValuesCompared': false,
      'capexTotalAvailable': false,
    };
  }
}
