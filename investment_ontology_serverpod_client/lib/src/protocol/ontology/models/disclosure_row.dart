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

/// 주요정보 응답 한 행을 원문 그대로. 항목 28종 모두 이 형식으로 보관한다.
/// 타입 층(ShareholderEntry 등)은 이 행에서 호출 없이 다시 만들 수 있다.
abstract class DisclosureRow
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DisclosureRow._({
    this.id,
    required this.reportId,
    required this.ord,
    required this.isTotal,
    required this.rowJson,
  });

  factory DisclosureRow({
    int? id,
    required int reportId,
    required int ord,
    required bool isTotal,
    required String rowJson,
  }) = _DisclosureRowImpl;

  factory DisclosureRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return DisclosureRow(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      ord: jsonSerialization['ord'] as int,
      isTotal: _isc.BoolJsonExtension.fromJson(jsonSerialization['isTotal']),
      rowJson: jsonSerialization['rowJson'] as String,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int reportId;

  /// 응답 순서 (0부터)
  int ord;

  /// 합계·소계 행 (계, 합계, 소계, 총계)
  bool isTotal;

  /// 응답 행 JSON 원문 (공통 필드 rcept_no·corp_code 등 포함)
  String rowJson;

  /// Returns a shallow copy of this [DisclosureRow]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DisclosureRow copyWith({
    int? id,
    int? reportId,
    int? ord,
    bool? isTotal,
    String? rowJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DisclosureRow',
      if (id != null) 'id': id,
      'reportId': reportId,
      'ord': ord,
      'isTotal': isTotal,
      'rowJson': rowJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DisclosureRow',
      if (id != null) 'id': id,
      'reportId': reportId,
      'ord': ord,
      'isTotal': isTotal,
      'rowJson': rowJson,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DisclosureRowImpl extends DisclosureRow {
  _DisclosureRowImpl({
    int? id,
    required int reportId,
    required int ord,
    required bool isTotal,
    required String rowJson,
  }) : super._(
         id: id,
         reportId: reportId,
         ord: ord,
         isTotal: isTotal,
         rowJson: rowJson,
       );

  /// Returns a shallow copy of this [DisclosureRow]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DisclosureRow copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? ord,
    bool? isTotal,
    String? rowJson,
  }) {
    return DisclosureRow(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      ord: ord ?? this.ord,
      isTotal: isTotal ?? this.isTotal,
      rowJson: rowJson ?? this.rowJson,
    );
  }
}
