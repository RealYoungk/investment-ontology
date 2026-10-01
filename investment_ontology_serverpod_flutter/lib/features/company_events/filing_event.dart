import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

/// A navigation aid based only on the filing title, never a finding about outcome.
enum FilingTopic {
  financing('자금조달', '조달 목적과 발행 조건, 주식 수 변화를 확인하세요.'),
  returns('주주환원', '배당·자사주 계획과 실제 이행 내역을 구분해 보세요.'),
  ownership('지분 변동', '보유 변동의 주체와 사유를 확인하세요. 증가가 곧 매수는 아닙니다.'),
  business('사업 변화', '계약·인수·분할의 조건과 사업 범위 변화를 확인하세요.'),
  results('실적', '보고 기간과 연결·별도 기준, 이전 실적을 함께 보세요.'),
  risk('위험 공시', '발생 사유와 현재 진행 상태를 원문에서 확인하세요.'),
  other('기타', '공시 원문에서 내용과 적용 시점을 확인하세요.');

  const FilingTopic(this.label, this.guide);
  final String label;
  final String guide;
}

class FilingEvent {
  const FilingEvent(this.filing);
  final DartDisclosure filing;

  String get _title => filing.reportName.replaceAll(RegExp(r'\s+'), '');
  bool get corrected => RegExp(r'\[[^\]]*정정[^\]]*\]').hasMatch(_title);
  bool get withdrawn => _title.contains('철회');
  bool get planned => _title.contains('결정');
  String get stage => withdrawn
      ? '철회 공시'
      : corrected
      ? '정정 공시'
      : planned
      ? '결정 공시'
      : '공시';

  FilingTopic get topic {
    final title = _title;
    bool has(List<String> words) => words.any(title.contains);
    if (has(['부도발생', '회생절차', '파산', '영업정지', '소송등의제기', '해산사유'])) {
      return FilingTopic.risk;
    }
    if (has(['자기주식', '자사주', '배당', '주식소각'])) return FilingTopic.returns;
    if (has(['대량보유', '소유상황보고', '최대주주변경', '소유주식변동', '주식등의대량'])) {
      return FilingTopic.ownership;
    }
    if (has(['증자', '감자', '전환사채', '신주인수권부사채', '교환사채', '증권신고서', '조건부자본증권'])) {
      return FilingTopic.financing;
    }
    if (has(['합병', '분할', '양수', '양도', '공급계약', '영업실적전망', '신규시설투자'])) {
      return FilingTopic.business;
    }
    if (has(['사업보고서', '반기보고서', '분기보고서', '잠정실적', '영업실적', '손익구조'])) {
      return FilingTopic.results;
    }
    return FilingTopic.other;
  }

  Uri? get source {
    if (!RegExp(r'^\d{14}$').hasMatch(filing.rceptNo)) return null;
    return Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
      'rcpNo': filing.rceptNo,
    });
  }
}

List<FilingEvent> filingEvents(List<DartDisclosure> rows) {
  final seen = <String>{};
  final sorted = [...rows]
    ..sort((a, b) {
      final date = b.receivedDate.compareTo(a.receivedDate);
      return date != 0 ? date : b.rceptNo.compareTo(a.rceptNo);
    });
  return [
    for (final row in sorted)
      if (seen.add(row.rceptNo)) FilingEvent(row),
  ];
}
