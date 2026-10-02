import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'public_financial_period_metadata.dart';

class VerifiedHalfBasisCancelled implements Exception {}

/// Exact primary-source classification; contains no financial amount.
class VerifiedHalfBasisAbsence {
  VerifiedHalfBasisAbsence(
    this.cover,
    this.statementSource,
    this.statementSha256,
  );
  static const receipt = '20260813000889';
  static const corpCode = '00960623';
  static const bodySha =
      '3f078e33d1a2080cacd48e2a42ec03fd0f449b334a7bbe0f70ead8cfe3cdc0ac';
  static const coverSha =
      '9074e01dd0ade6b10d660e8c54051585a3ed64aae30a3e6d17fcc21cd12a0ab3';
  final PublicFinancialPeriodMetadata cover;
  final Uri statementSource;
  final String statementSha256;
  static Future<VerifiedHalfBasisAbsence> fetch(
    http.Client client, {
    required String targetReceipt,
    required String targetCorpCode,
    required String companyName,
    required Future<bool> Function() cancelled,
    Duration interval = const Duration(seconds: 1),
  }) async {
    if (targetReceipt != receipt || targetCorpCode != corpCode) {
      throw const FormatException('Unverified half-year basis identity');
    }
    final bounded = _BoundedClient(client, cancelled, interval);
    final cover = await PublicFinancialPeriodMetadata.fetch(
      bounded,
      receipt: receipt,
      targetReceipt: receipt,
      corpCode: corpCode,
      companyName: companyName,
      periodEnd: DateTime.utc(2026, 6, 30),
      halfYear: true,
      interval: Duration.zero,
    );
    if (cover.periodStart != DateTime.utc(2026) ||
        cover.periodEnd != DateTime.utc(2026, 6, 30) ||
        bounded.coverDigest != coverSha) {
      throw const FormatException('Unverified exact half-year cover');
    }
    final shell = bounded.shell;
    if (shell == null) {
      throw const FormatException('Missing exact source shell');
    }
    final matches = <Uri>[];
    for (final m in RegExp(
      r'''(node\d+)\['text'\]\s*=\s*"([^"]+)";''',
    ).allMatches(shell)) {
      if (m.group(2)!.replaceAll(RegExp(r'\s+'), '') != '2.연결재무제표') continue;
      final tail = shell.substring(m.end);
      final nextNode = RegExp(r'var\s+node\d+\s*=').firstMatch(tail);
      final block = nextNode == null ? tail : tail.substring(0, nextNode.start);
      final values = <String, String>{};
      for (final field in [
        'rcpNo',
        'dcmNo',
        'eleId',
        'offset',
        'length',
        'dtd',
      ]) {
        final pattern = "${m.group(1)}\\['$field'\\]\\s*=\\s*\"([^\"]+)\";";
        final coordinates = RegExp(pattern).allMatches(block).toList();
        if (coordinates.length != 1) {
          throw const FormatException('Malformed CFS node');
        }
        values[field] = coordinates.single.group(1)!;
      }
      if (values['rcpNo'] != receipt ||
          values['dcmNo'] != '11523776' ||
          values['eleId'] != '19' ||
          values['offset'] != '155297' ||
          values['length'] != '182' ||
          values['dtd'] != 'dart4.xsd') {
        throw const FormatException('Unverified CFS coordinates');
      }
      matches.add(Uri.https('dart.fss.or.kr', '/report/viewer.do', values));
    }
    if (matches.length != 1) throw const FormatException('Ambiguous CFS node');
    final source = matches.single;
    final response = await bounded.get(source);
    final raw = response.bodyBytes;
    final digest = sha256.convert(raw).toString();
    final body = RegExp(
      r'<body\b[^>]*>(.*?)</body>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(utf8.decode(raw)).toList();
    if (body.length != 1 ||
        RegExp(
          r'<(?:table|script|style)\b',
          caseSensitive: false,
        ).hasMatch(body.single.group(1)!)) {
      throw const FormatException('Non-literal CFS body');
    }
    final plain = body.single
        .group(1)!
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', '')
        .replaceAll(RegExp(r'\s+'), '');
    if (plain != '2.연결재무제표해당사항없음.' || digest != bodySha) {
      throw const FormatException('Unverified CFS absence literal');
    }
    if (await cancelled()) throw VerifiedHalfBasisCancelled();
    return VerifiedHalfBasisAbsence(cover, source, digest);
  }
}

class _BoundedClient extends http.BaseClient {
  _BoundedClient(this.delegate, this.cancelled, this.interval);
  final http.Client delegate;
  final Future<bool> Function() cancelled;
  final Duration interval;
  int requests = 0;
  String? shell;
  String? coverDigest;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (await cancelled()) throw VerifiedHalfBasisCancelled();
    if (requests >= 3) {
      throw const FormatException('Half-year classification request cap');
    }
    await Future<void>.delayed(interval);
    if (await cancelled()) throw VerifiedHalfBasisCancelled();
    requests++;
    final res = await delegate
        .send(request)
        .timeout(const Duration(seconds: 30));
    final raw = await res.stream.toBytes().timeout(const Duration(seconds: 30));
    if (res.statusCode != 200 ||
        (res.request?.url ?? request.url) != request.url ||
        raw.length > 5 * 1024 * 1024) {
      throw const FormatException('Invalid half-year source response');
    }
    if (request.url.path == '/dsaf001/main.do') shell = utf8.decode(raw);
    if (request.url.queryParameters['eleId'] == '1') {
      coverDigest = sha256.convert(raw).toString();
    }
    return http.StreamedResponse(
      Stream.value(raw),
      res.statusCode,
      headers: res.headers,
      request: res.request,
    );
  }
}
