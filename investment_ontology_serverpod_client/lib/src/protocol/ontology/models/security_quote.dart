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

/// 종목의 기준일 시세 요약.
abstract class SecurityQuote
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SecurityQuote._({
    required this.securityId,
    required this.shortCode,
    required this.name,
    this.closePrice,
    this.listedShares,
    this.marketCap,
    this.volume,
  });

  factory SecurityQuote({
    required int securityId,
    required String shortCode,
    required String name,
    BigInt? closePrice,
    BigInt? listedShares,
    BigInt? marketCap,
    BigInt? volume,
  }) = _SecurityQuoteImpl;

  factory SecurityQuote.fromJson(Map<String, dynamic> jsonSerialization) {
    return SecurityQuote(
      securityId: jsonSerialization['securityId'] as int,
      shortCode: jsonSerialization['shortCode'] as String,
      name: jsonSerialization['name'] as String,
      closePrice: jsonSerialization['closePrice'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['closePrice']),
      listedShares: jsonSerialization['listedShares'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['listedShares'],
            ),
      marketCap: jsonSerialization['marketCap'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['marketCap']),
      volume: jsonSerialization['volume'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['volume']),
    );
  }

  int securityId;

  String shortCode;

  String name;

  BigInt? closePrice;

  BigInt? listedShares;

  BigInt? marketCap;

  BigInt? volume;

  /// Returns a shallow copy of this [SecurityQuote]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SecurityQuote copyWith({
    int? securityId,
    String? shortCode,
    String? name,
    BigInt? closePrice,
    BigInt? listedShares,
    BigInt? marketCap,
    BigInt? volume,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SecurityQuote',
      'securityId': securityId,
      'shortCode': shortCode,
      'name': name,
      if (closePrice != null) 'closePrice': closePrice?.toJson(),
      if (listedShares != null) 'listedShares': listedShares?.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      if (volume != null) 'volume': volume?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SecurityQuote',
      'securityId': securityId,
      'shortCode': shortCode,
      'name': name,
      if (closePrice != null) 'closePrice': closePrice?.toJson(),
      if (listedShares != null) 'listedShares': listedShares?.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      if (volume != null) 'volume': volume?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SecurityQuoteImpl extends SecurityQuote {
  _SecurityQuoteImpl({
    required int securityId,
    required String shortCode,
    required String name,
    BigInt? closePrice,
    BigInt? listedShares,
    BigInt? marketCap,
    BigInt? volume,
  }) : super._(
         securityId: securityId,
         shortCode: shortCode,
         name: name,
         closePrice: closePrice,
         listedShares: listedShares,
         marketCap: marketCap,
         volume: volume,
       );

  /// Returns a shallow copy of this [SecurityQuote]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SecurityQuote copyWith({
    int? securityId,
    String? shortCode,
    String? name,
    Object? closePrice = _Undefined,
    Object? listedShares = _Undefined,
    Object? marketCap = _Undefined,
    Object? volume = _Undefined,
  }) {
    return SecurityQuote(
      securityId: securityId ?? this.securityId,
      shortCode: shortCode ?? this.shortCode,
      name: name ?? this.name,
      closePrice: closePrice is BigInt? ? closePrice : this.closePrice,
      listedShares: listedShares is BigInt? ? listedShares : this.listedShares,
      marketCap: marketCap is BigInt? ? marketCap : this.marketCap,
      volume: volume is BigInt? ? volume : this.volume,
    );
  }
}
