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

/// 기업 묶음 안 여러 기업의 최대주주 명단에 나오는 인물.
abstract class GroupPerson
    implements _is.SerializableModel, _is.ProtocolSerialization {
  GroupPerson._({
    required this.personId,
    required this.name,
    required this.estimated,
    required this.companyCount,
  });

  factory GroupPerson({
    required int personId,
    required String name,
    required bool estimated,
    required int companyCount,
  }) = _GroupPersonImpl;

  factory GroupPerson.fromJson(Map<String, dynamic> jsonSerialization) {
    return GroupPerson(
      personId: jsonSerialization['personId'] as int,
      name: jsonSerialization['name'] as String,
      estimated: _is.BoolJsonExtension.fromJson(jsonSerialization['estimated']),
      companyCount: jsonSerialization['companyCount'] as int,
    );
  }

  int personId;

  String name;

  /// 추정 연결 (지분 묶음 규칙)
  bool estimated;

  /// 이 인물이 주주인 묶음 안 기업 수
  int companyCount;

  /// Returns a shallow copy of this [GroupPerson]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  GroupPerson copyWith({
    int? personId,
    String? name,
    bool? estimated,
    int? companyCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GroupPerson',
      'personId': personId,
      'name': name,
      'estimated': estimated,
      'companyCount': companyCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GroupPerson',
      'personId': personId,
      'name': name,
      'estimated': estimated,
      'companyCount': companyCount,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _GroupPersonImpl extends GroupPerson {
  _GroupPersonImpl({
    required int personId,
    required String name,
    required bool estimated,
    required int companyCount,
  }) : super._(
         personId: personId,
         name: name,
         estimated: estimated,
         companyCount: companyCount,
       );

  /// Returns a shallow copy of this [GroupPerson]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  GroupPerson copyWith({
    int? personId,
    String? name,
    bool? estimated,
    int? companyCount,
  }) {
    return GroupPerson(
      personId: personId ?? this.personId,
      name: name ?? this.name,
      estimated: estimated ?? this.estimated,
      companyCount: companyCount ?? this.companyCount,
    );
  }
}
