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

/// 관계가 가리키는 원천 행의 종류.
enum RelationFactKind implements _is.SerializableModel {
  shareholderEntry,
  executiveEntry,
  investmentEntry,

  /// 사업보고서 본문 (AI 추출의 원문)
  businessDocument;

  static RelationFactKind fromJson(String name) {
    switch (name) {
      case 'shareholderEntry':
        return RelationFactKind.shareholderEntry;
      case 'executiveEntry':
        return RelationFactKind.executiveEntry;
      case 'investmentEntry':
        return RelationFactKind.investmentEntry;
      case 'businessDocument':
        return RelationFactKind.businessDocument;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "RelationFactKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
