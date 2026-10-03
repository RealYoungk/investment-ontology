import 'dart:convert';

import 'retrospective_fund_profiles.dart';

/// A single retrospective source. Printed source tokens are compiler-bound facts,
/// not hand-entered amounts. This contract never substitutes an own audit report.
abstract final class RetrospectiveFundContract {
  static const category = 'printedRetrospectiveProspectusFundCategories';
  static const version = 'kbif-corrected-retrospective-detail-v1';
  static const data = RetrospectiveFundProfiles.data;
  static bool same(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.entries.every(
            (e) => b.containsKey(e.key) && same(e.value, b[e.key]),
          );
    }
    if (a is List && b is List) {
      return a.length == b.length &&
          List.generate(a.length, (i) => same(a[i], b[i])).every((v) => v);
    }
    return a == b;
  }

  static bool supports(Map doc) =>
      same(doc['metadata'], data['metadata']) &&
      same(doc['proof'], data['documentProof']);
  static BigInt? integer(dynamic raw) {
    if (raw == null || raw == '-') return null;
    if (raw is! String ||
        !RegExp(r'^(?:\d{1,3}(?:,\d{3})+|\(\d{1,3}(?:,\d{3})+\))$')
            .hasMatch(raw)) {
      throw const FormatException(
        'Exact grouped printed source amount required',
      );
    }
    return BigInt.parse(
      raw.startsWith('(')
          ? '-${raw.substring(1, raw.length - 1).replaceAll(',', '')}'
          : raw.replaceAll(',', ''),
    );
  }

  static List<Map<String, dynamic>> build() {
    final metadata = data['metadata'] as Map;
    return (data['profiles'] as List).map((profile) {
      final p = profile as Map, cells = p['cells'] as Map;
      final checks = <Map<String, dynamic>>[];
      for (final eq in p['equations'] as List) {
        final left = integer(cells[eq['lhs']]['printedAmount']);
        var total = BigInt.zero, missing = 0;
        for (final term in eq['terms'] as List) {
          final n = integer(cells[term['cellKey']]['printedAmount']);
          if (n == null) {
            missing++;
          } else {
            total += n * BigInt.from(term['coefficient']);
          }
        }
        // Explicit missing witnesses are not stored amount facts or zero facts.
        // A null lhs is a partial missing-component subtotal, never a full equation.
        if ((left ?? BigInt.zero) != total) {
          throw const FormatException(
            'Printed retrospective source equation mismatch',
          );
        }
        final complete = left != null && missing == 0;
        checks.add({
          ...Map<String, dynamic>.from(eq),
          'difference': '0',
          'missingTerms': missing,
          'leftIsMissing': left == null,
          'equationScope': complete
              ? 'fullyNumericPrintedEquation'
              : 'printedSubtotalWithMissingNonAmountWitness',
        });
      }
      final accounts = (p['accounts'] as List).map((bound) {
        final c = cells[bound['cellKey']] as Map,
            n = integer(c['printedAmount']);
        if (n == null) {
          throw const FormatException('Selected numeric account missing');
        }
        return <String, dynamic>{
          ...Map<String, dynamic>.from(bound),
          ...Map<String, dynamic>.from(c),
          'amountInteger': n.toString(),
          'amountRole': 'directPrintedDetailedTableToken',
          'periodStart': bound['amountScope'] == 'stockAtPeriodEnd'
              ? p['periodEnd']
              : p['periodStart'],
          'periodEnd': p['periodEnd'],
          'currency': 'KRW',
          'printedUnit': '원',
          'precisionUnit': '1',
        };
      }).toList();
      return <String, dynamic>{
        'corpCode': metadata['corpCode'],
        'categorySchema': category,
        'documentType': 'prospectus',
        'provider': 'officialIR',
        'providerReceipt': null,
        'officialUrl': metadata['officialUrl'],
        'sha256': metadata['sha256'],
        'publishedAt': metadata['publishedAt'],
        'sourceRole': 'retrospectiveCorrectedProspectus',
        'sourceCoveredPeriodStart': metadata['periodStart'],
        'sourceCoveredPeriodEnd': metadata['periodEnd'],
        'periodStart': p['periodStart'],
        'periodEnd': p['periodEnd'],
        'periodKind': p['periodKind'],
        'fiscalTerm': p['fiscalTerm'],
        'printedColumnOrdinal': p['printedColumnOrdinal'],
        'basis': 'singleFundEntity',
        'auditStatus':
            'prospectusReportsUnqualifiedOpinion;standaloneAuditNotRetrieved',
        'auditorReportedByProspectus': '이지회계법인',
        'observationRole': 'ownFiscalPeriodInLaterProspectus',
        'currency': 'KRW',
        'printedUnit': '원',
        'precisionUnit': '1',
        'numericState':
            'partialPrintedRetrospectiveDetailedCategoriesWithSourceConflicts',
        'publicContent': 'sourceLinkAndValues',
        'parserVersion': version,
        'extractedBy': 'exactImmutablePdfTextRule',
        'extractedTextSha256': data['textSha256'],
        'extractionTool': 'pdftotext 26.02.0 -layout -enc UTF-8',
        'sourceReadScope': 'physicalPages265-269;correctionDatePage1;noNotes',
        'fullStatementCollected': false,
        'wholeDocumentReviewed': false,
        'notesVerified': false,
        'standaloneOwnAuditRetrieved': false,
        'regularReportCode': null,
        'xbrlAccountId': null,
        'ttmEligible': false,
        'accounts': accounts,
        'sourceConflicts': data['sourceConflicts'],
        'excludedFiscalPeriods': data['excludedFiscalPeriods'],
        'validation': {
          'cells': cells,
          'checks': checks,
          'fullyNumericEquationCount': checks
              .where((c) => c['equationScope'] == 'fullyNumericPrintedEquation')
              .length,
          'missingWitnessSubtotalCount': checks
              .where((c) => c['equationScope'] != 'fullyNumericPrintedEquation')
              .length,
          'missingWitnessesAreAmountFacts': false,
          'completeStatementsVerified': false,
        },
      };
    }).toList();
  }

  static List<Map<String, dynamic>> validateRows(dynamic raw) {
    if (raw is! List || raw.isEmpty || raw.length > 2) {
      throw const FormatException(
        'Two exact retrospective fiscal groups required',
      );
    }
    final expected = build(), seen = <String>{};
    return raw.map((r) {
      if (r is! Map || !seen.add('${r['periodEnd']}')) {
        throw const FormatException('Duplicate retrospective fiscal group');
      }
      final matches = expected.where((e) => e['periodEnd'] == r['periodEnd']);
      if (matches.length != 1 || !same(r, matches.single)) {
        throw const FormatException(
          'Immutable retrospective source contract mismatch',
        );
      }
      // Return a fresh canonical object, never a caller-owned mutable map.
      return Map<String, dynamic>.from(
        jsonDecode(jsonEncode(matches.single)) as Map,
      );
    }).toList();
  }
}
