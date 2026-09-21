import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'dart_values.dart';

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
    '021', // 조회 가능한 회사 개수 초과
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
  final DateTime? modifyDate;
}

/// `list.json`의 공시 한 건.
class DartFilingItem {
  DartFilingItem({
    required this.corpCode,
    required this.corpName,
    required this.stockCode,
    required this.corpCls,
    required this.reportName,
    required this.rceptNo,
    required this.rceptDate,
    this.filerName,
  });

  final String corpCode;
  final String corpName;
  final String? stockCode;
  final String? corpCls;
  final String reportName;
  final String rceptNo;

  /// 제출인 (회사가 아닐 수도 있다 — 주주의 대량보유 보고 등).
  final String? filerName;
  final DateTime? rceptDate;
}

class DartFilingPage {
  DartFilingPage({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.items,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final List<DartFilingItem> items;
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

  /// 인증키를 뺀 재무 API 주소 (Source 기록용).
  static Uri financialApiUrl(
    String corpCode,
    int bsnsYear,
    String reportCode,
    String fsDiv,
  ) => Uri.parse('$baseUrl/fnlttSinglAcntAll.json').replace(
    queryParameters: _financialParams(corpCode, bsnsYear, reportCode, fsDiv),
  );

  /// DART 공시 뷰어.
  static Uri filingViewerUrl(String rceptNo) =>
      Uri.parse('https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$rceptNo');

  /// 조회된 데이터가 없음.
  static const noDataStatus = '013';

  /// `list.json` 페이지당 최대 건수.
  static const filingPageSize = 100;

  static Map<String, String> _financialParams(
    String corpCode,
    int bsnsYear,
    String reportCode,
    String fsDiv,
  ) => {
    'corp_code': corpCode,
    'bsns_year': '$bsnsYear',
    'reprt_code': reportCode,
    'fs_div': fsDiv,
  };

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
      String? text(String name) =>
          DartValues.text(e.getElement(name)?.innerText);

      return DartCorpCode(
        corpCode: text('corp_code')!,
        corpName: text('corp_name') ?? '',
        stockCode: text('stock_code'),
        modifyDate: DartValues.ymd(text('modify_date')),
      );
    }).toList();
  }

  /// 기업개황 (`company.json`). 원문 필드를 그대로 돌려준다.
  Future<Map<String, dynamic>> fetchCompany(String corpCode) async =>
      (await _json('company.json', {'corp_code': corpCode}))!;

  /// 정기공시 목록 (`list.json`, 공시유형 A) 한 페이지.
  ///
  /// 회사를 지정하지 않으면 DART가 기간을 3개월 이내로 제한한다. [lastReportOnly]이면
  /// 정정 전 원본은 빠지고 최종 보고서만 온다. `pblntf_detail_ty`는 실제로 걸러지지
  /// 않으므로 보고서 종류는 이름([DartReportName])으로 가린다.
  Future<DartFilingPage> fetchFilings({
    required DateTime from,
    required DateTime to,
    int page = 1,
    String? corpCode,
    bool lastReportOnly = true,

    /// 공시 종류 (A 정기공시…). null이면 모든 종류.
    String? typeCode = 'A',
  }) async {
    final body = await _json('list.json', {
      'bgn_de': DartValues.formatYmd(from),
      'end_de': DartValues.formatYmd(to),
      'pblntf_ty': ?typeCode,
      'last_reprt_at': lastReportOnly ? 'Y' : 'N',
      'sort': 'date',
      'sort_mth': 'asc',
      'page_no': '$page',
      'page_count': '$filingPageSize',
      'corp_code': ?corpCode,
    }, allowNoData: true);
    if (body == null) {
      return DartFilingPage(
        page: page,
        totalPages: 0,
        totalCount: 0,
        items: const [],
      );
    }
    final list = (body['list'] as List?) ?? const [];
    return DartFilingPage(
      page: page,
      totalPages: (body['total_page'] as num?)?.toInt() ?? 0,
      totalCount: (body['total_count'] as num?)?.toInt() ?? 0,
      items: [
        for (final e in list.cast<Map<String, dynamic>>())
          if (DartValues.text(e['corp_code']) != null &&
              DartValues.text(e['rcept_no']) != null)
            DartFilingItem(
              corpCode: DartValues.text(e['corp_code'])!,
              corpName: DartValues.text(e['corp_name']) ?? '',
              stockCode: DartValues.text(e['stock_code']),
              corpCls: DartValues.text(e['corp_cls']),
              reportName: DartValues.text(e['report_nm']) ?? '',
              rceptNo: DartValues.text(e['rcept_no'])!,
              rceptDate: DartValues.ymd(e['rcept_dt']),
              filerName: DartValues.text(e['flr_nm']),
            ),
      ],
    );
  }

  /// 단일회사 전체 재무제표 (`fnlttSinglAcntAll.json`) 원문 행.
  ///
  /// [reportCode]는 11011(사업)/11012(반기)/11013(1분기)/11014(3분기),
  /// [fsDiv]는 CFS(연결)/OFS(별도). 해당 재무제표가 없으면(013) null.
  Future<List<Map<String, dynamic>>?> fetchFinancialStatements({
    required String corpCode,
    required int bsnsYear,
    required String reportCode,
    required String fsDiv,
  }) async {
    final body = await _json(
      'fnlttSinglAcntAll.json',
      _financialParams(corpCode, bsnsYear, reportCode, fsDiv),
      allowNoData: true,
    );
    if (body == null) return null;
    return ((body['list'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  /// 정기보고서 주요정보 (`hyslrSttus.json` 등, 경로는 `DartSections`) 원문 행.
  ///
  /// 자료가 없으면 013으로 오기도 하고, 값이 모두 `-`인 행을 주기도 한다. 013이면 null.
  Future<List<Map<String, dynamic>>?> fetchDisclosure({
    required String api,
    required String corpCode,
    required int bsnsYear,
    required String reportCode,
  }) async {
    final body = await _json('$api.json', {
      'corp_code': corpCode,
      'bsns_year': '$bsnsYear',
      'reprt_code': reportCode,
    }, allowNoData: true);
    if (body == null) return null;
    return ((body['list'] as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  /// 공시 원본 파일 (`document.xml`, zip). 파일이 없으면(014 — 첨부만 고친 정정공시 등) null.
  Future<List<int>?> fetchDocument(String rceptNo) async {
    final res = await _get('document.xml', {'rcept_no': rceptNo});
    final bytes = res.bodyBytes;
    if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) return bytes;
    try {
      _throwFromErrorBody(utf8.decode(bytes, allowMalformed: true));
    } on DartApiException catch (e) {
      if (e.status == fileNotFoundStatus || e.status == noDataStatus) {
        return null;
      }
      rethrow;
    }
  }

  /// 공시 원본 파일이 없음.
  static const fileNotFoundStatus = '014';

  /// JSON API 호출. status가 000이 아니면 예외, [allowNoData]이고 013이면 null.
  Future<Map<String, dynamic>?> _json(
    String path,
    Map<String, String> params, {
    bool allowNoData = false,
  }) async {
    final res = await _get(path, params);
    if (res.bodyBytes.isEmpty) {
      // DART가 짧은 시간에 호출이 몰리면 200과 빈 본문을 돌려줄 때가 있다.
      throw DartApiException('empty', '$path 빈 응답');
    }
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw DartApiException('parse', '$path 파싱 실패: $e');
    }
    final status = body['status'] as String?;
    if (allowNoData && status == noDataStatus) return null;
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
      // JSON이 아니면 XML 오류 응답.
    }
    try {
      final doc = XmlDocument.parse(body);
      final status = doc.findAllElements('status').firstOrNull?.innerText;
      final message = doc.findAllElements('message').firstOrNull?.innerText;
      throw DartApiException(status ?? 'unknown', message ?? body);
    } on XmlException {
      throw DartApiException('parse', '오류 응답을 해석할 수 없음');
    }
  }

  void close() => _http.close();
}
