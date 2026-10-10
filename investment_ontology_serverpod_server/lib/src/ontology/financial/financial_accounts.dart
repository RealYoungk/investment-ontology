import 'hanwha_own_net_income_scope.dart';
import 'suntech_own_cf_scope.dart';
import 'solumix_own_revenue_scope.dart';
import '../../generated/protocol.dart';
import 'financial_comparatives.dart';

/// 화면에 쓰는 핵심 계정.
///
/// XBRL ID를 우선한다. ID가 없는 행은 정해진 총계 명칭과 재무제표가
/// 정확히 일치하고 후보가 하나뿐일 때만 보완한다. 원본 계정 ID는 보존한다.
class FinancialAccount {
  const FinancialAccount(
    this.key,
    this.label,
    this.accountIds,
    this.statements,
  );

  final String key;
  final String label;

  /// 우선순위 순서의 XBRL ID.
  final List<String> accountIds;

  /// 찾을 재무제표. 앞의 것을 우선한다 (손익은 손익계산서 → 포괄손익계산서).
  final List<FinancialStatementKind> statements;
}

abstract final class FinancialAccounts {
  static const _pl = [
    FinancialStatementKind.incomeStatement,
    FinancialStatementKind.comprehensiveIncome,
  ];
  static const _bs = [FinancialStatementKind.balanceSheet];
  static const _cf = [FinancialStatementKind.cashFlow];

  static const all = [
    FinancialAccount('revenue', '매출액', [
      'ifrs-full_Revenue',
      'ifrs-full_RevenueFromContractsWithCustomers',
    ], _pl),
    FinancialAccount('operatingIncome', '영업이익', [
      'dart_OperatingIncomeLoss',
      'ifrs-full_ProfitLossFromOperatingActivities',
    ], _pl),
    FinancialAccount('netIncome', '당기순이익', ['ifrs-full_ProfitLoss'], _pl),
    FinancialAccount('netIncomeOwners', '지배주주 당기순이익', [
      'ifrs-full_ProfitLossAttributableToOwnersOfParent',
    ], _pl),
    FinancialAccount('interestDebtIncludingLeases', '이자부채(리스 포함)', [], _bs),
    FinancialAccount('cash', '현금및현금성자산', [
      'ifrs-full_CashAndCashEquivalents',
    ], _bs),
    FinancialAccount('noncontrollingInterest', '비지배지분', [
      'ifrs-full_NoncontrollingInterests',
    ], _bs),
    FinancialAccount('depreciationAmortisation', '감가상각비 및 무형자산상각비', [
      'ifrs-full_AdjustmentsForDepreciationAndAmortisationExpense',
    ], _cf),
    FinancialAccount('depreciation', '감가상각비', [
      'ifrs-full_AdjustmentsForDepreciationExpense',
    ], _cf),
    FinancialAccount('amortisation', '무형자산상각비', [
      'ifrs-full_AdjustmentsForAmortisationExpense',
    ], _cf),
    FinancialAccount('shortTermDeposits', '단기금융상품', [
      'ifrs-full_ShorttermDepositsNotClassifiedAsCashEquivalents',
    ], _bs),
    FinancialAccount('assets', '자산총계', ['ifrs-full_Assets'], _bs),
    FinancialAccount('liabilities', '부채총계', ['ifrs-full_Liabilities'], _bs),
    FinancialAccount('equity', '자본총계', ['ifrs-full_Equity'], _bs),
    FinancialAccount('equityOwners', '지배주주 자본', [
      'ifrs-full_EquityAttributableToOwnersOfParent',
    ], _bs),
    FinancialAccount('operatingCashFlow', '영업활동 현금흐름', [
      'ifrs-full_CashFlowsFromUsedInOperatingActivities',
    ], _cf),
    FinancialAccount('capex', '유형자산의 취득', [
      'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities',
    ], _cf),
  ];

  static final Set<String> accountIds = {
    for (final a in all) ...a.accountIds,
    FinancialComparatives.minority,
  };

