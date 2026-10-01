import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class PublicFinancialMetadataPeriodMismatch extends FormatException {
  const PublicFinancialMetadataPeriodMismatch()
    : super('Official cover reporting period mismatch');
}

/// Primary cover metadata only; no financial values are read or verified.
class PublicFinancialPeriodMetadata {
  PublicFinancialPeriodMetadata({
    required this.receipt,
    required this.corpCode,
    required this.periodStart,
    required this.periodEnd,
    required this.shellSource,
    required this.coverSource,
    required this.digest,
  });
  final String receipt;
  final String corpCode;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Uri shellSource;
  final Uri coverSource;
  final String digest;

  static Future<PublicFinancialPeriodMetadata> fetch(
    http.Client client, {
    required String receipt,
    required String corpCode,
    required String companyName,
    required String targetReceipt,
    required DateTime periodEnd,
    bool halfYear = false,
    Duration interval = const Duration(seconds: 1),
  }) async {
    if (!RegExp(r'^\d{14}$').hasMatch(receipt) ||
        !RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw const FormatException('Invalid source metadata identity');
    }
    final reportTitle = halfYear ? '반기보고서' : '사업보고서';
    final shellSource = Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
      'rcpNo': receipt,
    });
    String? cookie;
    Future<String> get(Uri uri, {Uri? referer}) async {
      final response = await client
          .get(
            uri,
            headers: {
              'User-Agent': 'InvestmentOntology/1.0',
              if (referer != null) 'Referer': referer.toString(),
              if (cookie != null) 'Cookie': cookie!,
            },
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 ||
          (response.request?.url.host ?? uri.host) != 'dart.fss.or.kr' ||
          response.bodyBytes.length > 5 * 1024 * 1024) {
        throw const FormatException('Invalid metadata response');
      }
      cookie = response.headers['set-cookie']?.split(';').first ?? cookie;
      return utf8.decode(response.bodyBytes);
    }

    if (targetReceipt != receipt) {
      if (!RegExp(r'^\d{14}$').hasMatch(targetReceipt) ||
          receipt.compareTo(targetReceipt) >= 0) {
        throw const FormatException('Invalid target/source receipt order');
      }
      final targetShell = await get(
        Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
          'rcpNo': targetReceipt,
        }),
      );
      final targetCompanies = RegExp(
        r"openCorpInfoNew\('(\d{8})',\s*'winCorpInfo',\s*'/dsae001/selectPopup.ax'\)",
      ).allMatches(targetShell).map((m) => m.group(1)!).toSet();
      final families = RegExp(
        r'''<select\b[^>]*\bid=["']family["'][^>]*>(.*?)</select>''',
        dotAll: true,
      ).allMatches(targetShell).toList();
      if (families.length != 1) {
        throw const FormatException('Missing or ambiguous family selector');
      }
      final link = RegExp(
        '<option[^>]+value=["\']rcpNo=$receipt["\'][^>]*>([^<]+)</option>',
      ).allMatches(families.single.group(1)!).toList();
      if (targetCompanies.length != 1 ||
          targetCompanies.single != corpCode ||
          !targetShell.contains("openPdfDownload('$targetReceipt',") ||
          link.length != 1 ||
          !link.single
              .group(1)!
              .replaceAll(RegExp(r'\s+'), '')
              .contains(reportTitle)) {
        throw const FormatException(
          'No explicit official target/source report-family link',
        );
      }
      await Future<void>.delayed(interval);
    }
    final shell = await get(shellSource);
    final companies = RegExp(
      r"openCorpInfoNew\('(\d{8})',\s*'winCorpInfo',\s*'/dsae001/selectPopup.ax'\)",
    ).allMatches(shell).map((m) => m.group(1)!).toSet();
    final documents = RegExp("openPdfDownload\\('$receipt',\\s*'(\\d+)'\\)")
        .allMatches(shell)
        .map((m) => m.group(1)!)
        .toSet();
    if (companies.length != 1 ||
        companies.single != corpCode ||
        documents.length != 1) {
      throw const FormatException('Unbound source metadata shell');
    }
    final covers = <Uri>[];
    for (final node in RegExp(
      r'''node[12]\['text'\]\s*=\s*"([^"]+)";(.*?)(?=node[12]\['text'\]|$)''',
      dotAll: true,
    ).allMatches(shell)) {
      if (node.group(1)!.replaceAll(RegExp(r'\s+'), '') != reportTitle) {
        continue;
      }
      final coordinates = <String, String>{};
      for (final a in RegExp(
        r'''node[12]\['(rcpNo|dcmNo|eleId|offset|length|dtd)'\]\s*=\s*"([^"]+)"''',
      ).allMatches(node.group(2)!)) {
        if (coordinates.containsKey(a.group(1))) {
          throw const FormatException('Duplicate cover coordinate');
        }
        coordinates[a.group(1)!] = a.group(2)!;
      }
      if (coordinates['rcpNo'] != receipt ||
          coordinates['dcmNo'] != documents.single ||
          [
            'eleId',
            'offset',
            'length',
          ].any((k) => !RegExp(r'^\d{1,9}$').hasMatch(coordinates[k] ?? '')) ||
          !const ['dart3.xsd', 'dart4.xsd'].contains(coordinates['dtd']) ||
          int.parse(coordinates['length']!) <= 0 ||
          int.parse(coordinates['length']!) > 5 * 1024 * 1024) {
        throw const FormatException('Unbound annual cover');
      }
      covers.add(Uri.https('dart.fss.or.kr', '/report/viewer.do', coordinates));
    }
    if (covers.length != 1) {
      throw const FormatException('Ambiguous annual cover');
    }
    await Future<void>.delayed(interval);
    final cover = await get(covers.single, referer: shellSource);
    final compact = cover
        .replaceAll(RegExp(r'<[^>]*>', dotAll: true), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#160;', ' ')
        .replaceAll(RegExp(r'\s+'), '');
    final normalized = compact.replaceAllMapped(
      RegExp(r'(\d{4})\.(\d{1,2})\.(\d{1,2})\.?'),
      (m) => '${m[1]}년${m[2]}월${m[3]}일',
    );
    final periods = RegExp(
      r'사업연도(\d{4})년(\d{1,2})월(\d{1,2})일부터(\d{4})년(\d{1,2})월(\d{1,2})일까지',
    ).allMatches(normalized).toList();
    if (periods.length != 1 || !compact.contains(reportTitle)) {
      throw const FormatException('Missing annual cover period');
    }
    DateTime date(int n) {
      final m = periods.single;
      final y = int.parse(m.group(n)!);
      final mo = int.parse(m.group(n + 1)!);
      final d = int.parse(m.group(n + 2)!);
      final value = DateTime.utc(y, mo, d);
      if (value.year != y || value.month != mo || value.day != d) {
        throw const FormatException('Invalid cover date');
      }
      return value;
    }

    final start = date(1), end = date(4);
    // Stable shell corpCode is authoritative even after a company rename.
    if (end != DateTime.utc(periodEnd.year, periodEnd.month, periodEnd.day)) {
      throw const PublicFinancialMetadataPeriodMismatch();
    }
    if (!compact.contains('회사명') ||
        start.isAfter(end) ||
        end.difference(start).inDays + 1 > (halfYear ? 184 : 366)) {
      throw const FormatException('Cover company or reporting period mismatch');
    }
    return PublicFinancialPeriodMetadata(
      receipt: receipt,
      corpCode: corpCode,
      periodStart: start,
      periodEnd: end,
      shellSource: shellSource,
      coverSource: covers.single,
      digest: sha256.convert(utf8.encode('$shell\n$cover')).toString(),
    );
  }
}
