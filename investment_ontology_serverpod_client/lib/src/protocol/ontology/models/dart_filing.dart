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
import '../../ontology/models/filing_fetch_status.dart' as _iy9345ub;
import '../../ontology/models/financial_report_code.dart' as _i6mbh8k5;

/// 수집 장부: DART 공시 목록(list.json)에서 찾은 상장사 정기보고서.
/// 온톨로지 엔티티가 아니라, 어떤 보고서를 받았고 받을지 기록한다.
abstract class DartFiling
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DartFiling._({
    this.id,
    required this.rceptNo,
    required this.corpCode,
    this.companyId,
    required this.reportName,
    this.receivedDate,
    this.bsnsYear,
    this.reportCode,
    required this.consolidatedStatus,
    required this.separateStatus,
    int? attempts,
    this.lastError,
    required this.discoveredAt,
    this.checkedAt,
  }) : attempts = attempts ?? 0;

  factory DartFiling({
    int? id,
    required String rceptNo,
    required String corpCode,
    int? companyId,
    required String reportName,
    DateTime? receivedDate,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    required _iy9345ub.FilingFetchStatus consolidatedStatus,
    required _iy9345ub.FilingFetchStatus separateStatus,
    int? attempts,
    String? lastError,
    required DateTime discoveredAt,
    DateTime? checkedAt,
  }) = _DartFilingImpl;

  factory DartFiling.fromJson(Map<String, dynamic> jsonSerialization) {
    return DartFiling(
      id: jsonSerialization['id'] as int?,
      rceptNo: jsonSerialization['rceptNo'] as String,
      corpCode: jsonSerialization['corpCode'] as String,
      companyId: jsonSerialization['companyId'] as int?,
      reportName: jsonSerialization['reportName'] as String,
      receivedDate: jsonSerialization['receivedDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['receivedDate'],
            ),
      bsnsYear: jsonSerialization['bsnsYear'] as int?,
      reportCode: jsonSerialization['reportCode'] == null
          ? null
          : _i6mbh8k5.FinancialReportCode.fromJson(
              (jsonSerialization['reportCode'] as String),
            ),
      consolidatedStatus: _iy9345ub.FilingFetchStatus.fromJson(
        (jsonSerialization['consolidatedStatus'] as String),
      ),
      separateStatus: _iy9345ub.FilingFetchStatus.fromJson(
        (jsonSerialization['separateStatus'] as String),
      ),
      attempts: jsonSerialization['attempts'] as int?,
      lastError: jsonSerialization['lastError'] as String?,
      discoveredAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['discoveredAt'],
      ),
      checkedAt: jsonSerialization['checkedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['checkedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// 공시 접수번호 (14자리)
  String rceptNo;

  String corpCode;

  int? companyId;

  /// 예: "[기재정정]사업보고서 (2025.12)"
  String reportName;

  /// 접수일 (UTC 자정)
  DateTime? receivedDate;

  int? bsnsYear;

  _i6mbh8k5.FinancialReportCode? reportCode;

  _iy9345ub.FilingFetchStatus consolidatedStatus;

  _iy9345ub.FilingFetchStatus separateStatus;

  /// 실패한 호출 수 (연결·별도 합산)
  int attempts;

  String? lastError;

  DateTime discoveredAt;

  DateTime? checkedAt;

  /// Returns a shallow copy of this [DartFiling]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DartFiling copyWith({
    int? id,
    String? rceptNo,
    String? corpCode,
    int? companyId,
    String? reportName,
    DateTime? receivedDate,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    _iy9345ub.FilingFetchStatus? consolidatedStatus,
    _iy9345ub.FilingFetchStatus? separateStatus,
    int? attempts,
    String? lastError,
    DateTime? discoveredAt,
    DateTime? checkedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DartFiling',
      if (id != null) 'id': id,
      'rceptNo': rceptNo,
      'corpCode': corpCode,
      if (companyId != null) 'companyId': companyId,
      'reportName': reportName,
      if (receivedDate != null) 'receivedDate': receivedDate?.toJson(),
      if (bsnsYear != null) 'bsnsYear': bsnsYear,
      if (reportCode != null) 'reportCode': reportCode?.toJson(),
      'consolidatedStatus': consolidatedStatus.toJson(),
      'separateStatus': separateStatus.toJson(),
      'attempts': attempts,
      if (lastError != null) 'lastError': lastError,
      'discoveredAt': discoveredAt.toJson(),
      if (checkedAt != null) 'checkedAt': checkedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DartFiling',
      if (id != null) 'id': id,
      'rceptNo': rceptNo,
      'corpCode': corpCode,
      if (companyId != null) 'companyId': companyId,
      'reportName': reportName,
      if (receivedDate != null) 'receivedDate': receivedDate?.toJson(),
      if (bsnsYear != null) 'bsnsYear': bsnsYear,
      if (reportCode != null) 'reportCode': reportCode?.toJson(),
      'consolidatedStatus': consolidatedStatus.toJson(),
      'separateStatus': separateStatus.toJson(),
      'attempts': attempts,
      if (lastError != null) 'lastError': lastError,
      'discoveredAt': discoveredAt.toJson(),
      if (checkedAt != null) 'checkedAt': checkedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DartFilingImpl extends DartFiling {
  _DartFilingImpl({
    int? id,
    required String rceptNo,
    required String corpCode,
    int? companyId,
    required String reportName,
    DateTime? receivedDate,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    required _iy9345ub.FilingFetchStatus consolidatedStatus,
    required _iy9345ub.FilingFetchStatus separateStatus,
    int? attempts,
    String? lastError,
    required DateTime discoveredAt,
    DateTime? checkedAt,
  }) : super._(
         id: id,
         rceptNo: rceptNo,
         corpCode: corpCode,
         companyId: companyId,
         reportName: reportName,
         receivedDate: receivedDate,
         bsnsYear: bsnsYear,
         reportCode: reportCode,
         consolidatedStatus: consolidatedStatus,
         separateStatus: separateStatus,
         attempts: attempts,
         lastError: lastError,
         discoveredAt: discoveredAt,
         checkedAt: checkedAt,
       );

  /// Returns a shallow copy of this [DartFiling]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DartFiling copyWith({
    Object? id = _Undefined,
    String? rceptNo,
    String? corpCode,
    Object? companyId = _Undefined,
    String? reportName,
    Object? receivedDate = _Undefined,
    Object? bsnsYear = _Undefined,
    Object? reportCode = _Undefined,
    _iy9345ub.FilingFetchStatus? consolidatedStatus,
    _iy9345ub.FilingFetchStatus? separateStatus,
    int? attempts,
    Object? lastError = _Undefined,
    DateTime? discoveredAt,
    Object? checkedAt = _Undefined,
  }) {
    return DartFiling(
      id: id is int? ? id : this.id,
      rceptNo: rceptNo ?? this.rceptNo,
      corpCode: corpCode ?? this.corpCode,
      companyId: companyId is int? ? companyId : this.companyId,
      reportName: reportName ?? this.reportName,
      receivedDate: receivedDate is DateTime?
          ? receivedDate
          : this.receivedDate,
      bsnsYear: bsnsYear is int? ? bsnsYear : this.bsnsYear,
      reportCode: reportCode is _i6mbh8k5.FinancialReportCode?
          ? reportCode
          : this.reportCode,
      consolidatedStatus: consolidatedStatus ?? this.consolidatedStatus,
      separateStatus: separateStatus ?? this.separateStatus,
      attempts: attempts ?? this.attempts,
      lastError: lastError is String? ? lastError : this.lastError,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      checkedAt: checkedAt is DateTime? ? checkedAt : this.checkedAt,
    );
  }
}
