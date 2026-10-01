import 'dart:convert';
import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../disclosure/business_text.dart';

/// A viewer has no business-section node. Ambiguous nodes remain a strict error.
class PublicBusinessNodeMissing extends FormatException {
  const PublicBusinessNodeMissing() : super('Business section node missing');
}

/// An actual, receipt-bound public DART business section, never a viewer shell.
class PublicBusinessBody {
  const PublicBusinessBody({
    required this.receipt,
    required this.title,
    required this.text,
    required this.sourceUri,
    required this.bodySha256,
  });
  final String receipt;
  final String title;
  final String text;
  final Uri sourceUri;
  final String bodySha256;
}

/// Public transport has no OpenDART key and does not change OpenDART allowance.
/// The caller owns job cancellation, request pacing and public-request limits.
class PublicBusinessDocument {
  PublicBusinessDocument({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;
  final http.Client _client;
  final bool _ownsClient;
  bool _stopped = false;

  /// Prevents further shell/body GETs after the coordinator observes cancel.
  /// An already-issued request can still finish; its result must not be stored.
  void stop() => _stopped = true;
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static final _requestGateKey = Object();

  /// The scoped gate covers each native shell/body GET, without mutable shared
  /// callbacks or any database dependency in the HTTP reader.
  Future<PublicBusinessBody> fetchWithGate(
    String receipt,
    Future<bool> Function() gate,
  ) => runZoned(() => fetch(receipt), zoneValues: {_requestGateKey: gate});

  Future<PublicBusinessBody> fetch(String receipt) async {
    if (!RegExp(r'^\d{14}$').hasMatch(receipt)) {
      throw const FormatException('Invalid DART receipt');
    }
    final shellUri = Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
      'rcpNo': receipt,
    });
    final shell = await _get(shellUri);
    final source = bodyUri(receipt, shell);
    final body = await _get(source, referer: shellUri);
    return parse(receipt, source, body);
  }

  Future<String> _get(Uri uri, {Uri? referer}) async {
    final gate = Zone.current[_requestGateKey] as Future<bool> Function()?;
    if (_stopped || (gate != null && !await gate())) {
      throw const PublicBusinessFetchCancelled();
    }
    final response = await _client
        .get(
          uri,
          headers: {
            'User-Agent': 'InvestmentOntology/1.0',
            'Accept': 'text/html,application/xhtml+xml',
            if (referer != null) 'Referer': referer.toString(),
          },
        )
        .timeout(const Duration(seconds: 30));
    if (_stopped) throw const PublicBusinessFetchCancelled();
    if (response.request?.url case final finalUri?) {
      if (finalUri.scheme != 'https' || finalUri.host != 'dart.fss.or.kr') {
        throw const FormatException('DART response redirected outside source');
      }
    }
    if (response.statusCode != 200) {
      throw StateError('DART public HTTP ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes); // Reject lossy UTF-8.
  }

  static Uri bodyUri(String receipt, String shell) {
    final nodes = RegExp(
      r'''node\d+\[['"]text['"]\]\s*=\s*['"]II\.\s*사업의\s*내용['"];(.*?)(?:cnt\+\+)''',
      dotAll: true,
    ).allMatches(shell).toList();
    if (nodes.isEmpty) {
      if (RegExp(r'II\.\s*사업의\s*내용').hasMatch(shell)) {
        throw const FormatException('Malformed business section node');
      }
      final otherNodes = RegExp(
        r"""node\d+\[['"]text['"]\]\s*=\s*['"][^'"]+['"];(.*?)(?:cnt\+\+)""",
        dotAll: true,
      ).allMatches(shell);
      for (final node in otherNodes) {
        try {
          _nodeUri(receipt, node.group(1)!);
          throw const PublicBusinessNodeMissing();
        } on PublicBusinessNodeMissing {
          rethrow;
        } on FormatException {
          // A partial/foreign node is not evidence of a normal requested viewer.
        }
      }
      throw const FormatException('No verified receipt-bound DART viewer node');
    }
    if (nodes.length != 1) {
      throw const FormatException('Business section node ambiguous');
    }
    return _nodeUri(receipt, nodes.single.group(1)!);
  }

  static Uri _nodeUri(String receipt, String node) {
    final fields = <String, String>{};
    for (final match in RegExp(
      r'''\[['"](rcpNo|dcmNo|eleId|offset|length|dtd)['"]\]\s*=\s*['"]([^'"]+)['"]''',
    ).allMatches(node)) {
      if (fields.containsKey(match.group(1))) {
        throw const FormatException('Duplicate document coordinate');
      }
      fields[match.group(1)!] = match.group(2)!;
    }
    if (fields.length != 6 ||
        fields['rcpNo'] != receipt ||
        ![
          'dcmNo',
          'eleId',
          'offset',
          'length',
        ].every((key) => RegExp(r'^\d+$').hasMatch(fields[key]!)) ||
        int.parse(fields['length']!) <= 0 ||
        !RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(fields['dtd']!)) {
      {
        throw const FormatException(
          'DART document coordinates or receipt mismatch',
        );
      }
    }
    return Uri.https('dart.fss.or.kr', '/report/viewer.do', fields);
  }

  static PublicBusinessBody parse(String receipt, Uri sourceUri, String html) {
    if (sourceUri.scheme != 'https' ||
        sourceUri.host != 'dart.fss.or.kr' ||
        sourceUri.path != '/report/viewer.do' ||
        sourceUri.queryParameters['rcpNo'] != receipt ||
        html.contains('\uFFFD')) {
      throw const FormatException('Unverified DART body source');
    }
    var body = html.replaceAll(
      RegExp(
        r'<(script|style)\b[^>]*>.*?</\1>',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );
    // Existing XML normalization preserves table rows, entities and paragraph lines.
    body = body.replaceAllMapped(
      RegExp(r'<(/?)(tr|td|th|p|br|table)\b', caseSensitive: false),
      (m) => '<${m[1]}${m[2]!.toUpperCase()}',
    );
    body = body.replaceAllMapped(
      RegExp(
        r'<h[1-6]\b[^>]*>(.*?)</h[1-6]>',
        caseSensitive: false,
        dotAll: true,
      ),
      (m) => '<TITLE>${m[1]}</TITLE>',
    );
    var text = BusinessText.toText(body);
    final lines = text.split('\n');
    final start = lines.indexWhere(
      (line) => RegExp(r'^(?:## )?II\.\s*사업의\s*내용\s*$').hasMatch(line),
    );
    if (start < 0) throw const FormatException('Actual business title missing');
    final kept = lines
        .skip(start + 1)
        .takeWhile((line) => !RegExp(r'^(?:## )?III\.').hasMatch(line))
        .map((line) => RegExp(r'^\d+\.\s+').hasMatch(line) ? '## $line' : line)
        .toList();
    text = kept.join('\n');
    if (text.length < 100 ||
        !RegExp(r'[가-힣]').hasMatch(text) ||
        text.contains("node1['text']")) {
      throw const FormatException('Actual business content missing');
    }
    return PublicBusinessBody(
      receipt: receipt,
      title: 'II. 사업의 내용',
      text: text,
      sourceUri: sourceUri,
      bodySha256: sha256.convert(utf8.encode(html)).toString(),
    );
  }
}

/// A cooperative HTTP stop, not a missing source or a failed parsing attempt.
class PublicBusinessFetchCancelled implements Exception {
  const PublicBusinessFetchCancelled();
}
