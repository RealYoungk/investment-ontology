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

/// 주식의 총수 현황 한 줄 (보통주 · 우선주 · 합계).
abstract class StockTotalRow
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  StockTotalRow._({
    required this.kind,
    this.issued,
    this.treasury,
    this.outstanding,
  });

  factory StockTotalRow({
    required String kind,
    BigInt? issued,
    BigInt? treasury,
    BigInt? outstanding,
  }) = _StockTotalRowImpl;

  factory StockTotalRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return StockTotalRow(
      kind: jsonSerialization['kind'] as String,
      issued: jsonSerialization['issued'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['issued']),
      treasury: jsonSerialization['treasury'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['treasury']),
      outstanding: jsonSerialization['outstanding'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['outstanding']),
    );
  }

  String kind;

  /// 발행주식의 총수
  BigInt? issued;

  BigInt? treasury;

  /// 유통주식수
  BigInt? outstanding;

  /// Returns a shallow copy of this [StockTotalRow]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  StockTotalRow copyWith({
    String? kind,
    BigInt? issued,
    BigInt? treasury,
    BigInt? outstanding,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StockTotalRow',
      'kind': kind,
      if (issued != null) 'issued': issued?.toJson(),
      if (treasury != null) 'treasury': treasury?.toJson(),
      if (outstanding != null) 'outstanding': outstanding?.toJson(),
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
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StockTotalRowImpl extends StockTotalRow {
  _StockTotalRowImpl({
    required String kind,
    BigInt? issued,
    BigInt? treasury,
    BigInt? outstanding,
  }) : super._(
         kind: kind,
         issued: issued,
         treasury: treasury,
         outstanding: outstanding,
       );

  /// Returns a shallow copy of this [StockTotalRow]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  StockTotalRow copyWith({
    String? kind,
    Object? issued = _Undefined,
    Object? treasury = _Undefined,
    Object? outstanding = _Undefined,
  }) {
    return StockTotalRow(
      kind: kind ?? this.kind,
      issued: issued is BigInt? ? issued : this.issued,
      treasury: treasury is BigInt? ? treasury : this.treasury,
      outstanding: outstanding is BigInt? ? outstanding : this.outstanding,
    );
  }
}
