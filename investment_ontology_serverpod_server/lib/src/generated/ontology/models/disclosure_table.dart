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
import '../../ontology/models/dart_section.dart' as _iy0bhrwp;
import '../../ontology/models/disclosure_table_row.dart' as _iib1bouo;
import '../../ontology/models/source.dart' as _i5ra8lvy;

/// 주요정보 항목 하나의 원문 표 (응답 필드 그대로, 머리글만 한글로).
abstract class DisclosureTable
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DisclosureTable._({
    required this.section,
    required this.label,
    required this.bsnsYear,
    required this.rceptNo,
    this.settlementDate,
    required this.headers,
    required this.rows,
    required this.emptyRowCount,
    this.source,
    required this.years,
  });

  factory DisclosureTable({
    required _iy0bhrwp.DartSection section,
    required String label,
    required int bsnsYear,
    required String rceptNo,
    DateTime? settlementDate,
    required List<String> headers,
    required List<_iib1bouo.DisclosureTableRow> rows,
    required int emptyRowCount,
    _i5ra8lvy.Source? source,
    required List<int> years,
  }) = _DisclosureTableImpl;

  factory DisclosureTable.fromJson(Map<String, dynamic> jsonSerialization) {
    return DisclosureTable(
      section: _iy0bhrwp.DartSection.fromJson(
        (jsonSerialization['section'] as String),
      ),
      label: jsonSerialization['label'] as String,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      rceptNo: jsonSerialization['rceptNo'] as String,
      settlementDate: jsonSerialization['settlementDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['settlementDate'],
            ),
      headers: _i4yshtjp.Protocol().deserialize<List<String>>(
        jsonSerialization['headers'],
      ),
      rows: _i4yshtjp.Protocol()
          .deserialize<List<_iib1bouo.DisclosureTableRow>>(
            jsonSerialization['rows'],
          ),
      emptyRowCount: jsonSerialization['emptyRowCount'] as int,
      source: jsonSerialization['source'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<_i5ra8lvy.Source>(
              jsonSerialization['source'],
            ),
      years: _i4yshtjp.Protocol().deserialize<List<int>>(
        jsonSerialization['years'],
      ),
    );
  }

  _iy0bhrwp.DartSection section;

  String label;

  int bsnsYear;

  String rceptNo;

  DateTime? settlementDate;

  List<String> headers;

  List<_iib1bouo.DisclosureTableRow> rows;

  int emptyRowCount;

  _i5ra8lvy.Source? source;

  List<int> years;

  /// Returns a shallow copy of this [DisclosureTable]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DisclosureTable copyWith({
    _iy0bhrwp.DartSection? section,
    String? label,
    int? bsnsYear,
    String? rceptNo,
    DateTime? settlementDate,
    List<String>? headers,
    List<_iib1bouo.DisclosureTableRow>? rows,
    int? emptyRowCount,
    _i5ra8lvy.Source? source,
    List<int>? years,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DisclosureTable',
      'section': section.toJson(),
      'label': label,
      'bsnsYear': bsnsYear,
      'rceptNo': rceptNo,
      if (settlementDate != null) 'settlementDate': settlementDate?.toJson(),
      'headers': headers.toJson(),
      'rows': rows.toJson(valueToJson: (v) => v.toJson()),
      'emptyRowCount': emptyRowCount,
      if (source != null) 'source': source?.toJson(),
      'years': years.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DisclosureTable',
      'section': section.toJson(),
      'label': label,
      'bsnsYear': bsnsYear,
      'rceptNo': rceptNo,
      if (settlementDate != null) 'settlementDate': settlementDate?.toJson(),
      'headers': headers.toJson(),
      'rows': rows.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'emptyRowCount': emptyRowCount,
      if (source != null) 'source': source?.toJsonForProtocol(),
      'years': years.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DisclosureTableImpl extends DisclosureTable {
  _DisclosureTableImpl({
    required _iy0bhrwp.DartSection section,
    required String label,
    required int bsnsYear,
    required String rceptNo,
    DateTime? settlementDate,
    required List<String> headers,
    required List<_iib1bouo.DisclosureTableRow> rows,
    required int emptyRowCount,
    _i5ra8lvy.Source? source,
    required List<int> years,
  }) : super._(
         section: section,
         label: label,
         bsnsYear: bsnsYear,
         rceptNo: rceptNo,
         settlementDate: settlementDate,
         headers: headers,
         rows: rows,
         emptyRowCount: emptyRowCount,
         source: source,
         years: years,
       );

  /// Returns a shallow copy of this [DisclosureTable]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DisclosureTable copyWith({
    _iy0bhrwp.DartSection? section,
    String? label,
    int? bsnsYear,
    String? rceptNo,
    Object? settlementDate = _Undefined,
    List<String>? headers,
    List<_iib1bouo.DisclosureTableRow>? rows,
    int? emptyRowCount,
    Object? source = _Undefined,
    List<int>? years,
  }) {
    return DisclosureTable(
      section: section ?? this.section,
      label: label ?? this.label,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      rceptNo: rceptNo ?? this.rceptNo,
      settlementDate: settlementDate is DateTime?
          ? settlementDate
          : this.settlementDate,
      headers: headers ?? this.headers.map((e0) => e0).toList(),
      rows: rows ?? this.rows.map((e0) => e0.copyWith()).toList(),
      emptyRowCount: emptyRowCount ?? this.emptyRowCount,
      source: source is _i5ra8lvy.Source? ? source : this.source?.copyWith(),
      years: years ?? this.years.map((e0) => e0).toList(),
    );
  }
}
