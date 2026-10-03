import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../design/components/components.dart';

/// Only known ingest Source.title contracts identify the collection scope.
/// Neither fact count nor an unknown title implies whole-statement coverage.
class FinancialSourceScopeNotice extends StatelessWidget {
  const FinancialSourceScopeNotice({super.key, required this.sourceTitle});
  final String? sourceTitle;

  static String? messageFor(String? title) {
    if (title == null) return null;
    final separator = title.indexOf(' · {');
    final structured = separator >= 0 ? title.substring(separator + 3) : title;
    try {
      final decoded = jsonDecode(structured);
      if (decoded is Map &&
          decoded['action'] ==
              'verified-keyless-annual-source-after-api-noData' &&
          decoded['corpCode'] == '01205514' &&
          decoded['targetReceipt'] == '20250305000164' &&
          decoded['fsDiv'] == 'separate' &&
          decoded['coreRows'] == 7) {
        final provenance = decoded['coreRowProvenance'];
        final seven =
            provenance is List &&
            provenance.any(
              (row) =>
                  row is Map &&
                  row['html_provenance'] is Map &&
                  (row['html_provenance'] as Map)['partialCore7'] == true,
            );
        if (seven) {
          return '공식 원문에서 핵심 7개 계정을 검증해 수집했습니다. 세부 계정 전체와 주석은 검증을 마치지 않았습니다. 유형자산 취득 총액은 미확보입니다. 연구장비 취득 일부를 전체 설비투자로 대신하지 않으며, FCF와 FCF 수익률은 계산하지 않습니다.';
        }
      }
    } on FormatException {
      // Plain source titles remain supported without inferring coverage.
    }
    if (const [
      'DART 원문 HTML 부분 핵심계정',
      'DART 원문 XBRL 핵심계정',
      'DART 원문 XBRL 반기 부분 핵심7계정',
      'DART 원문 XBRL 당기 핵심계정 복구',
      'DART 원문 HTML 부분 핵심6계정',
    ].any(title.startsWith)) {
      return '공식 원문의 검증된 핵심계정 일부를 수집한 보고서입니다. 전체 재무제표·주석의 원문 행을 저장한 자료가 아닙니다. 수집 범위와 미확보 항목은 아래 출처에서 확인하세요.';
    }
    if (title.startsWith('DART 전체 재무제표 (fnlttSinglAcntAll)')) {
      return '재무 API 응답의 계정과 금액을 수집한 보고서입니다. 공시 원문의 모든 표·주석 행을 저장했다는 뜻은 아닙니다.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final message = messageFor(sourceTitle);
    return message == null
        ? const SizedBox.shrink()
        : AppNotice(message: message);
  }
}
