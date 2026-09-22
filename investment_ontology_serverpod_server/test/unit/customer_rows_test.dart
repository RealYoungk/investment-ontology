import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/supplier_rows.dart';
import 'package:test/test.dart';

/// 실제 사업보고서의 "주요 매출처" 표 모양으로 확인한다.
void main() {
  test('매출처 이름과 비중을 읽는다 (한국카본 모양)', () {
    const t = '''
(단위 : 백만원)
주요매출처 | 제27기 매출액 | 점유율 | 비 고
한화오션㈜ | 505,182 | 36.8 | -
삼성중공업㈜거제조선소 | 476,272 | 34.7
Zhoushan Changhong | 93,297 | 6.8
합 계 | 1,074,751 | 78.3
''';
    final rows = SupplierRows.customerRows(t);
    expect(rows.map((r) => r.name), [
      '한화오션㈜',
      '삼성중공업㈜',
      'Zhoushan Changhong',
    ]);
    expect(rows.first.share, 36.8);
    expect(rows[1].share, 34.7);
  });

  test('당기·전기가 나란히 있으면 당기 비중만, 둘째 머리글 줄은 건너뛴다', () {
    const t = '''
매출처 | 구분 | 매출액
2025년(제27기) | 2024년(제26기) | 2023년(제25기)
금액 | 비중 | 금액 | 비중 | 금액 | 비중
방위사업청 등 | 내수 | 1,755,325 | 48.41% | 2,136,281 | 59.37% | 1,965,348 | 51.74%
''';
    final rows = SupplierRows.customerRows(t);
    expect(rows, hasLength(1));
    expect(rows.single.name, '방위사업청');
    // 비중 칸을 머리글에서 집지 못한 표(머리글이 두 줄)에서는 비중을 붙이지 않는다.
    expect(rows.single.share, isNull);
  });

  test('구분(유통·직영)이나 A사 같은 익명은 매출처가 아니고, 매입처 표는 받지 않는다', () {
    const t = '''
매출처 | 구분 | 사업 부문 | 매출 품목 | 매출액 비중
유통 | 내수 | 가전 | 전기밥솥 등 | 67.4 | 68.7 | 68.9
직영 | 내수 | 가전 | 전기밥솥 등 | 6.0 | 6.1 | 5.6
매출처 | 매출액 | 매출액 대비 비율
A사 | 180,829 | 9.12%
품목 | 매입처 | 매입액
동박 | 일진머트리얼즈 | 1,000
''';
    expect(SupplierRows.customerRows(t), isEmpty);
  });

  test('한 칸에 여럿이면 이름은 나누되 비중은 붙이지 않는다', () {
    const t = '''
구분 | 2025년 | 2024년
매출액 | 비중 | 매출액 | 비중
삼성전자, SK하이닉스 외 | 214,655 | 35.5% | 201,213 | 39.7%
''';
    // 머리글에 매출처 낱말이 없어 표로 보지 않는다.
    expect(SupplierRows.customerRows(t), isEmpty);

    const t2 = '''
주요 매출처 | 매출액 | 비중
삼성전자, SK하이닉스 외 | 214,655 | 35.5%
Intel, TSMC, Micron 외 | 370,839 | 61.4%
''';
    final rows = SupplierRows.customerRows(t2);
    expect(rows.map((r) => r.name), [
      '삼성전자',
      'SK하이닉스',
      'Intel',
      'TSMC',
      'Micron',
    ]);
    expect(rows.every((r) => r.share == null), isTrue);
  });

  test('법인 접미사 앞의 쉼표는 이름을 나누지 않고, 비중도 붙는다', () {
    const t = '''
주요 매출처 | 매출액 | 비중
SK Energy International Pte., Ltd. | 1,000 | 20.1%
MITSUI AND CO., LTD, | 100 | 2.0%
iHerb, Inc | 68,442 | 6.13%
Airbus 계열 | 507,416 | 14.00%
''';
    final rows = SupplierRows.customerRows(t);
    expect(rows.map((r) => r.name), [
      'SK Energy International Pte., Ltd.',
      'MITSUI AND CO., LTD',
      'iHerb, Inc',
      'Airbus',
    ]);
    expect(rows.map((r) => r.share), [20.1, 2.0, 6.13, 14.0]);
  });

  test('총계·기타거래처·제조회사·매출비중 같은 이름 아닌 칸은 버린다', () {
    const t = '''
주요 매출처 | 매출액 | 비중
방위사업청 | 109,015,041 | 13.81%
기타거래처 | 13,464 | 31.3%
제조회사 | 100 | 50
조선 산업 | 100 | 31.3
대리점 및 특약점 | 100 | 85.7
폴란드 등완제기 수출국 | 925,405 | 25.53%
조합관리보수 | 611 | 0.2
삼성중공업㈜거제조선소 | 476,272 | 34.7
총 계 | 789,341,915 | 100.00%
매출처 | 글로벌 A사 | 글로벌 B사 | 동아에스티
매출비중 | 24.27% | 17.34% | 6.36%
''';
    final rows = SupplierRows.customerRows(t);
    expect(rows.map((r) => r.name), ['방위사업청', '삼성중공업㈜']);
  });

  test('판매경로·결제조건 표나 숫자 없는 줄은 매출처가 아니다', () {
    const t = '''
품 목 | 판 매 경 로 | 거래처 | 결제조건
콘덴서 | 직접판매 | 윤테크놀로지 | 30일 현금
주요 매출처 | 매출액 | 비중
STX엔진(주) | 25,818 | 3.27%
비고 | 없음
레저/서비스업 | 한화호텔앤드리조트㈜ | 콘도/골프/호텔 | 내수
''';
    final rows = SupplierRows.customerRows(t);
    expect(rows.map((r) => r.name), ['STX엔진(주)']);
    expect(rows.single.share, 3.27);
  });
}
