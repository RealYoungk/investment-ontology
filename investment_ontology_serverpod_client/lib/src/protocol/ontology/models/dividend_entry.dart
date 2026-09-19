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

/// 배당에 관한 사항 한 행 (alotMatter). 값의 단위는 행 이름에 있어(unit) 원으로 바꾸지 않는다.
abstract class DividendEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DividendEntry._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.ord,
    required this.item,
    this.unit,
    this.stockKind,
    this.current,
    this.prior,
    this.beforePrior,
  });

  factory DividendEntry({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String item,
    String? unit,
    String? stockKind,
    double? current,
    double? prior,
    double? beforePrior,
  }) = _DividendEntryImpl;

  factory DividendEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return DividendEntry(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      ord: jsonSerialization['ord'] as int,
      item: jsonSerialization['item'] as String,
      unit: jsonSerialization['unit'] as String?,
      stockKind: jsonSerialization['stockKind'] as String?,
      current: (jsonSerialization['current'] as num?)?.toDouble(),
      prior: (jsonSerialization['prior'] as num?)?.toDouble(),
      beforePrior: (jsonSerialization['beforePrior'] as num?)?.toDouble(),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int reportId;

  int companyId;

  int bsnsYear;

  int ord;

  /// 항목 원문 (주당액면가액(원), (연결)당기순이익(백만원), 현금배당성향(%) …)
  String item;

  /// 항목 이름 끝의 단위 (원, 백만원, %, 주 …). 없으면 null
  String? unit;

  String? stockKind;

  /// 당기·전기·전전기 값
  double? current;

  double? prior;

  double? beforePrior;

  /// Returns a shallow copy of this [DividendEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DividendEntry copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? item,
    String? unit,
    String? stockKind,
    double? current,
    double? prior,
    double? beforePrior,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DividendEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'item': item,
      if (unit != null) 'unit': unit,
      if (stockKind != null) 'stockKind': stockKind,
      if (current != null) 'current': current,
      if (prior != null) 'prior': prior,
      if (beforePrior != null) 'beforePrior': beforePrior,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DividendEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'item': item,
      if (unit != null) 'unit': unit,
      if (stockKind != null) 'stockKind': stockKind,
      if (current != null) 'current': current,
      if (prior != null) 'prior': prior,
      if (beforePrior != null) 'beforePrior': beforePrior,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DividendEntryImpl extends DividendEntry {
  _DividendEntryImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String item,
    String? unit,
    String? stockKind,
    double? current,
    double? prior,
    double? beforePrior,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         ord: ord,
         item: item,
         unit: unit,
         stockKind: stockKind,
         current: current,
         prior: prior,
         beforePrior: beforePrior,
       );

  /// Returns a shallow copy of this [DividendEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DividendEntry copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? item,
    Object? unit = _Undefined,
    Object? stockKind = _Undefined,
    Object? current = _Undefined,
    Object? prior = _Undefined,
    Object? beforePrior = _Undefined,
  }) {
    return DividendEntry(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      ord: ord ?? this.ord,
      item: item ?? this.item,
      unit: unit is String? ? unit : this.unit,
      stockKind: stockKind is String? ? stockKind : this.stockKind,
      current: current is double? ? current : this.current,
      prior: prior is double? ? prior : this.prior,
      beforePrior: beforePrior is double? ? beforePrior : this.beforePrior,
    );
  }
}
