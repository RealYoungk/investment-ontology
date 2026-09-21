import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_sections.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/disclosure_rows.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/disclosure_values.dart';
import 'package:test/test.dart';

void main() {
  group('DisclosureValues', () {
    test('기업 이름은 법인 형태·각주·꼬리표·공백을 떼고 비교한다', () {
      for (final (raw, want) in [
        ('삼성생명보험㈜', '삼성생명보험'),
        ('삼성생명보험㈜\n(특별계정)', '삼성생명보험'),
        ('주식회사 에코프로이엠', '에코프로이엠'),
        ('(주)카카오', '카카오'),
        ('카카오 성장나눔게임펀드 (주1)', '카카오성장나눔게임펀드'),
        ('Kakao piccoma Corp.', 'kakaopiccomacorp.'),
        ('SK(주)', 'sk'),
      ]) {
        expect(DisclosureValues.companyName(raw), want, reason: raw);
      }
    });

    test('사람 이름은 공백을 뗀다', () {
      expect(DisclosureValues.personName('이 재 용'), '이재용');
      expect(DisclosureValues.displayName('삼성생명보험㈜\n(특별계정)'), '삼성생명보험㈜ (특별계정)');
    });

    test('숫자 표기를 스키마 타입으로', () {
      expect(DisclosureValues.integer('508,157,148'), BigInt.from(508157148));
      expect(DisclosureValues.integer('-2,308,000'), BigInt.from(-2308000));
      expect(DisclosureValues.integer('-'), isNull);
      expect(DisclosureValues.integer('주3)'), isNull);
      expect(DisclosureValues.decimal('8.51'), 8.51);
      expect(DisclosureValues.decimal('20.07%'), 20.07);
      expect(DisclosureValues.decimal('      17.4'), 17.4);
      expect(DisclosureValues.decimal('-'), isNull);
    });

    test('날짜·출생년월·재직기간', () {
      expect(DisclosureValues.date('2025.03.31'), DateTime.utc(2025, 3, 31));
      expect(DisclosureValues.date('2028년 03월 18일'), DateTime.utc(2028, 3, 18));
      expect(DisclosureValues.date('2025-12-31'), DateTime.utc(2025, 12, 31));
      expect(DisclosureValues.date('2025.02.30'), isNull);
      expect(DisclosureValues.yearMonth('1960년 12월'), (year: 1960, month: 12));
      expect(DisclosureValues.yearMonth('1960년'), isNull);
      // 공시 오타: 앞으로 올 해는 태어난 해일 수 없다.
      expect(DisclosureValues.yearMonth('2068년 01월', thisYear: 2026), isNull);
      expect(
        DisclosureValues.yearMonth('2026년 07월', thisYear: 2026),
        (year: 2026, month: 7),
      );
      expect(DisclosureValues.yearMonth('2027년 07월', thisYear: 2026), isNull);
      expect(DisclosureValues.months('46개월'), 46);
      expect(DisclosureValues.months('10'), 10);
      expect(DisclosureValues.months('1년'), isNull);
      expect(DisclosureValues.fullTime('비상근'), isFalse);
    });

    test('배당 항목 이름 끝의 단위', () {
      expect(DisclosureValues.unitOf('(연결)당기순이익(백만원)'), '백만원');
      expect(DisclosureValues.unitOf('주당액면가액(원)'), '원');
      expect(DisclosureValues.unitOf('(연결)현금배당성향(%)'), '%');
      expect(DisclosureValues.unitOf('현금배당수익률'), isNull);
    });
  });

  group('DisclosureRows', () {
    Map<String, dynamic> hyslr(String nm, String rt, {String relate = '-'}) => {
      'rcept_no': '20260310002820',
      'corp_code': '00126380',
      'nm': nm,
      'relate': relate,
      'stock_knd': '보통주',
      'trmend_posesn_stock_qota_rt': rt,
      'stlm_dt': '2025-12-31',
    };

    test('값이 모두 -인 빈 줄은 빼고, 합계 행을 표시한다', () {
      final p = DisclosureRows.prepare([
        hyslr('삼성생명보험㈜', '8.51', relate: '최대주주 본인'),
        {'rcept_no': '1', 'corp_code': '2', 'nm': '-', 'relate': '-'},
        hyslr('계', '19.84'),
      ]);
      expect(p.empty, 1);
      expect(
        [for (final r in p.rows) (r.ord, r.isTotal)],
        [(0, false), (2, true)],
      );
    });

    test('주주 이름이 상장사 한 곳과 같으면 연결하고, 자기 자신과 합계는 잇지 않는다', () {
      final p = DisclosureRows.prepare([
        hyslr('삼성생명보험㈜', '8.51', relate: '최대주주 본인'),
        hyslr('삼성전자㈜', '0.0'),
        hyslr('이재용', '1.65', relate: '최대주주의 특수관계인'),
        hyslr('계', '19.84'),
      ]);
      final rows = DisclosureRows.shareholders(
        p.rows,
        reportId: 1,
        companyId: 10,
        bsnsYear: 2025,
        companiesByName: {'삼성생명보험': 20, '삼성전자': 10},
      );
      expect([for (final r in rows) r.holderCompanyId], [20, null, null, null]);
      expect(rows.first.holderLinkBasis, DisclosureLinkBasis.companyName);
      expect(rows.first.ratioEnd, 8.51);
      expect(rows.last.isTotal, isTrue);
    });

    test('임원 등기 구분', () {
      expect(DisclosureRows.registration('사내이사'), ExecutiveRegistration.inside);
      expect(
        DisclosureRows.registration('사외 이사'),
        ExecutiveRegistration.outside,
      );
      expect(
        DisclosureRows.registration('기타비상무이사'),
        ExecutiveRegistration.nonExecutive,
      );
      expect(
        DisclosureRows.registration('미등기'),
        ExecutiveRegistration.unregistered,
      );
      expect(DisclosureRows.registration('감사'), ExecutiveRegistration.other);
    });
  });

  test('주요정보 28종의 API 주소는 서로 다르고 모든 항목에 정보가 있다', () {
    expect(DartSections.info.keys.toSet(), DartSection.values.toSet());
    expect({for (final i in DartSections.info.values) i.api}.length, 29);
    expect(
      [
        for (final e in DartSections.info.entries)
          if (e.value.tier == 0) e.key,
      ],
      hasLength(9),
    );
  });
}
