import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../generated/protocol.dart';
import 'public_financial_html_fetch.dart';
import 'public_financial_html.dart';
import 'verified_annual_source_registry.dart';

/// Exact immutable original-primary bundles. Published money keeps its receipt.
/// This rule is separate from original-audit correction recovery.
abstract final class Header18LinkedPrimarySource {
  static const primaryRule = 'header18-linked-direct-whole-v1';
  static const absenceRule = 'header18-linked-explicit-absence-v1';
  static const profiles = <String, Map<String, Object>>{
    '20220322000265:ofs': {
      'digest':
          '0c12f71f2ae2c8c367cf209d761be9dea53d06a948677f6a60891078e3681be4',
      'corp': '01396931',
      'year': 2021,
      'original': '20220321001430',
      'money': '20220321001430',
      'role': 'same_receipt_audit',
    },
    '20220324000876:cfs': {
      'digest':
          'ab52277dd9d4858b075580e53fa224e4d514fe3bd7f5ee6a72ba73c61ee16477',
      'corp': '01397620',
      'year': 2021,
      'original': '20220322000350',
      'money': '20220322000350',
      'role': 'original_primary_with_current_audit_witness',
    },
    '20220324000876:ofs': {
      'digest':
          '93da5692428b5332075d89b10dd702f4b60a7646e3116ec411a0da20571dc42e',
      'corp': '01397620',
      'year': 2021,
      'original': '20220322000350',
      'money': '20220322000350',
      'role': 'original_primary_with_current_audit_witness',
    },
    '20220328000884:ofs': {
      'digest':
          '4de2cc81b6350d2e5aaa6e4c919ee38cb9bb7c9892b642fcc467d6cb77fb36ee',
      'corp': '01353848',
      'year': 2021,
      'original': '20220321000630',
      'money': '20220328000884',
      'role': 'corrected_audit',
    },
    '20221213000195:cfs': {
      'digest':
          '7d1e652fd413b4598aa8b91db7eed526e6bc1ab2b06581088c385f188a4b8ad1',
      'corp': '00311216',
      'year': 2021,
      'original': '20220322000963',
      'money': '20220322000963',
      'role': 'original_primary_with_current_audit_witness',
    },
    '20221213000195:ofs': {
      'digest':
          '6c41defb7b2b123b7abb3e490ebe22e6f10193cddd9ffa8983b4a74e7686ffa0',
      'corp': '00311216',
      'year': 2021,
      'original': '20220322000963',
      'money': '20220322000963',
      'role': 'original_primary_with_current_audit_witness',
    },
    '20230323001121:cfs': {
      'digest':
          '63bead4f55ed89ceb2b5a32ac62f1954f8f3d184bfdbfa81cd6a94b08617e5eb',
      'corp': '00976615',
      'year': 2022,
      'original': '20230323000812',
      'money': '20230323000812',
      'role': 'original_primary_with_current_audit_witness',
    },
    '20230323001121:ofs': {
      'digest':
          '79868de23a397e2b2b0f1217a72f7ddf7fd11c537647756226ffdc2474f9de48',
      'corp': '00976615',
      'year': 2022,
      'original': '20230323000812',
      'money': '20230323000812',
      'role': 'original_primary_with_current_audit_witness',
    },
    '20250327000068:ofs': {
      'digest':
          '0c214d0977b4b91a550dda162a544b24386807c6e94b731deee8334d3baaec90',
      'corp': '01466832',
      'year': 2024,
      'original': '20250318000867',
      'money': '20250318000867',
      'role': 'original_primary_with_current_audit_witness',
    },
    '20260320001301:ofs': {
      'digest':
          '84f63ded1b530584b1ffa9da3db4807bc72e7c74f6ebe0a04c84b410829b10ff',
      'corp': '01466832',
      'year': 2025,
      'original': '20260311003697',
      'money': '20260311003697',
      'role': 'original_primary_with_current_audit_witness',
    },
    '20260323000764:cfs': {
      'digest':
          '50293af1fc3287e8df9dd0f1f2afe297657586c28e11d05227bf653dc00dad24',
      'corp': '01229240',
      'year': 2025,
      'original': '20260323000737',
      'money': '20260323000737',
      'role': 'original_primary_with_current_audit_witness',
    },
    '20260323000764:ofs': {
      'digest':
          'cecf6877b154cb9a424cb6265512c491388f0ea3c6fffe949bc308ee68ec5ee3',
      'corp': '01229240',
      'year': 2025,
      'original': '20260323000737',
      'money': '20260323000737',
      'role': 'original_primary_with_current_audit_witness',
    },
    '20260324000715:ofs': {
      'digest':
          '6eac7bf6e5d727b4058f4103cae575a01f01fd7b3819395b583d9429534c2588',
      'corp': '00929228',
      'year': 2025,
      'original': '20260323000900',
      'money': '20260323000900',
      'role': 'original_primary_with_current_audit_witness',
    },
    '20220322000265:cfs': {
      'digest':
          '27e185774c6e623594fa3c40099c1733fff94631a063cb8ead03fec8a0864cf2',
      'corp': '01396931',
      'year': 2021,
      'original': '20220321001430',
      'money': '20220321001430',
      'role': 'original_primary_explicit_absence',
    },
    '20220328000884:cfs': {
      'digest':
          '7232bb79571aefd16637e0f9f65394885879d0ee3eccf595765e7c893a73f2a1',
      'corp': '01353848',
      'year': 2021,
      'original': '20220321000630',
      'money': '20220321000630',
      'role': 'original_primary_explicit_absence',
    },
    '20250327000068:cfs': {
      'digest':
          '388d996da4eecee2aaacbdd42c038d9264849b5d90e90065329e337e737fea75',
      'corp': '01466832',
      'year': 2024,
      'original': '20250318000867',
      'money': '20250318000867',
      'role': 'original_primary_explicit_absence',
    },
    '20260320001301:cfs': {
      'digest':
          '3f79096aa61c191199311fb9755a7560d66b01b6541ff80221d163938b43b80c',
      'corp': '01466832',
      'year': 2025,
      'original': '20260311003697',
      'money': '20260311003697',
      'role': 'original_primary_explicit_absence',
    },
    '20260324000715:cfs': {
      'digest':
          '4d1d4c245791a126ebe7f96a1be6682e1e77923161d1d22e5febb8dbfd242437',
      'corp': '00929228',
      'year': 2025,
      'original': '20260323000900',
      'money': '20260323000900',
      'role': 'original_primary_explicit_absence',
    },
  };

