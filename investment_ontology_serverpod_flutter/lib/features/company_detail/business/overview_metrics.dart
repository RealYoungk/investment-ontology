/// Lending/insurance balance sheets need different headline metrics from factories.
/// Keep statement calculations intact; only choose the company header's emphasis.
/// Non-financial holding companies deliberately retain ordinary metrics.
bool usesFinancialOverviewMetrics(String? industryCode, String companyName) {
  final code = industryCode ?? '';
  return code.startsWith('641') ||
      code == '64911' ||
      code == '64913' ||
      code.startsWith('65') ||
      code.startsWith('6612') ||
      companyName.contains('금융지주') ||
      (code.startsWith('66') && companyName.contains('증권'));
}

bool isAssetInvestmentVehicle(String companyName) =>
    RegExp('부동산투자|리츠|리얼티|인프라투융자|기업인수목적').hasMatch(companyName);

bool showOverviewMetric(
  String key, {
  required bool financial,
  bool assetVehicle = false,
}) {
  if (const {'freeCashFlow', 'fcfYield'}.contains(key) &&
      (financial || assetVehicle)) {
    return false;
  }
  return !financial || !const {'operatingMargin', 'debtRatio'}.contains(key);
}
