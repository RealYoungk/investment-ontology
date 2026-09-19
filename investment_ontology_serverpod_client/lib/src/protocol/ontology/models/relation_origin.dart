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

/// 관계를 만든 방법.
enum RelationOrigin implements _isc.SerializableModel {
  /// 구조화된 API 응답
  api,

  /// AI 추출 (4단계)
  ai,

  /// 사람이 입력
  manual;

  static RelationOrigin fromJson(String name) {
    switch (name) {
      case 'api':
        return RelationOrigin.api;
      case 'ai':
        return RelationOrigin.ai;
      case 'manual':
        return RelationOrigin.manual;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "RelationOrigin"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