  // Deliberately excludes EPS, comprehensive income, continuing operations,
  // owner/segment subtotals. Exact whole-loss labels require non-positive amounts.
  static const fallbackNames = <String, List<String>>{
    'interestDebtIncludingLeases': ['총차입금(리스부채포함)', '차입금및사채및리스부채합계'],
    'revenue': [
      '매출',
      '매출액',
      '매출액(주5)',
      '영업수익',
      '영업수익:',
      '수익(매출액)',
      '수익(매출액)(주30)',
    ],
    'assets': ['자산총계', '[자산총계]'],
    'liabilities': ['부채총계', '[부채총계]'],
    'cash': ['현금및현금성자산'],
    'equity': ['자본총계'],
    'operatingCashFlow': [
      '영업활동현금흐름',
      '영업활동순현금흐름',
      '영업활동으로인한순현금흐름',
      '영업활동으로인한순현금흐름액',
      '영업활동으로부터의순현금유출',
      '영업활동으로인한현금흐름',
      '영업활동으로부터의현금흐름',
      '영업활동으로인한현금흐름(1+2+3)',
      '영업활동으로인한현금흐름(순액)',
    ],
    'depreciation': ['감가상각비'],
    'amortisation': ['무형자산상각비'],
    'netIncome': [
      // Exact LS/Ebest FY21/22 and Kiwoom FY21 whole NI, equal to own CE.
      '당기순이익(대손준비금반영후조정이익당기:903,901,167천원,전기:680,651,395천원)',
      '당기순이익(대손준비금반영후조정이익:당기35,862,295천원전기153,367,335천원)',
      '당기순이익(대손준비금반영후조정이익:당기35,776,373천원전기153,214,707천원)',
      '당기순이익(대손준비금반영후조정이익:당기153,367,335천원전기121,709,052천원)',
      '당기순이익(대손준비금반영후조정이익:당기153,214,707천원전기121,089,623천원)',

      // Pinned Daishin FY2021 own whole NI; independently equal to CE and CF.
      '당기연결순손익',
      '당기순이익(대손준비금반영후조정이익당기:178,664백만원전기:175,386백만원)',
      // Exact Heungkuk FY2021/22 current whole NI, equal to own CE total.
      '당기순이익(대손준비금반영후조정이익당기:138,148백만원전기:54,202백만원)(비상위험준비금반영후조정이익당기:134,462백만원전기:51,465백만원)',
      '당기순이익(대손준비금반영후조정이익당기:54,202백만원전기:13,888백만원)(비상위험준비금반영후조정이익당기:51,465백만원전기:12,242백만원)',
      // Exact NH FY2021 OFS whole NI, independently equal to CE total.
      '당기순이익(대손준비금반영후조정이익:당기:782,640백만원,전기:484,955백만원,전전기:418,256백만원)',
      '당기순이익(대손준비금반영후조정이익당기:87,133백만원전기:178,664백만원)',
      // Exact insurance whole NI cells, independently equal to pinned CE totals.
      "당기순이익(손실)(비상위험준비금반영후조정이익(손실)당기:114,199,225,967원전기:(-)24,215,079,079원대손준비금반영후조정이익(손실)당기:120,125,439,090원전기:(-)28,815,936,079원)",
      "당기순이익(대손준비금반영후조정이익당기:75,781,712,981원,전기:77,699,663,310원)",
      "당기순이익(대손준비금반영후조정이익당기:92,823,564,486원,전기:90,024,490,823원)",
      "당기순이익(주석23)(비상위험준비금반영후조정이익당기:465,707,342,599원전기:330,317,307,787원대손준비금반영후조정이익당기:562,246,349,804원전기:405,964,567,689원)",
      "당기순이익(주석23)(비상위험준비금반영후조정이익당기:452,051,776,492원전기:336,102,116,734원대손준비금반영후조정이익당기:548,543,201,146원전기:411,689,146,425원",
      "당기순이익(대손준비금반영후조정이익당기:58,458,197,450원,전기:75,781,712,981원)",
      "당기순이익(대손준비금반영후조정이익당기:57,113,704,745원,전기:92,823,564,486)",
      "당기순이익(손실)(비상위험준비금반영후조정이익(손실)당기:(-)64,149,087,377원전기:114,199,225,967원대손준비금반영후조정이익(손실)당기:(-)55,543,106,206원전기:120,125,439,090원))",
      // Exact whole NI labels independently checked against immutable CE totals.
      "당기순이익(주석23)(비상위험준비금반영후조정이익당기:330,317,307,787원전기:248,252,980,147원대손준비금반영후조정이익당기:405,964,567,689원전기:331,157,062,319원)",
      "당기순이익(주석23)(비상위험준비금반영후조정이익당기:336,102,116,734원전기:222,542,621,783원대손준비금반영후조정이익당기:411,689,146,425원전기:305,558,393,253원)",
      "당기연결순이익",

      '당기순손익',
      '당기순손실',
      '연결당기순손실',
      '연결당기순이익',
      '연결당기순손익',
      '연결당기순이익(손실)',
      '당기순이익(손실)',
      '당기순손익(손실)',
      '반기순이익(손실)',
      '분기순이익(손실)',
      '당기순이익',
      '반기순이익',
      '분기순이익',
    ],
    'operatingIncome': ['영업이익(손실)', '영업손익(손실)', '영업이익', '영업손익', '영업손실'],
    'capex': ['유형자산의취득', '유형자산취득', '(7)유형자산의취득', '(8)유형자산의취득', '(9)유형자산의취득'],
  };

