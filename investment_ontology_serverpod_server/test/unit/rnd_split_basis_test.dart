import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/rnd_facts.dart';

void main() {
  test(
    'explicit consolidated and separate blocks keep consolidated values',
    () {
      final table = RndFacts.parse('''(단위 : 백만원)
과 목 | 연결 | 별도
제27기 | 제 26기 | 제27기 | 제 26기
연구개발비용 계 | 2,221,750 | 1,857,936 | 750,955 | 623,045
(정부보조금) | - | - | - | -
연구개발비/영업수익 비율 | 18.5% | 17.3% | 10.7% | 10.1%
''', bsnsYear: 2025);
      expect(table!.years, [2025, 2024]);
      expect(table.totals.single.values, [2221750, 1857936]);
      expect(table.ratio!.values, [18.5, 17.3]);
      expect(table.totals.single.evidence, contains('750,955'));
    },
  );
}
