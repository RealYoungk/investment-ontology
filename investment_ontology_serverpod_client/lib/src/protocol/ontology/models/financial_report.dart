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
import '../../ontology/models/financial_report_code.dart' as _i6mbh8k5;
import '../../ontology/models/fs_div.dart' as _igqrlzji;

/// 재무 보고서: 공시 1건의 연결 또는 별도 재무제표 한 벌. FinancialFact를 묶는다.
/// 정정공시로 대체되면 지우지 않고 supersededBy로 새 보고서를 가리킨다.
abstract class FinancialReport
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  FinancialReport._({
    this.id,
    required this.companyId,
    required this.rceptNo,
    required this.fsDiv,
    required this.bsnsYear,
    required this.reportCode,
    required this.reportName,
    this.receivedDate,
    required this.factCount,
    int? invalidAmountCount,
    required this.sourceId,
    this.supersededById,
    required this.fetchedAt,
  }) : invalidAmountCount = invalidAmountCount ?? 0;

  factory FinancialReport({
    int? id,
    required int companyId,
    required String rceptNo,
    required _igqrlzji.FsDiv fsDiv,
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    required String reportName,
    DateTime? receivedDate,
    required int factCount,
    int? invalidAmountCount,
    required int sourceId,
    int? supersededById,
    required DateTime fetchedAt,
  }) = _FinancialReportImpl;

  factory FinancialReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return FinancialReport(
      id: jsonSerialization['id'] as int?,
      companyId: jsonSerialization['companyId'] as int,
      rceptNo: jsonSerialization['rceptNo'] as String,
      fsDiv: _igqrlzji.FsDiv.fromJson((jsonSerialization['fsDiv'] as String)),
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      reportCode: _i6mbh8k5.FinancialReportCode.fromJson(
        (jsonSerialization['reportCode'] as String),
      ),
      reportName: jsonSerialization['reportName'] as String,
      receivedDate: jsonSerialization['receivedDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['receivedDate'],
            ),
      factCount: jsonSerialization['factCount'] as int,
      invalidAmountCount: jsonSerialization['invalidAmountCount'] as int?,
      sourceId: jsonSerialization['sourceId'] as int,
      supersededById: jsonSerialization['supersededById'] as int?,
      fetchedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int companyId;

  /// 재무 API 응답의 접수번호. 이 숫자들이 실린 공시
  String rceptNo;

  _igqrlzji.FsDiv fsDiv;

  int bsnsYear;

  _i6mbh8k5.FinancialReportCode reportCode;

  String reportName;

  DateTime? receivedDate;

  int factCount;

  /// 원천 값이 있었지만 원 단위 정수가 아니어서 비워 둔 금액 수
  int invalidAmountCount;

  int sourceId;

  int? supersededById;

  DateTime fetchedAt;

  /// Returns a shallow copy of this [FinancialReport]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  FinancialReport copyWith({
    int? id,
    int? companyId,
    String? rceptNo,
    _igqrlzji.FsDiv? fsDiv,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    String? reportName,
    DateTime? receivedDate,
    int? factCount,
    int? invalidAmountCount,
    int? sourceId,
    int? supersededById,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FinancialReport',
      if (id != null) 'id': id,
      'companyId': companyId,
      'rceptNo': rceptNo,
      'fsDiv': fsDiv.toJson(),
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      'reportName': reportName,
      if (receivedDate != null) 'receivedDate': receivedDate?.toJson(),
      'factCount': factCount,
      'invalidAmountCount': invalidAmountCount,
      'sourceId': sourceId,
      if (supersededById != null) 'supersededById': supersededById,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FinancialReport',
      if (id != null) 'id': id,
      'companyId': companyId,
      'rceptNo': rceptNo,
      'fsDiv': fsDiv.toJson(),
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      'reportName': reportName,
      if (receivedDate != null) 'receivedDate': receivedDate?.toJson(),
      'factCount': factCount,
      'invalidAmountCount': invalidAmountCount,
      'sourceId': sourceId,
      if (supersededById != null) 'supersededById': supersededById,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FinancialReportImpl extends FinancialReport {
  _FinancialReportImpl({
    int? id,
    required int companyId,
    required String rceptNo,
    required _igqrlzji.FsDiv fsDiv,
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    required String reportName,
    DateTime? receivedDate,
    required int factCount,
    int? invalidAmountCount,
    required int sourceId,
    int? supersededById,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         companyId: companyId,
         rceptNo: rceptNo,
         fsDiv: fsDiv,
         bsnsYear: bsnsYear,
         reportCode: reportCode,
         reportName: reportName,
         receivedDate: receivedDate,
         factCount: factCount,
         invalidAmountCount: invalidAmountCount,
         sourceId: sourceId,
         supersededById: supersededById,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [FinancialReport]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  FinancialReport copyWith({
    Object? id = _Undefined,
    int? companyId,
    String? rceptNo,
    _igqrlzji.FsDiv? fsDiv,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    String? reportName,
    Object? receivedDate = _Undefined,
    int? factCount,
    int? invalidAmountCount,
    int? sourceId,
    Object? supersededById = _Undefined,
    DateTime? fetchedAt,
  }) {
    return FinancialReport(
      id: id is int? ? id : this.id,
      companyId: companyId ?? this.companyId,
      rceptNo: rceptNo ?? this.rceptNo,
      fsDiv: fsDiv ?? this.fsDiv,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      reportCode: reportCode ?? this.reportCode,
      reportName: reportName ?? this.reportName,
      receivedDate: receivedDate is DateTime?
          ? receivedDate
          : this.receivedDate,
      factCount: factCount ?? this.factCount,
      invalidAmountCount: invalidAmountCount ?? this.invalidAmountCount,
      sourceId: sourceId ?? this.sourceId,
      supersededById: supersededById is int?
          ? supersededById
          : this.supersededById,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}
