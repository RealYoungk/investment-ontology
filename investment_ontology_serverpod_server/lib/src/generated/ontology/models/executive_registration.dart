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

/// 임원의 등기 구분 (임원 현황 rgist_exctv_at).
enum ExecutiveRegistration implements _is.SerializableModel {
  inside,
  outside,

  /// 기타비상무이사
  nonExecutive,
  unregistered,

  /// 위에 없는 표기 (원문은 registrationRaw)
  other;

  static ExecutiveRegistration fromJson(String name) {
    switch (name) {
      case 'inside':
        return ExecutiveRegistration.inside;
      case 'outside':
        return ExecutiveRegistration.outside;
      case 'nonExecutive':
        return ExecutiveRegistration.nonExecutive;
      case 'unregistered':
        return ExecutiveRegistration.unregistered;
      case 'other':
        return ExecutiveRegistration.other;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ExecutiveRegistration"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
