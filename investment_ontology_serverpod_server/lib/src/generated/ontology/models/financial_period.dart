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
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart'
    as _i4yshtjp;
import 'package:serverpod/serverpod.dart' as _is;

import '../../ontology/models/financial_line.dart' as _iub4r7it;
import '../../ontology/models/financial_report_code.dart' as _i6mbh8k5;

/// 한 보고 기간(사업연도 × 보고서 코드)의 현재 보고서와 핵심 계정.
abstract class FinancialPeriod
    implements _is.SerializableModel, _is.ProtocolSerialization {
  FinancialPeriod._({
    required this.bsnsYear,
    required this.reportCode,
    required this.reportId,
    required this.rceptNo,
    required this.reportName,
    this.receivedDate,
    this.periodName,
    required this.supersededCount,
    required this.lines,
  });

  factory FinancialPeriod({
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    required int reportId,
    required String rceptNo,
    required String reportName,
    DateTime? receivedDate,
    String? periodName,
    required int supersededCount,
    required List<_iub4r7it.FinancialLine> lines,
  }) = _FinancialPeriodImpl;

  factory FinancialPeriod.fromJson(Map<String, dynamic> jsonSerialization) {
    return FinancialPeriod(
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      reportCode: _i6mbh8k5.FinancialReportCode.fromJson(
        (jsonSerialization['reportCode'] as String),
      ),
      reportId: jsonSerialization['reportId'] as int,
      rceptNo: jsonSerialization['rceptNo'] as String,
      reportName: jsonSerialization['reportName'] as String,
      receivedDate: jsonSerialization['receivedDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['receivedDate'],
            ),
      periodName: jsonSerialization['periodName'] as String?,
      supersededCount: jsonSerialization['supersededCount'] as int,
      lines: _i4yshtjp.Protocol().deserialize<List<_iub4r7it.FinancialLine>>(
        jsonSerialization['lines'],
      ),
    );
  }

  int bsnsYear;

  _i6mbh8k5.FinancialReportCode reportCode;

  int reportId;

  String rceptNo;

  String reportName;

  DateTime? receivedDate;

  /// 예: "제 57 기", "제 58 기 반기"
  String? periodName;

  /// 정정으로 대체된 이전 보고서 수
  int supersededCount;

  List<_iub4r7it.FinancialLine> lines;

  /// Returns a shallow copy of this [FinancialPeriod]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FinancialPeriod copyWith({
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    int? reportId,
    String? rceptNo,
    String? reportName,
    DateTime? receivedDate,
    String? periodName,
    int? supersededCount,
    List<_iub4r7it.FinancialLine>? lines,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FinancialPeriod',
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      'reportId': reportId,
      'rceptNo': rceptNo,
      'reportName': reportName,
      if (receivedDate != null) 'receivedDate': receivedDate?.toJson(),
      if (periodName != null) 'periodName': periodName,
      'supersededCount': supersededCount,
      'lines': lines.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FinancialPeriod',
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      'reportId': reportId,
      'rceptNo': rceptNo,
      'reportName': reportName,
      if (receivedDate != null) 'receivedDate': receivedDate?.toJson(),
      if (periodName != null) 'periodName': periodName,
      'supersededCount': supersededCount,
      'lines': lines.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FinancialPeriodImpl extends FinancialPeriod {
  _FinancialPeriodImpl({
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    required int reportId,
    required String rceptNo,
    required String reportName,
    DateTime? receivedDate,
    String? periodName,
    required int supersededCount,
    required List<_iub4r7it.FinancialLine> lines,
  }) : super._(
         bsnsYear: bsnsYear,
         reportCode: reportCode,
         reportId: reportId,
         rceptNo: rceptNo,
         reportName: reportName,
         receivedDate: receivedDate,
         periodName: periodName,
         supersededCount: supersededCount,
         lines: lines,
       );

  /// Returns a shallow copy of this [FinancialPeriod]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FinancialPeriod copyWith({
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    int? reportId,
    String? rceptNo,
    String? reportName,
    Object? receivedDate = _Undefined,
    Object? periodName = _Undefined,
    int? supersededCount,
    List<_iub4r7it.FinancialLine>? lines,
  }) {
    return FinancialPeriod(
      bsnsYear: bsnsYear ?? this.bsnsYear,
      reportCode: reportCode ?? this.reportCode,
      reportId: reportId ?? this.reportId,
      rceptNo: rceptNo ?? this.rceptNo,
      reportName: reportName ?? this.reportName,
      receivedDate: receivedDate is DateTime?
          ? receivedDate
          : this.receivedDate,
      periodName: periodName is String? ? periodName : this.periodName,
      supersededCount: supersededCount ?? this.supersededCount,
      lines: lines ?? this.lines.map((e0) => e0.copyWith()).toList(),
    );
  }
}
