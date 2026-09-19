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
import '../../ontology/models/financial_fact.dart' as _iy7yplk2;
import '../../ontology/models/financial_report.dart' as _irspo4dx;
import '../../ontology/models/source.dart' as _i5ra8lvy;

/// 재무 보고서 원문 표: 보고서의 모든 사실과 같은 기간의 정정 이력.
abstract class FinancialReportDetail
    implements _is.SerializableModel, _is.ProtocolSerialization {
  FinancialReportDetail._({
    required this.report,
    this.source,
    required this.facts,
    required this.history,
  });

  factory FinancialReportDetail({
    required _irspo4dx.FinancialReport report,
    _i5ra8lvy.Source? source,
    required List<_iy7yplk2.FinancialFact> facts,
    required List<_irspo4dx.FinancialReport> history,
  }) = _FinancialReportDetailImpl;

  factory FinancialReportDetail.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return FinancialReportDetail(
      report: _i4yshtjp.Protocol().deserialize<_irspo4dx.FinancialReport>(
        jsonSerialization['report'],
      ),
      source: jsonSerialization['source'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<_i5ra8lvy.Source>(
              jsonSerialization['source'],
            ),
      facts: _i4yshtjp.Protocol().deserialize<List<_iy7yplk2.FinancialFact>>(
        jsonSerialization['facts'],
      ),
      history: _i4yshtjp.Protocol()
          .deserialize<List<_irspo4dx.FinancialReport>>(
            jsonSerialization['history'],
          ),
    );
  }

  _irspo4dx.FinancialReport report;

  _i5ra8lvy.Source? source;

  List<_iy7yplk2.FinancialFact> facts;

  /// 같은 기업·기간·연결구분의 보고서 (접수번호 순, 이 보고서 포함)
  List<_irspo4dx.FinancialReport> history;

  /// Returns a shallow copy of this [FinancialReportDetail]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FinancialReportDetail copyWith({
    _irspo4dx.FinancialReport? report,
    _i5ra8lvy.Source? source,
    List<_iy7yplk2.FinancialFact>? facts,
    List<_irspo4dx.FinancialReport>? history,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FinancialReportDetail',
      'report': report.toJson(),
      if (source != null) 'source': source?.toJson(),
      'facts': facts.toJson(valueToJson: (v) => v.toJson()),
      'history': history.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FinancialReportDetail',
      'report': report.toJsonForProtocol(),
      if (source != null) 'source': source?.toJsonForProtocol(),
      'facts': facts.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'history': history.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FinancialReportDetailImpl extends FinancialReportDetail {
  _FinancialReportDetailImpl({
    required _irspo4dx.FinancialReport report,
    _i5ra8lvy.Source? source,
    required List<_iy7yplk2.FinancialFact> facts,
    required List<_irspo4dx.FinancialReport> history,
  }) : super._(
         report: report,
         source: source,
         facts: facts,
         history: history,
       );

  /// Returns a shallow copy of this [FinancialReportDetail]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FinancialReportDetail copyWith({
    _irspo4dx.FinancialReport? report,
    Object? source = _Undefined,
    List<_iy7yplk2.FinancialFact>? facts,
    List<_irspo4dx.FinancialReport>? history,
  }) {
    return FinancialReportDetail(
      report: report ?? this.report.copyWith(),
      source: source is _i5ra8lvy.Source? ? source : this.source?.copyWith(),
      facts: facts ?? this.facts.map((e0) => e0.copyWith()).toList(),
      history: history ?? this.history.map((e0) => e0.copyWith()).toList(),
    );
  }
}
