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
import 'package:investment_ontology_serverpod_client/src/protocol/protocol.dart'
    as _ilkzeueu;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../ontology/models/financial_report_code.dart' as _i6mbh8k5;
import '../../ontology/models/shareholder_entry.dart' as _i2z9gcy6;
import '../../ontology/models/source.dart' as _i5ra8lvy;

/// 공시별 최대주주 현황. 미수집 보고서도 빈 행으로 표시한다.
abstract class OwnershipSnapshot
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  OwnershipSnapshot._({
    required this.bsnsYear,
    required this.reportCode,
    required this.reportName,
    required this.rceptNo,
    this.periodStart,
    this.periodEnd,
    required this.collected,
    required this.shareholders,
    this.source,
  });

  factory OwnershipSnapshot({
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    required String reportName,
    required String rceptNo,
    DateTime? periodStart,
    DateTime? periodEnd,
    required bool collected,
    required List<_i2z9gcy6.ShareholderEntry> shareholders,
    _i5ra8lvy.Source? source,
  }) = _OwnershipSnapshotImpl;

  factory OwnershipSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return OwnershipSnapshot(
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      reportCode: _i6mbh8k5.FinancialReportCode.fromJson(
        (jsonSerialization['reportCode'] as String),
      ),
      reportName: jsonSerialization['reportName'] as String,
      rceptNo: jsonSerialization['rceptNo'] as String,
      periodStart: jsonSerialization['periodStart'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['periodStart'],
            ),
      periodEnd: jsonSerialization['periodEnd'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['periodEnd']),
      collected: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['collected'],
      ),
      shareholders: _ilkzeueu.Protocol()
          .deserialize<List<_i2z9gcy6.ShareholderEntry>>(
            jsonSerialization['shareholders'],
          ),
      source: jsonSerialization['source'] == null
          ? null
          : _ilkzeueu.Protocol().deserialize<_i5ra8lvy.Source>(
              jsonSerialization['source'],
            ),
    );
  }

  int bsnsYear;

  _i6mbh8k5.FinancialReportCode reportCode;

  String reportName;

  String rceptNo;

  DateTime? periodStart;

  DateTime? periodEnd;

  bool collected;

  List<_i2z9gcy6.ShareholderEntry> shareholders;

  _i5ra8lvy.Source? source;

  /// Returns a shallow copy of this [OwnershipSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  OwnershipSnapshot copyWith({
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    String? reportName,
    String? rceptNo,
    DateTime? periodStart,
    DateTime? periodEnd,
    bool? collected,
    List<_i2z9gcy6.ShareholderEntry>? shareholders,
    _i5ra8lvy.Source? source,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OwnershipSnapshot',
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      'reportName': reportName,
      'rceptNo': rceptNo,
      if (periodStart != null) 'periodStart': periodStart?.toJson(),
      if (periodEnd != null) 'periodEnd': periodEnd?.toJson(),
      'collected': collected,
      'shareholders': shareholders.toJson(valueToJson: (v) => v.toJson()),
      if (source != null) 'source': source?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OwnershipSnapshot',
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      'reportName': reportName,
      'rceptNo': rceptNo,
      if (periodStart != null) 'periodStart': periodStart?.toJson(),
      if (periodEnd != null) 'periodEnd': periodEnd?.toJson(),
      'collected': collected,
      'shareholders': shareholders.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      if (source != null) 'source': source?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OwnershipSnapshotImpl extends OwnershipSnapshot {
  _OwnershipSnapshotImpl({
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    required String reportName,
    required String rceptNo,
    DateTime? periodStart,
    DateTime? periodEnd,
    required bool collected,
    required List<_i2z9gcy6.ShareholderEntry> shareholders,
    _i5ra8lvy.Source? source,
  }) : super._(
         bsnsYear: bsnsYear,
         reportCode: reportCode,
         reportName: reportName,
         rceptNo: rceptNo,
         periodStart: periodStart,
         periodEnd: periodEnd,
         collected: collected,
         shareholders: shareholders,
         source: source,
       );

  /// Returns a shallow copy of this [OwnershipSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  OwnershipSnapshot copyWith({
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    String? reportName,
    String? rceptNo,
    Object? periodStart = _Undefined,
    Object? periodEnd = _Undefined,
    bool? collected,
    List<_i2z9gcy6.ShareholderEntry>? shareholders,
    Object? source = _Undefined,
  }) {
    return OwnershipSnapshot(
      bsnsYear: bsnsYear ?? this.bsnsYear,
      reportCode: reportCode ?? this.reportCode,
      reportName: reportName ?? this.reportName,
      rceptNo: rceptNo ?? this.rceptNo,
      periodStart: periodStart is DateTime? ? periodStart : this.periodStart,
      periodEnd: periodEnd is DateTime? ? periodEnd : this.periodEnd,
      collected: collected ?? this.collected,
      shareholders:
          shareholders ?? this.shareholders.map((e0) => e0.copyWith()).toList(),
      source: source is _i5ra8lvy.Source? ? source : this.source?.copyWith(),
    );
  }
}
