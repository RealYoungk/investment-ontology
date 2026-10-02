import 'dart:convert';

import '../financial/financial_accounts.dart';

/// Validates the parser's source-bound six-core evidence, never invents revenue.
/// The caller must retain the official source's independently verified digest.
abstract final class SourceVerifiedPartialCore {
  static bool verifiedRows(
    List<Map<String, dynamic>> rows, {
    required String sourceDigest,
    required String sourceUrl,
    required String bodySha256,
    required String companyCode,
    required String targetReceipt,
    required String basis,
    required int year,
  }) {
    try {
      if (!{'consolidated', 'separate'}.contains(basis) ||
          !RegExp(r'^[0-9]{8}$').hasMatch(companyCode) ||
          !RegExp(r'^[0-9]{14}$').hasMatch(targetReceipt) ||
          rows.length != 6 ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(sourceDigest)) {
        return false;
      }
      final uri = Uri.parse(sourceUrl);
      if (uri.scheme != 'https' ||
          uri.host != 'dart.fss.or.kr' ||
          uri.path != '/report/viewer.do' ||
          uri.hasPort ||
          uri.userInfo.isNotEmpty ||
          uri.fragment.isNotEmpty) {
        return false;
      }
      const fields = ['rcpNo', 'dcmNo', 'eleId', 'offset', 'length', 'dtd'];
      if (uri.queryParametersAll.keys
              .toSet()
              .difference(fields.toSet())
              .isNotEmpty ||
          fields.any((k) => uri.queryParametersAll[k]?.length != 1) ||
          uri.queryParameters['rcpNo'] != targetReceipt ||
          !{'dart3.xsd', 'dart4.xsd'}.contains(uri.queryParameters['dtd']) ||
          [
            'dcmNo',
            'eleId',
            'offset',
            'length',
          ].any(
            (k) => !RegExp(r'^[0-9]+$').hasMatch(uri.queryParameters[k]!),
          )) {
        return false;
      }
      final values = <String, BigInt>{};
      String? firstProof;
      for (final row in rows) {
        if (row['account_id'] != null ||
            row['corp_code'] != companyCode ||
            row['rcept_no'] != targetReceipt ||
            row['bsns_year'] != '$year' ||
            row['reprt_code'] != '11011' ||
            row['currency'] != 'KRW') {
          return false;
        }
        final p = row['html_provenance'] as Map;
        final proof = p['partialCoreProof'] as Map;
        if (firstProof != null && jsonEncode(proof) != firstProof) return false;
        firstProof = jsonEncode(proof);
        if (proof['rule'] != 'source-six-with-unavailable-whole-revenue-v1' ||
            proof['receipt'] != targetReceipt ||
            proof['corpCode'] != companyCode ||
            proof['basis'] != (basis == 'separate' ? 'OFS' : 'CFS') ||
            proof['source'] != sourceUrl ||
            proof['sourceDigest'] != sourceDigest ||
            proof['bodySha256'] != bodySha256 ||
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(bodySha256) ||
            proof['missingAccount'] != 'revenue' ||
            p['basis'] != proof['basis'] ||
            p['source'] != sourceUrl ||
            p['periodStart'] != proof['periodStart'] ||
            p['periodEnd'] != proof['periodEnd']) {
          return false;
        }
        final start = DateTime.parse('${proof['periodStart']}T00:00:00Z'),
            end = DateTime.parse('${proof['periodEnd']}T00:00:00Z');
        if (start != DateTime.utc(year) || end != DateTime.utc(year, 12, 31)) {
          return false;
        }
        final missing = proof['revenueUnavailable'] as Map;
        if (!{
          'printed-dash-unavailable',
          'no-recognized-single-whole-revenue-row',
        }.contains(missing['reason'])) {
          return false;
        }
        if (missing['reason'] == 'printed-dash-unavailable') {
          if (!FinancialAccounts.fallbackNames['revenue']!.contains(
            FinancialAccounts.normalizedName(missing['printedLabel'] as String),
          )) {
            return false;
          }
          final cells = (missing['printedCurrentCells'] as List)
              .cast<String>()
              .map((s) => s.replaceAll(RegExp(r'\s+'), ''))
              .toList();
          if (cells.where((s) => s == '-').length != 1 ||
              cells.any((s) => s.isNotEmpty && s != '-')) {
            return false;
          }
        } else {
          final labels = (missing['actualPrintedStatementLabels'] as List)
              .cast<String>()
              .map(FinancialAccounts.normalizedName)
              .toList();
          if (labels.isEmpty ||
              labels.any(
                FinancialAccounts.fallbackNames['revenue']!.contains,
              )) {
            return false;
          }
        }

        final name = FinancialAccounts.normalizedName(
          row['account_nm'] as String,
        );
        final hits = FinancialAccounts.fallbackNames.entries
            .where(
              (e) =>
                  const {
                    'assets',
                    'liabilities',
                    'equity',
                    'operatingIncome',
                    'netIncome',
                    'operatingCashFlow',
                  }.contains(e.key) &&
                  e.value.contains(name),
            )
            .toList();
        if (hits.length != 1 || values.containsKey(hits.single.key)) {
          return false;
        }
        final role = hits.single.key, statement = row['sj_div'];
        if ((const {'assets', 'liabilities', 'equity'}.contains(role) &&
                statement != 'BS') ||
            (const {'operatingIncome', 'netIncome'}.contains(role) &&
                statement != 'CIS') ||
            (role == 'operatingCashFlow' && statement != 'CF')) {
          return false;
        }
        if (p['printedLabel'] != row['account_nm'] ||
            p['normalizedUnit'] != '원') {
          return false;
        }
        final multiplier = switch (p['unit']) {
          '원' => BigInt.one,
          '천원' => BigInt.from(1000),
          '백만원' => BigInt.from(1000000),
          _ => null,
        };
        if (multiplier == null ||
            p['unitMultiplier'] != multiplier.toString()) {
          return false;
        }
        final current = (p['printedCurrentCells'] as List)
            .cast<String>()
            .map((s) => s.replaceAll(RegExp(r'\s+'), ''))
            .toList();
        if (p['currentColumn'] is! int ||
            (p['currentColumn'] as int) < 1 ||
            (p['currentColumn'] as int) > 9 ||
            !{1, 2}.contains(p['currentColumnSpan']) ||
            current.length != p['currentColumnSpan']) {
          return false;
        }
        final printed = <BigInt>[];
        for (final c in current) {
          if (c.isEmpty || c == '-') continue;
          if (!RegExp(
            r'^(?:-?(?:\d+|\d{1,3}(?:,\d{3})+)|\((?:\d+|\d{1,3}(?:,\d{3})+)\))$',
          ).hasMatch(c)) {
            return false;
          }
          printed.add(
            BigInt.parse(
              c.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
            ),
          );
        }
        if (printed.length != 1) return false;
        final value = BigInt.parse(row['thstrm_amount'] as String);
        if (printed.single * multiplier != value) return false;
        if (const {'영업손실', '당기순손실'}.contains(name) && value > BigInt.zero) {
          return false;
        }
        values[role] = value;
      }
      if (values.length != 6 ||
          values['assets'] != values['liabilities']! + values['equity']!) {
        return false;
      }
      final ce =
          (rows.first['html_provenance'] as Map)['partialCoreProof']['wholeCE']
              as Map;
      final header = ce['rawHeader'] as List;
      if (ce['wholeColumn'] != header.length - 1 ||
          (header.last as String).replaceAll(RegExp(r'\s+'), '') != '총계' ||
          ce['wholeProfit'] != values['netIncome'].toString() ||
          ce['closingEquity'] != values['equity'].toString()) {
        return false;
      }
      BigInt? printedWhole(Object raw, Object? unit) {
        final cells = (raw as List).cast<String?>();
        if (cells.length != header.length || cells.last == null) return null;
        final money = cells.last!.replaceAll(RegExp(r'\s+'), '');
        if (!RegExp(
          r'^(?:-?(?:\d+|\d{1,3}(?:,\d{3})+)|\((?:\d+|\d{1,3}(?:,\d{3})+)\))$',
        ).hasMatch(money)) {
          return null;
        }
        final multiplier = switch (unit) {
          '원' => BigInt.one,
          '천원' => BigInt.from(1000),
          '백만원' => BigInt.from(1000000),
          _ => null,
        };
        if (multiplier == null) return null;
        return BigInt.parse(
              money
                  .replaceAll(',', '')
                  .replaceAll('(', '-')
                  .replaceAll(')', ''),
            ) *
            multiplier;
      }

      if (printedWhole(ce['printedProfitCells'], ce['unit']) !=
              values['netIncome'] ||
          printedWhole(ce['printedClosingCells'], ce['unit']) !=
              values['equity']) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
