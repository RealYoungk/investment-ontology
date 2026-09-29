import 'package:investment_ontology_serverpod_server/src/ontology/peers/peer_rules.dart';
import 'package:test/test.dart';

void main() {
  const header = '## 2. 주요 제품 및 서비스\n';
  test('source evidence is exact and equipment target plus method match', () {
    const text =
        '$header당사는 반도체 기판의 결함을 검사하는 AOI 장비를 판매합니다.\n자동광학수리기 AOR도 판매합니다.';
    final a = PeerRules.parse(text);
    expect(
      a.map((s) => s.key),
      containsAll(['substrate', 'optical', 'repair']),
    );
    for (final signal in a) {
      expect(text.contains(signal.evidence), isTrue);
    }
    final b = PeerRules.parse('${header}FC-BGA 검사장비 | AOI 및 외관검사장비');
    final match = PeerRules.match(a, b)!;
    expect(match.tier, 'product');
    expect(match.differences, contains('기준 기업 공시: 자동광학수리'));
  });
  test('industry prose, R&D and competitors never establish a product', () {
    for (final text in [
      '## 1. 사업의 개요\n반도체 기판 AOI 검사 시장이 성장합니다.',
      '$header경쟁사는 반도체 기판 AOI 검사장비를 판매합니다.',
      '$header## 6. 연구개발\n반도체 기판 AOI 검사장비 개발',
      '$header반도체 기판 AOI 검사장비 개발 예정',
      '$header반도체 기판 자동외관검사기를 보유하고 있습니다.',
    ]) {
      expect(PeerRules.parse(text), isEmpty, reason: text);
    }
  });
  test('SMT optical and wafer electrical equipment are not substrate optical peers', () {
    final anchor = PeerRules.parse('$header반도체 기판 AOI 검사장비');
    expect(
      PeerRules.match(anchor, PeerRules.parse('${header}SMT 3D AOI 검사장비')),
      isNull,
    );
    expect(
      PeerRules.match(anchor, PeerRules.parse('$header웨이퍼 전기적 검사장비')),
      isNull,
    );
    expect(
      PeerRules.match(anchor, PeerRules.parse('$header웨이퍼 AOI 검사장비')),
      isNull,
    );
  });
  test(
    'incidental target in another sentence cannot become inspection product',
    () {
      final parsed = PeerRules.parse(
        '$header당사 고객은 반도체 기판을 생산합니다. SMT AOI 검사장비를 판매합니다.',
      );
      expect(parsed.map((s) => s.key), isNot(contains('substrate')));
    },
  );
  test('no headings, unknown products and repair only are unsupported', () {
    expect(PeerRules.parse('반도체 기판 AOI 검사장비'), isEmpty);
    expect(PeerRules.parse('$header자동광학수리기 AOR'), isEmpty);
    expect(PeerRules.parse('$header일반 제조 설비'), isEmpty);
  });
}
