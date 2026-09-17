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
import 'package:serverpod/serverpod.dart' as _is;

/// DART 정기보고서 코드 (reprt_code).
enum FinancialReportCode implements _is.SerializableModel {
  /// 사업보고서 (11011)
  annual,

  /// 반기보고서 (11012)
  halfYear,

  /// 1분기보고서 (11013)
  q1,

  /// 3분기보고서 (11014)
  q3;

  static FinancialReportCode fromJson(String name) {
    switch (name) {
      case 'annual':
        return FinancialReportCode.annual;
      case 'halfYear':
        return FinancialReportCode.halfYear;
      case 'q1':
        return FinancialReportCode.q1;
      case 'q3':
        return FinancialReportCode.q3;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "FinancialReportCode"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
