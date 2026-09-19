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

/// 종목의 하루 시세. 공공데이터포털 금융위원회_주식시세정보(getStockPriceInfo) 응답 한 행.
/// 가격·금액은 원 단위 정수. 등락률처럼 원천 값으로 계산되는 값은 저장하지 않는다.
abstract class MarketSnapshot
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MarketSnapshot._({
    this.id,
    required this.securityId,
    required this.baseDate,
    this.closePrice,
    this.change,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.volume,
    this.tradingValue,
    this.listedShares,
    this.marketCap,
    required this.sourceId,
  });

  factory MarketSnapshot({
    int? id,
    required int securityId,
    required DateTime baseDate,
    BigInt? closePrice,
    BigInt? change,
    BigInt? openPrice,
    BigInt? highPrice,
    BigInt? lowPrice,
    BigInt? volume,
    BigInt? tradingValue,
    BigInt? listedShares,
    BigInt? marketCap,
    required int sourceId,
  }) = _MarketSnapshotImpl;

  factory MarketSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return MarketSnapshot(
      id: jsonSerialization['id'] as int?,
      securityId: jsonSerialization['securityId'] as int,
      baseDate: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['baseDate'],
      ),
      closePrice: jsonSerialization['closePrice'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['closePrice']),
      change: jsonSerialization['change'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['change']),
      openPrice: jsonSerialization['openPrice'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['openPrice']),
      highPrice: jsonSerialization['highPrice'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['highPrice']),
      lowPrice: jsonSerialization['lowPrice'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['lowPrice']),
      volume: jsonSerialization['volume'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['volume']),
      tradingValue: jsonSerialization['tradingValue'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['tradingValue'],
            ),
      listedShares: jsonSerialization['listedShares'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['listedShares'],
            ),
      marketCap: jsonSerialization['marketCap'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['marketCap']),
      sourceId: jsonSerialization['sourceId'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int securityId;

  /// 기준일 (UTC 자정)
  DateTime baseDate;

  /// 종가 (clpr)
  BigInt? closePrice;

  /// 전일 대비 (vs)
  BigInt? change;

  /// 시가·고가·저가 (mkp, hipr, lopr)
  BigInt? openPrice;

  BigInt? highPrice;

  BigInt? lowPrice;

  /// 거래량 (trqu)
  BigInt? volume;

  /// 거래대금 (trPrc)
  BigInt? tradingValue;

  /// 상장주식수 (lstgStCnt)
  BigInt? listedShares;

  /// 시가총액 (mrktTotAmt)
  BigInt? marketCap;

  int sourceId;

  /// Returns a shallow copy of this [MarketSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MarketSnapshot copyWith({
    int? id,
    int? securityId,
    DateTime? baseDate,
    BigInt? closePrice,
    BigInt? change,
    BigInt? openPrice,
    BigInt? highPrice,
    BigInt? lowPrice,
    BigInt? volume,
    BigInt? tradingValue,
    BigInt? listedShares,
    BigInt? marketCap,
    int? sourceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MarketSnapshot',
      if (id != null) 'id': id,
      'securityId': securityId,
      'baseDate': baseDate.toJson(),
      if (closePrice != null) 'closePrice': closePrice?.toJson(),
      if (change != null) 'change': change?.toJson(),
      if (openPrice != null) 'openPrice': openPrice?.toJson(),
      if (highPrice != null) 'highPrice': highPrice?.toJson(),
      if (lowPrice != null) 'lowPrice': lowPrice?.toJson(),
      if (volume != null) 'volume': volume?.toJson(),
      if (tradingValue != null) 'tradingValue': tradingValue?.toJson(),
      if (listedShares != null) 'listedShares': listedShares?.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      'sourceId': sourceId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MarketSnapshot',
      if (id != null) 'id': id,
      'securityId': securityId,
      'baseDate': baseDate.toJson(),
      if (closePrice != null) 'closePrice': closePrice?.toJson(),
      if (change != null) 'change': change?.toJson(),
      if (openPrice != null) 'openPrice': openPrice?.toJson(),
      if (highPrice != null) 'highPrice': highPrice?.toJson(),
      if (lowPrice != null) 'lowPrice': lowPrice?.toJson(),
      if (volume != null) 'volume': volume?.toJson(),
      if (tradingValue != null) 'tradingValue': tradingValue?.toJson(),
      if (listedShares != null) 'listedShares': listedShares?.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      'sourceId': sourceId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MarketSnapshotImpl extends MarketSnapshot {
  _MarketSnapshotImpl({
    int? id,
    required int securityId,
    required DateTime baseDate,
    BigInt? closePrice,
    BigInt? change,
    BigInt? openPrice,
    BigInt? highPrice,
    BigInt? lowPrice,
    BigInt? volume,
    BigInt? tradingValue,
    BigInt? listedShares,
    BigInt? marketCap,
    required int sourceId,
  }) : super._(
         id: id,
         securityId: securityId,
         baseDate: baseDate,
         closePrice: closePrice,
         change: change,
         openPrice: openPrice,
         highPrice: highPrice,
         lowPrice: lowPrice,
         volume: volume,
         tradingValue: tradingValue,
         listedShares: listedShares,
         marketCap: marketCap,
         sourceId: sourceId,
       );

  /// Returns a shallow copy of this [MarketSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MarketSnapshot copyWith({
    Object? id = _Undefined,
    int? securityId,
    DateTime? baseDate,
    Object? closePrice = _Undefined,
    Object? change = _Undefined,
    Object? openPrice = _Undefined,
    Object? highPrice = _Undefined,
    Object? lowPrice = _Undefined,
    Object? volume = _Undefined,
    Object? tradingValue = _Undefined,
    Object? listedShares = _Undefined,
    Object? marketCap = _Undefined,
    int? sourceId,
  }) {
    return MarketSnapshot(
      id: id is int? ? id : this.id,
      securityId: securityId ?? this.securityId,
      baseDate: baseDate ?? this.baseDate,
      closePrice: closePrice is BigInt? ? closePrice : this.closePrice,
      change: change is BigInt? ? change : this.change,
      openPrice: openPrice is BigInt? ? openPrice : this.openPrice,
      highPrice: highPrice is BigInt? ? highPrice : this.highPrice,
      lowPrice: lowPrice is BigInt? ? lowPrice : this.lowPrice,
      volume: volume is BigInt? ? volume : this.volume,
      tradingValue: tradingValue is BigInt? ? tradingValue : this.tradingValue,
      listedShares: listedShares is BigInt? ? listedShares : this.listedShares,
      marketCap: marketCap is BigInt? ? marketCap : this.marketCap,
      sourceId: sourceId ?? this.sourceId,
    );
  }
}
