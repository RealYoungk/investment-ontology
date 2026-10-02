import 'public_issuer_legal_name.dart';
import 'bnk_six_core_profile.dart';
import 'verified_historical_company_identity.dart';

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'public_financial_html.dart';

/// Verified source data retains the original receipt, never the attachment's.
class PublicFinancialHtmlSource {
  PublicFinancialHtmlSource({
    required this.sourceReceipt,
    required this.correctionReceipt,
    required this.correctionSource,
    required this.coverHtml,
    required this.coverSource,
    required this.statementHtml,
    required this.statementSource,
    required this.periodStart,
    required this.periodEnd,
    required this.rows,
    this.issuerProof,
  });

  final String sourceReceipt;
  final String? correctionReceipt;
  final Uri? correctionSource;
  final String coverHtml;
  final Uri coverSource;
  final String statementHtml;
  final Uri statementSource;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<Map<String, dynamic>> rows;
  final PublicIssuerLegalName? issuerProof;

  String get sourceDigest =>
      sha256.convert(utf8.encode('$coverHtml\n$statementHtml')).toString();
}

/// Official exact-annual evidence that the company does not prepare CFS.
/// This is never inferred from missing tables or empty extracted rows.
class PublicFinancialHtmlBasisNotApplicable extends FormatException {
  PublicFinancialHtmlBasisNotApplicable({
    required this.sourceReceipt,
    required this.corpCode,
    required this.companyName,
    required this.reportName,
    required this.periodStart,
    required this.periodEnd,
    required this.coverSource,
    required this.statementSource,
    required this.coverHtml,
    required this.statementHtml,
    required this.evidence,
    this.issuerProof,
  }) : super(
         'Official annual consolidated statements explicitly not applicable',
       );

