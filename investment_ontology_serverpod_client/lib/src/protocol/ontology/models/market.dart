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

/// DART `corp_cls` 기준 시장 구분.
enum Market implements _isc.SerializableModel {
  /// 유가증권시장 (Y)
  kospi,

  /// 코스닥 (K)
  kosdaq,

  /// 코넥스 (N)
  konex,

  /// 기타 — 상장폐지 등 (E)
  other;

  static Market fromJson(String name) {
    switch (name) {
      case 'kospi':
        return Market.kospi;
      case 'kosdaq':
        return Market.kosdaq;
      case 'konex':
        return Market.konex;
      case 'other':
        return Market.other;
      default:
        throw ArgumentError('Value "$name" cannot be converted to "Market"');
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
