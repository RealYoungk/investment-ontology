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
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart'
    as _i4yshtjp;
import 'package:serverpod/serverpod.dart' as _is;

/// 인물 검색 결과 한 줄.
abstract class PersonHit
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PersonHit._({
    required this.personId,
    required this.name,
    required this.estimated,
    this.birthYear,
    this.birthMonth,
    required this.companyCount,
    required this.companyNames,
  });

  factory PersonHit({
    required int personId,
    required String name,
    required bool estimated,
    int? birthYear,
    int? birthMonth,
    required int companyCount,
    required List<String> companyNames,
  }) = _PersonHitImpl;

  factory PersonHit.fromJson(Map<String, dynamic> jsonSerialization) {
    return PersonHit(
      personId: jsonSerialization['personId'] as int,
      name: jsonSerialization['name'] as String,
      estimated: _is.BoolJsonExtension.fromJson(jsonSerialization['estimated']),
      birthYear: jsonSerialization['birthYear'] as int?,
      birthMonth: jsonSerialization['birthMonth'] as int?,
      companyCount: jsonSerialization['companyCount'] as int,
      companyNames: _i4yshtjp.Protocol().deserialize<List<String>>(
        jsonSerialization['companyNames'],
      ),
    );
  }

  int personId;

  String name;

  bool estimated;

  int? birthYear;

  int? birthMonth;

  /// 이 인물이 주주·임원으로 이어진 기업 수
  int companyCount;

  /// 이어진 기업 가운데 세 곳까지의 이름 (가나다순)
  List<String> companyNames;

  /// Returns a shallow copy of this [PersonHit]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PersonHit copyWith({
    int? personId,
    String? name,
    bool? estimated,
    int? birthYear,
    int? birthMonth,
    int? companyCount,
    List<String>? companyNames,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PersonHit',
      'personId': personId,
      'name': name,
      'estimated': estimated,
      if (birthYear != null) 'birthYear': birthYear,
      if (birthMonth != null) 'birthMonth': birthMonth,
      'companyCount': companyCount,
      'companyNames': companyNames.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PersonHit',
      'personId': personId,
      'name': name,
      'estimated': estimated,
      if (birthYear != null) 'birthYear': birthYear,
      if (birthMonth != null) 'birthMonth': birthMonth,
      'companyCount': companyCount,
      'companyNames': companyNames.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PersonHitImpl extends PersonHit {
  _PersonHitImpl({
    required int personId,
    required String name,
    required bool estimated,
    int? birthYear,
    int? birthMonth,
    required int companyCount,
    required List<String> companyNames,
  }) : super._(
         personId: personId,
         name: name,
         estimated: estimated,
         birthYear: birthYear,
         birthMonth: birthMonth,
         companyCount: companyCount,
         companyNames: companyNames,
       );

  /// Returns a shallow copy of this [PersonHit]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PersonHit copyWith({
    int? personId,
    String? name,
    bool? estimated,
    Object? birthYear = _Undefined,
    Object? birthMonth = _Undefined,
    int? companyCount,
    List<String>? companyNames,
  }) {
    return PersonHit(
      personId: personId ?? this.personId,
      name: name ?? this.name,
      estimated: estimated ?? this.estimated,
      birthYear: birthYear is int? ? birthYear : this.birthYear,
      birthMonth: birthMonth is int? ? birthMonth : this.birthMonth,
      companyCount: companyCount ?? this.companyCount,
      companyNames: companyNames ?? this.companyNames.map((e0) => e0).toList(),
    );
  }
}