  final String sourceReceipt;
  final String corpCode;
  final String companyName;
  final String reportName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Uri coverSource;
  final Uri statementSource;
  final String coverHtml;
  final String statementHtml;
  final String evidence;
  final PublicIssuerLegalName? issuerProof;
  Map<String, String>? get issuerIdentityEvidence {
    final names = RegExp(r'회사명:(.*?)(?:공동)?대표이사:')
        .allMatches(coverHtml.replaceAll(RegExp(r'<[^>]+>|\s+|&nbsp;'), ''))
        .toList();
    if (names.length != 1) return null;
    return issuerProof?.verify(
      receipt: sourceReceipt,
      corpCode: corpCode,
      masterName: companyName,
      printedName: names.single.group(1)!,
      coverSource: coverSource,
      coverHtml: coverHtml,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  String? get correctionReceipt => null;
  Uri? get correctionSource => null;
  bool get consolidated => true;
  String get sourceDigest =>
      sha256.convert(utf8.encode('$coverHtml\n$statementHtml')).toString();
}

/// Public HTML transport for exact annuals, attachment originals and half-years.
/// Company IDs come from each official shell; dates come from the actual cover.
/// No account IDs, date ranges, or amounts are inferred by this transport.
class PublicFinancialHtmlFetcher {
  PublicFinancialHtmlFetcher(this.client);
  final http.Client client;

  // Reserve starts across exact-annual instances, including call boundaries.
  static DateTime? _nextAnnualRequestAt;

  Future<PublicFinancialHtmlSource> fetchAttachmentAnnual(
    String receipt, {
    required String reportName,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) => _fetch(
    receipt,
    reportName: reportName,
    corpCode: corpCode,
    companyName: companyName,
    bsnsYear: bsnsYear,
    periodEnd: periodEnd,
    consolidated: consolidated,
    halfYear: false,
  );

  /// Exact annual receipt only. Never follows an attachment or prior receipt.
  Future<PublicFinancialHtmlSource> fetchAnnual(
    String receipt, {
    required String reportName,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) => _fetch(
    receipt,
    reportName: reportName,
    corpCode: corpCode,
    companyName: companyName,
    bsnsYear: bsnsYear,
    periodEnd: periodEnd,
    consolidated: consolidated,
    halfYear: false,
    exactAnnual: true,
  );

  /// Exact-receipt half-year HTML. This never follows a prior annual report.
  Future<PublicFinancialHtmlSource> fetchHalfYear(
    String receipt, {
    required String reportName,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) => _fetch(
    receipt,
    reportName: reportName,
    corpCode: corpCode,
    companyName: companyName,
    bsnsYear: bsnsYear,
    periodEnd: periodEnd,
    consolidated: consolidated,
    halfYear: true,
  );

  Future<PublicFinancialHtmlSource> _fetch(
    String correctionReceipt, {
    required String reportName,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
    required bool halfYear,
    bool exactAnnual = false,
  }) async {
    if (!RegExp(r'^\d{14}$').hasMatch(correctionReceipt) ||
        !RegExp(r'^\d{8}$').hasMatch(corpCode) ||
        !(exactAnnual
            ? RegExp(r'^(?:\[(?:기재정정|첨부추가)\])?사업보고서\s*\(\d{4}\.\d{2}\)$')
                      .hasMatch(reportName) &&
                  reportName.endsWith(
                    '(${periodEnd.year}.${periodEnd.month.toString().padLeft(2, '0')})',
                  )
            : halfYear
            ? reportName.startsWith('반기보고서')
            : reportName.startsWith('[첨부정정]사업보고서')) ||
        periodEnd.year != bsnsYear) {
      throw const FormatException(
        'Not a bound supported financial HTML report',
      );
    }
    String? cookie;
    var requested = false;
    Future<String> get(Uri uri, {Uri? referer}) async {
      if (exactAnnual) {
        final now = DateTime.now();
        final reserved = _nextAnnualRequestAt;
        final start = reserved != null && reserved.isAfter(now)
            ? reserved
            : now;
        _nextAnnualRequestAt = start.add(const Duration(seconds: 1));
        final delay = start.difference(now);
        if (delay > Duration.zero) await Future<void>.delayed(delay);
      } else if (requested) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      requested = true;
      final response = await client
          .get(
            uri,
            headers: {
              'User-Agent': 'InvestmentOntology/1.0',
              'Accept': 'text/html',
              if (cookie != null) 'Cookie': cookie!,
              if (referer != null) 'Referer': referer.toString(),
            },
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 ||
          (response.request?.url.host ?? uri.host) != 'dart.fss.or.kr' ||
          (exactAnnual &&
              response.request != null &&
              response.request!.url != uri) ||
          response.bodyBytes.length > 5 * 1024 * 1024) {
        throw const FormatException('Invalid official financial HTML response');
      }
      final setCookie = response.headers['set-cookie'];
      if (setCookie != null) cookie = setCookie.split(';').first;
      return utf8.decode(response.bodyBytes);
    }

    Uri shellUri(String receipt) =>
        Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {'rcpNo': receipt});
    String document(String shell, String receipt) {
      final documents = RegExp("openPdfDownload\\('$receipt',\\s*'(\\d+)'\\)")
          .allMatches(shell)
          .map((m) => m.group(1)!)
          .toSet();
      final companies = RegExp(
        r"openCorpInfoNew\('(\d{8})',\s*'winCorpInfo',\s*'/dsae001/selectPopup.ax'\)",
      ).allMatches(shell).map((m) => m.group(1)!).toSet();
      if (documents.length != 1 ||
          companies.length != 1 ||
          companies.single != corpCode) {
        throw const FormatException('Official shell receipt/company mismatch');
      }
      return documents.single;
    }

    final correctionSource = shellUri(correctionReceipt);
    final correctionShell = await get(correctionSource);
    document(correctionShell, correctionReceipt);
    var sourceReceipt = correctionReceipt;
    var originalSource = correctionSource;
    var shell = correctionShell;
    var dcm = document(shell, sourceReceipt);
    if (!halfYear && !exactAnnual) {
      final family = RegExp(
        r'<select\b[^>]*\bid=["\x27]family["\x27][^>]*>(.*?)</select>',
        dotAll: true,
        caseSensitive: false,
      ).allMatches(correctionShell).toList();
      if (family.length != 1) {
        throw const FormatException('Ambiguous official main selection');
      }
      final originals = <String>[];
      for (final option in RegExp(
        r'<option\b([^>]*)>',
        caseSensitive: false,
      ).allMatches(family.single.group(1)!)) {
        final attrs = <String, String>{};
        for (final attr in RegExp(
          r'([\w-]+)\s*=\s*["\x27]([^"\x27]*)["\x27]',
        ).allMatches(option.group(1)!)) {
          if (attrs.containsKey(attr.group(1))) {
            throw const FormatException('Duplicate main selection attribute');
          }
          attrs[attr.group(1)!] = attr.group(2)!;
        }
        if (attrs['title'] != '사업보고서') continue;
        if (!RegExp(r'^rcpNo=\d{14}$').hasMatch(attrs['value'] ?? '')) {
          throw const FormatException(
            'Invalid official original receipt option',
          );
        }
        originals.add(attrs['value']!.substring(6));
      }
      if (originals.length != 1 ||
          originals.single.compareTo(correctionReceipt) >= 0) {
        throw const FormatException('Ambiguous or nonprior annual original');
      }

      sourceReceipt = originals.single;
      originalSource = shellUri(sourceReceipt);
      shell = await get(originalSource, referer: correctionSource);
      dcm = document(shell, sourceReceipt);
    }
    Uri node(String expected) {
      final matches = <Uri>[];
      final nodes = RegExp(
        r'''(node[12])\['text'\]\s*=\s*"([^"]+)";(.*?)(?=node[12]\['text'\]|$)''',
        dotAll: true,
      ).allMatches(shell);
      for (final block in nodes) {
        if (block.group(2)!.replaceAll(RegExp(r'\s+'), '') != expected) {
          continue;
        }
        final values = <String, String>{};
        for (final attribute in RegExp(
          r'''node[12]\['(rcpNo|dcmNo|eleId|offset|length|dtd)'\]\s*=\s*"([^"]+)"''',
        ).allMatches(block.group(3)!)) {
          if (values.containsKey(attribute.group(1))) {
            throw const FormatException('Ambiguous financial node coordinate');
          }
          values[attribute.group(1)!] = attribute.group(2)!;
        }
        if (values['rcpNo'] != sourceReceipt ||
            values['dcmNo'] != dcm ||
            [
              'eleId',
              'offset',
              'length',
            ].any((k) => !RegExp(r'^\d{1,9}$').hasMatch(values[k] ?? '')) ||
            !const ['dart3.xsd', 'dart4.xsd'].contains(values['dtd']) ||
            int.parse(values['length']!) == 0 ||
            int.parse(values['length']!) > 5 * 1024 * 1024) {
          throw const FormatException('Unbound financial node coordinates');
        }
        matches.add(Uri.https('dart.fss.or.kr', '/report/viewer.do', values));
      }
      if (matches.length != 1) {
        throw const FormatException('Missing or ambiguous financial node');
      }
      return matches.single;
    }

    final coverSource = node(halfYear ? '반기보고서' : '사업보고서');
    final statementSource = node(
      halfYear
          ? 'III.재무에관한사항'
          : consolidated
          ? '2.연결재무제표'
          : '4.재무제표',
    );
    final coverHtml = await get(coverSource, referer: originalSource);
    final text = coverHtml
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', '')
        .replaceAll(RegExp(r'\s+'), '');
    final periods = RegExp(
      exactAnnual
          ? r'사업연도(\d{4})(?:년|\.)(\d{1,2})(?:월|\.)(\d{1,2})(?:일|\.?)부터(\d{4})(?:년|\.)(\d{1,2})(?:월|\.)(\d{1,2})(?:일|\.?)까지'
          : r'사업연도(\d{4})년(\d{2})월(\d{2})일부터(\d{4})년(\d{2})월(\d{2})일까지',
    ).allMatches(text).toList();
    if (periods.length != 1) {
      throw const FormatException('Missing or ambiguous declared annual cover');
    }
    DateTime date(int offset) {
      final m = periods.single;
      final value = [
        m.group(offset),
        m.group(offset + 1)!.padLeft(2, '0'),
        m.group(offset + 2)!.padLeft(2, '0'),
      ].join('-');
      final parsed = DateTime.tryParse(value);
      if (parsed == null ||
          parsed.toIso8601String().substring(0, 10) != value) {
        throw const FormatException('Invalid declared cover date');
      }
      return DateTime.utc(parsed.year, parsed.month, parsed.day);
    }

    final periodStart = date(1);
    if (date(4) !=
        DateTime.utc(periodEnd.year, periodEnd.month, periodEnd.day)) {
      throw const FormatException('Declared source end mismatch');
    }
    PublicIssuerLegalName? issuerProof;
    if (exactAnnual) {
      String normalize(String name) =>
          name.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s+'), '');
      final printedNames = RegExp(r'회사명:(.*?)(?:공동)?대표이사:')
          .allMatches(text)
          .toList();
      if (printedNames.length != 1 ||
          periodEnd.difference(periodStart).inDays < 0 ||
          periodEnd.difference(periodStart).inDays + 1 > 367) {
        throw const FormatException('Exact annual company/duration mismatch');
      }
      final printedName = printedNames.single.group(1)!;
      if (normalize(printedName) != normalize(companyName) &&
          !BnkSixCoreProfile.boundCover(
            targetReceipt: sourceReceipt,
            companyCode: corpCode,
            companyName: companyName,
            consolidated: consolidated,
            end: periodEnd,
            source: coverSource,
            html: coverHtml,
          ) &&
          VerifiedHistoricalCompanyIdentity.evidence(
                receipt: sourceReceipt,
                corpCode: corpCode,
                currentName: companyName,
                printedName: printedName,
                periodEnd: periodEnd,
                consolidated: consolidated,
                coverSource: coverSource,
                coverHtml: coverHtml,
              ) ==
              null) {
        final overviewSource = node('I.회사의개요');
        final overviewHtml = await get(overviewSource, referer: originalSource);
        issuerProof = PublicIssuerLegalName(
          shellHtml: shell,
          shellSource: originalSource,
          overviewHtml: overviewHtml,
          overviewSource: overviewSource,
        );
        if (issuerProof.verify(
              receipt: sourceReceipt,
              corpCode: corpCode,
              masterName: companyName,
              printedName: printedName,
              coverSource: coverSource,
              coverHtml: coverHtml,
              periodStart: periodStart,
              periodEnd: periodEnd,
            ) ==
            null) {
          throw const FormatException(
            'Exact annual legal issuer corroboration failed',
          );
        }
      }
    }
    final statementHtml = await get(statementSource, referer: originalSource);
    if (exactAnnual && consolidated) {
      const explicitStatements = [
        '당사는 연결재무제표 작성법인이 아니므로 해당사항이 없습니다.',
        '해당사항 없습니다.',
        '해당사항이 없습니다.',
        '당사는 사업보고서 제출일 현재 해당사항이 없습니다.',
        '공시서류작성기준일 현재 해당사항이 없습니다.',
        '해당사항 없음.',
        '해당 사항 없음',
        '- 해당사항 없음.',
        '- 해당사항 없음',
        '- 당사는 보고서 제출일 현재 해당사항이 없습니다.',
        '당사는 해당사항 없습니다.',
        '본보고서 작성기준일 현재 해당사항이 없습니다.',
        '당사는 연결재무제표 작성대상 법인이 아니므로 해당사항이 없습니다.',
        '당사는 보고서 제출일 현재 해당사항 없습니다.',
        '당사는 본 보고서 작성기준일 현재 연결대상 종속회사가 없어 해당사항이 없습니다.',
        '당사는 본 보고서 작성기준일 현재 해당사항 없습니다.',
        '당사는 보고서 작성기준일 현재 해당사항이 없습니다.',
        '- 보고서 작성 기준일 현재 해당사항 없습니다.',
        '- 해당사항 없습니다.',
        '- 해당사항이 없습니다.',
        '- 당사는 사업보고서 작성기준일 현재 해당사항 없습니다.',
      ];
      final body = RegExp(
        r'<body\b[^>]*>(.*?)</body>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(statementHtml).toList();
      if (body.length == 1 &&
          !RegExp(
            r'<(?:table|script|style)\b',
            caseSensitive: false,
          ).hasMatch(body.single.group(1)!)) {
        final plain = body.single
            .group(1)!
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll('&nbsp;', '')
            .replaceAll(RegExp(r'\s+'), '');
        final matches = explicitStatements
            .where((e) => plain == '2.연결재무제표${e.replaceAll(' ', '')}')
            .toList();
        if (matches.length == 1) {
          final explicitNone = matches.single;
          throw PublicFinancialHtmlBasisNotApplicable(
            sourceReceipt: sourceReceipt,
            corpCode: corpCode,
            companyName: companyName,
            reportName: reportName,
            periodStart: periodStart,
            periodEnd: DateTime.utc(
              periodEnd.year,
              periodEnd.month,
              periodEnd.day,
            ),
            coverSource: coverSource,
            statementSource: statementSource,
            coverHtml: coverHtml,
            statementHtml: statementHtml,
            evidence: explicitNone,
            issuerProof: issuerProof,
          );
        }
      }
    }
    final name = companyName.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s+'), '');
    final suntechOriginal =
        !halfYear &&
        sourceReceipt == '20260317000808' &&
        corpCode == '00963000' &&
        periodEnd == DateTime.utc(2025, 12, 31);
    final parse = (exactAnnual || suntechOriginal)
        ? PublicFinancialHtml.parseStandardAnnual
        : halfYear
        ? PublicFinancialHtml.parseHalfYear
        : PublicFinancialHtml.parse;
    final rows = exactAnnual
        ? PublicFinancialHtml.parseStandardAnnual(
            issuerProof: issuerProof,
            coverHtml: coverHtml,
            statementHtml: statementHtml,
            coverSource: coverSource,
            statementSource: statementSource,
            receipt: sourceReceipt,
            corpCode: corpCode,
            companyName: companyName,
            periodStart: periodStart,
            periodEnd: periodEnd,
            consolidated: consolidated,
          )
        : parse(
            coverHtml: coverHtml,
            statementHtml: statementHtml,
            coverSource: coverSource,
            statementSource: statementSource,
            receipt: sourceReceipt,
            corpCode: corpCode,
            companyName: name,
            periodStart: periodStart,
            periodEnd: periodEnd,
            consolidated: consolidated,
          );
    return PublicFinancialHtmlSource(
      sourceReceipt: sourceReceipt,
      correctionReceipt: halfYear || exactAnnual ? null : correctionReceipt,
      correctionSource: halfYear || exactAnnual ? null : correctionSource,
      coverHtml: coverHtml,
      coverSource: coverSource,
      statementHtml: statementHtml,
      statementSource: statementSource,
      periodStart: periodStart,
      periodEnd: periodEnd,
      rows: rows,
      issuerProof: issuerProof,
    );
  }
}
