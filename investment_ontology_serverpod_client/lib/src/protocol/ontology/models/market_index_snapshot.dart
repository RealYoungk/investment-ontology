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

/// 지수(코스피·코스닥·KRX·테마)의 하루 값. 공공데이터포털 금융위원회_지수시세정보(getStockMarketIndex_V2) 응답 한 행.
/// 지수 값은 원문 소수 그대로, 금액은 원 단위 정수. 등락률처럼 원천 값으로 계산되는 값은 등락률(fltRt)만 원문대로 둔다.
abstract class MarketIndexSnapshot
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MarketIndexSnapshot._({
    this.id,
    required this.baseDate,
    required this.series,
    required this.name,
    required this.close,
    this.change,
    this.changeRate,
    this.open,
    this.high,
    this.low,
    this.volume,
    this.tradingValue,
    this.marketCap,
    this.constituentCount,
    required this.sourceId,
  });

  factory MarketIndexSnapshot({
    int? id,
    required DateTime baseDate,
    required String series,
    required String name,
    required double close,
    double? change,
    double? changeRate,
    double? open,
    double? high,
    double? low,
    BigInt? volume,
    BigInt? tradingValue,
    BigInt? marketCap,
    int? constituentCount,
    required int sourceId,
  }) = _MarketIndexSnapshotImpl;

  factory MarketIndexSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return MarketIndexSnapshot(
      id: jsonSerialization['id'] as int?,
      baseDate: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['baseDate'],
      ),
      series: jsonSerialization['series'] as String,
      name: jsonSerialization['name'] as String,
      close: (jsonSerialization['close'] as num).toDouble(),
      change: (jsonSerialization['change'] as num?)?.toDouble(),
      changeRate: (jsonSerialization['changeRate'] as num?)?.toDouble(),
      open: (jsonSerialization['open'] as num?)?.toDouble(),
      high: (jsonSerialization['high'] as num?)?.toDouble(),
      low: (jsonSerialization['low'] as num?)?.toDouble(),
      volume: jsonSerialization['volume'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['volume']),
      tradingValue: jsonSerialization['tradingValue'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['tradingValue'],
            ),
      marketCap: jsonSerialization['marketCap'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['marketCap']),
      constituentCount: jsonSerialization['constituentCount'] as int?,
      sourceId: jsonSerialization['sourceId'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// 기준일 (UTC 자정)
  DateTime baseDate;

  /// 지수 계열 (idxCsf: KOSPI시리즈 · KOSDAQ시리즈 · KRX시리즈 · 테마시리즈)
  String series;

  /// 지수명 (idxNm: 코스피, 코스닥, IT 서비스 …)
  String name;

  /// 종가 (clpr)
  double close;

  /// 전일 대비 (vs)
  double? change;

  /// 등락률 % (fltRt)
  double? changeRate;

  /// 시가·고가·저가 (mkp, hipr, lopr)
  double? open;

  double? high;

  double? low;

  /// 거래량 (trqu)
  BigInt? volume;

  /// 거래대금 (trPrc)
  BigInt? tradingValue;

  /// 상장시가총액 (lstgMrktTotAmt)
  BigInt? marketCap;

  /// 채용 종목 수 (epyItmsCnt)
  int? constituentCount;

  int sourceId;

  /// Returns a shallow copy of this [MarketIndexSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MarketIndexSnapshot copyWith({
    int? id,
    DateTime? baseDate,
    String? series,
    String? name,
    double? close,
    double? change,
    double? changeRate,
    double? open,
    double? high,
    double? low,
    BigInt? volume,
    BigInt? tradingValue,
    BigInt? marketCap,
    int? constituentCount,
    int? sourceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MarketIndexSnapshot',
      if (id != null) 'id': id,
      'baseDate': baseDate.toJson(),
      'series': series,
      'name': name,
      'close': close,
      if (change != null) 'change': change,
      if (changeRate != null) 'changeRate': changeRate,
      if (open != null) 'open': open,
      if (high != null) 'high': high,
      if (low != null) 'low': low,
      if (volume != null) 'volume': volume?.toJson(),
      if (tradingValue != null) 'tradingValue': tradingValue?.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      if (constituentCount != null) 'constituentCount': constituentCount,
      'sourceId': sourceId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MarketIndexSnapshot',
      if (id != null) 'id': id,
      'baseDate': baseDate.toJson(),
      'series': series,
      'name': name,
      'close': close,
      if (change != null) 'change': change,
      if (changeRate != null) 'changeRate': changeRate,
      if (open != null) 'open': open,
      if (high != null) 'high': high,
      if (low != null) 'low': low,
      if (volume != null) 'volume': volume?.toJson(),
      if (tradingValue != null) 'tradingValue': tradingValue?.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      if (constituentCount != null) 'constituentCount': constituentCount,
      'sourceId': sourceId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MarketIndexSnapshotImpl extends MarketIndexSnapshot {
  _MarketIndexSnapshotImpl({
    int? id,
    required DateTime baseDate,
    required String series,
    required String name,
    required double close,
    double? change,
    double? changeRate,
    double? open,
    double? high,
    double? low,
    BigInt? volume,
    BigInt? tradingValue,
    BigInt? marketCap,
    int? constituentCount,
    required int sourceId,
  }) : super._(
         id: id,
         baseDate: baseDate,
         series: series,
         name: name,
         close: close,
         change: change,
         changeRate: changeRate,
         open: open,
         high: high,
         low: low,
         volume: volume,
         tradingValue: tradingValue,
         marketCap: marketCap,
         constituentCount: constituentCount,
         sourceId: sourceId,
       );

  /// Returns a shallow copy of this [MarketIndexSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MarketIndexSnapshot copyWith({
    Object? id = _Undefined,
    DateTime? baseDate,
    String? series,
    String? name,
    double? close,
    Object? change = _Undefined,
    Object? changeRate = _Undefined,
    Object? open = _Undefined,
    Object? high = _Undefined,
    Object? low = _Undefined,
    Object? volume = _Undefined,
    Object? tradingValue = _Undefined,
    Object? marketCap = _Undefined,
    Object? constituentCount = _Undefined,
    int? sourceId,
  }) {
    return MarketIndexSnapshot(
      id: id is int? ? id : this.id,
      baseDate: baseDate ?? this.baseDate,
      series: series ?? this.series,
      name: name ?? this.name,
      close: close ?? this.close,
      change: change is double? ? change : this.change,
      changeRate: changeRate is double? ? changeRate : this.changeRate,
      open: open is double? ? open : this.open,
      high: high is double? ? high : this.high,
      low: low is double? ? low : this.low,
      volume: volume is BigInt? ? volume : this.volume,
      tradingValue: tradingValue is BigInt? ? tradingValue : this.tradingValue,
      marketCap: marketCap is BigInt? ? marketCap : this.marketCap,
      constituentCount: constituentCount is int?
          ? constituentCount
          : this.constituentCount,
      sourceId: sourceId ?? this.sourceId,
    );
  }
}
