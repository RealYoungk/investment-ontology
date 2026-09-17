import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// DART OpenAPI (https://opendart.fss.or.kr) 호출 오류.
class DartApiException implements Exception {
  DartApiException(this.status, this.message);

  /// DART 응답 status. 네트워크·파싱 오류는 `http`/`parse`.
  final String status;
  final String message;

  /// 키 오류, 호출 한도 초과, 점검 등 계속 호출해도 소용없는 상태.
  bool get isFatal => const {
    '010', // 등록되지 않은 키
    '011', // 사용할 수 없는 키
    '012', // 접근할 수 없는 IP
    '020', // 요청 제한 초과
    '800', // 시스템 점검
    '901', // 개인정보 보유기간 만료 계정
  }.contains(status);

  @override
  String toString() => 'DartApiException($status): $message';
}

/// `corpCode.xml`의 한 항목.
class DartCorpCode {
  DartCorpCode({
    required this.corpCode,
    required this.corpName,
    required this.stockCode,
    required this.modifyDate,
  });

  final String corpCode;
  final String corpName;
  final String? stockCode;
  final String? modifyDate;
}

class DartClient {
  DartClient(this.apiKey, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  static const baseUrl = 'https://opendart.fss.or.kr/api';

  final String apiKey;
  final http.Client _http;

  /// 호출 수 (한도 관리용).
  int calls = 0;

  static Uri companyPageUrl(String corpCode) => Uri.parse(
    'https://dart.fss.or.kr/dsab007/main.do?autoSearch=true&option=corp&textCrpCik=$corpCode',
  );

  static Uri companyApiUrl(String corpCode) =>
      Uri.parse('$baseUrl/company.json?corp_code=$corpCode');

  /// 전체 고유번호 목록 (zip 안의 CORPCODE.xml).
  Future<List<DartCorpCode>> fetchCorpCodes() async {
    final res = await _get('corpCode.xml', const {});
    final bytes = res.bodyBytes;
    // zip 시그니처(PK)가 아니면 오류 응답(XML/JSON).
    if (bytes.length < 2 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
      _throwFromErrorBody(utf8.decode(bytes, allowMalformed: true));
    }
    final archive = ZipDecoder().decodeBytes(bytes);
    final file = archive.files.firstWhere(
      (f) => f.name.toUpperCase().endsWith('.XML'),
      orElse: () => throw DartApiException('parse', 'corpCode zip에 XML이 없음'),
    );
    final doc = XmlDocument.parse(utf8.decode(file.content));
    return doc.findAllElements('list').map((e) {
      String? text(String name) {
        final v = e.getElement(name)?.innerText.trim();
        return (v == null || v.isEmpty) ? null : v;
      }

      return DartCorpCode(
        corpCode: text('corp_code')!,
        corpName: text('corp_name') ?? '',
        stockCode: text('stock_code'),
        modifyDate: text('modify_date'),
      );
    }).toList();
  }

  /// 기업개황 (`company.json`). 원문 필드를 그대로 돌려준다.
  Future<Map<String, dynamic>> fetchCompany(String corpCode) async {
    final res = await _get('company.json', {'corp_code': corpCode});
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw DartApiException('parse', 'company.json 파싱 실패: $e');
    }
    final status = body['status'] as String?;
    if (status != '000') {
      throw DartApiException(status ?? 'unknown', '${body['message']}');
    }
    return body;
  }

  Future<http.Response> _get(String path, Map<String, String> params) async {
    final uri = Uri.parse(
      '$baseUrl/$path',
    ).replace(queryParameters: {'crtfc_key': apiKey, ...params});
    calls++;
    final http.Response res;
    try {
      res = await _http.get(uri).timeout(const Duration(seconds: 30));
    } catch (e) {
      throw DartApiException('http', '$path 요청 실패: $e');
    }
    if (res.statusCode != 200) {
      throw DartApiException('http', '$path HTTP ${res.statusCode}');
    }
    return res;
  }

  Never _throwFromErrorBody(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      throw DartApiException('${json['status']}', '${json['message']}');
    } on FormatException {
      final doc = XmlDocument.parse(body);
      final status = doc.findAllElements('status').firstOrNull?.innerText;
      final message = doc.findAllElements('message').firstOrNull?.innerText;
      throw DartApiException(status ?? 'unknown', message ?? body);
    }
  }

  void close() => _http.close();
}