  static const _lossNames = ['영업손실', '당기순손실', '연결당기순손실'];
  static bool _unambiguousLoss(FinancialFact fact) =>
      !_lossNames.contains(normalizedName(fact.accountName)) ||
      fact.amount != null && fact.amount! <= BigInt.zero;

  // Only the printed whole-profit annotation; its adjusted numbers are never used.
  static const adjustedProfitAnnotation =
      r'^(?:당기순(이익|손익)[(]대손준비금반영후조정이익:?(당기:([0-9]+|[0-9]{1,3}(,[0-9]{3})*)원전기:([0-9]+|[0-9]{1,3}(,[0-9]{3})*)원(전전기:([0-9]+|[0-9]{1,3}(,[0-9]{3})*)원)?|제[0-9]+기:([0-9]+|[0-9]{1,3}(,[0-9]{3})*)백만원,제[0-9]+기:([0-9]+|[0-9]{1,3}(,[0-9]{3})*)백만원,제[0-9]+기:([0-9]+|[0-9]{1,3}(,[0-9]{3})*)백만원)[)]|(?:연결)?당기순이익[(]대손준비금반영후조정이익당기:([0-9]+|[0-9]{1,3}(,[0-9]{3})*)원전기:([0-9]+|[0-9]{1,3}(,[0-9]{3})*)원[)][(]비상위험준비금반영후조정이익당기:([0-9]+|[0-9]{1,3}(,[0-9]{3})*)원전기:([0-9]+|[0-9]{1,3}(,[0-9]{3})*)원[)])$';

  static const exactHanyangPrintedProfit =
      '당기순이익(대손준비금반영후조정이익당기:25,894,824,085원전기:76,378,389,687원';

  static String normalizedName(String name) {
    if (name.replaceAll(RegExp(r'\s+'), '') == 'III..영업이익') {
      return '영업이익';
    }
    final clean = name
        .replaceAll(RegExp(r'\s+'), '')
        .replaceFirst(RegExp(r'^(Vlll|lll|[Ⅰ-ⅫIVXLCDM0-9]+)[.)．]'), '')
        .replaceFirst(
          RegExp(r'(?:\(주(?:석)?[0-9]+(?:,[0-9]+)*\)|<주석[0-9]+>)$'),
          '',
        );
    return clean == exactHanyangPrintedProfit ||
            RegExp(adjustedProfitAnnotation).hasMatch(clean)
        ? '당기순이익'
        : clean;
  }

