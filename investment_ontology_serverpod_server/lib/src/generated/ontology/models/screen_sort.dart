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

/// 스크리닝 정렬 기준.
enum ScreenSort implements _is.SerializableModel {
  marketCap,
  per,
  pbr,
  roe,
  operatingMargin,
  debtRatio,
  fcfYield,
  dividendYield;

  static ScreenSort fromJson(String name) {
    switch (name) {
      case 'marketCap':
        return ScreenSort.marketCap;
      case 'per':
        return ScreenSort.per;
      case 'pbr':
        return ScreenSort.pbr;
      case 'roe':
        return ScreenSort.roe;
      case 'operatingMargin':
        return ScreenSort.operatingMargin;
      case 'debtRatio':
        return ScreenSort.debtRatio;
      case 'fcfYield':
        return ScreenSort.fcfYield;
      case 'dividendYield':
        return ScreenSort.dividendYield;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ScreenSort"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
