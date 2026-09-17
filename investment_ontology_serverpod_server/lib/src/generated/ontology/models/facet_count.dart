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

/// 분류별 기업 수.
abstract class FacetCount
    implements _is.SerializableModel, _is.ProtocolSerialization {
  FacetCount._({
    required this.code,
    required this.name,
    required this.count,
  });

  factory FacetCount({
    required String code,
    required String name,
    required int count,
  }) = _FacetCountImpl;

  factory FacetCount.fromJson(Map<String, dynamic> jsonSerialization) {
    return FacetCount(
      code: jsonSerialization['code'] as String,
      name: jsonSerialization['name'] as String,
      count: jsonSerialization['count'] as int,
    );
  }

  String code;

  String name;

  int count;

  /// Returns a shallow copy of this [FacetCount]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FacetCount copyWith({
    String? code,
    String? name,
    int? count,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FacetCount',
      'code': code,
      'name': name,
      'count': count,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FacetCount',
      'code': code,
      'name': name,
      'count': count,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _FacetCountImpl extends FacetCount {
  _FacetCountImpl({
    required String code,
    required String name,
    required int count,
  }) : super._(
         code: code,
         name: name,
         count: count,
       );

  /// Returns a shallow copy of this [FacetCount]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FacetCount copyWith({
    String? code,
    String? name,
    int? count,
  }) {
    return FacetCount(
      code: code ?? this.code,
      name: name ?? this.name,
      count: count ?? this.count,
    );
  }
}
