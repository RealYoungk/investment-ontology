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

/// 주식의 총수 현황 한 줄 (보통주 · 우선주 · 합계).
abstract class StockTotalRow
    implements _is.SerializableModel, _is.ProtocolSerialization {
  StockTotalRow._({
    required this.kind,
    this.issued,
    this.treasury,
    this.outstanding,
    this.authorized,
  });

  factory StockTotalRow({
    required String kind,
    BigInt? issued,
    BigInt? treasury,
    BigInt? outstanding,
    BigInt? authorized,
  }) = _StockTotalRowImpl;

  factory StockTotalRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return StockTotalRow(
      kind: jsonSerialization['kind'] as String,
      issued: jsonSerialization['issued'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['issued']),
      treasury: jsonSerialization['treasury'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['treasury']),
      outstanding: jsonSerialization['outstanding'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['outstanding']),
      authorized: jsonSerialization['authorized'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['authorized']),
    );
  }

  String kind;

  /// 발행주식의 총수
  BigInt? issued;

  BigInt? treasury;

  /// 유통주식수
  BigInt? outstanding;

  /// 정관상 발행할 수 있는 주식의 총수 (발행 계획이나 확정 희석 물량 아님)
  BigInt? authorized;

  /// Returns a shallow copy of this [StockTotalRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  StockTotalRow copyWith({
    String? kind,
    BigInt? issued,
    BigInt? treasury,
    BigInt? outstanding,
    BigInt? authorized,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StockTotalRow',
      'kind': kind,
      if (issued != null) 'issued': issued?.toJson(),
      if (treasury != null) 'treasury': treasury?.toJson(),
      if (outstanding != null) 'outstanding': outstanding?.toJson(),
      if (authorized != null) 'authorized': authorized?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StockTotalRow',
      'kind': kind,
      if (issued != null) 'issued': issued?.toJson(),
      if (treasury != null) 'treasury': treasury?.toJson(),
      if (outstanding != null) 'outstanding': outstanding?.toJson(),
      if (authorized != null) 'authorized': authorized?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StockTotalRowImpl extends StockTotalRow {
  _StockTotalRowImpl({
    required String kind,
    BigInt? issued,
    BigInt? treasury,
    BigInt? outstanding,
    BigInt? authorized,
  }) : super._(
         kind: kind,
         issued: issued,
         treasury: treasury,
         outstanding: outstanding,
         authorized: authorized,
       );

  /// Returns a shallow copy of this [StockTotalRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  StockTotalRow copyWith({
    String? kind,
    Object? issued = _Undefined,
    Object? treasury = _Undefined,
    Object? outstanding = _Undefined,
    Object? authorized = _Undefined,
  }) {
    return StockTotalRow(
      kind: kind ?? this.kind,
      issued: issued is BigInt? ? issued : this.issued,
      treasury: treasury is BigInt? ? treasury : this.treasury,
      outstanding: outstanding is BigInt? ? outstanding : this.outstanding,
      authorized: authorized is BigInt? ? authorized : this.authorized,
    );
  }
}
