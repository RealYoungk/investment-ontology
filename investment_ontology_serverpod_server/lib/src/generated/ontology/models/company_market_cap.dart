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
import '../../ontology/models/security_quote.dart' as _ioj0l7a6;
import '../../ontology/models/source.dart' as _i5ra8lvy;

/// 기업의 기준일 시가총액. 발행 종목(보통주·우선주 등) 시가총액의 합.
abstract class CompanyMarketCap
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CompanyMarketCap._({
    required this.baseDate,
    this.marketCap,
    required this.securities,
    this.source,
  });

  factory CompanyMarketCap({
    required DateTime baseDate,
    BigInt? marketCap,
    required List<_ioj0l7a6.SecurityQuote> securities,
    _i5ra8lvy.Source? source,
  }) = _CompanyMarketCapImpl;

  factory CompanyMarketCap.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyMarketCap(
      baseDate: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['baseDate'],
      ),
      marketCap: jsonSerialization['marketCap'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['marketCap']),
      securities: _i4yshtjp.Protocol()
          .deserialize<List<_ioj0l7a6.SecurityQuote>>(
            jsonSerialization['securities'],
          ),
      source: jsonSerialization['source'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<_i5ra8lvy.Source>(
              jsonSerialization['source'],
            ),
    );
  }

  DateTime baseDate;

  /// 종목 시가총액 합. 한 종목이라도 값이 없으면 null
  BigInt? marketCap;

  List<_ioj0l7a6.SecurityQuote> securities;

  _i5ra8lvy.Source? source;

  /// Returns a shallow copy of this [CompanyMarketCap]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CompanyMarketCap copyWith({
    DateTime? baseDate,
    BigInt? marketCap,
    List<_ioj0l7a6.SecurityQuote>? securities,
    _i5ra8lvy.Source? source,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyMarketCap',
      'baseDate': baseDate.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      'securities': securities.toJson(valueToJson: (v) => v.toJson()),
      if (source != null) 'source': source?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyMarketCap',
      'baseDate': baseDate.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      'securities': securities.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      if (source != null) 'source': source?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanyMarketCapImpl extends CompanyMarketCap {
  _CompanyMarketCapImpl({
    required DateTime baseDate,
    BigInt? marketCap,
    required List<_ioj0l7a6.SecurityQuote> securities,
    _i5ra8lvy.Source? source,
  }) : super._(
         baseDate: baseDate,
         marketCap: marketCap,
         securities: securities,
         source: source,
       );

  /// Returns a shallow copy of this [CompanyMarketCap]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CompanyMarketCap copyWith({
    DateTime? baseDate,
    Object? marketCap = _Undefined,
    List<_ioj0l7a6.SecurityQuote>? securities,
    Object? source = _Undefined,
  }) {
    return CompanyMarketCap(
      baseDate: baseDate ?? this.baseDate,
      marketCap: marketCap is BigInt? ? marketCap : this.marketCap,
      securities:
          securities ?? this.securities.map((e0) => e0.copyWith()).toList(),
      source: source is _i5ra8lvy.Source? ? source : this.source?.copyWith(),
    );
  }
}
