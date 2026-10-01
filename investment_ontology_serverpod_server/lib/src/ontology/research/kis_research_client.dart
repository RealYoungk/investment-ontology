import 'dart:convert';

import 'package:http/http.dart' as http;

/// Quote endpoints only. No account number, balance or order endpoint is used.
class KisResearchClient {
  KisResearchClient(this.appKey, this.appSecret, {http.Client? client})
    : _http = client ?? http.Client();
  final String appKey;
  final String appSecret;
  final http.Client _http;
  String? _token;
  DateTime? _expires;
  static const origin = 'https://openapi.koreainvestment.com:9443';

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    if (response.statusCode != 200) {
      throw StateError('KIS HTTP ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) throw StateError('KIS 응답 형식 오류');
    return data;
  }

  Future<void> _authenticate() async {
    if (_token != null && _expires!.isAfter(DateTime.now())) return;
    final data = await _decode(
      await _http
          .post(
            Uri.parse('$origin/oauth2/tokenP'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'grant_type': 'client_credentials',
              'appkey': appKey,
              'appsecret': appSecret,
            }),
          )
          .timeout(const Duration(seconds: 20)),
    );
    if (data['access_token'] is! String || data['expires_in'] is! num) {
      throw StateError('KIS 인증 실패. 서버의 키 설정을 확인하세요.');
    }
    _token = data['access_token'];
    _expires = DateTime.now().add(
      Duration(seconds: (data['expires_in'] as num).toInt() - 120),
    );
  }

  /// One provider page; callers see coverage explicitly, never claim a full range.
  Future<List<Map<String, dynamic>>> fetch(
    String kind,
    String stockCode,
    DateTime end,
  ) async {
    if (!{'flows', 'shorts'}.contains(kind) ||
        !RegExp(r'^\d{6}$').hasMatch(stockCode)) {
      throw ArgumentError('자료 종류 또는 종목코드 오류');
    }
    await _authenticate();
    String day(DateTime d) =>
        d.toIso8601String().substring(0, 10).replaceAll('-', '');
    final short = kind == 'shorts';
    final path = short ? 'daily-short-sale' : 'investor-trade-by-stock-daily';
    final data = await _decode(
      await _http
          .get(
            Uri.parse(
              '$origin/uapi/domestic-stock/v1/quotations/$path',
            ).replace(
              queryParameters: {
                'FID_COND_MRKT_DIV_CODE': 'J',
                'FID_INPUT_ISCD': stockCode,
                'FID_INPUT_DATE_1': day(
                  short ? end.subtract(const Duration(days: 90)) : end,
                ),
                if (short) 'FID_INPUT_DATE_2': day(end),
                if (!short) ...{'FID_ORG_ADJ_PRC': '', 'FID_ETC_CLS_CODE': ''},
              },
            ),
            headers: {
              'authorization': 'Bearer $_token',
              'appkey': appKey,
              'appsecret': appSecret,
              'tr_id': short ? 'FHPST04830000' : 'FHPTJ04160001',
              'custtype': 'P',
            },
          )
          .timeout(const Duration(seconds: 20)),
    );
    if (data['rt_cd'] != '0' || data['output2'] is! List) {
      throw StateError('KIS 조회 실패. 인증·이용한도·자료 제공 여부를 확인하세요.');
    }
    return normalize(kind, stockCode, data['output2'] as List);
  }

  static List<Map<String, dynamic>> normalize(
    String kind,
    String stockCode,
    List raw,
  ) => [
    for (final r in raw)
      if (r is Map && RegExp(r'^\d{8}$').hasMatch('${r['stck_bsop_date']}'))
        {
          'date': '${r['stck_bsop_date']}'.replaceFirstMapped(
            RegExp(r'^(\d{4})(\d{2})(\d{2})$'),
            (m) => '${m[1]}-${m[2]}-${m[3]}',
          ),
          'stockCode': stockCode,
          if (kind == 'flows') ...{
            'foreign': r['frgn_ntby_qty'],
            'individual': r['prsn_ntby_qty'],
            'institution': r['orgn_ntby_qty'],
          } else ...{
            'volume': r['ssts_cntg_qty'],
            'totalVolume': r['acml_vol'],
          },
        },
  ];
  void close() => _http.close();
}
