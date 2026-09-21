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

enum CompanySort implements _is.SerializableModel {
  name,
  stockCode,
  establishedDate,

  /// 시가총액 큰 순 (가장 최근 기준일, 시세가 없으면 뒤로)
  marketCap;

  static CompanySort fromJson(String name) {
    switch (name) {
      case 'name':
        return CompanySort.name;
      case 'stockCode':
        return CompanySort.stockCode;
      case 'establishedDate':
        return CompanySort.establishedDate;
      case 'marketCap':
        return CompanySort.marketCap;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "CompanySort"',
        );
    }
  }

  @override
  String toJson() => this.name;

  @override
  String toString() => this.name;
}
