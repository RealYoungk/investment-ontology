import '../../generated/protocol.dart';

/// DART interim cash-flow comparison is cumulative; interim P/L quarter
/// comparison is NOT cumulative except Q1. Never substitute a 3-month amount
/// for a half-year/nine-month input.
abstract final class FinancialComparatives {
  static BigInt? priorSame(FinancialFact f) {
    if (f.reportCode == FinancialReportCode.annual ||
        f.statement == FinancialStatementKind.balanceSheet) {
      return null;
    }
    if (f.statement == FinancialStatementKind.cashFlow) {
      return f.priorQuarterAmount;
    }
    return f.priorCumulativeAmount ??
        (f.reportCode == FinancialReportCode.q1 ? f.priorQuarterAmount : null);
  }

  static const owners = 'ifrs-full_ProfitLossAttributableToOwnersOfParent';
  static const total = 'ifrs-full_ProfitLoss';
  static const minority =
      'ifrs-full_ProfitLossAttributableToNoncontrollingInterests';

  static bool invalidOwners(FinancialFact f, List<FinancialFact> facts) {
    if (f.accountId != owners || priorSame(f) == null) return false;
    final components = <BigInt>[];
    for (final id in [total, minority]) {
      final matches = facts
          .where(
            (x) =>
                x.accountId == id &&
                x.reportId == f.reportId &&
                x.statement == f.statement &&
                x.accountDetail == null &&
                x.supersededById == null,
          )
          .toList();
      if (matches.length != 1 ||
          priorSame(matches.single) == null ||
          (matches.single.currency ?? 'KRW') != (f.currency ?? 'KRW')) {
        return false;
      }
      components.add(priorSame(matches.single)!);
    }
    final tolerance = components.first.abs() ~/ BigInt.from(1000000);
    final allowed = tolerance > BigInt.from(1000)
        ? tolerance
        : BigInt.from(1000);
    return (priorSame(f)! + components.last - components.first).abs() > allowed;
  }

  static String rawSql(String alias) =>
      '''CASE
    WHEN $alias."reportCode"='annual' OR $alias.statement='balanceSheet' THEN NULL
    WHEN $alias.statement='cashFlow' THEN $alias."priorQuarterAmount"::numeric
    ELSE coalesce($alias."priorCumulativeAmount"::numeric,
      CASE WHEN $alias."reportCode"='q1' THEN $alias."priorQuarterAmount"::numeric END) END''';

  static String validatedSql(String alias) {
    final value = rawSql(alias);
    final t = rawSql('pt'), m = rawSql('pm');
    return '''CASE WHEN $alias."accountId"='$owners' AND EXISTS (
      SELECT 1 FROM financial_fact pt JOIN financial_fact pm
        ON pm."reportId"=pt."reportId" AND pm.statement=pt.statement
      WHERE pt."reportId"=$alias."reportId" AND pt.statement=$alias.statement
        AND pt."accountId"='$total' AND pm."accountId"='$minority'
        AND pt."accountDetail" IS NULL AND pm."accountDetail" IS NULL
        AND pt."supersededById" IS NULL AND pm."supersededById" IS NULL
        AND coalesce(pt.currency,'KRW')=coalesce($alias.currency,'KRW')
        AND coalesce(pm.currency,'KRW')=coalesce($alias.currency,'KRW')
        AND (SELECT count(*) FROM financial_fact z WHERE z."reportId"=pt."reportId"
          AND z.statement=pt.statement AND z."accountDetail" IS NULL
          AND z."supersededById" IS NULL AND z."accountId"='$total')=1
        AND (SELECT count(*) FROM financial_fact z WHERE z."reportId"=pm."reportId"
          AND z.statement=pm.statement AND z."accountDetail" IS NULL
          AND z."supersededById" IS NULL AND z."accountId"='$minority')=1
        AND abs(($value)+($m)-($t))>greatest(1000,abs(($t))/1000000)
      ) THEN NULL ELSE ($value) END''';
  }
}
