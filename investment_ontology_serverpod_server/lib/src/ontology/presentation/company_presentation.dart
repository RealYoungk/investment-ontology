import '../../generated/protocol.dart';
import 'company_display_name.dart';

extension CompanyPresentation on Company {
  String get displayName => companyDisplayName(
    name: name,
    stockName: stockName,
    stockCode: stockCode,
  );
}
