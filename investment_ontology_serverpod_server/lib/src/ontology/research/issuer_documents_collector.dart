import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'issuer_documents_feed.dart';

/// Fixed, human-read source manifest. No discovery, monetary extraction or DART API.
class IssuerDocumentsCollector {
  IssuerDocumentsCollector({
    required this.cache,
    http.Client? client,
    Future<void> Function(Duration)? delay,
  }) : client = client ?? http.Client(),
       delay = delay ?? Future<void>.delayed;
  final Directory cache;
  final http.Client client;
  final Future<void> Function(Duration) delay;
  static DateTime? _lastLaunch;
  static const maxBytes = 20 * 1024 * 1024;

  static List<Map<String, dynamic>> manifest(String text) {
    final raw = jsonDecode(text);
    if (raw is! Map || raw['schemaVersion'] != 1 || raw['documents'] is! List) {
      throw const FormatException('고정 원문 목록 형식 오류');
    }
    final docs = (raw['documents'] as List).map((v) {
      if (v is! Map || v['metadata'] is! Map || v['proof'] is! Map) {
        throw const FormatException('원문 증거 형식 오류');
      }
      final d = Map<String, dynamic>.from(v), proof = d['proof'] as Map;
      final at = DateTime.tryParse('${proof['downloadedAt']}');
      if (at == null ||
          at.isAfter(DateTime.now().toUtc()) ||
          !{'text cover p1', 'visual cover p1'}.contains(proof['readScope']) ||
          proof['periodProof'] != 'printed PDF cover, no filename inference') {
        throw const FormatException('원문 다운로드/기간 읽기 증거 오류');
      }
      return d;
    }).toList();
    if (docs.isEmpty || docs.length > 30) {
      throw const FormatException('원문 목록 한도 오류');
    }
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final d in docs) {
      final m = Map<String, dynamic>.from(d['metadata'] as Map);
      groups.putIfAbsent('${m['corpCode']}', () => []).add(m);
    }
    for (final rows in groups.values) {
      IssuerDocumentsFeed.validate(rows);
    }
    return docs;
  }

  /// Verifies exact bytes before exposing metadata to the store. Cache is private.
  Future<bool> ensure(
    Map<String, dynamic> doc, {
    required Future<bool> Function() cancelled,
  }) async {
    if (await cancelled()) return false;
    final m = doc['metadata'] as Map, digest = m['sha256'] as String;
    final file = File('${cache.path}/$digest.pdf');
    List<int> bytes;
    if (await file.exists()) {
      if (await file.length() > maxBytes) {
        throw const FormatException('공식 PDF cache 크기 한도 초과');
      }
      bytes = await file.readAsBytes();
    } else {
      final since = _lastLaunch == null
          ? Duration.zero
          : DateTime.now().difference(_lastLaunch!);
      if (since < const Duration(seconds: 1)) {
        await delay(const Duration(seconds: 1) - since);
      }
      if (await cancelled()) return false;
      _lastLaunch = DateTime.now();
      final uri = IssuerDocumentsFeed.officialUrl(
        m['officialUrl'] as String,
        m['corpCode'] as String,
      );
      final request = http.Request('GET', uri)..followRedirects = false;
      final started = DateTime.now();
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 ||
          response.request?.url != uri ||
          (response.contentLength ?? 0) > maxBytes) {
        throw const FormatException('공식 PDF 응답/경로/크기 오류');
      }
      bytes = <int>[];
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 30),
      )) {
        if (await cancelled()) return false;
        if (DateTime.now().difference(started) > const Duration(seconds: 30)) {
          throw const FormatException('공식 PDF 수집 시간 한도 초과');
        }
        bytes.addAll(chunk);
        if (bytes.length > maxBytes) {
          throw const FormatException('공식 PDF 크기 한도 초과');
        }
      }
    }
    if (bytes.length < 5 ||
        bytes.length > maxBytes ||
        ascii.decode(bytes.take(5).toList(), allowInvalid: true) != '%PDF-' ||
        sha256.convert(bytes).toString() != digest) {
      throw const FormatException('검증된 원본 PDF SHA 불일치');
    }
    if (await cancelled()) return false;
    await cache.create(recursive: true);
    if (!await file.exists()) {
      // Atomic same-filesystem publication. Existing content is never overwritten.
      final temp = File(
        '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
      );
      await temp.writeAsBytes(bytes, flush: true);
      try {
        await temp.rename(file.path);
      } finally {
        if (await temp.exists()) await temp.delete();
      }
    }
    return true;
  }
}
