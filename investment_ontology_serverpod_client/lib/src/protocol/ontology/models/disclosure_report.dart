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
import '../../ontology/models/dart_section.dart' as _iy0bhrwp;
import '../../ontology/models/financial_report_code.dart' as _i6mbh8k5;

/// 정기보고서 한 건의 주요정보 항목 하나. 응답 행(DisclosureRow)을 묶는다.
/// 정정공시로 대체되면 지우지 않고 supersededBy로 새 보고서를 가리킨다.
abstract class DisclosureReport
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DisclosureReport._({
    this.id,
    required this.companyId,
    required this.section,
    required this.rceptNo,
    required this.bsnsYear,
    required this.reportCode,
    this.settlementDate,
    required this.rowCount,
    int? emptyRowCount,
    required this.sourceId,
    this.supersededById,
    required this.fetchedAt,
  }) : emptyRowCount = emptyRowCount ?? 0;

  factory DisclosureReport({
    int? id,
    required int companyId,
    required _iy0bhrwp.DartSection section,
    required String rceptNo,
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    DateTime? settlementDate,
    required int rowCount,
    int? emptyRowCount,
    required int sourceId,
    int? supersededById,
    required DateTime fetchedAt,
  }) = _DisclosureReportImpl;

  factory DisclosureReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return DisclosureReport(
      id: jsonSerialization['id'] as int?,
      companyId: jsonSerialization['companyId'] as int,
      section: _iy0bhrwp.DartSection.fromJson(
        (jsonSerialization['section'] as String),
      ),
      rceptNo: jsonSerialization['rceptNo'] as String,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      reportCode: _i6mbh8k5.FinancialReportCode.fromJson(
        (jsonSerialization['reportCode'] as String),
      ),
      settlementDate: jsonSerialization['settlementDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['settlementDate'],
            ),
      rowCount: jsonSerialization['rowCount'] as int,
      emptyRowCount: jsonSerialization['emptyRowCount'] as int?,
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

  _iy0bhrwp.DartSection section;

  /// 응답의 접수번호. 이 값들이 실린 공시
  String rceptNo;

  int bsnsYear;

  _i6mbh8k5.FinancialReportCode reportCode;

  /// 응답의 결산기준일 (stlm_dt, UTC 자정) — 관계의 기준일
  DateTime? settlementDate;

  /// 저장한 행 수 (값이 모두 '-'인 빈 줄 제외)
  int rowCount;

  /// 값이 모두 '-'여서 저장하지 않은 빈 줄 수
  int emptyRowCount;

  int sourceId;

  int? supersededById;

  DateTime fetchedAt;

  /// Returns a shallow copy of this [DisclosureReport]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DisclosureReport copyWith({
    int? id,
    int? companyId,
    _iy0bhrwp.DartSection? section,
    String? rceptNo,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    DateTime? settlementDate,
    int? rowCount,
    int? emptyRowCount,
    int? sourceId,
    int? supersededById,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DisclosureReport',
      if (id != null) 'id': id,
      'companyId': companyId,
      'section': section.toJson(),
      'rceptNo': rceptNo,
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      if (settlementDate != null) 'settlementDate': settlementDate?.toJson(),
      'rowCount': rowCount,
      'emptyRowCount': emptyRowCount,
      'sourceId': sourceId,
      if (supersededById != null) 'supersededById': supersededById,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DisclosureReport',
      if (id != null) 'id': id,
      'companyId': companyId,
      'section': section.toJson(),
      'rceptNo': rceptNo,
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      if (settlementDate != null) 'settlementDate': settlementDate?.toJson(),
      'rowCount': rowCount,
      'emptyRowCount': emptyRowCount,
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

class _DisclosureReportImpl extends DisclosureReport {
  _DisclosureReportImpl({
    int? id,
    required int companyId,
    required _iy0bhrwp.DartSection section,
    required String rceptNo,
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    DateTime? settlementDate,
    required int rowCount,
    int? emptyRowCount,
    required int sourceId,
    int? supersededById,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         companyId: companyId,
         section: section,
         rceptNo: rceptNo,
         bsnsYear: bsnsYear,
         reportCode: reportCode,
         settlementDate: settlementDate,
         rowCount: rowCount,
         emptyRowCount: emptyRowCount,
         sourceId: sourceId,
         supersededById: supersededById,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [DisclosureReport]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DisclosureReport copyWith({
    Object? id = _Undefined,
    int? companyId,
    _iy0bhrwp.DartSection? section,
    String? rceptNo,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    Object? settlementDate = _Undefined,
    int? rowCount,
    int? emptyRowCount,
    int? sourceId,
    Object? supersededById = _Undefined,
    DateTime? fetchedAt,
  }) {
    return DisclosureReport(
      id: id is int? ? id : this.id,
      companyId: companyId ?? this.companyId,
      section: section ?? this.section,
      rceptNo: rceptNo ?? this.rceptNo,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      reportCode: reportCode ?? this.reportCode,
      settlementDate: settlementDate is DateTime?
          ? settlementDate
          : this.settlementDate,
      rowCount: rowCount ?? this.rowCount,
      emptyRowCount: emptyRowCount ?? this.emptyRowCount,
      sourceId: sourceId ?? this.sourceId,
      supersededById: supersededById is int?
          ? supersededById
          : this.supersededById,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}
