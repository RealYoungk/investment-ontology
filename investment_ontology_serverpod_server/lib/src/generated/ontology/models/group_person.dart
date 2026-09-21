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
    this.birthYear,
    required this.companyCount,
  });

  factory GroupPerson({
    required int personId,
    required String name,
    required bool estimated,
    int? birthYear,
    required int companyCount,
  }) = _GroupPersonImpl;

  factory GroupPerson.fromJson(Map<String, dynamic> jsonSerialization) {
    return GroupPerson(
      personId: jsonSerialization['personId'] as int,
      name: jsonSerialization['name'] as String,
      estimated: _is.BoolJsonExtension.fromJson(jsonSerialization['estimated']),
      birthYear: jsonSerialization['birthYear'] as int?,
      companyCount: jsonSerialization['companyCount'] as int,
    );
  }

  int personId;

  String name;

  /// 추정 연결 (지분 묶음 규칙)
  bool estimated;

  /// 출생년도 (임원 명단에 있으면). 같은 이름의 다른 사람을 가른다
  int? birthYear;

  /// 이 인물이 주주인 묶음 안 기업 수
  int companyCount;

  /// Returns a shallow copy of this [GroupPerson]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  GroupPerson copyWith({
    int? personId,
    String? name,
    bool? estimated,
    int? birthYear,
    int? companyCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GroupPerson',
      'personId': personId,
      'name': name,
      'estimated': estimated,
      if (birthYear != null) 'birthYear': birthYear,
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
      if (birthYear != null) 'birthYear': birthYear,
      'companyCount': companyCount,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GroupPersonImpl extends GroupPerson {
  _GroupPersonImpl({
    required int personId,
    required String name,
    required bool estimated,
    int? birthYear,
    required int companyCount,
  }) : super._(
         personId: personId,
         name: name,
         estimated: estimated,
         birthYear: birthYear,
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
    Object? birthYear = _Undefined,
    int? companyCount,
  }) {
    return GroupPerson(
      personId: personId ?? this.personId,
      name: name ?? this.name,
      estimated: estimated ?? this.estimated,
      birthYear: birthYear is int? ? birthYear : this.birthYear,
      companyCount: companyCount ?? this.companyCount,
    );
  }
}
