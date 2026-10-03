import 'reviewed_dart_issuer_sources.dart';

/// Metadata-only official documents. Never creates financial reports or facts.
/// Content evidence is prepared offline; this validator is not a PDF parser.
abstract final class IssuerDocumentsFeed {
  static const hosts = {
    '00435297': 'www.mkif.com',
    '01880801': 'kbif.co.kr',
    '00600013': 're1.miraeasset.com',
  };

  static Uri officialUrl(String value, String corpCode) {
    if (ReviewedDartIssuerSources.findUrl(value, corpCode) != null) {
      return Uri.parse(
        value,
      ); // Exact compiled URI, including its reviewed node.
    }
    final u = Uri.tryParse(value);
    if (u == null ||
        u.scheme != 'https' ||
        u.host != hosts[corpCode] ||
        u.hasPort ||
        RegExp(r'^https://[^/]+:').hasMatch(value) ||
        u.userInfo.isNotEmpty ||
        u.hasFragment ||
        u.hasQuery ||
        !u.path.endsWith('.pdf') ||
        u.pathSegments.contains('..') ||
        u.path.contains('%') ||
        !(u.path.startsWith('/upload/') ||
            u.path.startsWith('/assets/mkif/'))) {
      throw const FormatException('공식 회사의 고정 PDF URL만 허용합니다.');
    }
    return u;
  }

  static List<Map<String, dynamic>> validate(dynamic input) {
    if (input is! List || input.isEmpty || input.length > 100) {
      throw const FormatException('공식 원문 메타데이터는 1~100행이어야 합니다.');
    }
    final seen = <String>{};
    String? company;
    return input.map((raw) {
      if (raw is! Map) throw const FormatException('행은 객체여야 합니다.');
      const keys = {
        'corpCode',
        'title',
        'documentType',
        'provider',
        'providerReceipt',
        'providerDocumentId',
        'periodStart',
        'periodEnd',
        'publishedAt',
        'officialUrl',
        'sha256',
        'issuerQuote',
        'periodQuote',
        'numericState',
        'financialValues',
        'publicContent',
      };
      if (raw.keys.toSet().difference(keys).isNotEmpty ||
          keys.difference(raw.keys.toSet()).isNotEmpty) {
        throw const FormatException('원문 메타데이터 필드가 일치하지 않습니다.');
      }
      String text(String k, int max) {
        final v = raw[k];
        if (v is! String || v.trim().isEmpty || v.length > max) {
          throw FormatException('$k 문자열 오류');
        }
        return v;
      }

      String date(String k) {
        final v = text(k, 10), d = DateTime.tryParse(v);
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) ||
            d == null ||
            d.toIso8601String().substring(0, 10) != v) {
          throw FormatException('$k 날짜 오류');
        }
        return v;
      }

      final corp = text('corpCode', 8);
      if ((!hosts.containsKey(corp) &&
              ReviewedDartIssuerSources.findUrl(
                    '${raw['officialUrl']}',
                    corp,
                  ) ==
                  null) ||
          (company != null && company != corp)) {
        throw const FormatException('검증 대상 회사 한 곳의 자료만 허용합니다.');
      }
      company = corp;
      officialUrl(text('officialUrl', 1000), corp);
      if (raw['provider'] == 'DART' ||
          ReviewedDartIssuerSources.findUrl('${raw['officialUrl']}', corp) !=
              null) {
        ReviewedDartIssuerSources.validateMetadata(raw);
      }
      final start = date('periodStart'), end = date('periodEnd');
      final published = raw['publishedAt'] == null ? null : date('publishedAt');
      if (start.compareTo(end) > 0 ||
          (published != null &&
              (published.compareTo(end) < 0 ||
                  DateTime.parse(published).isAfter(DateTime.now().toUtc())))) {
        throw const FormatException('보고기간/게시일 모순');
      }
      text('title', 300);
      text('issuerQuote', 1000);
      text('periodQuote', 1000);
      if (!{
            'auditReport',
            'assetManagementReport',
            'operatingReport',
            'securitiesRegistrationStatement',
            'prospectus',
          }.contains(text('documentType', 50)) ||
          (raw['provider'] != 'DART' &&
              {
                'securitiesRegistrationStatement',
                'prospectus',
              }.contains(raw['documentType'])) ||
          !{'officialIR', 'KIND', 'DART'}.contains(text('provider', 20))) {
        throw const FormatException('원문 종류/제공처 오류');
      }
      final receipt = raw['providerReceipt'], doc = raw['providerDocumentId'];
      for (final v in [receipt, doc]) {
        if (v != null && (v is! String || !RegExp(r'^\d{14}$').hasMatch(v))) {
          throw const FormatException('접수/문서 ID 오류');
        }
      }
      if (raw['provider'] != 'officialIR' && receipt == null ||
          raw['provider'] == 'officialIR' && (receipt != null || doc != null)) {
        throw const FormatException('제공처별 원접수 증거가 필요합니다.');
      }
      final sha = text('sha256', 64);
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha) ||
          raw['numericState'] != 'notExtracted' ||
          raw['financialValues'] != null ||
          raw['publicContent'] != 'linkOnly') {
        throw const FormatException('원문 SHA/숫자 미추출/링크 공개 계약 오류');
      }
      if (!seen.add('${raw['officialUrl']}|$sha')) {
        throw const FormatException('중복 원문');
      }
      return Map<String, dynamic>.from(raw);
    }).toList();
  }
}
