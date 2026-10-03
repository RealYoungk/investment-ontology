/// 제목에서 찾은 확인 지점이며 실제 변경 내용·결의 여부를 판정하지 않는다.
({String label, String check})? shareholderEvent(String title) {
  final name = title.replaceAll(RegExp(r'\s+'), '');
  if (name.contains('정관') || name.contains('주주총회') || name.contains('의결권')) {
    return (
      label: name.contains('결과') ? '결의 내용 확인' : '안건·권리 확인',
      check: '정관 신구조문·변경 사유, 의결권 행사 방식, 이사·감사 선임과 책임 조항을 확인하세요. 소집 공고만으로 정관 변경이나 안건 승인을 확정할 수 없습니다.',
    );
  }
  if (['유상증자', '전환사채', '신주인수권'].any(name.contains)) {
    return (
      label: '지분 희석 확인',
      check:
          '발행 규모·가격, 배정 대상, 전환·행사 조건과 자금 사용 목적을 확인하세요. 발행 결정과 실제 발행은 구분해야 합니다.',
    );
  }
  if (['자기주식처분', '자기주식취득', '주식소각'].any(name.contains)) {
    return (
      label: '자기주식 활용 확인',
      check: '취득·처분·소각을 구분하고 수량·상대방·목적을 확인하세요. 취득이 소각을 의미하지는 않습니다.',
    );
  }
  if (['감자', '합병', '분할', '주식교환', '주식이전'].any(name.contains)) {
    return (
      label: '권리·구조 변화 확인',
      check: '교환·합병 비율, 존속 회사, 주식 수 변화와 반대 주주의 권리·신청 기간을 원문에서 확인하세요.',
    );
  }
  return null;
}
