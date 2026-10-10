import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import 'company_display_name.dart';

export 'company_display_name.dart';

extension CompanyPresentation on Company {
  String get displayName => companyDisplayName(
    name: name,
    stockName: stockName,
    stockCode: stockCode,
  );
}
