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

/// 호출 한도를 관리하는 외부 API 제공자.
enum ApiProvider implements _isc.SerializableModel {
  /// DART OpenAPI (키당 일일 약 20,000건)
  dart,

  /// 공공데이터포털 (서비스별 일일 한도, 개발계정 10,000건)
  dataGoKr;

  static ApiProvider fromJson(String name) {
    switch (name) {
      case 'dart':
        return ApiProvider.dart;
      case 'dataGoKr':
        return ApiProvider.dataGoKr;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ApiProvider"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