  /// Shared finite mapping for SQL consumers; no fuzzy or company-specific match.
  static String resolvedIdSql(String alias) {
    const spaces =
        r'[[:space:]\u00A0\u1680\u2000-\u200A\u2028\u2029\u202F\u205F\u3000\uFEFF]';
    final compact =
        "regexp_replace($alias.\"accountName\", '$spaces', '', 'g')";
    final unprefixed =
        "regexp_replace($compact, '^(Vlll|lll|[Ⅰ-ⅫIVXLCDM0-9]+)[.)．]', '')";
    final unannotated =
        "regexp_replace($unprefixed, '([(]주(석)?[0-9]+(,[0-9]+)*[)]|<주석[0-9]+>)\$', '')";
    final name =
        "CASE WHEN $compact = 'III..영업이익' THEN '영업이익' WHEN $unannotated = '$exactHanyangPrintedProfit' OR $unannotated ~ '$adjustedProfitAnnotation' THEN '당기순이익' ELSE $unannotated END";
    final cases = <String>[
      "WHEN ${HanwhaOwnNetIncomeScope.sqlCondition(alias)} THEN 'ifrs-full_ProfitLoss'",
      "WHEN ${HanwhaOwnNetIncomeScope.boundReportSql(alias)} AND NOT ${HanwhaOwnNetIncomeScope.standardApiSql(alias)} AND ($alias.\"accountId\" IN ('ifrs-full_ProfitLoss') OR $name IN ('당기순이익','당기순손실','당기순손익','연결당기순이익','연결당기순손실')) THEN NULL",
      "WHEN ${SuntechOwnCfScope.sqlCondition(alias, 'netIncome')} THEN 'ifrs-full_ProfitLoss'",
      "WHEN ${SuntechOwnCfScope.sqlCondition(alias, 'capex')} THEN 'ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities'",
      "WHEN ${SuntechOwnCfScope.boundReportSql(alias)} AND ($alias.\"accountId\" IN ('ifrs-full_ProfitLoss','ifrs-full_PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities') OR $name IN ('당기순이익','당기순손실','연결당기순이익','연결당기순손실','유형자산의증가')) THEN NULL",

      "WHEN ${SolumixOwnRevenueScope.sqlCondition(alias)} THEN 'ifrs-full_Revenue'",
    ];
    for (final account in all) {
      for (final aliasId in account.accountIds.skip(1)) {
        cases.add(
          "WHEN $alias.\"accountId\" = '$aliasId' THEN '${account.accountIds.first}'",
        );
      }
      final names = fallbackNames[account.key];
      if (names == null || account.accountIds.isEmpty) continue;
      final finiteRevenueExclusion = account.key == 'revenue'
          ? " AND NOT EXISTS (SELECT 1 FROM financial_report bound_report WHERE bound_report.id=$alias.\"reportId\" AND bound_report.\"rceptNo\"='${SolumixOwnRevenueScope.receipt}')"
          : account.key == 'netIncome'
          ? " AND NOT EXISTS (SELECT 1 FROM financial_report bound_report WHERE bound_report.id=$alias.\"reportId\" AND bound_report.\"rceptNo\"='${HanwhaOwnNetIncomeScope.receipt}' AND bound_report.\"fsDiv\"='separate')"
          : '';
      final labels = names.map((n) => "'$n'").join(',');
      final statements = account.statements.map((s) => "'${s.name}'").join(',');
      cases.add(
        "WHEN $alias.\"accountId\" IS NULL AND $alias.statement IN ($statements) AND $name IN ($labels) AND ($name NOT IN ('영업손실','당기순손실','연결당기순손실') OR $alias.amount::numeric <= 0)$finiteRevenueExclusion THEN '${account.accountIds.first}'",
      );
    }
    return 'CASE ${cases.join(' ')} ELSE $alias."accountId" END';
  }

