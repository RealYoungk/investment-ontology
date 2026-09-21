import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/governance/governance_view.dart';
import 'package:investment_ontology_serverpod_flutter/features/shareholder_return/shareholder_return_tab.dart';

DividendEntry dividend(
  int year,
  String item,
  double? current,
  double? prior,
  double? beforePrior, {
  String? kind,
  int ord = 0,
}) => DividendEntry(
  reportId: year,
  companyId: 1,
  bsnsYear: year,
  ord: ord,
  item: item,
  unit: '원',
  stockKind: kind,
  current: current,
  prior: prior,
  beforePrior: beforePrior,
);

ShareholderEntry holder(
  String name,
  double ratio, {
  String kind = '보통주',
  int? companyId,
  int? personId,
  DisclosureLinkBasis? basis,
  bool total = false,
}) => ShareholderEntry(
  reportId: 1,
  companyId: 10,
  bsnsYear: 2025,
  ord: 0,
  holderName: name,
  stockKind: kind,
  ratioEnd: ratio,
  isTotal: total,
  holderCompanyId: companyId,
  holderPersonId: personId,
  holderLinkBasis: basis,
);

void main() {
  test('배당: 그 해 보고서의 당기 값을 먼저, 없으면 뒤 보고서의 전기·전전기 값', () {
    final series = dividendSeries([
      dividend(2025, '주당 현금배당금(원)', 1668, 1446, 1444, kind: '보통주'),
      // FY2024 보고서의 당기 값(1,450)이 FY2025 보고서의 전기 값(1,446)보다 우선한다.
      dividend(2024, '주당 현금배당금(원)', 1450, 1444, 2994, kind: '보통주'),
    ]);
    expect(series, hasLength(1));
    expect(series.single.values, {
      2025: 1668,
      2024: 1450,
      2023: 1444,
      2022: 2994,
    });
    expect(series.single.label, '주당 현금배당금(원) · 보통주');
  });

  test('배당 값 표시', () {
    expect(formatDividendValue(1668, '원'), '1,668원');
    expect(formatDividendValue(25.1, '%'), '25.10%');
    expect(formatDividendValue(null, '%'), '—');
  });

  test('지배구조: 주주를 사람·기업 단위로 묶고 보통주 지분율만 더한다', () {
    final view = GovernanceView(
      CompanyGovernance(
        corpCode: '00126380',
        bsnsYear: 2025,
        availableYears: [2025],
        shareholders: [
          holder('삼성생명보험㈜', 8.51, companyId: 20),
          holder(
            '이재용',
            1.65,
            personId: 7,
            basis: DisclosureLinkBasis.ownershipCluster,
          ),
          holder('이재용', 0.02, kind: '우선주', personId: 7),
          holder('삼성생명보험㈜ (특별계정)', 0.07, companyId: 20),
          holder('계', 10.25, total: true),
        ],
        executives: [],
        investments: [
          InvestmentEntry(
            reportId: 2,
            companyId: 10,
            bsnsYear: 2025,
            ord: 0,
            investeeName: 'SDMA',
            purpose: '경영참여',
            ratioEnd: 75,
            isTotal: false,
          ),
          InvestmentEntry(
            reportId: 2,
            companyId: 10,
            bsnsYear: 2025,
            ord: 1,
            investeeName: '삼성전기㈜',
            purpose: '경영참여',
            ratioEnd: 23.7,
            isTotal: false,
            investeeCompanyId: 30,
          ),
        ],
        investors: [],
        holdings: [],
        companies: [
          CompanyRef(id: 20, corpCode: '00126256', name: '삼성생명보험(주)'),
          CompanyRef(id: 30, corpCode: '00126371', name: '삼성전기(주)'),
        ],
        persons: [],
        sources: [],
      ),
    );
    final holders = view.holders();
    expect(
      [for (final h in holders) (h.name, h.weight)],
      [
        ('삼성생명보험㈜', 8.58),
        ('이재용', 1.65),
      ],
    );
    expect(holders.first.corpCode, '00126256');
    expect(holders.last.estimated, isTrue);
    expect(view.holderTotal(), 10.25);
    // 상장사는 지분율이 낮아도 먼저.
    expect([for (final i in view.investments()) i.name], ['삼성전기㈜', 'SDMA']);
  });
}
