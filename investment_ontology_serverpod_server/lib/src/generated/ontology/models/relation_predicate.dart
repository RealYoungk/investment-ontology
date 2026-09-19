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

/// 온톨로지 관계 종류. 4단계(AI 추출)에서 공급·경쟁 등을 더한다.
enum RelationPredicate implements _is.SerializableModel {
  /// 주주 → 기업 (최대주주 현황)
  shareholderOf,

  /// 인물 → 기업 (임원 현황)
  executiveOf,

  /// 기업 → 출자 대상 (타법인 출자현황)
  investsIn;

  static RelationPredicate fromJson(String name) {
    switch (name) {
      case 'shareholderOf':
        return RelationPredicate.shareholderOf;
      case 'executiveOf':
        return RelationPredicate.executiveOf;
      case 'investsIn':
        return RelationPredicate.investsIn;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "RelationPredicate"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
