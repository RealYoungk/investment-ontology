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

/// DART에 올라온 공시 하나 (종류 가리지 않음). 기업 화면의 "최근 공시"에 쓴다.
///
/// 정기보고서는 [DartFiling]이 따로 관리한다. 이 표는 계약·증자·주요사항 등
/// 무슨 일이 있었는지 훑어보는 용도라 목록만 담는다.
abstract class DartDisclosure
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DartDisclosure._({
    this.id,
    required this.rceptNo,
    required this.corpCode,
    this.companyId,
    required this.corpName,
    required this.reportName,
    required this.receivedDate,
    this.filerName,
    required this.discoveredAt,
  });

  factory DartDisclosure({
    int? id,
    required String rceptNo,
    required String corpCode,
    int? companyId,
    required String corpName,
    required String reportName,
    required DateTime receivedDate,
    String? filerName,
    required DateTime discoveredAt,
  }) = _DartDisclosureImpl;

  factory DartDisclosure.fromJson(Map<String, dynamic> jsonSerialization) {
    return DartDisclosure(
      id: jsonSerialization['id'] as int?,
      rceptNo: jsonSerialization['rceptNo'] as String,
      corpCode: jsonSerialization['corpCode'] as String,
      companyId: jsonSerialization['companyId'] as int?,
      corpName: jsonSerialization['corpName'] as String,
      reportName: jsonSerialization['reportName'] as String,
      receivedDate: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['receivedDate'],
      ),
      filerName: jsonSerialization['filerName'] as String?,
      discoveredAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['discoveredAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String rceptNo;

  String corpCode;

  int? companyId;

  String corpName;

  String reportName;

  DateTime receivedDate;

  /// 제출인 (회사가 아닌 경우도 있다 — 주주의 대량보유 보고 등)
  String? filerName;

  DateTime discoveredAt;

  /// Returns a shallow copy of this [DartDisclosure]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DartDisclosure copyWith({
    int? id,
    String? rceptNo,
    String? corpCode,
    int? companyId,
    String? corpName,
    String? reportName,
    DateTime? receivedDate,
    String? filerName,
    DateTime? discoveredAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DartDisclosure',
      if (id != null) 'id': id,
      'rceptNo': rceptNo,
      'corpCode': corpCode,
      if (companyId != null) 'companyId': companyId,
      'corpName': corpName,
      'reportName': reportName,
      'receivedDate': receivedDate.toJson(),
      if (filerName != null) 'filerName': filerName,
      'discoveredAt': discoveredAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DartDisclosure',
      if (id != null) 'id': id,
      'rceptNo': rceptNo,
      'corpCode': corpCode,
      if (companyId != null) 'companyId': companyId,
      'corpName': corpName,
      'reportName': reportName,
      'receivedDate': receivedDate.toJson(),
      if (filerName != null) 'filerName': filerName,
      'discoveredAt': discoveredAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DartDisclosureImpl extends DartDisclosure {
  _DartDisclosureImpl({
    int? id,
    required String rceptNo,
    required String corpCode,
    int? companyId,
    required String corpName,
    required String reportName,
    required DateTime receivedDate,
    String? filerName,
    required DateTime discoveredAt,
  }) : super._(
         id: id,
         rceptNo: rceptNo,
         corpCode: corpCode,
         companyId: companyId,
         corpName: corpName,
         reportName: reportName,
         receivedDate: receivedDate,
         filerName: filerName,
         discoveredAt: discoveredAt,
       );

  /// Returns a shallow copy of this [DartDisclosure]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DartDisclosure copyWith({
    Object? id = _Undefined,
    String? rceptNo,
    String? corpCode,
    Object? companyId = _Undefined,
    String? corpName,
    String? reportName,
    DateTime? receivedDate,
    Object? filerName = _Undefined,
    DateTime? discoveredAt,
  }) {
    return DartDisclosure(
      id: id is int? ? id : this.id,
      rceptNo: rceptNo ?? this.rceptNo,
      corpCode: corpCode ?? this.corpCode,
      companyId: companyId is int? ? companyId : this.companyId,
      corpName: corpName ?? this.corpName,
      reportName: reportName ?? this.reportName,
      receivedDate: receivedDate ?? this.receivedDate,
      filerName: filerName is String? ? filerName : this.filerName,
      discoveredAt: discoveredAt ?? this.discoveredAt,
    );
  }
}
