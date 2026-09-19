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

/// 사람이 끊은 추정 인물 연결. 연결을 다시 계산해도 이 기업의 이 이름은 묶지 않는다.
abstract class PersonLinkRejection
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PersonLinkRejection._({
    this.id,
    required this.companyId,
    required this.name,
    required this.createdAt,
  });

  factory PersonLinkRejection({
    int? id,
    required int companyId,
    required String name,
    required DateTime createdAt,
  }) = _PersonLinkRejectionImpl;

  factory PersonLinkRejection.fromJson(Map<String, dynamic> jsonSerialization) {
    return PersonLinkRejection(
      id: jsonSerialization['id'] as int?,
      companyId: jsonSerialization['companyId'] as int,
      name: jsonSerialization['name'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int companyId;

  /// 공백을 뗀 이름
  String name;

  DateTime createdAt;

  /// Returns a shallow copy of this [PersonLinkRejection]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PersonLinkRejection copyWith({
    int? id,
    int? companyId,
    String? name,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PersonLinkRejection',
      if (id != null) 'id': id,
      'companyId': companyId,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PersonLinkRejection',
      if (id != null) 'id': id,
      'companyId': companyId,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PersonLinkRejectionImpl extends PersonLinkRejection {
  _PersonLinkRejectionImpl({
    int? id,
    required int companyId,
    required String name,
    required DateTime createdAt,
  }) : super._(
         id: id,
         companyId: companyId,
         name: name,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PersonLinkRejection]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PersonLinkRejection copyWith({
    Object? id = _Undefined,
    int? companyId,
    String? name,
    DateTime? createdAt,
  }) {
    return PersonLinkRejection(
      id: id is int? ? id : this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
