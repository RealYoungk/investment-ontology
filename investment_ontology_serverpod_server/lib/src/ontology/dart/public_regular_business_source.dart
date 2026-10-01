import 'dart:convert';

import 'package:http/http.dart' as http;

import 'public_business_document.dart';
import 'public_financial_period_metadata.dart';
import 'dart_report_name.dart';

/// Official periodic-report discovery and metadata/body-presence proof only.
/// No financial amounts are parsed or inferred.
class PublicRegularBusinessSource {
  PublicRegularBusinessSource(
    this.metadata,
    this.body,
    this.reportName,
    this.discoverySource,
  );
  final PublicFinancialPeriodMetadata metadata;
  final PublicBusinessBody body;
  final String reportName;
  final Uri discoverySource;

  static Future<PublicRegularBusinessSource> fetch(
    http.Client client, {
    required String corpCode,
    required String companyName,
    required int? fiscalMonth,
    Duration interval = const Duration(seconds: 1),
  }) async {
    if (!RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw const FormatException('Invalid discovery company');
    }
    final transport = _BoundedCachedClient(client, interval);
    final discovery = Uri.https('dart.fss.or.kr', '/navi/searchNavi.do', {
      'naviCode': 'A002',
      'naviCrpCik': corpCode,
      'naviCrpNm': companyName,
    });
    final navi = await transport.text(discovery);
    final companies = RegExp(
      r"openCorpInfoNew\('(\d{8})',\s*'winCorpInfo',\s*'/dsae001/selectPopup.ax'\)",
    ).allMatches(navi).map((m) => m[1]!).toSet();
    final links = RegExp(
      r'''openReportViewer\(['"](\d{14})['"],['"]['"]\);[^>]*>(.*?)</a>''',
      dotAll: true,
    ).allMatches(navi).toList();
    if (companies.length != 1 ||
        companies.single != corpCode ||
        links.length != 1) {
      throw const FormatException(
        'Regular report not identified by company navigation',
      );
    }
    final label = links.single[2]!.replaceAll(RegExp(r'\s+'), '');
    final match = RegExp(r'^(사업보고서|반기보고서)\(사업연도:(\d{4})\)보러가기$')
        .firstMatch(label);
    if (match == null) {
      throw const FormatException(
        'Unsupported or nonperiodic navigation source',
      );
    }
    final receipt = links.single[1]!, kind = match[1]!;
    final shellUri = Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
      'rcpNo': receipt,
    });
    final shell = await transport.text(shellUri);
    final covers = <Uri>[];
    for (final block in RegExp(
      r'''node[12]\['text'\]\s*=\s*"([^"]+)";(.*?)(?=node[12]\['text'\]|$)''',
      dotAll: true,
    ).allMatches(shell)) {
      if (block[1]!.replaceAll(RegExp(r'\s+'), '') != kind) continue;
      final q = {
        for (final m in RegExp(
          r'''node[12]\['(rcpNo|dcmNo|eleId|offset|length|dtd)'\]\s*=\s*"([^"]+)"''',
        ).allMatches(block[2]!))
          m[1]!: m[2]!,
      };
      if (q.length != 6 || q['rcpNo'] != receipt) {
        throw const FormatException('Unbound discovered cover');
      }
      covers.add(Uri.https('dart.fss.or.kr', '/report/viewer.do', q));
    }
    if (covers.length != 1) {
      throw const FormatException('Discovered cover ambiguous');
    }
    final raw = await transport.text(covers.single);
    final compact = raw
        .replaceAll(RegExp(r'<[^>]*>', dotAll: true), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#160;', ' ')
        .replaceAll(RegExp(r'\s+'), '');
    final dates = RegExp(
      r'사업연도(\d{4})년(\d{1,2})월(\d{1,2})일부터(\d{4})년(\d{1,2})월(\d{1,2})일까지',
    ).allMatches(compact).toList();
    if (dates.length != 1) {
      throw const FormatException('Source reporting interval missing');
    }
    final m = dates.single;
    final end = DateTime.utc(
      int.parse(m[4]!),
      int.parse(m[5]!),
      int.parse(m[6]!),
    );
    if (end.day != int.parse(m[6]!) || end.month != int.parse(m[5]!)) {
      throw const FormatException('Invalid discovered date');
    }
    final reportName =
        '$kind (${end.year}.${end.month.toString().padLeft(2, '0')})';
    final resolved = DartReportName.parse(reportName)!.resolve(fiscalMonth);
    if (resolved == null || resolved.bsnsYear != int.parse(match[2]!)) {
      throw const FormatException('Navigation fiscal period mismatch');
    }
    final metadata = await PublicFinancialPeriodMetadata.fetch(
      transport,
      receipt: receipt,
      targetReceipt: receipt,
      corpCode: corpCode,
      companyName: companyName,
      periodEnd: end,
      halfYear: kind == '반기보고서',
      interval: Duration.zero,
    );
    final body = await PublicBusinessDocument(client: transport).fetch(receipt);
    if (body.receipt != receipt ||
        body.text.trim().isEmpty ||
        body.sourceUri.queryParameters['dcmNo'] !=
            metadata.coverSource.queryParameters['dcmNo']) {
      throw const FormatException('Discovered business body not bound');
    }
    return PublicRegularBusinessSource(metadata, body, reportName, discovery);
  }
}

class _BoundedCachedClient extends http.BaseClient {
  _BoundedCachedClient(this.delegate, this.interval);
  final http.Client delegate;
  final Duration interval;
  final _cache = <Uri, List<int>>{};
  int requests = 0;
  Future<String> text(Uri uri) async => utf8.decode((await get(uri)).bodyBytes);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;
    if (uri.scheme != 'https' ||
        uri.host != 'dart.fss.or.kr' ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Nonofficial discovery source');
    }
    if (_cache[uri] case final bytes?) {
      return http.StreamedResponse(Stream.value(bytes), 200, request: request);
    }
    if (requests++ >= 4) {
      throw const FormatException('Discovery request bound exceeded');
    }
    await Future<void>.delayed(interval);
    final response = await delegate.send(request);
    if (response.statusCode != 200 || (response.request?.url ?? uri) != uri) {
      throw const FormatException('Discovery response mismatch');
    }
    final bytes = await response.stream.toBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Oversized source');
    }
    _cache[uri] = bytes;
    return http.StreamedResponse(Stream.value(bytes), 200, request: request);
  }
}
