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

/// 자기주식 취득 및 처분 한 행 (tesstkAcqsDspsSttus). 수량은 주.
abstract class TreasuryStockEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  TreasuryStockEntry._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.ord,
    this.method1,
    this.method2,
    this.method3,
    this.stockKind,
    this.sharesBegin,
    this.acquired,
    this.disposed,
    this.retired,
    this.sharesEnd,
    this.remark,
    required this.isTotal,
  });

  factory TreasuryStockEntry({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    String? method1,
    String? method2,
    String? method3,
    String? stockKind,
    BigInt? sharesBegin,
    BigInt? acquired,
    BigInt? disposed,
    BigInt? retired,
    BigInt? sharesEnd,
    String? remark,
    required bool isTotal,
  }) = _TreasuryStockEntryImpl;

  factory TreasuryStockEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return TreasuryStockEntry(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      ord: jsonSerialization['ord'] as int,
      method1: jsonSerialization['method1'] as String?,
      method2: jsonSerialization['method2'] as String?,
      method3: jsonSerialization['method3'] as String?,
      stockKind: jsonSerialization['stockKind'] as String?,
      sharesBegin: jsonSerialization['sharesBegin'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['sharesBegin']),
      acquired: jsonSerialization['acquired'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['acquired']),
      disposed: jsonSerialization['disposed'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['disposed']),
      retired: jsonSerialization['retired'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['retired']),
      sharesEnd: jsonSerialization['sharesEnd'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['sharesEnd']),
      remark: jsonSerialization['remark'] as String?,
      isTotal: _isc.BoolJsonExtension.fromJson(jsonSerialization['isTotal']),
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

  /// 취득 방법 원문 (대·중·소분류)
  String? method1;

  String? method2;

  String? method3;

  String? stockKind;

  BigInt? sharesBegin;

  BigInt? acquired;

  BigInt? disposed;

  BigInt? retired;

  BigInt? sharesEnd;

  String? remark;

  /// 총계·소계 행
  bool isTotal;

  /// Returns a shallow copy of this [TreasuryStockEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  TreasuryStockEntry copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? method1,
    String? method2,
    String? method3,
    String? stockKind,
    BigInt? sharesBegin,
    BigInt? acquired,
    BigInt? disposed,
    BigInt? retired,
    BigInt? sharesEnd,
    String? remark,
    bool? isTotal,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TreasuryStockEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      if (method1 != null) 'method1': method1,
      if (method2 != null) 'method2': method2,
      if (method3 != null) 'method3': method3,
      if (stockKind != null) 'stockKind': stockKind,
      if (sharesBegin != null) 'sharesBegin': sharesBegin?.toJson(),
      if (acquired != null) 'acquired': acquired?.toJson(),
      if (disposed != null) 'disposed': disposed?.toJson(),
      if (retired != null) 'retired': retired?.toJson(),
      if (sharesEnd != null) 'sharesEnd': sharesEnd?.toJson(),
      if (remark != null) 'remark': remark,
      'isTotal': isTotal,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TreasuryStockEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      if (method1 != null) 'method1': method1,
      if (method2 != null) 'method2': method2,
      if (method3 != null) 'method3': method3,
      if (stockKind != null) 'stockKind': stockKind,
      if (sharesBegin != null) 'sharesBegin': sharesBegin?.toJson(),
      if (acquired != null) 'acquired': acquired?.toJson(),
      if (disposed != null) 'disposed': disposed?.toJson(),
      if (retired != null) 'retired': retired?.toJson(),
      if (sharesEnd != null) 'sharesEnd': sharesEnd?.toJson(),
      if (remark != null) 'remark': remark,
      'isTotal': isTotal,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TreasuryStockEntryImpl extends TreasuryStockEntry {
  _TreasuryStockEntryImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    String? method1,
    String? method2,
    String? method3,
    String? stockKind,
    BigInt? sharesBegin,
    BigInt? acquired,
    BigInt? disposed,
    BigInt? retired,
    BigInt? sharesEnd,
    String? remark,
    required bool isTotal,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         ord: ord,
         method1: method1,
         method2: method2,
         method3: method3,
         stockKind: stockKind,
         sharesBegin: sharesBegin,
         acquired: acquired,
         disposed: disposed,
         retired: retired,
         sharesEnd: sharesEnd,
         remark: remark,
         isTotal: isTotal,
       );

  /// Returns a shallow copy of this [TreasuryStockEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  TreasuryStockEntry copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    Object? method1 = _Undefined,
    Object? method2 = _Undefined,
    Object? method3 = _Undefined,
    Object? stockKind = _Undefined,
    Object? sharesBegin = _Undefined,
    Object? acquired = _Undefined,
    Object? disposed = _Undefined,
    Object? retired = _Undefined,
    Object? sharesEnd = _Undefined,
    Object? remark = _Undefined,
    bool? isTotal,
  }) {
    return TreasuryStockEntry(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      ord: ord ?? this.ord,
      method1: method1 is String? ? method1 : this.method1,
      method2: method2 is String? ? method2 : this.method2,
      method3: method3 is String? ? method3 : this.method3,
      stockKind: stockKind is String? ? stockKind : this.stockKind,
      sharesBegin: sharesBegin is BigInt? ? sharesBegin : this.sharesBegin,
      acquired: acquired is BigInt? ? acquired : this.acquired,
      disposed: disposed is BigInt? ? disposed : this.disposed,
      retired: retired is BigInt? ? retired : this.retired,
      sharesEnd: sharesEnd is BigInt? ? sharesEnd : this.sharesEnd,
      remark: remark is String? ? remark : this.remark,
      isTotal: isTotal ?? this.isTotal,
    );
  }
}
