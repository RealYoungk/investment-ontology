import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/supplier_rows.dart';
import 'package:test/test.dart';

/// 실제 사업보고서 표 모양으로 확인한다.
void main() {
  test('머리글의 매입처 칸에서 이름만 뽑는다', () {
    const text = '''
부 문 | 품 목 | 구체적 용도 | 매입액 | 비중 | 주요 매입처
DX | Camera Module | 스마트폰 카메라 | 59,043 | 7.9% | 삼성전기㈜, 엠씨넥스 등
DS | Wafer | 반도체 원판 | 21,625 | 12.4% | SILTRONIC, SK실트론㈜ 등
※ 주요 매입처 중 삼성전기㈜는 계열회사입니다.
''';
    final rows = SupplierRows.parse(text);
    expect(
      rows.map((r) => r.name),
      ['삼성전기㈜', '엠씨넥스', 'SILTRONIC', 'SK실트론㈜'],
    );
    expect(rows.first.evidence, contains('Camera Module'));
  });

  test('사업장 이름과 "등·外"는 떼어 내고, 숫자나 빈 칸은 버린다', () {
    const text = '''
부 문 | 품 목 | 구체적용도 | 매입액 | 비고(매입처)
건설 | 철근 | 골조공사 | 36,286 | 동국제강(주) 인천공장 外
건설 | 레미콘 | 골조공사 | 57,066 | (주)신일씨엠 外
건설 | 기타 | - | 1,000 | -
''';
    expect(
      SupplierRows.parse(text).map((r) => r.name),
      ['동국제강(주)', '(주)신일씨엠'],
    );
  });

  test('매입처 머리글이 없으면 아무것도 뽑지 않는다', () {
    const text = '''
부 문 | 품 목 | 매출액 | 비중 | 주요 매출처
DX | 스마트폰 | 100 | 50% | Alphabet, Apple
''';
    expect(SupplierRows.parse(text), isEmpty);
  });

  test('"주요 매출처는 A, B 등" 문장에서 이름을 뽑는다', () {
    const text = '''
주요 매출처는 Alphabet, Apple, Deutsche Telekom 등(알파벳순)이 있습니다.
주요 매출처는 자동차 OEM 업체로서 주요 5대 매출처에 대한 매출 비중은 약 63% 수준입니다.
''';
    expect(
      SupplierRows.customers(text).map((r) => r.name),
      ['Alphabet', 'Apple', 'Deutsche Telekom'],
    );
  });

  test('"매출처로는 … 등이 있으며"·"매출처는 A와 B입니다"도 읽고, 설명은 뗀다', () {
    const text = '''
주요 매출처로는 현대자동차, 현대모비스, Ford 등이 있으며 각각의 매출액에 대한 비중은 21.4%, 19.3%, 12.5% 입니다.
당사의 주요 매출처는 현대자동차(주)와 기아(주)입니다.
도료 부문의 주요 매출처는 자동차용 도료 거래선인 현대자동차, HD현대중공업 등이 있습니다.
주요 매출처는 삼성전자와 그 종속회사이며, 해당 거래처에 대한 매출 비중은 약 27% 입니다.
대한전선의 주요 매출처는 한국전력공사, (주)대원전선, (주)삼동 입니다.
2025년 당사의 주요 매출처로는 폭스바겐 그룹(폭스바겐, 아우디), 메르세데스 벤츠 등이 있습니다.
당사의 주요 매출처는 반도체 제조, 태양광용 잉곳, LED용 칩 등의 산업입니다.
각 부문의 주요 매출처는 내화물사업부문은 ㈜포스코 등 17.2%입니다.
''';
    expect(SupplierRows.customers(text).map((r) => r.name), [
      '현대자동차',
      '현대모비스',
      'Ford',
      '현대자동차(주)',
      '기아(주)',
      'HD현대중공업',
      '삼성전자',
      '한국전력공사',
      '(주)대원전선',
      '(주)삼동',
      '폭스바겐 그룹',
      '메르세데스 벤츠',
      '㈜포스코',
    ]);
  });

  test('매입처 칸의 ", Ltd." 쉼표는 이름을 나누지 않고, 겹쳐 붙은 이름은 한 번만', () {
    const text = '''
품목 | 매입처 | 매입액
원유 | SK Energy Americas, Inc. 등 | 1,000
나프타 | DAEHAN CERAMICS CO., LTD 외 | 100
P-X | SK지오센트릭SK지오센트릭 | 10
''';
    expect(SupplierRows.parse(text).map((r) => r.name), [
      'SK Energy Americas, Inc.',
      'DAEHAN CERAMICS CO., LTD',
      'SK지오센트릭',
    ]);
  });

  test('같은 이름은 한 번만', () {
    const text = '''
부 문 | 품 목 | 매입액 | 주요 매입처
A | 가 | 1 | 포스코 등
B | 나 | 2 | 포스코, 현대제철
''';
    expect(SupplierRows.parse(text).map((r) => r.name), ['포스코', '현대제철']);
  });

  test('둘째 머리글 줄과 익명 거래처(A사)·시장 구분은 이름이 아니다', () {
    const text = '''
사업부문 | 품목 | 매입액 | 비율 | 주요 매입처
| 매입액 | 비율 | 매입액 | 비율
전기사업 | 전기강판 | 241,156 | 30% | (주)포스코, A사, B사, 국내 등
''';
    expect(SupplierRows.parse(text).map((r) => r.name), ['(주)포스코']);
  });
}
