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
import 'package:serverpod/serverpod.dart' as _is;
import '../../ontology/models/financial_report_code.dart' as _i6mbh8k5;

/// Active business-document period metadata for time-series gaps and bases.
abstract class BusinessFactPeriod
    implements _is.SerializableModel, _is.ProtocolSerialization {
  BusinessFactPeriod._({
    required this.documentId,
    required this.bsnsYear,
    required this.reportCode,
    required this.periodEnd,
  });

  factory BusinessFactPeriod({
    required int documentId,
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    required DateTime periodEnd,
  }) = _BusinessFactPeriodImpl;

  factory BusinessFactPeriod.fromJson(Map<String, dynamic> jsonSerialization) {
    return BusinessFactPeriod(
      documentId: jsonSerialization['documentId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      reportCode: _i6mbh8k5.FinancialReportCode.fromJson(
        (jsonSerialization['reportCode'] as String),
      ),
      periodEnd: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['periodEnd'],
      ),
    );
  }

  int documentId;

  int bsnsYear;

  _i6mbh8k5.FinancialReportCode reportCode;

  DateTime periodEnd;

  /// Returns a shallow copy of this [BusinessFactPeriod]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BusinessFactPeriod copyWith({
    int? documentId,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    DateTime? periodEnd,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BusinessFactPeriod',
      'documentId': documentId,
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      'periodEnd': periodEnd.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BusinessFactPeriod',
      'documentId': documentId,
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      'periodEnd': periodEnd.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _BusinessFactPeriodImpl extends BusinessFactPeriod {
  _BusinessFactPeriodImpl({
    required int documentId,
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    required DateTime periodEnd,
  }) : super._(
         documentId: documentId,
         bsnsYear: bsnsYear,
         reportCode: reportCode,
         periodEnd: periodEnd,
       );

  /// Returns a shallow copy of this [BusinessFactPeriod]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BusinessFactPeriod copyWith({
    int? documentId,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    DateTime? periodEnd,
  }) {
    return BusinessFactPeriod(
      documentId: documentId ?? this.documentId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      reportCode: reportCode ?? this.reportCode,
      periodEnd: periodEnd ?? this.periodEnd,
    );
  }
}
