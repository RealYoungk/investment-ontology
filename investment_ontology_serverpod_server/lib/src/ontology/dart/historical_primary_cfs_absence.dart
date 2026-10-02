import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'primary_historical_issuer.dart';
import 'public_financial_html.dart';
import 'public_financial_html_fetch.dart';

/// Cache-only independent issuer witness; OFS values never become CFS facts.
abstract final class HistoricalPrimaryCfsAbsence {
  static PublicFinancialHtmlBasisNotApplicable verify({
    required String receipt,
    required String corpCode,
    required String currentName,
    required String reportName,
    required DateTime start,
    required DateTime end,
    required Uri shellSource,
    required String shell,
    required Uri coverSource,
    required String cover,
    required Uri ofsSource,
    required String ofs,
    required Uri overviewSource,
    required String overview,
    required Uri cfsSource,
    required String cfs,
    required String expectedLiteral,
  }) {
    const literals = {
      '당사는 주식회사의 외부감사에 관한 법률 제1조의2에 의한 연결재무제표 작성대상 법인이 아닙니다.',
      '※ 당사는 주식회사의 외부감사에 관한 법률 제1조의2에 의한 연결재무제표 작성대상 법인이 아닙니다.',
      '당사는 해당사항 없습니다.',
    };
    if (!literals.contains(expectedLiteral)) {
      throw const FormatException('Unreviewed CFS absence literal');
    }
    final witness = PrimaryHistoricalIssuer(
      shell: shell,
      shellSource: shellSource,
    );
    final proof = witness.verify(
      receipt: receipt,
      corp: corpCode,
      consolidated: false,
      coverSource: coverSource,
      cover: cover,
      statementSource: ofsSource,
      statement: ofs,
      start: start,
      end: end,
    );
    if (proof == null) {
      throw const FormatException('Independent own OFS issuer witness missing');
    }
    final rows = PublicFinancialHtml.parseStandardAnnual(
      coverHtml: cover,
      statementHtml: ofs,
      coverSource: coverSource,
      statementSource: ofsSource,
      receipt: receipt,
      corpCode: corpCode,
      companyName: currentName,
      periodStart: start,
      periodEnd: end,
      consolidated: false,
      primaryIssuerProof: witness,
    );
    if (rows.length < 7 || rows.length > 8) {
      throw const FormatException(
        'Independent OFS whole core witness incomplete',
      );
    }
    final nodes = <Map<String, String>>[];
    final overviewNodes = <Map<String, String>>[];
    for (final block in RegExp(
      r'var (node\d+) = \{\};([\s\S]*?)(?=cnt\+\+)',
      dotAll: true,
    ).allMatches(shell)) {
      final v = <String, String>{};
      for (final a in RegExp(
        r'''\['([^']+)'\]\s*=\s*"([^"]*)"''',
      ).allMatches(block[2]!)) {
        if (v.containsKey(a[1])) {
          throw const FormatException('Ambiguous source node attributes');
        }
        v[a[1]!] = a[2]!;
      }
      if (v['text']?.replaceAll(RegExp(r'\s+'), '') == '2.연결재무제표') {
        nodes.add(v);
      }
      if (v['text']?.replaceAll(RegExp(r'\s+'), '') == 'I.회사의개요') {
        overviewNodes.add(v);
      }
    }
    const keys = ['rcpNo', 'dcmNo', 'eleId', 'offset', 'length', 'dtd'];
    if (nodes.length != 1 ||
        cfsSource.scheme != 'https' ||
        cfsSource.host != 'dart.fss.or.kr' ||
        cfsSource.path != '/report/viewer.do' ||
        cfsSource.hasPort ||
        cfsSource.userInfo.isNotEmpty ||
        cfsSource.fragment.isNotEmpty ||
        cfsSource.queryParametersAll.length != 6 ||
        nodes.single['rcpNo'] != receipt ||
        nodes.single['dcmNo'] != ofsSource.queryParameters['dcmNo'] ||
        keys.any(
          (k) =>
              cfsSource.queryParametersAll[k]?.length != 1 ||
              nodes.single[k] != cfsSource.queryParameters[k],
        )) {
      throw const FormatException(
        'Own CFS node does not bind issuer OFS receipt',
      );
    }
    if (overviewNodes.length != 1 ||
        overviewSource.scheme != 'https' ||
        overviewSource.host != 'dart.fss.or.kr' ||
        overviewSource.path != '/report/viewer.do' ||
        overviewSource.hasPort ||
        overviewSource.userInfo.isNotEmpty ||
        overviewSource.fragment.isNotEmpty ||
        overviewSource.queryParametersAll.length != 6 ||
        overviewNodes.single['rcpNo'] != receipt ||
        overviewNodes.single['dcmNo'] != ofsSource.queryParameters['dcmNo'] ||
        keys.any(
          (k) =>
              overviewSource.queryParametersAll[k]?.length != 1 ||
              overviewNodes.single[k] != overviewSource.queryParameters[k],
        ) ||
        !overview
            .replaceAll(RegExp(r'<[^>]*>|\s+|&nbsp;'), '')
            .contains('I.회사의개요')) {
      throw const FormatException(
        'Own overview witness source binding mismatch',
      );
    }
    final bodies = RegExp(
      r'<body\b[^>]*>([\s\S]*?)</body>',
      caseSensitive: false,
    ).allMatches(cfs).toList();
    final heads = RegExp(
      r"<p\b[^>]*class=['\x22]section-2['\x22][^>]*>([\s\S]*?)</p>",
      caseSensitive: false,
    ).allMatches(cfs).toList();
    if (bodies.length != 1 ||
        heads.length != 1 ||
        RegExp(
          r'<(?:table|script|style|img|svg|iframe)\b',
          caseSensitive: false,
        ).hasMatch(cfs) ||
        RegExp(
              r'''\bstyle\s*=\s*(['\x22])(.*?)\1''',
              caseSensitive: false,
            )
            .allMatches(bodies.single[1]!)
            .any(
              (m) =>
                  m[2] != 'font-family:DartNBSP, "굴림", Gulim;font-size:11pt;',
            )) {
      throw const FormatException(
        'CFS absence is not a complete plain section',
      );
    }
    String visible(String v) => v
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final text = visible(bodies.single[1]!);
    final heading = visible(heads.single[1]!);
    if (heading.replaceAll(' ', '') != '2.연결재무제표' ||
        !text.startsWith(heading)) {
      throw const FormatException('CFS absence heading is not first');
    }
    final evidence = text.substring(heading.length).trim();
    if (evidence.replaceAll(RegExp(r'\s+'), '') !=
        expectedLiteral.replaceAll(RegExp(r'\s+'), '')) {
      throw const FormatException(
        'CFS absence has additional context or different evidence',
      );
    }
    return _WitnessedCfsAbsence(
      sourceReceipt: receipt,
      corpCode: corpCode,
      companyName: currentName,
      reportName: reportName,
      periodStart: start,
      periodEnd: end,
      coverSource: coverSource,
      statementSource: cfsSource,
      coverHtml: cover,
      statementHtml: cfs,
      evidence: evidence,
      witnessEvidence: {
        'kind': 'same-receipt-independent-OFS-issuer-only',
        'receipt': receipt,
        'corpCode': corpCode,
        'printedIssuer': proof['printedIssuer'].toString(),
        'primaryWitnessSource': ofsSource.toString(),
        'overviewSource': overviewSource.toString(),
        'overviewSha256': sha256.convert(utf8.encode(overview)).toString(),
        'primaryWitnessSha256': sha256.convert(utf8.encode(ofs)).toString(),
        'coverSha256': sha256.convert(utf8.encode(cover)).toString(),
        'shellSha256': sha256.convert(utf8.encode(shell)).toString(),
        'periodStart': start.toIso8601String().substring(0, 10),
        'periodEnd': end.toIso8601String().substring(0, 10),
        'witnessCoreRows': rows.length.toString(),
        'usage': 'OFS only proves issuer identity; no CFS amount inference',
      },
    );
  }
}

final class _WitnessedCfsAbsence extends PublicFinancialHtmlBasisNotApplicable {
  _WitnessedCfsAbsence({
    required super.sourceReceipt,
    required super.corpCode,
    required super.companyName,
    required super.reportName,
    required super.periodStart,
    required super.periodEnd,
    required super.coverSource,
    required super.statementSource,
    required super.coverHtml,
    required super.statementHtml,
    required super.evidence,
    required this.witnessEvidence,
  });
  final Map<String, String> witnessEvidence;
  @override
  Map<String, String> get issuerIdentityEvidence => witnessEvidence;
}
