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

/// 기업의 테마 편입 (EXPOSED_TO). 사람의 판단이라 출처는 manual이고, 왜 넣었는지 메모를 남긴다.
abstract class ThemeMember
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ThemeMember._({
    this.id,
    required this.themeId,
    required this.companyId,
    this.note,
    required this.sourceId,
    required this.createdAt,
  });

  factory ThemeMember({
    int? id,
    required int themeId,
    required int companyId,
    String? note,
    required int sourceId,
    required DateTime createdAt,
  }) = _ThemeMemberImpl;

  factory ThemeMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return ThemeMember(
      id: jsonSerialization['id'] as int?,
      themeId: jsonSerialization['themeId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      note: jsonSerialization['note'] as String?,
      sourceId: jsonSerialization['sourceId'] as int,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int themeId;

  int companyId;

  /// 노출도 메모 (왜 이 테마인지)
  String? note;

  int sourceId;

  DateTime createdAt;

  /// Returns a shallow copy of this [ThemeMember]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ThemeMember copyWith({
    int? id,
    int? themeId,
    int? companyId,
    String? note,
    int? sourceId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThemeMember',
      if (id != null) 'id': id,
      'themeId': themeId,
      'companyId': companyId,
      if (note != null) 'note': note,
      'sourceId': sourceId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ThemeMember',
      if (id != null) 'id': id,
      'themeId': themeId,
      'companyId': companyId,
      if (note != null) 'note': note,
      'sourceId': sourceId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ThemeMemberImpl extends ThemeMember {
  _ThemeMemberImpl({
    int? id,
    required int themeId,
    required int companyId,
    String? note,
    required int sourceId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         themeId: themeId,
         companyId: companyId,
         note: note,
         sourceId: sourceId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ThemeMember]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ThemeMember copyWith({
    Object? id = _Undefined,
    int? themeId,
    int? companyId,
    Object? note = _Undefined,
    int? sourceId,
    DateTime? createdAt,
  }) {
    return ThemeMember(
      id: id is int? ? id : this.id,
      themeId: themeId ?? this.themeId,
      companyId: companyId ?? this.companyId,
      note: note is String? ? note : this.note,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
