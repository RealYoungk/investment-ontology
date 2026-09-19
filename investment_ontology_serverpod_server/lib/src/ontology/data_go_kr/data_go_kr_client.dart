import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../dart/dart_values.dart';

/// 공공데이터포털 API 호출 오류.
class DataGoKrApiException implements Exception {
  DataGoKrApiException(this.code, this.message);

  /// 포털 결과 코드(`resultCode`/`returnReasonCode`) 또는 `http`/`parse`.
  final String code;
  final String message;

  /// 키 오류, 활용신청 안 됨, 호출 한도 초과 등 계속 호출해도 소용없는 상태.
  bool get isFatal => const {
    '12', // 해당 오픈API 서비스가 없거나 폐기됨
    '20', // 서비스 접근 거부 (활용신청 안 됨)
    '22', // 서비스 요청 제한 횟수 초과
    '30', // 등록되지 않은 서비스키
    '31', // 기한 만료된 서비스키
    '32', // 등록되지 않은 IP
    '401',
    '403',
    '429',
  }.contains(code);

  @override
  String toString() => 'DataGoKrApiException($code): $message';
}

/// 목록 API 한 페이지.
class DataGoKrPage {
  DataGoKrPage({
    required this.pageNo,
    required this.numOfRows,
    required this.totalCount,
    required this.items,
  });

  final int pageNo;
  final int numOfRows;
  final int totalCount;

  /// 원문 항목 (값은 모두 문자열).
  final List<Map<String, dynamic>> items;

  bool get isLast => pageNo * numOfRows >= totalCount;
}

/// 금융위원회 공공데이터 (https://www.data.go.kr) 클라이언트.
class DataGoKrClient {
  DataGoKrClient(this.serviceKey, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  static const baseUrl = 'https://apis.data.go.kr/1160100';

  /// 2026년 현재 활용신청되는 V2 주소. V2가 없는 옛 주소는 오류 12(서비스 없음)를 준다.
  static const stockPricePath =
      'GetStockSecuritiesInfoService_V2/getStockPriceInfo_V2';
  static const listedItemPath = 'GetKrxListedInfoService_V2/getItemInfo_V2';

  /// 페이지당 행 수.
  static const pageSize = 1000;

  final String serviceKey;
  final http.Client _http;

  /// 호출 수 (한도 관리용).
  int calls = 0;

  /// 서비스키를 뺀 주소 (Source 기록용).
  static Uri publicUrl(String path, DateTime baseDate) => Uri.parse(
    '$baseUrl/$path',
  ).replace(queryParameters: {'basDt': DartValues.formatYmd(baseDate)});

  /// 주식시세정보: 기준일의 전 종목 시세.
  Future<DataGoKrPage> fetchStockPrices(DateTime baseDate, {int page = 1}) =>
      _page(stockPricePath, baseDate, page);

  /// KRX상장종목정보: 기준일의 상장 종목과 발행 법인.
  Future<DataGoKrPage> fetchListedItems(DateTime baseDate, {int page = 1}) =>
      _page(listedItemPath, baseDate, page);

  Future<DataGoKrPage> _page(String path, DateTime baseDate, int page) async {
    final uri = Uri.parse('$baseUrl/$path').replace(
      queryParameters: {
        'serviceKey': serviceKey,
        'resultType': 'json',
        'basDt': DartValues.formatYmd(baseDate),
        'pageNo': '$page',
        'numOfRows': '$pageSize',
      },
    );
    calls++;
    final http.Response res;
    try {
      res = await _http.get(uri).timeout(const Duration(seconds: 60));
    } catch (e) {
      throw DataGoKrApiException('http', '$path 요청 실패: $e');
    }
    final text = utf8.decode(res.bodyBytes, allowMalformed: true);
    if (res.statusCode != 200) {
      throw DataGoKrApiException(
        '${res.statusCode}',
        '$path HTTP ${res.statusCode}: ${_short(text)}',
      );
    }
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(text) as Map<String, dynamic>;
    } on FormatException {
      // 키·한도 오류는 resultType과 관계없이 XML로 온다.
      _throwFromXml(path, text);
    }
    // 키·주소 오류는 JSON으로 와도 `OpenAPI_ServiceResponse` 형식이다.
    final gateway = json['OpenAPI_ServiceResponse'] as Map<String, dynamic>?;
    if (gateway != null) {
      final header = gateway['cmmMsgHeader'] as Map<String, dynamic>?;
      throw DataGoKrApiException(
        '${header?['returnReasonCode'] ?? 'parse'}',
        '${header?['errMsg'] ?? ''} ${header?['returnAuthMsg'] ?? ''}'.trim(),
      );
    }
    final response = json['response'] as Map<String, dynamic>?;
    final header = response?['header'] as Map<String, dynamic>?;
    final code = '${header?['resultCode'] ?? 'parse'}';
    if (code != '00') {
      throw DataGoKrApiException(code, '${header?['resultMsg'] ?? text}');
    }
    final body = (response?['body'] as Map<String, dynamic>?) ?? const {};
    return DataGoKrPage(
      pageNo: _int(body['pageNo']) ?? page,
      numOfRows: _int(body['numOfRows']) ?? pageSize,
      totalCount: _int(body['totalCount']) ?? 0,
      items: _items(body['items']),
    );
  }

  /// `items`는 결과가 없으면 빈 문자열, 한 건이면 객체로 올 수 있다.
  static List<Map<String, dynamic>> _items(Object? items) {
    if (items is! Map) return const [];
    final item = items['item'];
    if (item is List) return item.cast<Map<String, dynamic>>();
    if (item is Map<String, dynamic>) return [item];
    return const [];
  }

  static int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v');

  static String _short(String s) => s.length > 200 ? s.substring(0, 200) : s;

  Never _throwFromXml(String path, String text) {
    try {
      final doc = XmlDocument.parse(text);
      String? find(String name) =>
          doc.findAllElements(name).firstOrNull?.innerText.trim();
      final code = find('returnReasonCode') ?? find('resultCode');
      final message =
          find('returnAuthMsg') ?? find('errMsg') ?? find('resultMsg');
      throw DataGoKrApiException(code ?? 'parse', message ?? _short(text));
    } on XmlException {
      throw DataGoKrApiException(
        'parse',
        '$path 응답을 해석할 수 없음: ${_short(text)}',
      );
    }
  }

  void close() => _http.close();
}