  static String originalFor(String receipt, FsDiv basis) =>
      (profiles['$receipt:${basis == FsDiv.consolidated ? 'cfs' : 'ofs'}']?['original']
          as String?) ??
      (throw const FormatException('Unknown linked primary source'));

  static bool sourceEligible({
    required String receipt,
    required String corp,
    required FsDiv basis,
    required DateTime start,
    required DateTime end,
    required String sourceReceipt,
  }) {
    final p =
        profiles['$receipt:${basis == FsDiv.consolidated ? 'cfs' : 'ofs'}'];
    return p != null &&
        p['corp'] == corp &&
        p['money'] == sourceReceipt &&
        start == DateTime.utc(p['year'] as int) &&
        end == DateTime.utc(p['year'] as int, 12, 31);
  }

  static Future<
    ({
      PublicFinancialHtmlSource? numeric,
      PublicFinancialHtmlBasisNotApplicable? absence,
    })
  >
  verify({
    required AnnualSourceCacheEntry entry,
    required Company company,
    required DartFiling filing,
    required List<int> rawManifest,
    required Future<List<int>> Function(String) read,
  }) async {
    final key =
        '${entry.receipt}:${entry.basis == FsDiv.consolidated ? 'cfs' : 'ofs'}';
    final p = profiles[key];
    if (p == null ||
        p['digest'] != entry.manifestDigest ||
        sha256.convert(rawManifest).toString() != p['digest'] ||
        p['corp'] != company.corpCode ||
        filing.corpCode != company.corpCode ||
        filing.rceptNo != entry.receipt ||
        filing.bsnsYear != p['year'] ||
        filing.companyId != company.id ||
        entry.year != p['year']) {
      throw const FormatException('Linked primary immutable identity mismatch');
    }
    final m = jsonDecode(utf8.decode(rawManifest)) as Map;
    if (m['targetReceipt'] != entry.receipt ||
        m['originalReceipt'] != p['original'] ||
        m['numericSourceReceipt'] != p['money'] ||
        m['corpCode'] != p['corp'] ||
        m['basis'] != key.split(':').last ||
        m['year'] != p['year'] ||
        m['kind'] != 'annual' ||
        m['ruleVersion'] != entry.ruleVersion ||
        m['periodStart'] != '${p['year']}-01-01' ||
        m['periodEnd'] != '${p['year']}-12-31') {
      throw const FormatException('Linked primary manifest identity mismatch');
    }
    final docs = <String, ({Uri uri, String raw, List<int> bytes})>{};
    final requiredLabels = {
      'targetShell',
      'originalShell',
      'cover',
      'primary',
      if (entry.absenceLiteral == null) ...{'auditShell', 'audit'},
    };
    for (final source in m['sources'] as List) {
      final label = source['label'] as String;
      if (!requiredLabels.contains(label) ||
          docs.containsKey(label) ||
          source['file'] != '$label.html') {
        throw const FormatException('Unknown linked primary asset');
      }
      final bytes = await read('${entry.assetDirectory}/${source['file']}');
      if (sha256.convert(bytes).toString() != source['sha256']) {
        throw const FormatException('Linked primary raw digest mismatch');
      }
      final uri = Uri.parse(source['url'] as String);
      if (uri.scheme != 'https' ||
          uri.host != 'dart.fss.or.kr' ||
          uri.hasPort ||
          uri.queryParametersAll.values.any((x) => x.length != 1)) {
        throw const FormatException('Linked primary official URI mismatch');
      }
      docs[label] = (uri: uri, raw: utf8.decode(bytes), bytes: bytes);
    }
    if (docs.length != requiredLabels.length) {
      throw const FormatException('Linked primary package incomplete');
    }
    final target = docs['targetShell']!, original = docs['originalShell']!;
    for (final shell in [
      target,
      original,
      if (entry.absenceLiteral == null) docs['auditShell']!,
    ]) {
      final codes = RegExp(r'''openCorpInfoNew\(\s*['"](\d{8})['"]\s*,''')
          .allMatches(shell.raw)
          .map((x) => x.group(1))
          .toSet();
      if (codes.length != 1 || codes.single != company.corpCode) {
        throw const FormatException(
          'Linked primary shell corporate identity mismatch',
        );
      }
    }
    if (target.uri.toString() !=
            'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${entry.receipt}' ||
        original.uri.toString() !=
            'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${p['original']}') {
      throw const FormatException('Linked primary shell receipt mismatch');
    }
    final family = RegExp(
      r'<select[^>]*id=["\x27]family["\x27][^>]*>(.*?)</select>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(target.raw).toList();
    final options = family.length == 1
        ? RegExp(
                r'<option\b([^>]*)>(.*?)</option>',
                caseSensitive: false,
                dotAll: true,
              )
              .allMatches(family.single.group(1)!)
              .where(
                (option) =>
                    RegExp('value=["\x27]rcpNo=${p['original']}["\x27]')
                        .hasMatch(option.group(1)!) &&
                    option.group(2)!.contains('사업보고서'),
              )
              .toList()
        : <RegExpMatch>[];
    if (options.length != 1) {
      throw const FormatException(
        'Linked primary official family missing or ambiguous',
      );
    }
    final transport = _Header18PinnedClient({
      original.uri: original.bytes,
      docs['cover']!.uri: docs['cover']!.bytes,
      docs['primary']!.uri: docs['primary']!.bytes,
    });
    try {
      final directAudit =
          p['role'] == 'same_receipt_audit' || p['role'] == 'corrected_audit';
      PublicFinancialHtmlSource auditNumeric() {
        final rows = PublicFinancialHtml.parseStandardAnnual(
          coverHtml: docs['cover']!.raw,
          statementHtml: docs['audit']!.raw,
          coverSource: docs['cover']!.uri,
          statementSource: docs['audit']!.uri,
          receipt: p['money'] as String,
          corpCode: company.corpCode,
          companyName: company.name,
          periodStart: entry.periodStart,
          periodEnd: entry.periodEnd,
          consolidated: entry.basis == FsDiv.consolidated,
        );
        return PublicFinancialHtmlSource(
          sourceReceipt: p['money'] as String,
          correctionReceipt: p['money'] == entry.receipt ? null : entry.receipt,
          correctionSource: p['money'] == entry.receipt ? null : target.uri,
          coverHtml: docs['cover']!.raw,
          coverSource: docs['cover']!.uri,
          statementHtml: docs['audit']!.raw,
          statementSource: docs['audit']!.uri,
          periodStart: entry.periodStart,
          periodEnd: entry.periodEnd,
          rows: rows,
        );
      }

      final numeric = directAudit
          ? auditNumeric()
          : await PublicFinancialHtmlFetcher(transport).fetchAnnual(
              p['original'] as String,
              reportName: '사업보고서 (${entry.year}.12)',
              corpCode: company.corpCode,
              companyName: company.name,
              bsnsYear: entry.year,
              periodEnd: entry.periodEnd,
              consolidated: entry.basis == FsDiv.consolidated,
            );
      if (entry.absenceLiteral != null ||
          transport.requests != (directAudit ? 0 : 3) ||
          numeric.sourceReceipt != p['money'] ||
          numeric.rows.length < 7 ||
          numeric.rows.length > 8) {
        throw const FormatException('Linked primary numeric scope mismatch');
      }
      final expectedRaw = await read(
        '${entry.assetDirectory}/expected-rows.json',
      );
      if (sha256.convert(expectedRaw).toString() != m['expectedRowsSha256']) {
        throw const FormatException(
          'Linked primary witness rows digest mismatch',
        );
      }
      final expected = jsonDecode(utf8.decode(expectedRaw)) as List;
      if (expected.length != numeric.rows.length) {
        throw const FormatException(
          'Linked primary witness row count mismatch',
        );
      }
      for (var i = 0; i < expected.length; i++) {
        for (final field in [
          'account_nm',
          'account_id',
          'thstrm_amount',
          'sj_div',
        ]) {
          if (expected[i][field] != numeric.rows[i][field]) {
            throw const FormatException(
              'Linked primary current audit value conflict',
            );
          }
        }
        (numeric.rows[i]['html_provenance']
            as Map<String, dynamic>)['linkedPrimaryEvidence'] = {
          'kind': switch (p['role']) {
            'same_receipt_audit' =>
              'exact-original-receipt-audit-with-correction-family',
            'corrected_audit' => 'exact-corrected-audit-with-original-cover',
            _ => 'exact-original-primary-with-current-audit-witness',
          },
          'sourceRole': p['role'],
          'originalCoverReceipt': p['original'],
          'targetReceipt': entry.receipt,
          'sourceReceipt': numeric.sourceReceipt,
          'targetFamilySource': target.uri.toString(),
          'targetFamilySha256': sha256.convert(target.bytes).toString(),
          'auditSource': docs['audit']!.uri.toString(),
          'auditSha256': sha256.convert(docs['audit']!.bytes).toString(),
          'originalShellSha256': sha256.convert(original.bytes).toString(),
        };
      }
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: numeric.sourceReceipt,
          correctionReceipt: numeric.sourceReceipt == entry.receipt
              ? null
              : entry.receipt,
          correctionSource: numeric.sourceReceipt == entry.receipt
              ? null
              : target.uri,
          coverHtml: numeric.coverHtml,
          coverSource: numeric.coverSource,
          statementHtml: numeric.statementHtml,
          statementSource: numeric.statementSource,
          periodStart: numeric.periodStart,
          periodEnd: numeric.periodEnd,
          rows: numeric.rows,
        ),
        absence: null,
      );
    } on PublicFinancialHtmlBasisNotApplicable catch (none) {
      if (entry.absenceLiteral == null ||
          entry.basis != FsDiv.consolidated ||
          transport.requests != 3 ||
          none.sourceReceipt != p['original'] ||
          none.evidence.replaceAll(RegExp(r'\s+'), '') !=
              entry.absenceLiteral!.replaceAll(RegExp(r'\s+'), '')) {
        throw const FormatException(
          'Linked primary explicit absence scope mismatch',
        );
      }
      return (numeric: null, absence: none);
    } finally {
      transport.close();
    }
  }
}

final class _Header18PinnedClient extends http.BaseClient {
  _Header18PinnedClient(this.documents);
  final Map<Uri, List<int>> documents;
  int requests = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = documents[request.url];
    if (request.method != 'GET' || bytes == null || ++requests > 3) {
      throw const FormatException('Unpinned linked primary request');
    }
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      headers: {'content-type': 'text/html; charset=utf-8'},
      request: request,
    );
  }
}
