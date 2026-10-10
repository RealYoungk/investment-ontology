import 'package:investment_ontology_serverpod_server/src/ontology/news/company_news_matcher.dart';
import 'package:test/test.dart';

void main() {
  bool acryl(String title) => NewsCompanyMatcher.matches(
    name: '아크릴',
    title: title,
    excerpt: '',
    ceoName: '박외진',
  );
  test(
    'group names survive while celebrity homonyms and subsidiaries do not',
    () {
      bool matches(String title) => NewsCompanyMatcher.matches(
        name: '미코',
        title: title,
        excerpt: '',
        stockCode: '059090',
        ceoName: '전선규',
      );
      expect(matches("전선규 미코그룹 회장, 세라믹 기술 발전 메달 수상"), isTrue);
      expect(matches("미코 엄마 김지연, 딸과 데이트"), isFalse);
      expect(matches("미코파워 생산설비 증설"), isFalse);
      expect(matches("미코 주가 상승"), isTrue);
    },
  );
  test('excludes materials and name substrings', () {
    expect(acryl('아크릴 소재 수요 증가, 플라스틱 기업 매출 확대'), isFalse);
    expect(acryl('아크릴 물감으로 그린 인공지능 시대'), isFalse);
    expect(acryl('AI 기업이 아크릴 소재로 로봇을 개발'), isFalse);
    expect(acryl('대상 기업은 아크릴 소재를 판매한다'), isFalse);
    expect(acryl('한아크릴 주가 상승'), isFalse);
  });
  test('accepts issuer identity', () {
    expect(acryl('인공지능 기업 아크릴, 조나단 플랫폼 공개'), isTrue);
    expect(acryl('아크릴 박외진 대표 인터뷰'), isTrue);
    expect(acryl('아크릴 주가 상승'), isTrue);
  });
  test('handles Korean particles and subsidiaries', () {
    expect(
      NewsCompanyMatcher.matches(
        name: '삼성전자',
        title: '삼성전자는 반도체 투자를 확대한다',
        excerpt: '',
      ),
      isTrue,
    );
    expect(
      NewsCompanyMatcher.matches(
        name: '삼성전자',
        title: '삼성전자서비스 채용',
        excerpt: '',
      ),
      isFalse,
    );
  });
}
