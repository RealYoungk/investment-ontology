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

/// 인물. 출생년월이 있는 임원, 또는 지분으로 이어진 기업 묶음에서 같은 이름으로 나오는 주주(추정)에게서 만든다.
abstract class Person
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Person._({
    this.id,
    required this.name,
    this.birthYear,
    this.birthMonth,
    this.sex,
    required this.personKey,
    required this.estimated,
  });

  factory Person({
    int? id,
    required String name,
    int? birthYear,
    int? birthMonth,
    String? sex,
    required String personKey,
    required bool estimated,
  }) = _PersonImpl;

  factory Person.fromJson(Map<String, dynamic> jsonSerialization) {
    return Person(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      birthYear: jsonSerialization['birthYear'] as int?,
      birthMonth: jsonSerialization['birthMonth'] as int?,
      sex: jsonSerialization['sex'] as String?,
      personKey: jsonSerialization['personKey'] as String,
      estimated: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['estimated'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// 공백을 뗀 이름
  String name;

  int? birthYear;

  int? birthMonth;

  String? sex;

  /// 같은 사람을 찾는 키. 임원 "exec:이름:YYYY-MM", 추정 "cluster:이름:묶음의 첫 corpCode"
  String personKey;

  /// 출생년월 없이 이름과 기업 묶음으로만 정한 인물 (추정)
  bool estimated;

  /// Returns a shallow copy of this [Person]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Person copyWith({
    int? id,
    String? name,
    int? birthYear,
    int? birthMonth,
    String? sex,
    String? personKey,
    bool? estimated,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Person',
      if (id != null) 'id': id,
      'name': name,
      if (birthYear != null) 'birthYear': birthYear,
      if (birthMonth != null) 'birthMonth': birthMonth,
      if (sex != null) 'sex': sex,
      'personKey': personKey,
      'estimated': estimated,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Person',
      if (id != null) 'id': id,
      'name': name,
      if (birthYear != null) 'birthYear': birthYear,
      if (birthMonth != null) 'birthMonth': birthMonth,
      if (sex != null) 'sex': sex,
      'personKey': personKey,
      'estimated': estimated,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PersonImpl extends Person {
  _PersonImpl({
    int? id,
    required String name,
    int? birthYear,
    int? birthMonth,
    String? sex,
    required String personKey,
    required bool estimated,
  }) : super._(
         id: id,
         name: name,
         birthYear: birthYear,
         birthMonth: birthMonth,
         sex: sex,
         personKey: personKey,
         estimated: estimated,
       );

  /// Returns a shallow copy of this [Person]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Person copyWith({
    Object? id = _Undefined,
    String? name,
    Object? birthYear = _Undefined,
    Object? birthMonth = _Undefined,
    Object? sex = _Undefined,
    String? personKey,
    bool? estimated,
  }) {
    return Person(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      birthYear: birthYear is int? ? birthYear : this.birthYear,
      birthMonth: birthMonth is int? ? birthMonth : this.birthMonth,
      sex: sex is String? ? sex : this.sex,
      personKey: personKey ?? this.personKey,
      estimated: estimated ?? this.estimated,
    );
  }
}
