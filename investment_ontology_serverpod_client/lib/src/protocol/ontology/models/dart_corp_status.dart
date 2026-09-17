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

/// 수집 장부: 종목코드를 가진 DART 고유번호마다 마지막으로 확인한 상장 구분.
/// 온톨로지 엔티티가 아니라, 상장폐지 기업을 매번 다시 조회하지 않기 위한 기록이다.
abstract class DartCorpStatus
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DartCorpStatus._({
    this.id,
    required this.corpCode,
    required this.corpCls,
    this.modifiedDate,
    required this.checkedAt,
  });

  factory DartCorpStatus({
    int? id,
    required String corpCode,
    required String corpCls,
    DateTime? modifiedDate,
    required DateTime checkedAt,
  }) = _DartCorpStatusImpl;

  factory DartCorpStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return DartCorpStatus(
      id: jsonSerialization['id'] as int?,
      corpCode: jsonSerialization['corpCode'] as String,
      corpCls: jsonSerialization['corpCls'] as String,
      modifiedDate: jsonSerialization['modifiedDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['modifiedDate'],
            ),
      checkedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['checkedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String corpCode;

  /// company.json의 corp_cls (Y/K/N/E)
  String corpCls;

  DateTime? modifiedDate;

  DateTime checkedAt;

  /// Returns a shallow copy of this [DartCorpStatus]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DartCorpStatus copyWith({
    int? id,
    String? corpCode,
    String? corpCls,
    DateTime? modifiedDate,
    DateTime? checkedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DartCorpStatus',
      if (id != null) 'id': id,
      'corpCode': corpCode,
      'corpCls': corpCls,
      if (modifiedDate != null) 'modifiedDate': modifiedDate?.toJson(),
      'checkedAt': checkedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DartCorpStatus',
      if (id != null) 'id': id,
      'corpCode': corpCode,
      'corpCls': corpCls,
      if (modifiedDate != null) 'modifiedDate': modifiedDate?.toJson(),
      'checkedAt': checkedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DartCorpStatusImpl extends DartCorpStatus {
  _DartCorpStatusImpl({
    int? id,
    required String corpCode,
    required String corpCls,
    DateTime? modifiedDate,
    required DateTime checkedAt,
  }) : super._(
         id: id,
         corpCode: corpCode,
         corpCls: corpCls,
         modifiedDate: modifiedDate,
         checkedAt: checkedAt,
       );

  /// Returns a shallow copy of this [DartCorpStatus]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DartCorpStatus copyWith({
    Object? id = _Undefined,
    String? corpCode,
    String? corpCls,
    Object? modifiedDate = _Undefined,
    DateTime? checkedAt,
  }) {
    return DartCorpStatus(
      id: id is int? ? id : this.id,
      corpCode: corpCode ?? this.corpCode,
      corpCls: corpCls ?? this.corpCls,
      modifiedDate: modifiedDate is DateTime?
          ? modifiedDate
          : this.modifiedDate,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }
}
