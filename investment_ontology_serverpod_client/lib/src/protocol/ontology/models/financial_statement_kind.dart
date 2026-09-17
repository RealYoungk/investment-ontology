/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// 재무제표 종류 (DART sj_div).
enum FinancialStatementKind implements _isc.SerializableModel {
  /// 재무상태표 (BS)
  balanceSheet,

  /// 손익계산서 (IS)
  incomeStatement,

  /// 포괄손익계산서 (CIS)
  comprehensiveIncome,

  /// 현금흐름표 (CF)
  cashFlow,

  /// 자본변동표 (SCE)
  equityChanges;

  static FinancialStatementKind fromJson(String name) {
    switch (name) {
      case 'balanceSheet':
        return FinancialStatementKind.balanceSheet;
      case 'incomeStatement':
        return FinancialStatementKind.incomeStatement;
      case 'comprehensiveIncome':
        return FinancialStatementKind.comprehensiveIncome;
      case 'cashFlow':
        return FinancialStatementKind.cashFlow;
      case 'equityChanges':
        return FinancialStatementKind.equityChanges;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "FinancialStatementKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
