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

/// 한국표준산업분류(KSIC) 항목.
abstract class Industry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Industry._({
    this.id,
    required this.code,
    required this.name,
    required this.level,
    this.parentCode,
    required this.revision,
  });

  factory Industry({
    int? id,
    required String code,
    required String name,
    required int level,
    String? parentCode,
    required String revision,
  }) = _IndustryImpl;

  factory Industry.fromJson(Map<String, dynamic> jsonSerialization) {
    return Industry(
      id: jsonSerialization['id'] as int?,
      code: jsonSerialization['code'] as String,
      name: jsonSerialization['name'] as String,
      level: jsonSerialization['level'] as int,
      parentCode: jsonSerialization['parentCode'] as String?,
      revision: jsonSerialization['revision'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// A~U (대분류) 또는 2~5자리 숫자
  String code;

  String name;

  /// 1 대분류, 2 중분류, 3 소분류, 4 세분류, 5 세세분류
  int level;

  String? parentCode;

  /// 예: "KSIC 10"
  String revision;

  /// Returns a shallow copy of this [Industry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Industry copyWith({
    int? id,
    String? code,
    String? name,
    int? level,
    String? parentCode,
    String? revision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Industry',
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'level': level,
      if (parentCode != null) 'parentCode': parentCode,
      'revision': revision,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Industry',
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'level': level,
      if (parentCode != null) 'parentCode': parentCode,
      'revision': revision,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IndustryImpl extends Industry {
  _IndustryImpl({
    int? id,
    required String code,
    required String name,
    required int level,
    String? parentCode,
    required String revision,
  }) : super._(
         id: id,
         code: code,
         name: name,
         level: level,
         parentCode: parentCode,
         revision: revision,
       );

  /// Returns a shallow copy of this [Industry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Industry copyWith({
    Object? id = _Undefined,
    String? code,
    String? name,
    int? level,
    Object? parentCode = _Undefined,
    String? revision,
  }) {
    return Industry(
      id: id is int? ? id : this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      level: level ?? this.level,
      parentCode: parentCode is String? ? parentCode : this.parentCode,
      revision: revision ?? this.revision,
    );
  }
}