  /// 한 보고서의 사실에서 핵심 계정을 고른다. 자본변동표 세부(accountDetail) 행은 쓰지 않는다.
  static List<FinancialLine> pick(
    List<FinancialFact> facts, {
    Company? company,
    FinancialReport? report,
    Source? source,
  }) {
    final sunApi =
        company != null &&
        report != null &&
        source != null &&
        SuntechOwnCfScope.validApiSource(company, report, source);
    if (sunApi) {
      facts = facts
          .where((f) => SuntechOwnCfScope.apiFact(f, company, report))
          .toList();
    }
    final lines = <FinancialLine>[];
    for (final account in all) {
      FinancialFact? found;
      final sunBound =
          report?.rceptNo == SuntechOwnCfScope.receipt &&
          report?.fsDiv == FsDiv.consolidated &&
          SuntechOwnCfScope.keys.contains(account.key) &&
          !sunApi;
      if (sunBound) {
        if (company == null || report == null || source == null) continue;
        final candidates = facts
            .where(
              (f) =>
                  SuntechOwnCfScope.candidate(account.key, f, company, report),
            )
            .toList();
        if (candidates.length != 1 ||
            !SuntechOwnCfScope.validFact(
              account.key,
              candidates.single,
              company,
              report,
              source,
            )) {
          continue;
        }
        found = candidates.single;
      }
      final hanBound =
          account.key == 'netIncome' &&
          report?.rceptNo == HanwhaOwnNetIncomeScope.receipt &&
          report?.fsDiv == FsDiv.separate;
      final hanApi =
          hanBound &&
          company != null &&
          report != null &&
          source != null &&
          HanwhaOwnNetIncomeScope.validStandardApiSource(
            company,
            report,
            source,
          );
      search:
      for (final id in account.accountIds) {
        if (sunBound || (hanBound && !hanApi)) break;
        for (final statement in account.statements) {
          for (final f in facts) {
            if (f.accountId == id &&
                f.statement == statement &&
                f.supersededById == null &&
                f.accountDetail == null) {
              found = f;
              break search;
            }
          }
        }
      }
      if (found == null) {
        final names = fallbackNames[account.key];
        final candidates =
            names == null ||
                (account.key == 'revenue' &&
                    report?.rceptNo == SolumixOwnRevenueScope.receipt) ||
                (account.key == 'netIncome' &&
                    report?.rceptNo == HanwhaOwnNetIncomeScope.receipt &&
                    report?.fsDiv == FsDiv.separate)
            ? <FinancialFact>[]
            : facts
                  .where(
                    (f) =>
                        f.accountId == null &&
                        f.accountDetail == null &&
                        f.supersededById == null &&
                        account.statements.contains(f.statement) &&
                        names.contains(normalizedName(f.accountName)) &&
                        _unambiguousLoss(f),
                  )
                  .toList();
        if (candidates.length == 1) found = candidates.single;
      }
      if (found == null &&
          account.key == 'netIncome' &&
          company != null &&
          report != null &&
          source != null) {
        final candidates = facts
            .where((f) => HanwhaOwnNetIncomeScope.candidate(f, company, report))
            .toList();
        if (candidates.length == 1 &&
            HanwhaOwnNetIncomeScope.validFact(
              candidates.single,
              company,
              report,
              source,
            )) {
          found = candidates.single;
        }
      }
      if (found == null &&
          account.key == 'revenue' &&
          company != null &&
          report != null &&
          source != null) {
        final candidates = facts
            .where((f) => SolumixOwnRevenueScope.candidate(f, company, report))
            .toList();
        if (candidates.length == 1 &&
            SolumixOwnRevenueScope.validFact(
              candidates.single,
              company,
              report,
              source,
            )) {
          found = candidates.single;
        }
      }
      if (found == null) continue;
      lines.add(
        FinancialLine(
          key: account.key,
          factId: found.id!,
          statement: found.statement,
          accountId: found.accountId,
          accountName: found.accountName,
          currency: found.currency,
          amount: found.amount,
          cumulativeAmount: found.cumulativeAmount,
          priorSameCumulativeAmount:
              FinancialComparatives.invalidOwners(found, facts)
              ? null
              : FinancialComparatives.priorSame(found),
          priorSameUnavailableReason:
              FinancialComparatives.invalidOwners(found, facts)
              ? '전년 동기 지배주주·비지배주주 순이익 합계 불일치 · 원천 공시 확인 필요'
              : null,
        ),
      );
    }
    final bs = {for (final l in lines) l.key: l};
    final totals = [bs['assets'], bs['liabilities'], bs['equity']];
    if (totals.every((l) => l?.amount != null) &&
        totals.map((l) => l!.currency ?? 'KRW').toSet().length == 1) {
      final a = totals[0]!.amount!,
          b = totals[1]!.amount!,
          e = totals[2]!.amount!;
      // Allow at most one part per million for independently rounded totals.
      final tolerance = a.abs() ~/ BigInt.from(1000000);
      final allowed = tolerance > BigInt.from(1000)
          ? tolerance
          : BigInt.from(1000);
      if ((a - b - e).abs() > allowed) {
        for (final l in lines.where(
          (l) => const {
            'assets',
            'liabilities',
            'equity',
            'equityOwners',
          }.contains(l.key),
        )) {
          l.unavailableReason = '자산·부채·자본 합계 불일치 · 원천 공시 확인 필요';
        }
      }
    }
    final ownership = [
      bs['equity'],
      bs['equityOwners'],
      bs['noncontrollingInterest'],
    ];
    if (ownership.every((l) => l?.amount != null) &&
        ownership.map((l) => l!.currency ?? 'KRW').toSet().length == 1) {
      final total = ownership[0]!.amount!;
      final tolerance = total.abs() ~/ BigInt.from(1000000);
      final allowed = tolerance > BigInt.from(1000)
          ? tolerance
          : BigInt.from(1000);
      if ((total - ownership[1]!.amount! - ownership[2]!.amount!).abs() >
          allowed) {
        ownership[1]!.unavailableReason = '지배주주·비지배주주 자본 합계 불일치 · 원천 공시 확인 필요';
      }
    }
    return lines;
  }
}
