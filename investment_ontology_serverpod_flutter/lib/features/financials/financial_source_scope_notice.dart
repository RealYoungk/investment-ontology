import 'package:flutter/widgets.dart';

import '../../design/components/components.dart';

/// Only known ingest Source.title contracts identify the collection scope.
/// Neither fact count nor an unknown title implies whole-statement coverage.
class FinancialSourceScopeNotice extends StatelessWidget {
  const FinancialSourceScopeNotice({super.key, required this.sourceTitle});
  final String? sourceTitle;

  static String? messageFor(String? title) {
    if (title == null) return null;
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
