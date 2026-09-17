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

/// 기업 속성 변경 이력. 다시 수집했을 때 값이 바뀐 필드마다 한 행.
abstract class CompanyChange
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CompanyChange._({
    this.id,
    required this.companyId,
    required this.field,
    this.oldValue,
    this.newValue,
    this.sourceId,
    required this.changedAt,
  });

  factory CompanyChange({
    int? id,
    required int companyId,
    required String field,
    String? oldValue,
    String? newValue,
    int? sourceId,
    required DateTime changedAt,
  }) = _CompanyChangeImpl;

  factory CompanyChange.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyChange(
      id: jsonSerialization['id'] as int?,
      companyId: jsonSerialization['companyId'] as int,
      field: jsonSerialization['field'] as String,
      oldValue: jsonSerialization['oldValue'] as String?,
      newValue: jsonSerialization['newValue'] as String?,
      sourceId: jsonSerialization['sourceId'] as int?,
      changedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['changedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int companyId;

  /// Company 필드명 (예: ceoName, market)
  String field;

  /// 정규화된 값을 문자열로 (날짜는 YYYY-MM-DD, enum은 이름)
  String? oldValue;

  String? newValue;

  int? sourceId;

  DateTime changedAt;

  /// Returns a shallow copy of this [CompanyChange]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CompanyChange copyWith({
    int? id,
    int? companyId,
    String? field,
    String? oldValue,
    String? newValue,
    int? sourceId,
    DateTime? changedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyChange',
      if (id != null) 'id': id,
      'companyId': companyId,
      'field': field,
      if (oldValue != null) 'oldValue': oldValue,
      if (newValue != null) 'newValue': newValue,
      if (sourceId != null) 'sourceId': sourceId,
      'changedAt': changedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyChange',
      if (id != null) 'id': id,
      'companyId': companyId,
      'field': field,
      if (oldValue != null) 'oldValue': oldValue,
      if (newValue != null) 'newValue': newValue,
      if (sourceId != null) 'sourceId': sourceId,
      'changedAt': changedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanyChangeImpl extends CompanyChange {
  _CompanyChangeImpl({
    int? id,
    required int companyId,
    required String field,
    String? oldValue,
    String? newValue,
    int? sourceId,
    required DateTime changedAt,
  }) : super._(
         id: id,
         companyId: companyId,
         field: field,
         oldValue: oldValue,
         newValue: newValue,
         sourceId: sourceId,
         changedAt: changedAt,
       );

  /// Returns a shallow copy of this [CompanyChange]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CompanyChange copyWith({
    Object? id = _Undefined,
    int? companyId,
    String? field,
    Object? oldValue = _Undefined,
    Object? newValue = _Undefined,
    Object? sourceId = _Undefined,
    DateTime? changedAt,
  }) {
    return CompanyChange(
      id: id is int? ? id : this.id,
      companyId: companyId ?? this.companyId,
      field: field ?? this.field,
      oldValue: oldValue is String? ? oldValue : this.oldValue,
      newValue: newValue is String? ? newValue : this.newValue,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
      changedAt: changedAt ?? this.changedAt,
    );
  }
}
