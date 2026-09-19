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

/// 관계 검수 상태.
enum RelationStatus implements _isc.SerializableModel {
  /// 원천 응답 그대로 (API)
  verified,

  /// 추정 연결 또는 AI 추출. 사람이 끊을 수 있다
  draft,

  /// 사람이 틀렸다고 끊음
  rejected;

  static RelationStatus fromJson(String name) {
    switch (name) {
      case 'verified':
        return RelationStatus.verified;
      case 'draft':
        return RelationStatus.draft;
      case 'rejected':
        return RelationStatus.rejected;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "RelationStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
